
# Monitoring

```shell
# Prometheus Operator
kubectl apply -f bundle.yaml
kubectl get pod

# Prometheus Instances
kubectl create -f service-monitor.yaml
kubectl create -f prometheus.yaml
kubectl create -f prometheus-service.yaml

kubectl -n rook-ceph get pod prometheus-rook-prometheus-0

echo "http://$(kubectl -n rook-ceph -o jsonpath={.status.hostIP} get pod prometheus-rook-prometheus-0):30900"
```