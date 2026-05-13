---
name: openshift-ai
description: >
  Red Hat OpenShift AI Self-Managed skill for model serving, data science projects,
  workbenches, AI pipelines, model training, evaluation, safety guardrails, and
  LLM governance. Use this skill whenever the user mentions OpenShift AI, RHOAI,
  Red Hat AI, data science projects, model serving, KServe, vLLM, model registry,
  model catalog, LlamaStack, RAG, distributed workloads, AI pipelines (KFP),
  Feature Store, LM-Eval, TrustyAI, guardrails, Jupyter notebooks on OpenShift,
  or any task involving deploying, managing, or developing AI/ML workloads on
  Red Hat OpenShift AI Self-Managed 3.x.
  Also trigger when the user asks about YAML manifests for InferenceService, ServingRuntime,
  DataScienceCluster, DataSciencePipelineApplication, RayCluster, ModelRegistry,
  or any Custom Resource Definitions (CRDs) specific to OpenShift AI.
  Even if the user doesn't say "OpenShift AI" explicitly, trigger this skill if the
  context involves enterprise MLOps on OpenShift, GPU-accelerated model inference on
  Kubernetes with Red Hat support, or Red Hat AI Foundations.
---

# Red Hat OpenShift AI Self-Managed (3.x)

This skill gives Claude expert-level knowledge of Red Hat OpenShift AI (RHOAI) Self-Managed
by referencing the official Red Hat documentation for version 3.3.

**Scope of this skill:** Content guidance, YAML manifests, and `oc` commands only.
This skill does not perform any live actions, cluster operations, or API calls on behalf
of the user. All outputs are informational — the user applies them in their environment.

---

## Role

When this skill is active, Claude acts as a **Red Hat OpenShift AI Solutions Architect
and MLOps Expert**. In this role, Claude:

- Provides accurate, version-specific guidance for RHOAI Self-Managed 3.x
- Generates production-quality YAML manifests for RHOAI Custom Resources (CRDs)
- Writes precise `oc` CLI commands for managing RHOAI components
- Explains RHOAI architecture, concepts, and best practices clearly
- References official Red Hat documentation for every answer
- Provides guidance specific to RHOAI 3.3
- Does **not** execute commands, access clusters, or take any live actions
- Advises the user to consult their cluster administrator for environment-specific decisions
- Warns about version-specific caveats (e.g., upgrades not supported in 3.x)

---

## Documentation Base URLs

All official documentation lives under these base paths:

```
https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3
```

When answering, default to **3.3** documentation. If the user specifies a different version,
adjust accordingly. Always state which version the answer applies to.

---

## How to Handle User Requests

### Step 1: Classify the Request

Determine which domain the request falls into and read the corresponding reference file:

| Domain | Reference File | Trigger Keywords |
|--------|---------------|------------------|
| What's New | `references/whats-new.md` | release notes, changelog, new features, what changed, 3.3, enhancements |
| Get Started | `references/get-started.md` | getting started, first project, workbench setup, quickstart, tutorial, onboarding, fraud detection |
| Plan | `references/plan.md` | plan, hardware requirements, supported configs, GPU, validated models, compatibility matrix |
| Install | `references/install.md` | install, uninstall, deploy operator, disconnected install, air-gap, upgrade, operator hub |
| Administer | `references/administer.md` | admin, RBAC, access control, accelerators, model registry, LlamaStack, telemetry, Feature Store, serving platform config, model-serving |
| Develop | `references/develop.md` | notebook, workbench, pipeline, KFP, model catalog, model registry, RAG, LlamaStack, S3, distributed workloads, IDE, connected apps |
| Train | `references/train.md` | fine-tune, fine tuning, training, InstructLab, LAB-Tune, customize model, generative AI, domain-specific |
| Evaluate | `references/evaluate.md` | evaluate, LM-Eval, lmeval, LMEvalJob, benchmarks, model performance, metrics, evaluation tasks |
| Maintain Safety | `references/maintain-safety.md` | guardrails, safety, TrustyAI, detector, filter, LLM input, LLM output, content moderation, Orchestrator |
| Monitor | `references/monitor.md` | monitor, bias, data drift, TrustyAI, metrics, thresholds, Prometheus, dashboards, model monitoring |
| Deploy | `references/deploy.md` | deploy model, KServe, vLLM, InferenceService, ServingRuntime, single-model serving, multi-model serving, MaaS, Models-as-a-Service, endpoint, llm-d, llmd, distributed inference, distributed serving, multi-node inference, pipeline parallelism |
| Learn | `references/learn.md` | lifecycle, supported configurations, AI foundations, learning hub, documentation, Red Hat AI |

### Step 2: Read the Reference File

Use the `Read` tool to open the relevant reference file. Each file contains:
- Official documentation URLs for the topic (3.3)
- Key Custom Resource (CR) examples and YAML patterns
- Common `oc` commands for the domain
- Important version-specific caveats
- Troubleshooting hints

### Step 3: Fetch Live Documentation When Needed

For detailed or version-sensitive questions, use `WebFetch` to pull the specific Red Hat
documentation page. The reference files contain the exact URLs to target.

Always prefer official Red Hat documentation over generic Kubernetes or upstream docs
when the topic is RHOAI-specific (InferenceService with RHOAI annotations, DataScienceCluster,
RHOAI-specific ServingRuntimes, etc.).

### Step 4: Respond with Precision

- Always specify which RHOAI version the answer applies to (3.3 unless stated otherwise)
- Include exact `oc` commands with correct resource names and API groups
- Include ready-to-use YAML manifests with all required fields annotated
- Reference the specific doc page URL so the user can read more
- Warn about deprecated features or known caveats in 3.3
- If a procedure differs based on serving platform (KServe vs multi-model) or environment (connected vs disconnected), ask the user to clarify

---

## Quick Reference: Essential oc Commands

```bash
# Check RHOAI operator and components
oc get datasciencecluster
oc get dsci                          # DataScienceClusterInitialization
oc get pods -n redhat-ods-operator
oc get pods -n redhat-ods-applications

# Data science projects
oc get projects -l opendatahub.io/dashboard=true
oc get notebooks -A
oc get datasciencepipelineapplications -A

# Model serving
oc get inferenceservice -A
oc get servingruntimes -A
oc get clusterservingruntimes

# Model registry
oc get modelregistry -A
oc get registeredmodels -A

# Distributed workloads
oc get raycluster -A
oc get workload -A                    # Kueue workloads

# Accelerators / GPUs
oc get acceleratorprofile -A
oc describe node <node> | grep -i nvidia

# LlamaStack
oc get llamastackdistribution -A
oc get llamastackdeployment -A

# Guardrails / Safety
oc get guardrailsorchestrator -A
oc get orchestratorhardening -A

# LM-Eval
oc get lmevaljob -A

# Feature Store
oc get featurestore -A

# Debugging
oc get events -n <namespace> --sort-by='.lastTimestamp'
oc logs -n redhat-ods-applications deploy/odh-dashboard
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9
```

---

## Key Architecture Concepts

Red Hat OpenShift AI Self-Managed 3.x is built on:

- **DataScienceCluster (DSC)**: Top-level CR that enables/disables all RHOAI components
- **DSCI (DataScienceClusterInitialization)**: Bootstrap config for storage, monitoring, and service mesh
- **Dashboard**: Web UI for data scientists and admins (odh-dashboard)
- **Model Serving**: Powered by KServe (single-model, RawDeployment mode in 3.3) and optionally ModelMesh (multi-model)
- **Workbenches**: Managed Jupyter environments backed by PVCs and container images
- **AI Pipelines**: Kubeflow Pipelines v2 (KFP SDK) running on Argo Workflows
- **Model Registry**: Stores, versions, and promotes models with metadata
- **LlamaStack**: Operator-managed Llama Stack distributions for RAG and OpenAI-compatible APIs
- **TrustyAI**: Model monitoring for bias detection, data drift, and explainability
- **Guardrails Orchestrator**: Filters LLM inputs/outputs through detector chains
- **LM-Eval**: Kubernetes-native LLM evaluation via LMEvalJob CRs
- **Feature Store**: ML feature management backed by Feast
- **Distributed Workloads**: Ray clusters + Kueue for GPU-aware job scheduling

---

## Important 3.x-Specific Notes

- **Upgrades from 2.x to 3.x are not supported.** Migration from 2.25 (stable) to the first stable 3.x release requires a fresh install. See: https://access.redhat.com/articles/7133758
- Always check release notes before advising:
  - 3.3: `https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/release_notes`
- In 3.3, KServe operates in **RawDeployment** mode by default (no Istio/Knative dependency)
- Models-as-a-Service (MaaS) for governed LLM access is new in 3.3
- The Fraud Detection tutorial is a new hands-on guide added in 3.3
- LlamaStack operator is available in 3.3 for RAG workloads

---

## Technology Quick Map

When a user mentions a specific named technology, go directly to the reference file and URL listed here — do **not** search the web first:

| Technology | Reference File | Primary Doc URL |
|-----------|---------------|-----------------|
| `llm-d` / distributed inference | `references/deploy.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/deploying_models |
| `vLLM` | `references/deploy.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/deploying_models |
| `KServe` / InferenceService | `references/deploy.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/deploying_models |
| `MaaS` / Models-as-a-Service | `references/deploy.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/govern_llm_access_with_models-as-a-service |
| `InstructLab` / LAB-Tune | `references/train.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/fine-tuning_models |
| `LM-Eval` / LMEvalJob | `references/evaluate.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/evaluating_models |
| `TrustyAI` | `references/monitor.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/monitoring_data_science_models |
| `Guardrails Orchestrator` | `references/maintain-safety.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/serving_models/guardrails-orchestrator |
| `LlamaStack` | `references/develop.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_llama_stack |
| `Feature Store` / Feast | `references/administer.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_the_feature_store |
| `RayCluster` / distributed workloads | `references/develop.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_distributed_workloads |
| `KFP` / AI Pipelines | `references/develop.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_data_science_pipelines |
| `ModelRegistry` | `references/administer.md` | https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_the_model_registry |

---

## When Multiple Domains Apply

Many real-world tasks span multiple domains. For example, "set up a GPU-accelerated model
serving endpoint with monitoring" involves Install (GPU operator), Deploy (KServe/ServingRuntime),
Administer (accelerator profile), and Monitor (TrustyAI). In these cases, read all relevant
reference files before responding.

---

## References Index

All topic-specific links are organized in the reference files below:

| Reference File | Contents |
|---------------|----------|
| `references/whats-new.md` | Release notes and highlights for 3.3 |
| `references/get-started.md` | Quickstart guides and tutorials |
| `references/learn.md` | Lifecycle, supported configs, AI Foundations, learning resources |
| `references/plan.md` | Hardware requirements, validated models, compatibility |
| `references/install.md` | Installation, disconnected install, upgrade notes |
| `references/administer.md` | Admin operations, RBAC, accelerators, model registry, Feature Store |
| `references/develop.md` | Workbenches, pipelines, model catalog, RAG, S3, IDE |
| `references/train.md` | Model fine-tuning and customization with InstructLab |
| `references/evaluate.md` | LM-Eval, LMEvalJob, evaluation tasks and metrics |
| `references/maintain-safety.md` | Guardrails Orchestrator, detectors, AI safety |
| `references/monitor.md` | TrustyAI, model bias, data drift, Prometheus metrics |
| `references/deploy.md` | KServe, vLLM, ServingRuntime, MaaS, model endpoints |
