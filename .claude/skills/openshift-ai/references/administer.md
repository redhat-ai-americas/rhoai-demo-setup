# Administer — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Provision Workbenches and Custom Images**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/creating_a_workbench
- **Administer Platform Access, Apps, and Operations**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/managing_openshift_ai
- **Feature Store**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_machine_learning_features
- **Usage Telemetry**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/latest/html/managing_resources/managing-collection-of-usage-data#usage-data-collection-notice-for-openshift-ai
- **Accelerator Profiles**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_accelerators
- **Configure Model-Serving Platform**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/configuring_your_model-serving_platform
- **LlamaStack Operator**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_llama_stack
- **Manage Resources (User Access, Storage, Telemetry)**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/managing_resources
- **Manage Model Registries**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/managing_model_registries
- **Choose Production-Ready OpenShift AI APIs**: https://access.redhat.com/articles/7047935

---

## Accelerator Profiles

AcceleratorProfiles expose GPU/accelerator resources to workbenches and model servers:

```yaml
apiVersion: dashboard.opendatahub.io/v1alpha1
kind: AcceleratorProfile
metadata:
  name: nvidia-gpu
  namespace: redhat-ods-applications
spec:
  displayName: "NVIDIA GPU"
  enabled: true
  identifier: nvidia.com/gpu
  tolerations:
    - effect: NoSchedule
      key: nvidia.com/gpu
      operator: Exists
```

```bash
# List accelerator profiles
oc get acceleratorprofile -n redhat-ods-applications

# Describe a specific profile
oc describe acceleratorprofile nvidia-gpu -n redhat-ods-applications
```

---

## Custom Notebook Images

Publish custom notebook images for teams:

```yaml
apiVersion: dashboard.opendatahub.io/v1alpha1
kind: ImageStream
metadata:
  name: custom-pytorch-notebook
  namespace: redhat-ods-applications
  labels:
    opendatahub.io/notebook-image: "true"
spec:
  tags:
    - annotations:
        opendatahub.io/notebook-image-name: "Custom PyTorch 2.1"
        opendatahub.io/notebook-image-desc: "PyTorch 2.1 with custom libraries"
        opendatahub.io/default-image: "false"
      from:
        kind: DockerImage
        name: quay.io/my-org/custom-pytorch:latest
      name: "2024.1"
```

---

## Model Registry Administration

```bash
# Enable model registry component in DSC
oc patch datasciencecluster default-dsc \
  --type='merge' \
  -p '{"spec":{"components":{"modelregistry":{"managementState":"Managed"}}}}'

# List model registries
oc get modelregistry -A

# Create a new model registry instance
cat <<EOF | oc apply -f -
apiVersion: modelregistry.opendatahub.io/v1alpha1
kind: ModelRegistry
metadata:
  name: my-model-registry
  namespace: redhat-ods-applications
spec:
  grpc:
    port: 9090
  rest:
    port: 8080
    serviceRoute: enabled
EOF

# List registered models in a registry
oc get registeredmodels -n redhat-ods-applications
```

---

## RBAC and User Access

```bash
# Add a user as a data science project contributor
oc adm policy add-role-to-user edit <username> -n <project>

# Grant cluster-wide RHOAI admin role
oc adm policy add-cluster-role-to-user rhods-admins <username>

# View current RBAC for a project
oc get rolebindings -n <project>
```

---

## Feature Store (Feast-backed)

```bash
# Check Feature Store status
oc get featurestore -A

# Create a FeatureStore instance
cat <<EOF | oc apply -f -
apiVersion: feast.dev/v1alpha1
kind: FeatureStore
metadata:
  name: my-feature-store
  namespace: my-ds-project
spec:
  feastProject: my_feast_project
EOF
```

---

## LlamaStack Operator

```bash
# Check LlamaStack distributions
oc get llamastackdistribution -A

# Create a LlamaStack deployment
cat <<EOF | oc apply -f -
apiVersion: llamastack.io/v1alpha1
kind: LlamaStackDistribution
metadata:
  name: llama-stack-dist
  namespace: my-ds-project
spec:
  server:
    distribution:
      name: remote-vllm
    port: 8321
EOF
```

---

## Telemetry Management

```bash
# Check current telemetry config
oc get configmap odh-collection-controller-config -n redhat-ods-operator -o yaml

# Disable usage data collection
oc patch configmap odh-collection-controller-config \
  -n redhat-ods-operator \
  --type='merge' \
  -p '{"data":{"enableSelfManagedRhoaiTelemetry":"false"}}'
```

---

## API Stability Tiers

When building automation against RHOAI APIs, consult the API stability guide to understand
which endpoints are stable vs. tech preview:
https://access.redhat.com/articles/7047935

| Tier | Stability | Deprecation Policy |
|------|----------|--------------------|
| GA | Stable | 2 minor versions notice |
| Tech Preview | Unstable | May change without notice |
| Dev Preview | Experimental | No guarantees |
