# Plan — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Supported Product and Hardware Configurations**: https://docs.redhat.com/en/documentation/red_hat_ai/3/html/supported_product_and_hardware_configurations/index
- **Validated Models for Reliable Serving**: https://docs.redhat.com/en/documentation/red_hat_ai/latest/html/validated_models/index

---

## Planning Checklist

Before installing RHOAI Self-Managed, verify the following:

### OpenShift Platform
- [ ] OCP version is supported (check compatibility matrix)
- [ ] Cluster has sufficient compute: minimum 3 control plane + 2 worker nodes recommended
- [ ] Storage class with RWO and RWX support is available (for PVCs and pipelines)
- [ ] Network egress is available for image pulls (or mirroring is configured for disconnected)

### GPU / Accelerator Requirements
- [ ] NVIDIA GPU Operator is installed (for GPU workloads)
- [ ] Node Feature Discovery (NFD) operator is installed
- [ ] GPU nodes are labeled and tainted appropriately
- [ ] NVIDIA driver version is compatible with CUDA version required by model runtimes

### Networking
- [ ] OpenShift routes are reachable from data scientist clients
- [ ] If using KServe RawDeployment (3.3 default), no Istio/Knative dependency required
- [ ] Certificate management is configured (wildcard cert or cert-manager)

### Storage
- [ ] S3-compatible object storage is available (AWS S3, MinIO, ODF/Ceph, etc.)
- [ ] Bucket credentials are ready for data connections in workbenches and pipelines

---

## Supported GPU Hardware (Common Examples)

| GPU Model | Memory | Use Case |
|-----------|--------|----------|
| NVIDIA A100 (40GB/80GB) | 40/80 GB | Large model training and inference |
| NVIDIA H100 (80GB) | 80 GB | High-throughput LLM inference |
| NVIDIA L40S | 48 GB | Multi-modal inference |
| NVIDIA A10G | 24 GB | Small-to-medium model inference |
| NVIDIA T4 | 16 GB | Dev/test, smaller models |

Always verify GPU support in the official compatibility matrix:
https://access.redhat.com/articles/rhoai-supported-configs-3.x

---

## Validated Models

Red Hat validates a curated set of models for use with RHOAI and the Red Hat AI Inference Server:

- Llama 3.x family (Meta)
- Mistral / Mixtral family
- Granite family (IBM)
- Falcon family

Full validated model list: https://docs.redhat.com/en/documentation/red_hat_ai/latest/html/validated_models/index

Models in the validated list are tested for:
- Correct output with vLLM serving runtime
- Performance benchmarks on supported hardware
- License compatibility for enterprise use

---

## Sizing Guidelines

### Workbench Nodes
- Minimum: 4 vCPU, 8 GB RAM per concurrent workbench user
- Recommended: 8 vCPU, 16 GB RAM for data-heavy notebooks

### Model Serving Nodes (CPU-only)
- Small models (< 1B params): 4 vCPU, 8 GB RAM
- Medium models (1–7B params): 8–16 vCPU, 32–64 GB RAM

### Model Serving Nodes (GPU)
- 7B params: 1x A10G (24 GB) or 1x T4 (16 GB with quantization)
- 13B params: 1x A100 40 GB or 2x A10G
- 70B params: 2–4x A100 80 GB or H100 80 GB

### Pipeline Nodes
- Argo Workflows controller: 2 vCPU, 4 GB RAM (shared)
- Pipeline step pods: size per job, typically 2–4 vCPU, 8–16 GB RAM

---

## Key oc Commands for Planning/Verification

```bash
# Check available GPU nodes
oc get nodes -l nvidia.com/gpu.present=true

# Check GPU allocatable resources on a node
oc describe node <gpu-node> | grep -A5 Allocatable

# Check storage classes
oc get storageclass

# Verify NFD and GPU Operator are running
oc get pods -n nvidia-gpu-operator
oc get pods -n node-feature-discovery

# Check OCP version
oc version
```
