# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/k8s/ssl/ca.pem \
  --embed-certs=true \
  --server=https://10.26.8.100:8443 \
  --kubeconfig=kubectl.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials admin \
  --client-certificate=/etc/k8s/ssl/admin.pem \
  --client-key=/etc/k8s/ssl/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=kubectl.kubeconfig

# 设置上下文参数
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin \
  --kubeconfig=kubectl.kubeconfig
  
# 设置默认上下文
kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig


kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/k8s/ssl/ca.pem \
  --embed-certs=true \
  --server=https://10.26.8.100:8443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=/etc/k8s/ssl/admin.pem \
  --client-key=kube-/etc/k8s/ssl/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig