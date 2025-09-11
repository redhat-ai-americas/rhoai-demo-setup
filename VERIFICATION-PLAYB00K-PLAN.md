### Verification Playbook Plan

Purpose: Provide a fast, read-only validation that an OpenShift cluster is minimally ready for OpenShift AI projects.

This plan describes how we will implement an Ansible playbook `playbooks/verify-cluster.ansible.yml` that checks:
- One CPU worker node (non-GPU)
- At least one GPU node
- All nodes are schedulable (not cordoned)
- Web Terminal Operator is installed and healthy

Optional, toggleable checks are also provided to catch common blockers before RHOAI installation.

---

### Success criteria (acceptance tests)
- **CPU worker node**: At least 1 node with label `node-role.kubernetes.io/worker` and without GPU role/allocatable GPUs.
- **GPU node**: At least 1 node must be detected as GPU-capable by any of these signals:
  - Label `node-role.kubernetes.io/gpu` exists, or
  - NFD label `nvidia.com/gpu.present=true`, or
  - Allocatable resource `nvidia.com/gpu` > 0
- **All nodes schedulable**: No node has `.spec.unschedulable == true`.
- **Web Terminal Operator**: A `ClusterServiceVersion` in namespace `openshift-operators` with name starting `web-terminal` is present and `.status.phase == "Succeeded"`.

---

### Prerequisites
- `oc` CLI configured against the target cluster and authenticated (`oc whoami` succeeds)
- `jq` available in PATH (used for JSON parsing)

We will add a preflight in the playbook to assert both are present.

---

### Playbook layout
- File: `playbooks/verify-cluster.ansible.yml`
- Host: `localhost`
- Strategy: Read-only `shell`/`command` tasks using `oc` and `jq`, followed by `assert` tasks with clear failure messages
- Output: Human-friendly debug summary plus machine-friendly facts for CI consumption

---

### Default variables (toggle optional checks)
These will be implemented as Ansible vars (defaults may be overridden via `-e VAR=value`).

```yaml
# version / platform
min_ocp_version: "4.16.0"              # set to "" to disable version gating

# optional readiness checks (booleans)
require_default_sc: true                # fail if no default StorageClass
check_ingress: true                     # default IngressController available; console route admitted
check_olm: true                         # OLM packageserver CSV is Succeeded
check_pull_secret: true                 # global pull-secret has registry.redhat.io
check_clusteroperators: true            # key ClusterOperators are Available=True
check_scc_restricted_v2: true           # restricted-v2 SCC exists

# optional informational probes (do not fail by default)
info_gpu_taints: true                   # print taints on GPU nodes
info_capacity_floor: false              # print capacity of largest worker and warn if below floor
capacity_floor_cpu: 4                   # vCPU
capacity_floor_memory: "16Gi"          # RAM
optional_egress_probe: false            # try DNS/HTTPS for registry.redhat.io/quay.io
```

---

### Checks and implementation details

#### 1) Verify we can talk to the cluster
- Command: `oc whoami`
- Fail if non-zero exit code

Ansible outline:
```yaml
- name: Validate oc is authenticated
  shell: oc whoami
  register: oc_whoami
  changed_when: false
  failed_when: oc_whoami.rc != 0
```

#### 2) CPU worker node exists (non-GPU)
- Approach: Get all worker nodes; filter out nodes that appear GPU-capable; ensure >= 1 remains
- Command (robust):
```sh
oc get nodes -l 'node-role.kubernetes.io/worker' -o json \
| jq '[.items[]
       | select((.metadata.labels["node-role.kubernetes.io/gpu"]? // empty) | not)      # no gpu role label
       | select(((.status.allocatable["nvidia.com/gpu"]? // "0") | tonumber) == 0)    # no allocatable gpus
     ] | length'
```
- Assert result >= 1

Ansible outline:
```yaml
- name: Count CPU worker nodes (non-GPU)
  shell: >
    oc get nodes -l 'node-role.kubernetes.io/worker' -o json | \
    jq '[.items[] | select((.metadata.labels["node-role.kubernetes.io/gpu"]? // empty) | not)
                | select(((.status.allocatable["nvidia.com/gpu"]? // "0") | tonumber) == 0)] | length'
  register: cpu_worker_count
  changed_when: false

- name: Assert at least one CPU worker node exists
  assert:
    that:
      - (cpu_worker_count.stdout | int) >= 1
    fail_msg: "No CPU worker nodes detected (need at least one worker without GPU resources)."
    success_msg: "CPU worker nodes detected: {{ cpu_worker_count.stdout }}"
```

#### 3) GPU node exists
- Approach: Pass if any one of the following is true:
  - Node has role label `node-role.kubernetes.io/gpu`
  - Node has NFD label `nvidia.com/gpu.present=true`
  - Node has allocatable GPUs `status.allocatable["nvidia.com/gpu"] > 0`
- Commands:
```sh
oc get nodes -l 'node-role.kubernetes.io/gpu' --no-headers | wc -l
```
```sh
oc get nodes -o json | jq '[.items[] | select(.metadata.labels["nvidia.com/gpu.present"]=="true")] | length'
```
```sh
oc get nodes -o json | jq '[.items[] | ((.status.allocatable["nvidia.com/gpu"]? // "0")|tonumber) | select(.>0)] | length'
```
- Assert that at least one of the three counts is >= 1

Ansible outline:
```yaml
- name: Count GPU nodes by role label
  shell: oc get nodes -l 'node-role.kubernetes.io/gpu' --no-headers | wc -l
  register: gpu_role_count
  changed_when: false

- name: Count GPU nodes by NFD label
  shell: >
    oc get nodes -o json | jq '[.items[] | select(.metadata.labels["nvidia.com/gpu.present"]=="true")] | length'
  register: gpu_nfd_count
  changed_when: false

- name: Count GPU nodes by allocatable resource
  shell: >
    oc get nodes -o json | jq '[.items[] | ((.status.allocatable["nvidia.com/gpu"]? // "0")|tonumber) | select(.>0)] | length'
  register: gpu_alloc_count
  changed_when: false

- name: Assert at least one GPU node is available
  assert:
    that:
      - (gpu_role_count.stdout | int) > 0
      - (gpu_nfd_count.stdout | int) > 0
      - (gpu_alloc_count.stdout | int) > 0
    any_errors_fatal: false
  failed_when: >-
    (gpu_role_count.stdout | int) == 0 and
    (gpu_nfd_count.stdout | int) == 0 and
    (gpu_alloc_count.stdout | int) == 0
```

#### 4) All nodes are schedulable (not cordoned)
- Approach: Ensure no nodes have `.spec.unschedulable == true`
- Command:
```sh
oc get nodes -o json | jq '[.items[] | select(.spec.unschedulable==true)] | length'
```
- Assert result == 0; if not, print offending node names

Ansible outline:
```yaml
- name: Find unschedulable (cordoned) nodes
  shell: >
    oc get nodes -o json | jq -r '.items[] | select(.spec.unschedulable==true) | .metadata.name'
  register: unschedulable_nodes
  changed_when: false

- name: Assert all nodes are schedulable
  assert:
    that:
      - (unschedulable_nodes.stdout_lines | length) == 0
    fail_msg: "Found cordoned/unschedulable nodes: {{ unschedulable_nodes.stdout_lines | join(", ") }}"
    success_msg: "All nodes are schedulable."
```

#### 5) Web Terminal Operator is installed and healthy
- Approach: Find CSV in `openshift-operators` starting with `web-terminal` and verify `.status.phase==Succeeded`
- Command:
```sh
oc get csv -n openshift-operators -o json \
| jq -r '.items[] | select(.metadata.name | test("^web-terminal")) | select(.status.phase=="Succeeded") | .metadata.name'
```
- Assert non-empty

Ansible outline:
```yaml
- name: Verify Web Terminal operator CSV is Succeeded
  shell: >
    oc get csv -n openshift-operators -o json | \
    jq -r '.items[] | select(.metadata.name | test("^web-terminal")) | select(.status.phase=="Succeeded") | .metadata.name'
  register: web_terminal_csv
  changed_when: false

- name: Assert Web Terminal operator is installed
  assert:
    that:
      - web_terminal_csv.stdout != ""
    fail_msg: "Web Terminal operator CSV not found in Succeeded state."
    success_msg: "Web Terminal operator CSV: {{ web_terminal_csv.stdout }}"
```

---

### Optional checks (configurable)

#### OpenShift version gate (if `min_ocp_version` set)
- Command:
```sh
oc get clusterversion version -o json | jq -r '.status.desired.version'
```
- Compare semantic versions; fail if cluster version < `min_ocp_version`.

#### Default StorageClass present (`require_default_sc`)
- Command:
```sh
oc get sc -o json | jq '[.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true" or .metadata.annotations["storageclass.kubernetes.io/is-default-class"]==true)] | length'
```
- Assert count >= 1.

#### Ingress and route health (`check_ingress`)
- Default ingress Available:
```sh
oc get ingresscontroller/default -n openshift-ingress-operator -o json | jq -r 'first(.status.conditions[] | select(.type=="Available")).status'
```
- Console route admitted:
```sh
oc get route console -n openshift-console -o json | jq -e '.status.ingress[]? | any(.conditions[]?; .type=="Admitted" and .status=="True")'
```

#### OLM ready (`check_olm`)
- Packageserver CSV Succeeded:
```sh
oc get csv -n openshift-operator-lifecycle-manager -o json | jq -r 'first(.items[] | select(.metadata.name | test("packageserver"))).status.phase'
```
- Assert equals `Succeeded`.

#### Global pull-secret includes `registry.redhat.io` (`check_pull_secret`)
- Command:
```sh
oc get secret pull-secret -n openshift-config -o json \
| jq -r '.data[".dockerconfigjson"]' | base64 -d | jq -e '.auths | has("registry.redhat.io")'
```
- Assert exit code 0 (true).

#### Critical ClusterOperators Available (`check_clusteroperators`)
- Names to check: `console`, `ingress`, `image-registry`, `authentication`.
- Command:
```sh
oc get co -o json | jq -r '.items[] | {name:.metadata.name,available:(.status.conditions[] | select(.type=="Available").status)}'
```
- Assert each of the above names has `Available` = `True`.

#### SCC presence (`check_scc_restricted_v2`)
- Command: `oc get scc restricted-v2 --no-headers`
- Assert rc == 0.

#### GPU taints summary (`info_gpu_taints`)
- Command:
```sh
oc get nodes -l 'node-role.kubernetes.io/gpu' -o json | jq -r '.items[] | select(.spec.taints!=null) | "\(.metadata.name): \(.spec.taints | map(.key+":"+.effect) | join(", "))"'
```
- Print only; no failing condition.

#### Capacity floor (informational) (`info_capacity_floor`)
- Command (largest worker allocatable):
```sh
oc get nodes -l 'node-role.kubernetes.io/worker' -o json \
| jq -r '[.items[] | {name:.metadata.name,cpu:(.status.allocatable.cpu//"0"),mem:(.status.allocatable.memory//"0")} ]'
```
- Convert CPU/memory and compare to floors; warn if below.

#### Optional egress probe (`optional_egress_probe`)
- DNS/HTTPS reachability (no pods created):
```sh
getent hosts registry.redhat.io || nslookup registry.redhat.io || true
curl -sI https://registry.redhat.io/ | head -n1 || true
curl -sI https://quay.io/ | head -n1 || true
```
- Print results; do not fail by default.

---

### Preflight and summary tasks
- Check prerequisites:
```yaml
- name: Ensure oc is available
  shell: command -v oc
  register: oc_bin
  changed_when: false
  failed_when: oc_bin.rc != 0

- name: Ensure jq is available
  shell: command -v jq
  register: jq_bin
  changed_when: false
  failed_when: jq_bin.rc != 0
```
- Final summary debug:
```yaml
- name: Print verification summary
  debug:
    msg:
      - "CPU workers: {{ cpu_worker_count.stdout | default('N/A') }}"
      - "GPU role count: {{ gpu_role_count.stdout | default('0') }}"
      - "GPU NFD count: {{ gpu_nfd_count.stdout | default('0') }}"
      - "GPU alloc count: {{ gpu_alloc_count.stdout | default('0') }}"
      - "Unschedulable nodes: {{ unschedulable_nodes.stdout_lines | default([]) }}"
      - "Web Terminal CSV: {{ web_terminal_csv.stdout | default('') }}"
```

---

### Non-goals (for now)
- We will not modify cluster state (no uncordon/taint changes)
- We will not verify other operators beyond Web Terminal
- We will not check node readiness conditions; only schedulability as requested

---

### Running the playbook
```sh
ansible-playbook playbooks/verify-cluster.ansible.yml | tee verify-cluster.log
```
Exit code will be non-zero if any assertion fails.

---

### Future extensions (optional)
- Add a readiness check for node condition `Ready == True`
- Parameterize GPU detection strategy (role vs NFD vs allocatable) via vars
- Emit a single JSON result summary (for CI) in addition to human-readable output
- Add optional checks for other baseline operators (OpenShift GitOps, NFD, NVIDIA GPU Operator)