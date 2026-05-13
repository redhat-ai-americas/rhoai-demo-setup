# Deploy — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Deploy Large Models (KServe RawDeployment)**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/deploying_models
- **Govern LLM Access with Models-as-a-Service (MaaS)** *(New in 3.3)*: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/govern_llm_access_with_models-as-a-service

---

## Overview

RHOAI supports two model-serving platforms:

| Platform | Mode | Best For |
|----------|------|----------|
| **KServe** (single-model) | RawDeployment (3.3 default) | Large models, dedicated resources, LLMs |
| **ModelMesh** (multi-model) | Shared runtime pool | Many smaller models, efficient GPU sharing |

In **3.3**, KServe operates in **RawDeployment** mode by default, removing the dependency
on Istio/Knative. This simplifies deployment and improves compatibility.

---

## Enable Model Serving in DataScienceCluster

```yaml
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
spec:
  components:
    kserve:
      managementState: Managed
      serving:
        managementState: Unmanaged    # RawDeployment (no Knative/Istio)
    modelmeshserving:
      managementState: Managed        # Optional: enable multi-model serving
```

---

## ServingRuntime CR

A ServingRuntime defines the container image and protocol for a model server:

```yaml
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  name: vllm-runtime
  namespace: my-ds-project
spec:
  supportedModelFormats:
    - name: pytorch
      version: "1"
      autoSelect: true
  multiModel: false
  containers:
    - name: kserve-container
      image: quay.io/rhoai/vllm:latest
      command: ["python", "-m", "vllm.entrypoints.openai.api_server"]
      args:
        - "--model=/mnt/models"
        - "--port=8080"
        - "--served-model-name={{.Name}}"
        - "--tensor-parallel-size=1"
      ports:
        - containerPort: 8080
          protocol: TCP
      volumeMounts:
        - mountPath: /dev/shm
          name: shm
  volumes:
    - name: shm
      emptyDir:
        medium: Memory
        sizeLimit: 2Gi
```

---

## InferenceService CR (KServe)

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: llama-3-8b
  namespace: my-ds-project
  annotations:
    serving.kserve.io/deploymentMode: RawDeployment   # 3.3 default
spec:
  predictor:
    minReplicas: 1
    maxReplicas: 3
    model:
      modelFormat:
        name: pytorch
      runtime: vllm-runtime
      storageUri: s3://my-bucket/llama-3-8b/
      resources:
        limits:
          cpu: "8"
          memory: "32Gi"
          nvidia.com/gpu: "1"
        requests:
          cpu: "4"
          memory: "16Gi"
          nvidia.com/gpu: "1"
```

---

## InferenceService with Auth (Token-Protected)

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: llama-3-8b-secured
  namespace: my-ds-project
  annotations:
    serving.kserve.io/deploymentMode: RawDeployment
    security.opendatahub.io/enable-auth: "true"      # Enables token auth
spec:
  predictor:
    minReplicas: 1
    model:
      modelFormat:
        name: pytorch
      runtime: vllm-runtime
      storageUri: s3://my-bucket/llama-3-8b/
      resources:
        limits:
          nvidia.com/gpu: "1"
```

---

## ClusterServingRuntime (Cluster-Wide)

Admins can create cluster-wide runtimes available to all namespaces:

```yaml
apiVersion: serving.kserve.io/v1alpha1
kind: ClusterServingRuntime
metadata:
  name: vllm-cuda-runtime
spec:
  supportedModelFormats:
    - name: pytorch
      version: "1"
      autoSelect: true
  multiModel: false
  containers:
    - name: kserve-container
      image: quay.io/rhoai/vllm:latest
      args:
        - "--model=/mnt/models"
        - "--port=8080"
      ports:
        - containerPort: 8080
```

---

## Models-as-a-Service (MaaS) — New in 3.3

MaaS provides governed, multi-tenant LLM access with quota management:

```yaml
# Create a ModelServer for MaaS
apiVersion: serving.kserve.io/v1alpha1
kind: ModelServer
metadata:
  name: shared-llm-server
  namespace: rhoai-shared-models
spec:
  model: llama-3-70b
  replicas: 2
  resources:
    limits:
      nvidia.com/gpu: "4"
  quotas:
    requestsPerMinute: 1000
    tokensPerMinute: 100000
```

Full MaaS guide: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/govern_llm_access_with_models-as-a-service

---

## Key oc Commands

```bash
# List all InferenceServices
oc get inferenceservice -A

# Get InferenceService status and URL
oc get inferenceservice llama-3-8b -n my-ds-project
oc get inferenceservice llama-3-8b -n my-ds-project \
  -o jsonpath='{.status.url}'

# List ServingRuntimes in a namespace
oc get servingruntimes -n my-ds-project

# List ClusterServingRuntimes (cluster-wide)
oc get clusterservingruntimes

# Watch predictor pod startup
oc get pods -n my-ds-project -l serving.kserve.io/inferenceservice=llama-3-8b -w

# Scale replicas
oc patch inferenceservice llama-3-8b \
  -n my-ds-project \
  --type='merge' \
  -p '{"spec":{"predictor":{"minReplicas":2}}}'

# Get inference endpoint logs
oc logs -n my-ds-project \
  $(oc get pod -n my-ds-project -l serving.kserve.io/inferenceservice=llama-3-8b -o name | head -1) \
  -c kserve-container -f
```

---

## Testing an Endpoint

```bash
# Get the internal cluster URL for the model
MODEL_URL=$(oc get inferenceservice llama-3-8b -n my-ds-project \
  -o jsonpath='{.status.url}')

# OpenAI-compatible completions call
curl -X POST ${MODEL_URL}/v1/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -d '{
    "model": "llama-3-8b",
    "prompt": "What is Red Hat OpenShift AI?",
    "max_tokens": 200,
    "temperature": 0.7
  }'

# Chat completions call
curl -X POST ${MODEL_URL}/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -d '{
    "model": "llama-3-8b",
    "messages": [{"role": "user", "content": "Explain Kubernetes in one sentence."}],
    "max_tokens": 100
  }'
```

---

## llm-d (Distributed Inference)

**llm-d** enables disaggregated, multi-node LLM inference on OpenShift AI — splitting the
prefill and decode phases across separate pods/nodes for higher throughput on very large models.

**Official doc (read this first):**
https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/deploying_models

Look for the section titled **"Deploying models using distributed inference with llm-d"** within
the `deploying_models` guide. Fetch the full page via `WebFetch` and navigate to that section.

### When to use llm-d

- Models too large to fit on a single GPU node (e.g., 70B+ parameter models)
- Need to separate prefill (prompt processing) and decode (token generation) for latency optimization
- Multi-node tensor parallelism across infiniband or high-speed interconnect nodes

### llm-d ServingRuntime pattern

```yaml
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  name: llm-d-runtime
  namespace: my-ds-project
spec:
  supportedModelFormats:
    - name: pytorch
      version: "1"
      autoSelect: true
  multiModel: false
  containers:
    - name: kserve-container
      image: quay.io/rhoai/llm-d:latest      # llm-d disaggregated serving image
      args:
        - "--model=/mnt/models"
        - "--port=8080"
        - "--prefill-tp=4"                    # Tensor parallelism for prefill nodes
        - "--decode-tp=4"                     # Tensor parallelism for decode nodes
      ports:
        - containerPort: 8080
          protocol: TCP
```

### Key oc Commands for llm-d

```bash
# Check llm-d pods (prefill and decode pods are separate)
oc get pods -n my-ds-project -l serving.kserve.io/inferenceservice=<name>

# Inspect llm-d runtime logs (prefill pod)
oc logs -n my-ds-project \
  $(oc get pod -n my-ds-project -l llm-d-role=prefill -o name | head -1) -f

# Inspect llm-d runtime logs (decode pod)
oc logs -n my-ds-project \
  $(oc get pod -n my-ds-project -l llm-d-role=decode -o name | head -1) -f
```

> **Always fetch the official doc page** for the current llm-d configuration options and
> the exact YAML structure, as llm-d support in RHOAI 3.x may evolve across patch releases.

---

## Caveats

- In 3.3, **RawDeployment** is the default; `Serverless` mode requires Istio + Knative
- Always specify `storageUri` pointing to your S3 data connection bucket path
- GPU-enabled InferenceServices require an AcceleratorProfile to be configured first
- For large models (70B+), use tensor parallelism (`--tensor-parallel-size`) and multiple GPUs, or llm-d for multi-node disaggregated inference
- **llm-d** requires multi-node GPU infrastructure with high-speed interconnect (InfiniBand/RoCE); consult the official doc for node requirements
- MaaS (3.3) is designed for admin-managed shared LLM pools — not per-project deployments
- Token authentication via `security.opendatahub.io/enable-auth: "true"` is recommended for all production endpoints
