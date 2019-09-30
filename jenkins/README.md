# k8s集成jenkins

## yaml文件列表

- 挂载nfs
- 部署有状态的jenkins
- 配置jenkins的在k8s上的account
  
### 安装

```bash
kubectl -n ops apply -f 01jenkins-nfs.yml
kubectl -n ops apply -f 02jenkins.yml
kubectl -n ops apply -f 03service-account.yml
```

## 后续配置

### DNS

DNS解析到Ingress出口

### Jenkins配置

插件安装 kubernetes pipeline等，在[jenkins配置](http://jenkins.hashquark-dev.net/configure)上配置以下内容

- Jenkins Location
  - Jenkins URL： http://jenkins.hashquark-dev.net/

- 云
  - 新增一个云 Kubernetes
  - 名称：kubernetes
  - Kubernetes 地址：https://kubernetes.default （内网service地址）
  - 其余不用填，连接测试成功

### Jenkins Slave配置
