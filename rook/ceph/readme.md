# 使用

```shell
kubectl apply -f operator.yaml
kubectl apply -f cluster.yaml
kubectl apply -f dashboard-external-https.yaml

# admin/password
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```