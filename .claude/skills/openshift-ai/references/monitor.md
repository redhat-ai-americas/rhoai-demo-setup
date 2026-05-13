# Monitor — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Monitoring Your AI Systems**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/monitoring_your_ai_systems

---

## Overview

RHOAI uses **TrustyAI** as its model monitoring component. TrustyAI provides:

- **Bias detection**: Statistical fairness metrics across protected attributes
- **Data drift monitoring**: Detects when incoming data diverges from training distribution
- **Explainability**: SHAP-based feature attribution
- **Prometheus integration**: Exposes metrics for OpenShift's built-in monitoring stack
- **Thresholds and alerts**: Configurable thresholds that fire Prometheus alerts

---

## Enable TrustyAI in DataScienceCluster

```yaml
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
spec:
  components:
    trustyai:
      managementState: Managed
```

```bash
# Verify TrustyAI service is running
oc get pods -n my-ds-project | grep trustyai
oc get route -n my-ds-project | grep trustyai
```

---

## TrustyAIService CR

```yaml
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: TrustyAIService
metadata:
  name: trustyai-service
  namespace: my-ds-project
spec:
  storage:
    format: "PVC"
    folder: "/data"
    size: "1Gi"
  data:
    filename: "data.csv"
    format: "CSV"
  metrics:
    schedule: "5s"      # How often to compute metrics
```

```bash
# Check TrustyAI service status
oc get trustyaiservice -n my-ds-project
oc describe trustyaiservice trustyai-service -n my-ds-project
```

---

## Sending Inference Data to TrustyAI

TrustyAI intercepts inference data via a sidecar injected into InferenceService pods,
or via direct payload logging. To enable payload logging:

```bash
# Label the namespace to enable TrustyAI sidecar injection
oc label namespace my-ds-project modelmesh-enabled=true

# Or annotate a specific InferenceService
oc annotate inferenceservice my-model \
  -n my-ds-project \
  serving.kserve.io/enable-prometheus-scraping=true
```

---

## Bias Metrics (SPD and DIR)

RHOAI supports two standard fairness metrics:

| Metric | Name | Description |
|--------|------|------------|
| SPD | Statistical Parity Difference | Difference in positive prediction rates between groups |
| DIR | Disparate Impact Ratio | Ratio of positive prediction rates between groups |

```bash
# Request SPD metric for a protected attribute
curl -X POST \
  https://<trustyai-route>/metrics/spd/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "modelId": "my-model",
    "protectedAttribute": "gender",
    "favorableOutcome": 1,
    "outcomeName": "loan_approved",
    "privilegedAttribute": "male",
    "unprivilegedAttribute": "female"
  }'
```

---

## Data Drift Monitoring

```bash
# Check drift metrics for a deployed model
curl https://<trustyai-route>/metrics/drift/request \
  -H "Authorization: Bearer <token>" \
  -d '{
    "modelId": "my-model",
    "referenceTag": "TRAINING"
  }'
```

---

## Prometheus Metrics

TrustyAI exposes metrics that integrate with OpenShift Monitoring:

```bash
# Check Prometheus scraping is configured
oc get servicemonitor -n my-ds-project | grep trustyai

# Common metrics exposed
# trustyai_spd{model="my-model", protected_attribute="gender"} 0.03
# trustyai_dir{model="my-model"} 0.97
# trustyai_data_observations_total{model="my-model"} 12450
```

---

## Creating Alerts

```yaml
# PrometheusRule for bias drift alert
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: trustyai-bias-alert
  namespace: my-ds-project
spec:
  groups:
    - name: trustyai.bias
      rules:
        - alert: HighBiasDetected
          expr: abs(trustyai_spd{model="my-model"}) > 0.1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Model bias exceeds threshold"
            description: "SPD for {{ $labels.model }} is {{ $value }}, exceeding 0.1 threshold"
```

---

## Key oc Commands

```bash
# List TrustyAI services
oc get trustyaiservice -A

# Get TrustyAI service logs
oc logs -n my-ds-project \
  $(oc get pod -n my-ds-project -l app=trustyai-service -o name) -f

# Check registered models in TrustyAI
curl https://<trustyai-route>/info \
  -H "Authorization: Bearer $(oc whoami -t)"

# List scheduled metric requests
curl https://<trustyai-route>/metrics/spd/requests \
  -H "Authorization: Bearer $(oc whoami -t)"

# Delete a metric request
curl -X DELETE \
  https://<trustyai-route>/metrics/spd/request?requestId=<id> \
  -H "Authorization: Bearer $(oc whoami -t)"

# Check OpenShift monitoring stack
oc get pods -n openshift-monitoring | grep prometheus
```

---

## Dashboard Integration

TrustyAI metrics are visible in the RHOAI Dashboard under each model's **Model Metrics** tab.
The dashboard provides:
- Bias metric trend charts
- Data drift visualizations
- Threshold violation indicators
- Historical metric comparisons

---

## Caveats

- TrustyAI requires inference data to be logged — ensure payload logging is configured
- Metrics are computed on a schedule; real-time alerting has inherent delay
- For large-volume models, use PVC-backed storage with sufficient I/O throughput
- Explainability (SHAP) is computationally expensive; use sparingly in production
