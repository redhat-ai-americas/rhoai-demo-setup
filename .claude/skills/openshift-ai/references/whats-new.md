# What's New — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Release Notes 3.3**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/release_notes

---

## Highlights in 3.3

- **Models-as-a-Service (MaaS)**: Governed, multi-tenant LLM access with quota management and access control
  - Doc: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/govern_llm_access_with_models-as-a-service
- **Fraud Detection Tutorial**: New hands-on end-to-end tutorial for getting started
  - Doc: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/openshift_ai_tutorial_-_fraud_detection_example
- **KServe RawDeployment** is the default single-model serving mode (no Istio/Knative required)
- **LlamaStack operator** for RAG stack deployments
- **Upgrade path from 2.x to 3.x** is unsupported (see: https://access.redhat.com/articles/7133758)

---

## Core Platform Features in 3.3

- DataScienceCluster (DSC) CR-based component management
- KFP v2-based AI pipelines
- TrustyAI for model monitoring (bias, drift)
- Guardrails Orchestrator for LLM safety
- LM-Eval (LMEvalJob) for model evaluation
- Feature Store (Feast-backed) for ML feature management
- Model Registry for versioned model metadata and promotion
- Distributed workloads via Ray + Kueue

---

## Tips for Answering "What's New" Questions

- Always fetch the live release notes page: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/release_notes
- Highlight breaking changes and unsupported upgrade paths prominently
- Emphasize MaaS and KServe RawDeployment as the major serving capabilities in 3.3
- Reference: https://access.redhat.com/articles/7133758 for upgrade limitations
