## This is for k8s 1.10 setup

### ETCD
> 参数约定
> K8S_DIR=/etc/kubernetes
> PKI_DIR=${K8S_DIR}/pki
> ETCD_SSL=/etc/etcd/ssl
> MANIFESTS_DIR=/etc/kubernetes/manifests/
> CFSSL_URL="https://pkg.cfssl.org/R1.2"

```
mkdir -p ${ETCD_SSL}

cfssl gencert -initca ca-csr.json | cfssljson -bare ${ETCD_SSL}/ca

cfssl gencert \
  -ca=${ETCD_SSL}/ca.pem \
  -ca-key=${ETCD_SSL}/ca-key.pem \
  -config=ca-config.json \
  -hostname=127.0.0.1,$(xargs -n1<<<${MasterArray[@]} | sort  | paste -d, -s -) \
  -profile=kubernetes \
  etcd-csr.json | cfssljson -bare ${ETCD_SSL}/etcd

rm -rf ${ETCD_SSL}/{*.csr,*.json}
ls $ETCD_SSL
ca-key.pem  ca.pem  etcd-key.pem  etcd.pem

for NODE in "${otherMaster[@]}"; do
    echo "--- $NODE ---"
    ssh $NODE "mkdir -p ${ETCD_SSL}"
    for FILE in ca-key.pem  ca.pem  etcd-key.pem  etcd.pem; do
      scp /etc/etcd/ssl/${FILE} ${NODE}:/etc/etcd/ssl/${FILE}
    done
  done
```