oc apply -f grafana-ns.yaml

cd components/20-grafana
# CLUSTER_INFO=$(oc cluster-info | grep -Eo "api.*:6443")
# CLUSTER_ROUTE=${CLUSTER_INFO:4:-5}
manifests="$(helm template grafana . --set clusterRoute="$CLUSTER_ROUTE")"; while ! echo "$manifests" | oc apply -f-; do sleep 5; done