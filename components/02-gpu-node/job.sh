#!/bin/bash

# shellcheck disable=SC1091
. /scripts/ocp.sh

INSTANCE_TYPE=${INSTANCE_TYPE:-g4dn.4xlarge}
REPLICAS=${REPLICAS:-1}
GPU_INSTANCE_NAME="gpu-cluster-${INSTANCE_TYPE}"

ocp_aws_cluster || exit 0
echo "Creating GPU machineset for ${INSTANCE_TYPE} with name ${GPU_INSTANCE_NAME}"
ocp_aws_create_gpu_machineset "${INSTANCE_TYPE}" "{GPU_INSTANCE_NAME}"
echo "Tainting GPU machineset for ${INSTANCE_TYPE}"
ocp_aws_taint_gpu_machineset "${INSTANCE_TYPE}"
