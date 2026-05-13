# Train — Red Hat OpenShift AI Self-Managed

## Official Documentation

- **Customize Models to Build Gen AI Applications**: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.3/html/customize_models_to_build_gen_ai_applications

---

## Overview

RHOAI supports model customization and fine-tuning for domain-specific use cases using:

- **InstructLab / LAB-Tune**: Red Hat's synthetic data generation + fine-tuning workflow
- **Training Operator**: Kubernetes-native distributed training (PyTorchJob, TFJob)
- **Ray + KubeFlow**: Distributed training with RayJob or RayCluster + KFP pipelines

The typical workflow is:
```
1. Prepare domain-specific training data
2. Generate synthetic data (InstructLab / taxonomy)
3. Fine-tune a base model (e.g., Granite, Llama)
4. Evaluate the fine-tuned model (see evaluate.md)
5. Register in Model Registry
6. Deploy for inference (see deploy.md)
```

---

## Training Operator (PyTorchJob)

```yaml
# Distributed PyTorch training job
apiVersion: kubeflow.org/v1
kind: PyTorchJob
metadata:
  name: my-training-job
  namespace: my-ds-project
spec:
  pytorchReplicaSpecs:
    Master:
      replicas: 1
      restartPolicy: OnFailure
      template:
        spec:
          containers:
            - name: pytorch
              image: quay.io/modh/training:latest
              command:
                - python
                - train.py
                - --epochs=10
                - --model=granite-7b
              resources:
                limits:
                  cpu: "8"
                  memory: "32Gi"
                  nvidia.com/gpu: "1"
              volumeMounts:
                - name: training-data
                  mountPath: /data
          volumes:
            - name: training-data
              persistentVolumeClaim:
                claimName: training-data-pvc
    Worker:
      replicas: 3
      restartPolicy: OnFailure
      template:
        spec:
          containers:
            - name: pytorch
              image: quay.io/modh/training:latest
              resources:
                limits:
                  cpu: "8"
                  memory: "32Gi"
                  nvidia.com/gpu: "1"
```

```bash
# Check Training Operator is enabled in DSC
oc get datasciencecluster -o jsonpath='{.items[0].spec.components.trainingoperator}'

# List PyTorchJobs
oc get pytorchjob -n my-ds-project

# Watch training job logs
oc logs -f job/my-training-job-master-0 -n my-ds-project
```

---

## RayJob for Distributed Training

```yaml
apiVersion: ray.io/v1
kind: RayJob
metadata:
  name: fine-tune-job
  namespace: my-ds-project
spec:
  entrypoint: python fine_tune.py --model granite-7b --epochs 5
  runtimeEnvYAML: |
    pip:
      - transformers
      - peft
      - datasets
  rayClusterSpec:
    headGroupSpec:
      template:
        spec:
          containers:
            - name: ray-head
              image: quay.io/modh/ray:2.23.0-py39-cu121
              resources:
                limits:
                  cpu: "4"
                  memory: "16Gi"
    workerGroupSpecs:
      - groupName: gpu-workers
        replicas: 4
        template:
          spec:
            containers:
              - name: ray-worker
                image: quay.io/modh/ray:2.23.0-py39-cu121
                resources:
                  limits:
                    cpu: "8"
                    memory: "32Gi"
                    nvidia.com/gpu: "1"
```

```bash
# List RayJobs
oc get rayjob -n my-ds-project

# Get RayJob status
oc describe rayjob fine-tune-job -n my-ds-project
```

---

## InstructLab / LAB-Tune Workflow

InstructLab is Red Hat's open-source framework for domain-specific model customization using
synthetic data generation (SDG) and large-scale alignment tuning (LAB-Tune).

Key steps:
1. **Prepare taxonomy** — Create a domain-specific knowledge taxonomy (YAML)
2. **Generate synthetic data** — Use `ilab data generate` with a teacher model
3. **Fine-tune** — Run `ilab model train` with the Training Operator or RayJob
4. **Evaluate** — Use LM-Eval to benchmark the fine-tuned model (see evaluate.md)
5. **Serve** — Deploy the model via KServe (see deploy.md)

```bash
# Check if training operator supports InstructLab workloads
oc get crd | grep kubeflow

# Watch training job progress
oc get pods -n my-ds-project -l job-name=<training-job> -w
```

---

## Kueue for Job Scheduling

Kueue provides GPU-aware fair scheduling for training jobs:

```yaml
# Create a ClusterQueue for training workloads
apiVersion: kueue.x-k8s.io/v1beta1
kind: ClusterQueue
metadata:
  name: training-queue
spec:
  namespaceSelector: {}
  resourceGroups:
    - coveredResources: ["cpu", "memory", "nvidia.com/gpu"]
      flavors:
        - name: default-flavor
          resources:
            - name: "nvidia.com/gpu"
              nominalQuota: 8
```

```bash
# Check Kueue queues
oc get clusterqueue
oc get localqueue -n my-ds-project
oc get workload -n my-ds-project
```

---

## Tips

- GPU multi-instance (MIG) partitioning can improve GPU utilization for smaller training runs
- Use PVCs backed by high-throughput storage (ODF/Ceph RBD) for training data
- Store fine-tuned model checkpoints in S3-compatible object storage via data connections
- After training, register the model in the Model Registry before deploying (see develop.md)
