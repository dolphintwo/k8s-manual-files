## 1.场景
我们在实际生产中可能会有多个kubernetes集群，我们可能需要早一台机器访问多个集群。

## 2.生成融合配置文件
本例演示两个集群的配置文件(config)文件，在控制台执行命令:

KUBECONFIG=第一个配置文件:第二个配置文件 kubectl config view --flatten
这时控制台会输出融合后的配置内容，复制配置内容覆盖原有的$HOME/.kube/config.

## 3.连接
查看集群信息:
```yaml
kubectl config view
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:6443
  name: docker-for-desktop-cluster
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://152.32.130.135:6443
  name: kubernetes-152.135
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://172.20.0.23:6443
  name: kubernetes-172.23
contexts:
- context:
    cluster: docker-for-desktop-cluster
    user: docker-for-desktop
  name: docker-for-desktop
- context:
    cluster: kubernetes-152.135
    user: admin
  name: kubernetes-152.135
- context:
    cluster: kubernetes-172.23
    user: kubernetes-admin
  name: kubernetes-172.23
current-context: docker-for-desktop
kind: Config
preferences: {}
users:
- name: docker-for-desktop
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```

本例的两个集群的名字分别为`docker-for-desktop-cluster`,`kubernetes-152.135`,`kubernetes-172.23`

连接集群:
```shell
kubectl --context kubernetes-152.135 get nodes
```
此处的`kubernetes-152.135`为`config`文件中`contexts.context.name`属性,可从`kubectl config view`命令中看到.

## 4.设置默认

查看当前默认集群:
`kubectl config current-context`

修改当前默认集群:
`kubectl config use-context kubernetes-172.23`