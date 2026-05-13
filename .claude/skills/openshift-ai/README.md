# Red Hat OpenShift AI Self-Managed 3.3 Skill

A Claude skill for working with Red Hat OpenShift AI (RHOAI) Self-Managed 3.3 — covering model serving, data science projects, workbenches, AI pipelines, model training, evaluation, safety guardrails, and LLM governance.

## What It Does

This skill gives Claude expert-level knowledge of Red Hat OpenShift AI Self-Managed 3.3, backed by official Red Hat documentation. Claude provides accurate guidance on YAML manifests, `oc` CLI commands, and architecture decisions — without taking any live actions on your cluster.

> **Scope:** Content guidance, YAML manifests, and `oc` commands only. All outputs are informational — you apply them in your environment.

### Capabilities

- **Model Serving**: KServe RawDeployment, vLLM ServingRuntimes, InferenceService CRs, Models-as-a-Service (MaaS)
- **Data Science Projects**: Workbenches, Jupyter notebooks, S3 data connections, connected applications
- **AI Pipelines**: Kubeflow Pipelines v2 (KFP SDK), pipeline scheduling, artifact tracking
- **Model Training**: PyTorchJob, RayJob, InstructLab / LAB-Tune, distributed training with Kueue
- **Model Registry**: Registering, versioning, and promoting models with metadata
- **Model Catalog**: Discovering, evaluating, and deploying pre-validated models
- **RAG / LlamaStack**: Deploying RAG stacks, LlamaStack operator, OpenAI-compatible APIs
- **Distributed Workloads**: RayCluster, Kueue for GPU-aware job scheduling
- **Evaluation**: LM-Eval (LMEvalJob CRs), benchmarks, metrics, model comparison
- **Safety Guardrails**: Guardrails Orchestrator, HAP/PII/groundedness detectors, prompt injection defense
- **Model Monitoring**: TrustyAI, bias detection (SPD/DIR), data drift, Prometheus alerts
- **Feature Store**: Feast-backed ML feature management
- **Administration**: Accelerator profiles, RBAC, model registry admin, telemetry, LlamaStack operator
- **Installation**: Operator install, DSCI/DSC configuration, disconnected/air-gapped environments

## Example Prompts

```
"Deploy a Llama 3 8B model using KServe RawDeployment with token auth"
"Create a DataSciencePipelineApplication CR for my project"
"Write a PyTorchJob manifest for distributed fine-tuning with 4 GPU workers"
"Set up TrustyAI to monitor my model for gender bias"
"Configure a GuardrailsOrchestrator with HAP and PII detectors"
"Show me the oc commands to check all InferenceServices across namespaces"
"How do I enable the Model Registry component in my DataScienceCluster?"
"Create a RayCluster for distributed training with NVIDIA GPU support"
"What's the YAML for an LMEvalJob running mmlu and hellaswag?"
"Install RHOAI 3.3 in a disconnected environment"
"Set up Models-as-a-Service for governed LLM access"
"How do I connect a workbench to an S3-compatible object store?"
```

## Reference Files

| File | When Claude Reads It |
|------|---------------------|
| `references/whats-new.md` | Release notes, highlights, and new features in 3.3 |
| `references/get-started.md` | Onboarding, first project setup, workbench quickstart, fraud detection tutorial |
| `references/learn.md` | Product lifecycle, supported configurations, AI Foundations, learning resources |
| `references/plan.md` | Hardware requirements, GPU sizing, validated models, compatibility matrix |
| `references/install.md` | Operator install, DSCI/DSC CRs, disconnected install, uninstall |
| `references/administer.md` | RBAC, accelerator profiles, model registry admin, LlamaStack, Feature Store, telemetry |
| `references/develop.md` | Workbenches, AI pipelines, model catalog, RAG, S3, distributed workloads, IDE images |
| `references/train.md` | Model fine-tuning with InstructLab, PyTorchJob, RayJob, Kueue scheduling |
| `references/evaluate.md` | LM-Eval, LMEvalJob CRs, evaluation tasks, benchmark metrics |
| `references/maintain-safety.md` | Guardrails Orchestrator, detector types, OrchestratorHardening, AI safety |
| `references/monitor.md` | TrustyAI, bias metrics (SPD/DIR), data drift, Prometheus alerts |
| `references/deploy.md` | KServe, vLLM, ServingRuntime, InferenceService, MaaS, model endpoints |

## Documentation Source

All guidance is sourced from: [Red Hat OpenShift AI Self-Managed 3.3 Documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3)
