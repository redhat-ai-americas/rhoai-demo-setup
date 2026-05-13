### Remediation backlog

Track and implement the following fixes and improvements. Check off as completed.

---

### Critical fixes (ASAP)
- [ ] Ollama Service selector mismatch breaks routing
  - File: `components/15-ollama/ollama-svc.yaml`
  - Change Service selector to match the pod label:
    - Current: `selector: { deployment: ollama }`
    - Prefer: `selector: { app: ollama }`
  - Alternative: add label `deployment: ollama` to the Deployment pod template to match the current Service.

- [ ] Duplicate `resources` blocks in Ollama Deployment
  - File: `components/15-ollama/ollama-deployment.yaml`
  - Consolidate to a single `resources` block for the container (keep both memory and GPU limits/requests together).

---

### Version alignment
- [ ] Align RHOAI operator channel and vLLM ServingRuntime image
  - Files:
    - `components/10-rhoai-operator/rhoai-operator-subscription.yaml` (channel: `stable-2.19`)
    - `demos/vllm-modelserving/vllm-servingruntime.yaml` (image: `quay.io/modh/vllm:rhoai-2.20-cuda`)
  - Action: choose one path and align both sides
    - Option A: upgrade operator channel to the 2.20-compatible stream
    - Option B: downgrade vLLM image to `rhoai-2.19-cuda` (or ROCm if AMD)

---

### Image pinning and UBI compliance
- [ ] Replace `:latest` tags with pinned versions/digests for deterministic rollouts
  - Files containing `latest`:
    - `components/15-ollama/ollama-deployment.yaml` → `ghcr.io/redhat-na-ssa/ollama:latest`
    - `components/00-prereqs/web-terminal-tooling.yaml` → `ghcr.io/redhat-na-ssa/web-terminal-tooling:latest`
    - `components/14-minio/setup-minio.yaml` and `demos/vllm-modelserving/setup-minio.yaml` → `quay.io/minio/minio:latest`
    - Several `image-registry.openshift-image-registry.svc:5000/openshift/tools:latest`
- [ ] Confirm policy: Red Hat UBI-only images required?
  - If yes, plan to:
    - Build UBI9-based Containerfiles for OpenWebUI and Ollama
    - Publish internal images and update manifests
    - Consider replacing MinIO with ODF/NooBaa if policy restricts community storage
- [ ] OpenWebUI upstream image tag
  - File: `components/16-openwebui/openwebui-deployment.yaml` → `ghcr.io/open-webui/open-webui:main`
  - Pin to a release tag or digest; if UBI-only, rebase/build internally on UBI9.

---

### Secrets and authentication
- [ ] Remove committed HTPasswd secret from repo
  - File: `components/01-admin-user/secret-htpasswd.yaml`
  - Replace with automation to generate at apply time (similar to `openwebui-secret` creation in `playbooks/setup/openwebui.ansible.yml`).
- [ ] Protect external routes and avoid insecure termination
  - File: `components/15-ollama/ollama-route.yaml` uses `insecureEdgeTerminationPolicy: Allow`
  - Action: remove insecure policy; protect with OAuth proxy or Authorino (operator already installed) before exposure.
- [ ] Ensure `openwebui-secret` is created before Deployment starts
  - Already handled via playbook; verify idempotency and ordering.

---

### Notebook manifest cleanup
- [ ] Make `demos/vllm-modelserving/notebook.yaml` portable
  - Remove cluster-specific fields (e.g., `nodeName`, IPs, `imagePullSecrets`, `status` section, live annotations)
  - Keep minimal, reproducible spec with tolerations and accelerator profile label as needed.

---

### Documentation and prerequisites
- [ ] Add `jq` to prerequisites in `README.md` (used in playbooks)
- [ ] Fix README command and typos
  - Incorrect command reference: `playbooks/setup-cluster.ansible.yml` → should be `playbooks/cluster-setup.ansible.yml`
  - Fix typos: "NIVIDIA" → "NVIDIA", "depdendent" → "dependent", "OpenWebUi" → "OpenWebUI".

---

### GitOps readiness
- [ ] Add GitOps structure and Argo CD Applications
  - Create `manifests/` with `base/` and `overlays/`
  - Add `AppProject` and `Application` CRs to reconcile `components/` and `demos/`
  - Make automation optionally managed by Argo CD

---

### Consistency and hygiene
- [ ] Standardize `repo_dir` calculation across playbooks
  - Use a single, consistent pattern to resolve repository root for `oc apply` commands.
- [ ] Normalize namespace labels/annotations across components
  - Ensure monitoring labels and display names are consistent.

---

### FIPS and compliance follow-ups
- [ ] Confirm if FIPS is required for this environment
  - If yes:
    - Ensure FIPS-enabled UBI images and crypto libraries are used
    - Verify model-serving images (vLLM, Triton) compliance or provide approved alternates

---

### References (for quick navigation)
- Ollama Service: `components/15-ollama/ollama-svc.yaml`
- Ollama Deployment: `components/15-ollama/ollama-deployment.yaml`
- RHOAI operator subscription: `components/10-rhoai-operator/rhoai-operator-subscription.yaml`
- vLLM ServingRuntime: `demos/vllm-modelserving/vllm-servingruntime.yaml`
- OpenWebUI Deployment: `components/16-openwebui/openwebui-deployment.yaml`
- MinIO manifests: `components/14-minio/setup-minio.yaml`, `demos/vllm-modelserving/setup-minio.yaml`
- HTPasswd secret (to remove): `components/01-admin-user/secret-htpasswd.yaml`
- OpenWebUI secret creation: `playbooks/setup/openwebui.ansible.yml`
