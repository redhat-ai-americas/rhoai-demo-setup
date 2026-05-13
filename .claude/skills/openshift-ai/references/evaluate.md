# Evaluate — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Evaluating AI Systems with LM-Eval**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/evaluating_ai_systems

---

## Overview

RHOAI provides **LM-Eval** as a Kubernetes-native LLM evaluation framework.
LM-Eval runs as a **LMEvalJob** Custom Resource and supports hundreds of evaluation tasks
from the `lm-evaluation-harness` library.

Typical use cases:
- Benchmarking a fine-tuned model against its base model
- Running standardized safety evaluations
- Comparing models before promoting them in the Model Registry
- Validating model performance regressions after retraining

---

## LMEvalJob Anatomy

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: LMEvalJob
metadata:
  name: eval-llama-3-8b
  namespace: my-ds-project
spec:
  model: local-completions           # Use 'local-chat-completions' for chat models
  modelParameters:
    - name: base_url
      value: "http://llama-3-8b-predictor.my-ds-project.svc.cluster.local/v1/completions"
    - name: model
      value: "llama-3-8b"
    - name: num_concurrent
      value: "8"
    - name: max_retries
      value: "3"
    - name: tokenized_requests
      value: "False"
  taskList:
    taskNames:
      - "arc_easy"
      - "hellaswag"
      - "mmlu"
      - "truthfulqa_mc1"
  logSamples: true
  batchSize: "8"
  limit: "100"                       # Limit samples per task for quick runs
```

---

## Common Evaluation Tasks

| Task | Description | Category |
|------|------------|----------|
| `arc_easy` | ARC Easy — grade-school science QA | Reasoning |
| `arc_challenge` | ARC Challenge — harder science QA | Reasoning |
| `hellaswag` | Sentence completion | Commonsense |
| `mmlu` | Massive Multitask Language Understanding (57 subjects) | Knowledge |
| `truthfulqa_mc1` | TruthfulQA multiple choice | Safety/Truthfulness |
| `gsm8k` | Grade school math word problems | Math |
| `winogrande` | Winograd schema challenge | Commonsense |
| `bbh` | Big-Bench Hard | Complex Reasoning |

---

## Key oc Commands

```bash
# Check LM-Eval is enabled in DSC
oc get datasciencecluster -o jsonpath='{.items[0].spec.components.lmeval}'

# List all LMEvalJobs
oc get lmevaljob -A

# Watch job progress
oc get lmevaljob eval-llama-3-8b -n my-ds-project -w

# Get evaluation results
oc get lmevaljob eval-llama-3-8b -n my-ds-project -o jsonpath='{.status.results}'

# Get full status including metrics
oc describe lmevaljob eval-llama-3-8b -n my-ds-project

# View evaluator pod logs
oc logs -n my-ds-project \
  $(oc get pod -n my-ds-project -l lmevaljob=eval-llama-3-8b -o name) -f
```

---

## Evaluating a Chat Model

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: LMEvalJob
metadata:
  name: eval-granite-chat
  namespace: my-ds-project
spec:
  model: local-chat-completions
  modelParameters:
    - name: base_url
      value: "http://granite-3-8b-predictor.my-ds-project.svc.cluster.local/v1/chat/completions"
    - name: model
      value: "granite-3-8b"
    - name: num_concurrent
      value: "4"
  taskList:
    taskNames:
      - "mmlu"
      - "truthfulqa_mc1"
  batchSize: "4"
```

---

## Storing Results

LMEvalJob results are stored in the CR's `.status.results` field as JSON.
For persistent storage, configure an output PVC:

```yaml
spec:
  outputs:
    pvcManaged:
      size: "5Gi"    # Auto-creates a PVC to store eval logs and results
```

---

## Integration with Model Registry

After evaluation, record results against the model version in the Model Registry:

```bash
# Annotate model version with eval results
oc annotate modelversion <version-name> \
  -n redhat-ods-applications \
  lmeval.trustyai.opendatahub.io/mmlu-score="72.4" \
  lmeval.trustyai.opendatahub.io/hellaswag-score="85.1"
```

---

## Tips

- Run evaluations against your model's InferenceService endpoint (internal cluster URL)
- Use `limit` to run quick sanity checks during development; remove for full evaluations
- `logSamples: true` captures per-sample outputs for debugging
- Schedule regular LMEvalJobs via AI Pipelines (KFP) to catch regressions after retraining
- Compare scores between model versions before promoting in the Model Registry
