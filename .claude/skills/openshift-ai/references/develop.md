# Develop — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Model Registries**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_model_registries
- **Model Catalog**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_the_model_catalog
- **RAG Stack (LlamaStack)**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/latest/html/working_with_llama_stack/llama-stack-adv-examples_rag#deploying-a-rag-stack-in-a-project_rag
- **Gen AI Playground**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/experimenting_with_models_in_the_gen_ai_playground
- **Distributed Workloads**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_distributed_workloads
- **S3-Compatible Object Storage**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_data_in_an_s3-compatible_object_store
- **Working on Projects**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_on_projects
- **Data Science IDE Images**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_in_your_data_science_ide
- **AI Pipelines**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_ai_pipelines
- **Connected Applications**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/working_with_connected_applications

---

## Data Science Projects

```bash
# Create a data science project
oc new-project my-ds-project
oc label namespace my-ds-project opendatahub.io/dashboard=true

# List all data science projects
oc get projects -l opendatahub.io/dashboard=true

# Delete a project
oc delete project my-ds-project
```

---

## S3 Data Connections (Object Storage)

```yaml
# Create a Secret for S3 credentials
apiVersion: v1
kind: Secret
metadata:
  name: my-s3-connection
  namespace: my-ds-project
  labels:
    opendatahub.io/managed: "true"
  annotations:
    opendatahub.io/connection-type: s3
    openshift.io/display-name: "My S3 Bucket"
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: "<access-key>"
  AWS_SECRET_ACCESS_KEY: "<secret-key>"
  AWS_S3_BUCKET: "my-bucket"
  AWS_S3_ENDPOINT: "https://s3.amazonaws.com"
  AWS_DEFAULT_REGION: "us-east-1"
```

```bash
# List data connections in a project
oc get secrets -n my-ds-project -l opendatahub.io/managed=true
```

---

## AI Pipelines (KFP v2)

```bash
# Check pipeline server status
oc get datasciencepipelineapplication -n my-ds-project

# Create a pipeline application
cat <<EOF | oc apply -f -
apiVersion: datasciencepipelinesapplications.opendatahub.io/v1alpha1
kind: DataSciencePipelinesApplication
metadata:
  name: pipelines-definition
  namespace: my-ds-project
spec:
  apiServer:
    deploy: true
  database:
    disableHealthCheck: false
    mariaDB:
      deploy: true
  objectStorage:
    externalStorage:
      bucket: my-pipelines-bucket
      host: s3.amazonaws.com
      port: ""
      region: us-east-1
      s3CredentialsSecret:
        accessKey: AWS_ACCESS_KEY_ID
        secretKey: AWS_SECRET_ACCESS_KEY
        secretName: my-s3-connection
      scheme: https
EOF

# List pipeline runs
oc get pipelineruns -n my-ds-project
```

---

## Distributed Workloads (Ray + Kueue)

```yaml
# Create a RayCluster for distributed training
apiVersion: ray.io/v1
kind: RayCluster
metadata:
  name: my-ray-cluster
  namespace: my-ds-project
spec:
  headGroupSpec:
    rayStartParams:
      dashboard-host: "0.0.0.0"
    template:
      spec:
        containers:
          - name: ray-head
            image: quay.io/modh/ray:2.23.0-py39-cu121
            resources:
              limits:
                cpu: "4"
                memory: "8Gi"
  workerGroupSpecs:
    - groupName: worker-group
      maxReplicas: 4
      minReplicas: 1
      replicas: 2
      rayStartParams: {}
      template:
        spec:
          containers:
            - name: ray-worker
              image: quay.io/modh/ray:2.23.0-py39-cu121
              resources:
                limits:
                  cpu: "4"
                  memory: "8Gi"
                  nvidia.com/gpu: "1"
```

```bash
# Check RayClusters
oc get raycluster -n my-ds-project

# Check Kueue workloads
oc get workload -n my-ds-project
oc get clusterqueue
oc get localqueue -n my-ds-project
```

---

## Model Registry (Developer Usage)

```bash
# Register a model version
oc exec -n redhat-ods-applications \
  deploy/model-registry-db -- \
  curl -s http://my-model-registry:8080/api/model_registry/v1alpha3/registered_models

# List registered models via oc
oc get registeredmodels -n redhat-ods-applications

# List model versions
oc get modelversions -n redhat-ods-applications
```

---

## RAG Stack with LlamaStack

```bash
# Deploy a RAG stack (requires LlamaStack operator enabled in DSC)
# See: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/latest/html/working_with_llama_stack/llama-stack-adv-examples_rag

# Check LlamaStack deployments
oc get llamastackdeployment -n my-ds-project

# Check available LlamaStack APIs
oc get route -n my-ds-project | grep llama
```

---

## Available Workbench IDE Images

| Image | Description |
|-------|------------|
| `s2i-minimal-notebook` | Minimal Jupyter environment |
| `s2i-generic-data-science-notebook` | Standard data science (pandas, scikit-learn, etc.) |
| `pytorch` | PyTorch with GPU support |
| `tensorflow` | TensorFlow with GPU support |
| `code-server` | VS Code in browser |
| `rstudio` | RStudio for R workloads |

```bash
# List available notebook images
oc get imagestream -n redhat-ods-applications | grep notebook
```

---

## Connected Applications

RHOAI integrates with external tools via the Dashboard:

| Application | Purpose |
|------------|---------|
| Jupyter Hub | Legacy notebook access |
| MLflow | Experiment tracking |
| Starburst | SQL query engine |
| Anaconda | Package management |

```bash
# Check connected application OdhApplication CRs
oc get odhapplication -n redhat-ods-applications
```
