# Ceph存储快速入门

本指南将引导您完成Ceph集群的基本设置，并使您能够从群集中运行的其他pod中使用块，对象和文件存储。

## K8S最低版本

Rook支持Kubernetes v1.8或更高版本。

## 先决条件

要确保您已准备好Kubernetes群集，Rook可以按照这些说明进行操作。
如果您使用`dataDirHostPath`在kubernetes主机上放置rook数据，请确保您的主机在指定路径上至少有5GB可用空间。

## 快速启动

如果您感觉幸运，可以使用以下kubectl命令创建一个简单的Rook集群。有关更详细的安装，请跳至下一部分以部署Rook运算符。

```shell
kubectl apply -f operator.yaml
kubectl apply -f cluster.yaml
kubectl apply -f dashboard-external-https.yaml

# admin/password
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

群集运行后，您可以创建块存储，对象存储或文件存储以供群集中的其他应用程序使用。

### 部署Rook Operator

第一步是部署Rook系统组件，其中包括在群集中每个节点上运行的Rook代理以及Rook Operator pod。

```shell
kubectl create -f operator.yaml

# verify the rook-ceph-operator, rook-ceph-agent, and rook-discover pods are in the `Running` state before proceeding
kubectl -n rook-ceph-system get pod
```

也还可以使用`Rook Helm Chart`部署。

### 创建一个Rook集群

现在Rook Operator，代理和发现pod正在运行，我们可以创建Rook集群。要使群集在重新启动后继续存在，请确保设置对dataDirHostPath主机有效的属性。有关更多设置，请参阅有关配置群集的文档。

```shell
kubectl create -f cluster.yaml

kubectl -n rook-ceph get pod
NAME                                   READY     STATUS      RESTARTS   AGE
rook-ceph-mgr-a-9c44495df-ln9sq        1/1       Running     0          1m
rook-ceph-mon-a-69fb9c78cd-58szd       1/1       Running     0          2m
rook-ceph-mon-b-cf4ddc49c-c756f        1/1       Running     0          2m
rook-ceph-mon-c-5b467747f4-8cbmv       1/1       Running     0          2m
rook-ceph-osd-0-f6549956d-6z294        1/1       Running     0          1m
rook-ceph-osd-1-5b96b56684-r7zsp       1/1       Running     0          1m
rook-ceph-osd-prepare-mynode-ftt57     0/1       Completed   0          1m
```

## 存储

### 块存储

### 对象存储

### 文件存储

## Ceph Dashboard

Ceph有一个仪表板，您可以在其中查看群集的状态。有关详细信息，请参阅仪表板指南。

## 工具

我们创建了一个工具箱容器，其中包含用于调试和排除Rook集群故障的全套Ceph客户端。有关设置和使用信息，请参阅工具箱自述文件。另请参阅我们的高级配置文档以获取有用的维护和调整示例

## 监控

每个Rook集群都有一些内置的指标收集器/导出器，用于监控Prometheus。要了解如何为Rook群集设置监视，可以按照监视指南中的步骤进行操作。

## 卸载

完成测试群集后，请参阅这些说明以清理群集。
