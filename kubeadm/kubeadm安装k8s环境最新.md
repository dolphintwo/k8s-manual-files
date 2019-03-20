[TOC]
## 准备
### 关闭swap
```shell
vim /etc/fstab #注释swap
swapoff -a
```

### 调整系统参数
```shell
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```
## 安装docker
略

## kubeadm启动
### 安装kubeadm对应版本
```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

#####172内网配置#####
[kubernetes]
name=Kubernetes
baseurl=http://172.20.0.13:9999/kubernetes/
enabled=1
gpgcheck=0
repo_gpgcheck=0
##########

yum install kubelet-1.13.1 kubeadm-1.13.1 kubectl-1.13.1 --disableexcludes=kubernetes
systemctl enable kubelet && systemctl start kubelet
```

### kubeadm.yml
```yml
apiVersion: kubeadm.k8s.io/v1beta1
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: k60p22.go0fadibgqm2xcx8
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 172.20.0.23
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: kubeadm-02
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta1
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: ""
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: 172.20.0.13/google_containers
kind: ClusterConfiguration
kubernetesVersion: v1.13.1
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
scheduler: {}
```
### 初始化集群
K8s的控制面板组件运行在Master节点上，包括etcd和API server（Kubectl便是通过API server与k8s通信）。

在执行初始化之前，我们还有一下3点需要注意：
1.选择一个网络插件，并检查它是否需要在初始化Master时指定一些参数，比如我们可能需要根据选择的插件来设置`--pod-network-cidr`参数。参考：[Installing a pod network add-on](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network)。
2.kubeadm使用eth0的默认网络接口（通常是内网IP）做为Master节点的`advertise address`，如果我们想使用不同的网络接口，可以使用`--apiserver-advertise-address=<ip-address>`参数来设置。如果适应IPv6，则必须使用IPv6d的地址，如：`--apiserver-advertise-address=fd00::101`。
3.使用`kubeadm config images pull`来预先拉取初始化需要用到的镜像，用来检查是否能连接到Kubenetes的Registries。
Kubenetes默认Registries地址是`k8s.gcr.io`，很明显，在国内并不能访问gcr.io，因此在`kubeadm v1.13`之前的版本，安装起来非常麻烦，但是在1.13版本中终于解决了国内的痛点，其增加了一个`--image-repository`参数，默认值是`k8s.gcr.io`，我们将其指定为国内镜像地址：`registry.aliyuncs.com/google_containers`，其它的就可以完全按照官方文档来愉快的玩耍了。
其次，我们还需要指定--kubernetes-version参数，因为它的默认值是stable-1，会导致从`https://dl.k8s.io/release/stable-1.txt`下载最新的版本号，我们可以将其指定为固定版本（最新版：v1.13.1）来跳过网络请求。

```shell
# 使用calico网络 --pod-network-cidr=192.168.0.0/16
[root@kubeadm-02 ~]# kubeadm init --image-repository 172.20.0.13/google_containers --kubernetes-version v1.13.1 --pod-network-cidr=192.168.0.0/16

# 输出
[init] Using Kubernetes version: v1.13.1
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubeadm-02 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.20.0.23]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [kubeadm-02 localhost] and IPs [172.20.0.23 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [kubeadm-02 localhost] and IPs [172.20.0.23 127.0.0.1 ::1]
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 21.502156 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.13" in namespace kube-system with the configuration for the kubelets in the cluster
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "kubeadm-02" as an annotation
[mark-control-plane] Marking the node kubeadm-02 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node kubeadm-02 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: kl3k5j.zbasdjxnxg85bgsx
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube

▽
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 172.20.0.23:6443 --token kl3k5j.zbasdjxnxg85bgsx --discovery-token-ca-cert-hash sha256:47daff7fc07dbcef390fe25c62fc3341ea1714e3303137f596864586314d350c

# 输入
[root@kubeadm-02 ~]#  
[root@kubeadm-02 ~]# mkdir -p $HOME/.kube
[root@kubeadm-02 ~]# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[root@kubeadm-02 ~]# sudo chown $(id -u):$(id -g) $HOME/.kube/config
[root@kubeadm-02 ~]# kubectl get pods --all-namespaces

NAMESPACE    NAME                        READY  STATUS    RESTARTS  AGE
kube-system  coredns-8fb8df88c-rpl4d    0/1    Pending  0          53s
kube-system  coredns-8fb8df88c-tm87s    0/1    Pending  0          53s
kube-system  kube-apiserver-kubeadm-02  1/1    Running  0          17s
kube-system  kube-proxy-fx4cn            1/1    Running  0          53s
kube-system  kube-scheduler-kubeadm-02  1/1    Running  0          12s
```
## 安装网络插件
当前coredns的状态为`Pending`，因为我们网络插件还未安装。
Calico是一个纯三层的虚拟网络方案，Calico 为每个容器分配一个 IP，每个 host 都是 router，把不同 host 的容器连接起来。与 VxLAN 不同的是，Calico 不对数据包做额外封装，不需要 NAT 和端口映射，扩展性和性能都很好。
默认情况下，Calico网络插件使用的的网段是192.168.0.0/16，在init的时候，我们已经通过--pod-network-cidr=192.168.0.0/16来适配Calico，当然你也可以修改calico.yml文件来指定不同的网段。
```shell
[root@kubeadm-02 ~]# kubectl apply -f rbac-kdd.yaml
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
[root@kubeadm-02 ~]#
[root@kubeadm-02 ~]# kubectl apply -f calico.yaml
configmap/calico-config created
service/calico-typha created
deployment.apps/calico-typha created
poddisruptionbudget.policy/calico-typha created
daemonset.extensions/calico-node created
serviceaccount/calico-node created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
```

### rbac-kdd.yaml
```yml
# Calico Version v3.3.2
# https://docs.projectcalico.org/v3.3/releases#v3.3.2
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: calico-node
rules:
  - apiGroups: [""]
    resources:
      - namespaces
      - serviceaccounts
    verbs:
      - get
      - list
      - watch
  - apiGroups: [""]
    resources:
      - pods/status
    verbs:
      - patch
  - apiGroups: [""]
    resources:
      - pods
    verbs:
      - get
      - list
      - watch
  - apiGroups: [""]
    resources:
      - services
    verbs:
      - get
  - apiGroups: [""]
    resources:
      - endpoints
    verbs:
      - get
  - apiGroups: [""]
    resources:
      - nodes
    verbs:
      - get
      - list
      - update
      - watch
  - apiGroups: ["extensions"]
    resources:
      - networkpolicies
    verbs:
      - get
      - list
      - watch
  - apiGroups: ["networking.k8s.io"]
    resources:
      - networkpolicies
    verbs:
      - watch
      - list
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - globalfelixconfigs
      - felixconfigurations
      - bgppeers
      - globalbgpconfigs
      - bgpconfigurations
      - ippools
      - globalnetworkpolicies
      - globalnetworksets
      - networkpolicies
      - clusterinformations
      - hostendpoints
    verbs:
      - create
      - get
      - list
      - update
      - watch

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: calico-node
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: calico-node
subjects:
- kind: ServiceAccount
  name: calico-node
  namespace: kube-system
```
### calico.yaml
```yml
# Calico Version v3.3.2
# https://docs.projectcalico.org/v3.3/releases#v3.3.2
# This manifest includes the following component versions:
#  calico/node:v3.3.2
#  calico/cni:v3.3.2

# This ConfigMap is used to configure a self-hosted Calico installation.
kind: ConfigMap
apiVersion: v1
metadata:
  name: calico-config
  namespace: kube-system
data:
  # To enable Typha, set this to "calico-typha" *and* set a non-zero value for Typha replicas
  # below.  We recommend using Typha if you have more than 50 nodes. Above 100 nodes it is
  # essential.
  typha_service_name: "none"
  # Configure the Calico backend to use.
  calico_backend: "bird"

  # Configure the MTU to use
  veth_mtu: "1440"

  # The CNI network configuration to install on each node.  The special
  # values in this config will be automatically populated.
  cni_network_config: |-
    {
      "name": "k8s-pod-network",
      "cniVersion": "0.3.0",
      "plugins": [
        {
          "type": "calico",
          "log_level": "info",
          "datastore_type": "kubernetes",
          "nodename": "__KUBERNETES_NODE_NAME__",
          "mtu": __CNI_MTU__,
          "ipam": {
            "type": "host-local",
            "subnet": "usePodCidr"
          },
          "policy": {
              "type": "k8s"
          },
          "kubernetes": {
              "kubeconfig": "__KUBECONFIG_FILEPATH__"
          }
        },
        {
          "type": "portmap",
          "snat": true,
          "capabilities": {"portMappings": true}
        }
      ]
    }

---


# This manifest creates a Service, which will be backed by Calico's Typha daemon.
# Typha sits in between Felix and the API server, reducing Calico's load on the API server.

apiVersion: v1
kind: Service
metadata:
  name: calico-typha
  namespace: kube-system
  labels:
    k8s-app: calico-typha
spec:
  ports:
    - port: 5473
      protocol: TCP
      targetPort: calico-typha
      name: calico-typha
  selector:
    k8s-app: calico-typha

---

# This manifest creates a Deployment of Typha to back the above service.

apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: calico-typha
  namespace: kube-system
  labels:
    k8s-app: calico-typha
spec:
  # Number of Typha replicas.  To enable Typha, set this to a non-zero value *and* set the
  # typha_service_name variable in the calico-config ConfigMap above.
  #
  # We recommend using Typha if you have more than 50 nodes.  Above 100 nodes it is essential
  # (when using the Kubernetes datastore).  Use one replica for every 100-200 nodes.  In
  # production, we recommend running at least 3 replicas to reduce the impact of rolling upgrade.
  replicas: 0
  revisionHistoryLimit: 2
  template:
    metadata:
      labels:
        k8s-app: calico-typha
      annotations:
        # This, along with the CriticalAddonsOnly toleration below, marks the pod as a critical
        # add-on, ensuring it gets priority scheduling and that its resources are reserved
        # if it ever gets evicted.
        scheduler.alpha.kubernetes.io/critical-pod: ''
        cluster-autoscaler.kubernetes.io/safe-to-evict: 'true'
    spec:
      nodeSelector:
        beta.kubernetes.io/os: linux
      hostNetwork: true
      tolerations:
        # Mark the pod as a critical add-on for rescheduling.
        - key: CriticalAddonsOnly
          operator: Exists
      # Since Calico can't network a pod until Typha is up, we need to run Typha itself
      # as a host-networked pod.
      serviceAccountName: calico-node
      containers:
      - image: 172.20.0.13/calico/typha:v3.3.2
        name: calico-typha
        ports:
        - containerPort: 5473
          name: calico-typha
          protocol: TCP
        env:
          # Enable "info" logging by default.  Can be set to "debug" to increase verbosity.
          - name: TYPHA_LOGSEVERITYSCREEN
            value: "info"
          # Disable logging to file and syslog since those don't make sense in Kubernetes.
          - name: TYPHA_LOGFILEPATH
            value: "none"
          - name: TYPHA_LOGSEVERITYSYS
            value: "none"
          # Monitor the Kubernetes API to find the number of running instances and rebalance
          # connections.
          - name: TYPHA_CONNECTIONREBALANCINGMODE
            value: "kubernetes"
          - name: TYPHA_DATASTORETYPE
            value: "kubernetes"
          - name: TYPHA_HEALTHENABLED
            value: "true"
          # Uncomment these lines to enable prometheus metrics.  Since Typha is host-networked,
          # this opens a port on the host, which may need to be secured.
          #- name: TYPHA_PROMETHEUSMETRICSENABLED
          #  value: "true"
          #- name: TYPHA_PROMETHEUSMETRICSPORT
          #  value: "9093"
        livenessProbe:
          exec:
            command:
            - calico-typha
            - check
            - liveness
          periodSeconds: 30
          initialDelaySeconds: 30
        readinessProbe:
          exec:
            command:
            - calico-typha
            - check
            - readiness
          periodSeconds: 10

---

# This manifest creates a Pod Disruption Budget for Typha to allow K8s Cluster Autoscaler to evict

apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: calico-typha
  namespace: kube-system
  labels:
    k8s-app: calico-typha
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: calico-typha

---

# This manifest installs the calico/node container, as well
# as the Calico CNI plugins and network config on
# each master and worker node in a Kubernetes cluster.
kind: DaemonSet
apiVersion: extensions/v1beta1
metadata:
  name: calico-node
  namespace: kube-system
  labels:
    k8s-app: calico-node
spec:
  selector:
    matchLabels:
      k8s-app: calico-node
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  template:
    metadata:
      labels:
        k8s-app: calico-node
      annotations:
        # This, along with the CriticalAddonsOnly toleration below,
        # marks the pod as a critical add-on, ensuring it gets
        # priority scheduling and that its resources are reserved
        # if it ever gets evicted.
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      nodeSelector:
        beta.kubernetes.io/os: linux
      hostNetwork: true
      tolerations:
        # Make sure calico-node gets scheduled on all nodes.
        - effect: NoSchedule
          operator: Exists
        # Mark the pod as a critical add-on for rescheduling.
        - key: CriticalAddonsOnly
          operator: Exists
        - effect: NoExecute
          operator: Exists
      serviceAccountName: calico-node
      # Minimize downtime during a rolling upgrade or deletion; tell Kubernetes to do a "force
      # deletion": https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods.
      terminationGracePeriodSeconds: 0
      containers:
        # Runs calico/node container on each Kubernetes node.  This
        # container programs network policy and routes on each
        # host.
        - name: calico-node
          image: 172.20.0.13/calico/node:v3.3.2
          env:
            # Use Kubernetes API as the backing datastore.
            - name: DATASTORE_TYPE
              value: "kubernetes"
            # Typha support: controlled by the ConfigMap.
            - name: FELIX_TYPHAK8SSERVICENAME
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: typha_service_name
            # Wait for the datastore.
            - name: WAIT_FOR_DATASTORE
              value: "true"
            # Set based on the k8s node name.
            - name: NODENAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            # Choose the backend to use.
            - name: CALICO_NETWORKING_BACKEND
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: calico_backend
            # Cluster type to identify the deployment type
            - name: CLUSTER_TYPE
              value: "k8s,bgp"
            # Auto-detect the BGP IP address.
            - name: IP
              value: "autodetect"
            # Enable IPIP
            - name: CALICO_IPV4POOL_IPIP
              value: "Always"
            # Set MTU for tunnel device used if ipip is enabled
            - name: FELIX_IPINIPMTU
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: veth_mtu
            # The default IPv4 pool to create on startup if none exists. Pod IPs will be
            # chosen from this range. Changing this value after installation will have
            # no effect. This should fall within `--cluster-cidr`.
            - name: CALICO_IPV4POOL_CIDR
              value: "192.168.0.0/16"
            # Disable file logging so `kubectl logs` works.
            - name: CALICO_DISABLE_FILE_LOGGING
              value: "true"
            # Set Felix endpoint to host default action to ACCEPT.
            - name: FELIX_DEFAULTENDPOINTTOHOSTACTION
              value: "ACCEPT"
            # Disable IPv6 on Kubernetes.
            - name: FELIX_IPV6SUPPORT
              value: "false"
            # Set Felix logging to "info"
            - name: FELIX_LOGSEVERITYSCREEN
              value: "info"
            - name: FELIX_HEALTHENABLED
              value: "true"
          securityContext:
            privileged: true
          resources:
            requests:
              cpu: 250m
          livenessProbe:
            httpGet:
              path: /liveness
              port: 9099
              host: localhost
            periodSeconds: 10
            initialDelaySeconds: 10
            failureThreshold: 6
          readinessProbe:
            exec:
              command:
              - /bin/calico-node
              - -bird-ready
              - -felix-ready
            periodSeconds: 10
          volumeMounts:
            - mountPath: /lib/modules
              name: lib-modules
              readOnly: true
            - mountPath: /run/xtables.lock
              name: xtables-lock
              readOnly: false
            - mountPath: /var/run/calico
              name: var-run-calico
              readOnly: false
            - mountPath: /var/lib/calico
              name: var-lib-calico
              readOnly: false
        # This container installs the Calico CNI binaries
        # and CNI network config file on each node.
        - name: install-cni
          image: 172.20.0.13/calico/cni:v3.3.2
          command: ["/install-cni.sh"]
          env:
            # Name of the CNI config file to create.
            - name: CNI_CONF_NAME
              value: "10-calico.conflist"
            # Set the hostname based on the k8s node name.
            - name: KUBERNETES_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            # The CNI network config to install on each node.
            - name: CNI_NETWORK_CONFIG
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: cni_network_config
            # CNI MTU Config variable
            - name: CNI_MTU
              valueFrom:
                configMapKeyRef:
                  name: calico-config
                  key: veth_mtu
          volumeMounts:
            - mountPath: /host/opt/cni/bin
              name: cni-bin-dir
            - mountPath: /host/etc/cni/net.d
              name: cni-net-dir
      volumes:
        # Used by calico/node.
        - name: lib-modules
          hostPath:
            path: /lib/modules
        - name: var-run-calico
          hostPath:
            path: /var/run/calico
        - name: var-lib-calico
          hostPath:
            path: /var/lib/calico
        - name: xtables-lock
          hostPath:
            path: /run/xtables.lock
            type: FileOrCreate
        # Used to install CNI.
        - name: cni-bin-dir
          hostPath:
            path: /opt/cni/bin
        - name: cni-net-dir
          hostPath:
            path: /etc/cni/net.d
---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: calico-node
  namespace: kube-system

---

# Create all the CustomResourceDefinitions needed for
# Calico policy and networking mode.

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: felixconfigurations.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: FelixConfiguration
    plural: felixconfigurations
    singular: felixconfiguration
---

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: bgppeers.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: BGPPeer
    plural: bgppeers
    singular: bgppeer

---

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: bgpconfigurations.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: BGPConfiguration
    plural: bgpconfigurations
    singular: bgpconfiguration

---

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ippools.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: IPPool
    plural: ippools
    singular: ippool

---

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: hostendpoints.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: HostEndpoint
    plural: hostendpoints
    singular: hostendpoint

---

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: clusterinformations.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: ClusterInformation
    plural: clusterinformations
    singular: clusterinformation

---

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: globalnetworkpolicies.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: GlobalNetworkPolicy
    plural: globalnetworkpolicies
    singular: globalnetworkpolicy

---

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: globalnetworksets.crd.projectcalico.org
spec:
  scope: Cluster
  group: crd.projectcalico.org
  version: v1
  names:
    kind: GlobalNetworkSet
    plural: globalnetworksets
    singular: globalnetworkset

---

apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: networkpolicies.crd.projectcalico.org
spec:
  scope: Namespaced
  group: crd.projectcalico.org
  version: v1
  names:
    kind: NetworkPolicy
    plural: networkpolicies
    singular: networkpolicy
```
## 其他
默认情况下，由于安全原因，集群并不会将pods部署在Master节点上。但是在开发环境下，我们可能就只有一个Master节点，这时可以使用下面的命令来解除这个限制：
```shell
[root@kubeadm-02 ~]# kubectl get pods --all-namespaces
NAMESPACE    NAME                                READY  STATUS    RESTARTS  AGE
kube-system  calico-node-gsn89                    2/2    Running  0          20s
kube-system  coredns-8fb8df88c-rpl4d              1/1    Running  0          16m
kube-system  coredns-8fb8df88c-tm87s              1/1    Running  0          16m
kube-system  etcd-kubeadm-02                      1/1    Running  0          15m
kube-system  kube-apiserver-kubeadm-02            1/1    Running  0          16m
kube-system  kube-controller-manager-kubeadm-02  1/1    Running  0          15m
kube-system  kube-proxy-fx4cn                    1/1    Running  0          16m
kube-system  kube-scheduler-kubeadm-02            1/1    Running  0          15m
[root@kubeadm-02 ~]# kubectl taint nodes --all node-role.kubernetes.io/master-
node/kubeadm-02 untainted
```
## 添加新节点

要为群集添加工作节点，需要为每台计算机执行以下操作：
- SSH到机器
- 成为root用户，(如: sudo su -)
- 运行上面的`kubeadm init`命令输出的：`kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>`
- 如果我们忘记了Master节点的加入token，可以使用如下命令来查看：
```shell
kubeadm token list
# 输出
TOKEN TTL EXPIRES USAGES DESCRIPTION EXTRA GROUPS
6pkrlg.8glf2fqpuf3i489m 22h 2018-12-07T13:46:33Z authentication,signing The default bootstrap token generated by 'kubeadm init'. system:bootstrappers:kubeadm:default-node-token
```
默认情况下，token的有效期是24小时，如果我们的token已经过期的话，可以使用以下命令重新生成：
```shell
kubeadm token create
# 输出
u2mt59.tyqpo0v5wf05lx2q
```
如果我们也没有--discovery-token-ca-cert-hash的值，可以使用以下命令生成：
```shell
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
# 输出
eebfe256113bee397b218ba832f412273ae734bd4686241fb910885d26efd222
```
执行
```shell
[root@kubeadm-01 ~]# kubeadm join 172.20.0.23:6443 --token kl3k5j.zbasdjxnxg85bgsx --discovery-token-ca-cert-hash sha256:47daff7fc07dbcef390fe25c62fc3341ea1714e3303137f596864586314d350c
[preflight] Running pre-flight checks
[discovery] Trying to connect to API Server "172.20.0.23:6443"
[discovery] Created cluster-info discovery client, requesting info from "https://172.20.0.23:6443"
[discovery] Requesting info from "https://172.20.0.23:6443" again to validate TLS against the pinned public key
[discovery] Cluster info signature and contents are valid and TLS certificate validates against pinned roots, will use API Server "172.20.0.23:6443"
[discovery] Successfully established connection with API Server "172.20.0.23:6443"
[join] Reading configuration from the cluster...
[join] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[kubelet] Downloading configuration for the kubelet from the "kubelet-config-1.13" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Activating the kubelet service
[tlsbootstrap] Waiting for the kubelet to perform the TLS Bootstrap...
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "kubeadm-01" as an annotation

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the master to see this node join the cluster.

[root@kubeadm-02 ~]# kubectl get nodes
NAME        STATUS  ROLES    AGE    VERSION
kubeadm-01  Ready    <none>  19s    v1.13.1
kubeadm-02  Ready    master  4h45m  v1.13.1
```

## 集群删除
想要撤销kubeadm执行的操作，首先要排除节点，并确保该节点为空, 然后再将其关闭。
在Master节点上运行：
```
kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
kubectl delete node <node name>
```
然后在需要移除的节点上，重置kubeadm的安装状态：
```
sudo kubeadm reset
```
如果你想重新配置集群，使用新的参数重新运行`kubeadm init`或者`kubeadm join`即可。

## 错误排查
```shell
# 报错信息
    [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables contents are not set to 1
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
# 解决办法
echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables


```