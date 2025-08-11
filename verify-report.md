# OpenShift AI Verification Report
Timestamp: 2025-08-11T22:49:17Z

## Summary
- CPU workers: 7
- GPU nodes (alloc>0): ip-10-0-19-185.us-east-2.compute.internal
- Nodes schedulable: yes
- Web Terminal CSV: 
- Cluster version: 4.18.12

## Results
| Step | Coverage | Result |
|------|----------|--------|
| CPU worker node | At least 1 non-GPU worker | PASS |
| GPU node available | GPU via role/NFD/alloc | PASS |
| Nodes schedulable | No cordoned nodes | PASS |
| Web Terminal operator | CSV Succeeded in openshift-operators | FAIL |
| OpenShift version | >= 4.16.0 | PASS |
| Default StorageClass | Default StorageClass present | PASS |
| Ingress health | Default Ingress Available + console route admitted | PASS |
| OLM packageserver | CSV Succeeded | PASS |
| Pull-secret registry.redhat.io | Pull-secret includes registry.redhat.io | PASS |
| ClusterOperators available | console, ingress, image-registry, authentication | PASS |
| SCC restricted-v2 | SCC exists | PASS |

## Remediation recommendations
- Install Web Terminal operator (apply components/00-prereqs or run prereqs playbook) and wait for CSV Succeeded.
