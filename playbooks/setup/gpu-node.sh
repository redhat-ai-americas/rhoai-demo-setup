#!/bin/bash

set -euo pipefail

# Defaults (mirroring playbooks/setup/gpu-node.ansible.yml)
GPU_INSTANCE_TYPE="${GPU_INSTANCE_TYPE:-g6e.4xlarge}"
GPU_NODE_LABEL="${GPU_NODE_LABEL:-node-role.kubernetes.io/gpu}"
MACHINE_API_NAMESPACE="${MACHINE_API_NAMESPACE:-openshift-machine-api}"

print_usage() {
  echo "Usage: $0 [--instance-type TYPE] [--label KEY] [--namespace NS]"
  echo ""
  echo "Options:"
  echo "  --instance-type, -t   EC2 instance type to use (default: ${GPU_INSTANCE_TYPE})"
  echo "  --label, -l           Node label key for GPU nodes (default: ${GPU_NODE_LABEL})"
  echo "  --namespace, -n       Machineset namespace (default: ${MACHINE_API_NAMESPACE})"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --instance-type|-t)
      GPU_INSTANCE_TYPE="$2"; shift 2;;
    --label|-l)
      GPU_NODE_LABEL="$2"; shift 2;;
    --namespace|-n)
      MACHINE_API_NAMESPACE="$2"; shift 2;;
    --help|-h)
      print_usage; exit 0;;
    *)
      echo "Unknown argument: $1"; print_usage; exit 1;;
  esac
done

echo "Creating GPU MachineSet using:"
echo "  namespace      : ${MACHINE_API_NAMESPACE}"
echo "  instance type  : ${GPU_INSTANCE_TYPE}"
echo "  node label key : ${GPU_NODE_LABEL}"

# Dependency checks
command -v oc >/dev/null 2>&1 || { echo "Error: 'oc' CLI not found in PATH."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: 'jq' is required but not found in PATH."; exit 1; }

# Ensure we are logged in
if ! oc whoami >/dev/null 2>&1; then
  echo "Error: Not logged in to an OpenShift cluster. Please run 'oc login'."
  exit 1
fi

echo "Fetching MachineSets in namespace '${MACHINE_API_NAMESPACE}'..."
MACHINESETS_JSON=$(oc get machineset -n "${MACHINE_API_NAMESPACE}" -o json)

NAMES=$(echo "${MACHINESETS_JSON}" | jq -r '.items[].metadata.name')
if [[ -z "${NAMES}" ]]; then
  echo "Error: No MachineSets found in namespace ${MACHINE_API_NAMESPACE}."
  exit 1
fi

echo "MachineSets: ${NAMES//$'\n'/, }"

AVAILABILITY_ZONES=$(echo "${MACHINESETS_JSON}" | jq -r '.items[].spec.template.spec.providerSpec.value.placement.availabilityZone')
echo "Availability Zones: ${AVAILABILITY_ZONES//$'\n'/, }"

# Select first MachineSet as source
SOURCE_MACHINESET=$(echo "${MACHINESETS_JSON}" | jq -r '.items[0].metadata.name')
if [[ -z "${SOURCE_MACHINESET}" || "${SOURCE_MACHINESET}" == "null" ]]; then
  echo "Error: Unable to determine a source MachineSet."
  exit 1
fi
echo "Source MachineSet: ${SOURCE_MACHINESET}"

# Define new GPU MachineSet name (replace 'worker' with 'gpu')
GPU_MACHINESET=$(echo "${SOURCE_MACHINESET}" | sed 's/worker/gpu/g')
echo "GPU MachineSet name: ${GPU_MACHINESET}"

echo "Fetching source MachineSet JSON..."
SRC_JSON=$(oc get machineset -n "${MACHINE_API_NAMESPACE}" "${SOURCE_MACHINESET}" -o json)

echo "Preparing GPU MachineSet manifest..."
TMP_FILE=$(mktemp /tmp/gpu-machineset.XXXXXX.json)
echo "${SRC_JSON}" | jq \
  --arg name "${GPU_MACHINESET}" \
  --arg label "${GPU_NODE_LABEL}" \
  --arg inst "${GPU_INSTANCE_TYPE}" \
  '
  .metadata.name = $name
  | .metadata.labels["machine.openshift.io/cluster-api-machineset"] = $name
  | .metadata.labels["cluster-api/accelerator"] = "nvidia-gpu"
  | .spec.replicas = 1
  | .spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"] = $name
  | .spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"] = $name
  | .spec.template.metadata.labels[$label] = ""
  | .spec.template.spec.metadata.labels[$label] = ""
  | .spec.template.spec.metadata.labels["cluster-api/accelerator"] = "nvidia-gpu"
  | .spec.template.spec.providerSpec.value.instanceType = $inst
  ' > "${TMP_FILE}"

echo "Applying GPU MachineSet..."
oc apply -n "${MACHINE_API_NAMESPACE}" -f "${TMP_FILE}"

echo "Waiting for at least one GPU-labeled node to be Ready..."
RETRIES=20
DELAY=30
for ((i=1; i<=RETRIES; i++)); do
  COUNT=$(oc get nodes -l "${GPU_NODE_LABEL}" --no-headers 2>/dev/null | grep -i Ready | wc -l | tr -d ' ')
  echo "Attempt ${i}/${RETRIES}: Ready GPU nodes: ${COUNT}"
  if [[ "${COUNT}" -ge 1 ]]; then
    echo "GPU node is Ready."
    break
  fi
  if [[ ${i} -eq ${RETRIES} ]]; then
    echo "Timed out waiting for GPU node to become Ready."; exit 1
  fi
  sleep ${DELAY}
done

echo "Checking NVIDIA GPU operator pods status..."
REQUIRED_PODS=(
  "nvidia-container-toolkit-daemonset"
  "nvidia-driver-daemonset"
  "nvidia-device-plugin-daemonset"
  "nvidia-operator-validator"
)

RETRIES=40 # 40 x 30s = 20 minutes
DELAY=30
for ((i=1; i<=RETRIES; i++)); do
  ALL_READY=true
  echo "Pod status summary (try ${i}/${RETRIES}):"
  for POD_PATTERN in "${REQUIRED_PODS[@]}"; do
    TOTAL=$(oc get pods -n nvidia-gpu-operator --no-headers 2>/dev/null | grep "${POD_PATTERN}" | wc -l | tr -d ' ')
    RUNNING=$(oc get pods -n nvidia-gpu-operator --no-headers 2>/dev/null | grep "${POD_PATTERN}" | grep Running | wc -l | tr -d ' ')
    echo "  ${POD_PATTERN}: ${RUNNING}/${TOTAL} Running"
    if [[ "${TOTAL}" -eq 0 || "${RUNNING}" -lt "${TOTAL}" ]]; then
      ALL_READY=false
    fi
  done
  if [[ "${ALL_READY}" == true ]]; then
    echo "All required NVIDIA pods are Running."
    break
  fi
  if [[ ${i} -eq ${RETRIES} ]]; then
    echo "Timed out waiting for NVIDIA GPU operator pods to be Running."; exit 1
  fi
  sleep ${DELAY}
done

echo "Final NVIDIA pod listing:"
for POD_PATTERN in "${REQUIRED_PODS[@]}"; do
  oc get pods -n nvidia-gpu-operator --no-headers | grep "${POD_PATTERN}" || echo "No pod found for ${POD_PATTERN}"
done

echo "Done. GPU MachineSet '${GPU_MACHINESET}' applied."


