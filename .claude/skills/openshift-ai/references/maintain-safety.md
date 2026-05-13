# Maintain Safety — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Ensuring AI Safety with Guardrails**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/enabling_ai_safety_with_guardrails

---

## Overview

RHOAI provides the **Guardrails Orchestrator** (based on TrustyAI) to protect LLM-based
applications by filtering inputs and outputs through configurable detector chains.

Core capabilities:
- **Input filtering**: Scan prompts before they reach the model
- **Output filtering**: Scan model responses before returning to users
- **Detector chaining**: Compose multiple detectors in a pipeline
- **Auto-configuration**: Use pre-defined security profiles
- **Guarded endpoints**: Expose a new endpoint that transparently applies guardrails

---

## Enable Guardrails in DataScienceCluster

```yaml
# Ensure the guardsrails component is Managed in DSC
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
spec:
  components:
    guardsrails:
      managementState: Managed
```

```bash
# Verify guardrails operator pods are running
oc get pods -n redhat-ods-applications | grep guardrail
```

---

## GuardrailsOrchestrator CR

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: GuardrailsOrchestrator
metadata:
  name: my-guardrails
  namespace: my-ds-project
spec:
  orchestratorConfig: "fms-orchestr8-config-nlp"   # Pre-built config for NLP detectors
  replicas: 1
  vllmGateway:
    vllmServiceName: "llama-3-8b-predictor"         # Points to your InferenceService
    vllmServicePort: 8080
```

---

## OrchestratorHardening CR (Auto-Configuration)

For quick setup with sensible defaults:

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: OrchestratorHardening
metadata:
  name: my-hardening
  namespace: my-ds-project
spec:
  guardrailsOrchestrator:
    name: my-guardrails
  detectors:
    hap:                         # Hate, Abuse, and Profanity detector
      enabled: true
      threshold: 0.7
    pii:                         # Personally Identifiable Information detector
      enabled: true
    groundedness:                # Hallucination / groundedness detector
      enabled: true
      threshold: 0.5
```

---

## Detector Types

| Detector | Description | Direction |
|----------|------------|-----------|
| HAP (Hate, Abuse, Profanity) | Flags toxic or abusive language | Input & Output |
| PII | Detects personal identifiable information | Input & Output |
| Groundedness | Detects hallucinations / ungrounded responses | Output only |
| Regex | Custom pattern matching | Input & Output |
| Keyword | Blocked keyword lists | Input |
| Prompt injection | Detects jailbreak / injection attempts | Input |

---

## Guarded Endpoint Pattern

The Guardrails Orchestrator creates a proxy endpoint that wraps the model:

```
User → GuardrailsOrchestrator (port 8080)
          ↓ input detectors
       Model (InferenceService)
          ↓ output detectors
       GuardrailsOrchestrator
          ↓
       User (filtered response or rejection)
```

```bash
# Check the guarded endpoint route
oc get route -n my-ds-project | grep guardrail

# Test the guarded endpoint
curl -X POST https://<guarded-route>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "model": "llama-3-8b",
    "messages": [{"role": "user", "content": "Hello, how are you?"}]
  }'
```

---

## Key oc Commands

```bash
# List GuardrailsOrchestrator instances
oc get guardrailsorchestrator -A

# List OrchestratorHardening configs
oc get orchestratorhardening -A

# Describe a specific orchestrator
oc describe guardrailsorchestrator my-guardrails -n my-ds-project

# Check orchestrator pod logs
oc logs -n my-ds-project \
  $(oc get pod -n my-ds-project -l app=my-guardrails -o name) -f

# Check detector status
oc get pods -n my-ds-project | grep detector
```

---

## Detector Configuration Example (Inline)

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: GuardrailsOrchestrator
metadata:
  name: my-guardrails
  namespace: my-ds-project
spec:
  orchestratorConfig: "fms-orchestr8-config-nlp"
  replicas: 1
  vllmGateway:
    vllmServiceName: "my-model-predictor"
    vllmServicePort: 8080
  detectorConfig:
    detectors:
      - name: hap-detector
        type: hap
        endpoint: "http://hap-detector:8080"
        parameters:
          threshold: "0.75"
      - name: pii-detector
        type: pii
        endpoint: "http://pii-detector:8080"
```

---

## Caveats

- Guardrails add latency to every request; benchmark throughput impact before production use
- HAP and PII detectors require their own model containers — ensure GPU/CPU resources are available
- The `groundedness` detector requires a retrieval context (for RAG use cases)
- Guardrails work alongside (not instead of) network-level security (routes, auth, RBAC)
- Always test guardrails with adversarial inputs before going to production
