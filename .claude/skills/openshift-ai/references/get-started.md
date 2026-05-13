# Get Started — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Getting Started Guide**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/getting_started_with_red_hat_openshift_ai_self-managed
- **Fraud Detection Tutorial** *(New in 3.3)*: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/openshift_ai_tutorial_-_fraud_detection_example

---

## Onboarding Flow

The typical RHOAI onboarding path for a data scientist is:

```
1. Admin installs RHOAI operator → enables DataScienceCluster components
2. Admin creates a namespace / data science project
3. Data scientist launches a Workbench (Jupyter notebook environment)
4. Data scientist connects object storage (S3-compatible) for data and models
5. Data scientist builds and trains models in the notebook
6. Data scientist deploys a model via the Dashboard or InferenceService CR
7. Data scientist monitors the endpoint and model performance
```

---

## Key oc Commands for Getting Started

```bash
# Verify RHOAI is installed and healthy
oc get datasciencecluster
oc get pods -n redhat-ods-applications

# List data science projects
oc get projects -l opendatahub.io/dashboard=true

# Create a new data science project
oc new-project my-ds-project
oc label namespace my-ds-project opendatahub.io/dashboard=true

# List workbenches in a project
oc get notebooks -n my-ds-project

# Check the RHOAI Dashboard route
oc get route rhods-dashboard -n redhat-ods-applications
```

---

## Minimal Workbench YAML

```yaml
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: my-workbench
  namespace: my-ds-project
  annotations:
    notebooks.opendatahub.io/inject-oauth: "true"
spec:
  template:
    spec:
      containers:
        - name: my-workbench
          image: image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/s2i-minimal-notebook:2024.2
          resources:
            requests:
              cpu: "1"
              memory: 2Gi
            limits:
              cpu: "2"
              memory: 4Gi
          volumeMounts:
            - mountPath: /opt/app-root/src
              name: my-workbench-data
      volumes:
        - name: my-workbench-data
          persistentVolumeClaim:
            claimName: my-workbench-data
```

---

## Caveats and Tips

- The RHOAI Dashboard is the primary UI — always provide its route to new users
- Data science projects are standard OpenShift namespaces with special labels
- Workbenches require a PVC; always pre-create a PVC or use the Dashboard to auto-provision
- The Fraud Detection tutorial (3.3) is the best end-to-end example for new users
- GPU-enabled workbenches require the NVIDIA GPU Operator and an AcceleratorProfile CR
