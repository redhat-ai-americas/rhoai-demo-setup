# Learn — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Red Hat OpenShift AI Product Lifecycle**: https://access.redhat.com/support/policy/updates/rhoai-sm/lifecycle
- **Red Hat OpenShift AI: Supported Configurations (3.x)**: https://access.redhat.com/articles/rhoai-supported-configs-3.x
- **Red Hat AI Foundations**: https://docs.redhat.com/en/ai-foundations
- **Red Hat AI Learning Hub**: https://docs.redhat.com/en/learn/ai

---

## Product Lifecycle

RHOAI Self-Managed 3.x follows Red Hat's **Fast Release** cadence, meaning:
- Minor versions are released frequently (e.g., 3.1, 3.2, 3.3...)
- Each minor version has a shorter support window than Long Life (stable) releases
- **Upgrades between 3.x minor versions** — check release notes; upgrades from 2.x → 3.x are not supported
- The first Long Life (stable) 3.x release will have a defined migration path from 2.25

Reference lifecycle policy: https://access.redhat.com/support/policy/updates/rhoai-sm/lifecycle

---

## Supported Configurations

The supported configurations document covers:
- Supported OpenShift Container Platform (OCP) versions
- Supported GPU hardware (NVIDIA A100, H100, L40S, etc.)
- Supported cloud platforms (AWS, Azure, GCP, on-prem bare metal)
- Supported component versions (KServe, Ray, KFP, TrustyAI, etc.)
- Browser and client compatibility

Always check this before advising on GPU types, cloud environments, or component versions:
https://access.redhat.com/articles/rhoai-supported-configs-3.x

---

## Red Hat AI Foundations

Red Hat AI Foundations is the overarching product family that RHOAI is part of. It includes:
- **Red Hat OpenShift AI** — MLOps platform on OpenShift
- **Red Hat AI Inference Server** — Optimized vLLM-based inference runtime
- **Red Hat Enterprise Linux AI (RHEL AI)** — InstructLab on RHEL for model customization

Documentation hub: https://docs.redhat.com/en/ai-foundations

---

## Learning Resources

### Red Hat AI Learning Hub
Interactive learning paths, labs, and courses for:
- OpenShift AI fundamentals
- MLOps practices with RHOAI
- Model serving and monitoring
- AI safety and governance

URL: https://docs.redhat.com/en/learn/ai

### Recommended Learning Path for New Users
1. Start with the Getting Started guide (see `get-started.md`)
2. Complete the Fraud Detection tutorial (3.3+)
3. Explore the AI Learning Hub for hands-on labs
4. Review Red Hat AI Foundations for the broader product ecosystem

---

## Key Concepts Glossary

| Term | Definition |
|------|-----------|
| RHOAI | Red Hat OpenShift AI Self-Managed |
| DSC | DataScienceCluster — the top-level operator CR |
| DSCI | DataScienceClusterInitialization — bootstrap config |
| KServe | Kubernetes-native model serving framework |
| KFP | Kubeflow Pipelines — ML pipeline engine |
| TrustyAI | Red Hat's model monitoring and explainability component |
| LlamaStack | Meta's Llama inference/RAG stack, operated by RHOAI |
| MaaS | Models-as-a-Service — governed LLM access (3.3+) |
| LM-Eval | LLM evaluation framework, run as LMEvalJob CRs |
| InstructLab | Open-source model fine-tuning framework used in Train workflows |
