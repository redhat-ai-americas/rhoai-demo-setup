# Install — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Install and Uninstall (Connected)**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/installing_and_uninstalling_openshift_ai_self-managed
- **Install and Uninstall (Disconnected)**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment
- **Upgrade Limitation Notice**: https://access.redhat.com/articles/7133758

---

## ⚠️ Critical: Upgrades Not Supported in 3.x

> Upgrades from RHOAI 2.x to 3.x are **not supported**. The 3.x release introduces
> significant architectural changes. Migration from 2.25 (stable) to the first stable
> 3.x release requires a fresh installation.

Reference: https://access.redhat.com/articles/7133758

---

## Installation Overview

RHOAI Self-Managed is installed as an OpenShift Operator via OperatorHub or CLI.
The installation creates two primary namespaces:

| Namespace | Purpose |
|-----------|---------|
| `redhat-ods-operator` | Operator controller pod |
| `redhat-ods-applications` | All RHOAI component workloads |
| `redhat-ods-monitoring` | Prometheus monitoring stack |

---

## Install via OperatorHub (Connected)

### Step 1: Install the Operator

```bash
# Create the operator namespace
oc new-project redhat-ods-operator

# Create the OperatorGroup
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: rhods-operator
  namespace: redhat-ods-operator
spec:
  upgradeStrategy: Default
EOF

# Create the Subscription
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhods-operator
  namespace: redhat-ods-operator
spec:
  channel: fast              # Use 'stable' for LTS releases when available
  installPlanApproval: Automatic
  name: rhods-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

### Step 2: Create the DSCI (DataScienceClusterInitialization)

```yaml
apiVersion: dscinitialization.opendatahub.io/v1
kind: DSCInitialization
metadata:
  name: default-dsci
spec:
  applicationsNamespace: redhat-ods-applications
  monitoring:
    managementState: Managed
    namespace: redhat-ods-monitoring
  serviceMesh:
    managementState: Unmanaged   # Set to Managed if using Serverless/Istio
  trustedCABundle:
    customCABundle: ""
    managementState: Managed
```

### Step 3: Create the DataScienceCluster (DSC)

```yaml
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
spec:
  components:
    dashboard:
      managementState: Managed
    workbenches:
      managementState: Managed
    datasciencepipelines:
      managementState: Managed
    modelmeshserving:
      managementState: Managed
    kserve:
      managementState: Managed
      serving:
        managementState: Unmanaged   # RawDeployment (3.3 default)
        name: knative-serving
    trainingoperator:
      managementState: Managed
    ray:
      managementState: Managed
    kueue:
      managementState: Managed
    modelregistry:
      managementState: Managed
    trustyai:
      managementState: Managed
    lmeval:
      managementState: Managed
    guardsrails:
      managementState: Managed
    featurestore:
      managementState: Managed
    llamastack:
      managementState: Managed
```

---

## Disconnected / Air-Gapped Install

For disconnected environments, you must mirror images before installing:

```bash
# Mirror RHOAI images to your internal registry
oc adm catalog mirror \
  registry.redhat.io/redhat/redhat-operator-index:v4.15 \
  <your-registry>/redhat \
  --manifests-only

# Apply the ImageContentSourcePolicy and CatalogSource from mirrored manifests
oc apply -f manifests/imageContentSourcePolicy.yaml
oc apply -f manifests/catalogSource.yaml
```

Full disconnected guide: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment

---

## Verify Installation

```bash
# Check operator pod is running
oc get pods -n redhat-ods-operator

# Check all application pods are running
oc get pods -n redhat-ods-applications

# Check DSC status
oc get datasciencecluster default-dsc -o jsonpath='{.status.conditions}' | jq .

# Check DSCI status
oc get dsci default-dsci -o jsonpath='{.status.conditions}' | jq .

# Access the dashboard
oc get route rhods-dashboard -n redhat-ods-applications
```

---

## Uninstall RHOAI

```bash
# Delete the DataScienceCluster first
oc delete datasciencecluster default-dsc

# Delete the DSCI
oc delete dsci default-dsci

# Delete the Subscription and CSV
oc delete subscription rhods-operator -n redhat-ods-operator
oc delete csv -n redhat-ods-operator $(oc get csv -n redhat-ods-operator -o name)

# Delete namespaces (this removes all RHOAI resources)
oc delete project redhat-ods-applications
oc delete project redhat-ods-monitoring
oc delete project redhat-ods-operator
```

---

## Caveats

- Always verify the OCP version is in the supported configurations matrix before installing
- The `fast` channel receives updates more frequently; use `stable` (when available) for production
- For GPU support, install NVIDIA GPU Operator **before** deploying model serving workloads
- In disconnected environments, ensure all dependent images (notebook images, serving runtimes) are also mirrored
