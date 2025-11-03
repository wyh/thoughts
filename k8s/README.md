# Kubernetes 部署指南

本文档介绍如何在 Kubernetes 集群中部署 Hugo Thoughts 博客。

## 架构说明

- **容器内部端口**: Nginx 监听 80 端口
- **Service**: ClusterIP 类型，在集群内暴露服务
- **访问方式**:
  - 集群内：通过 Service 名称 `ivy-thoughts` 访问
  - 公网：通过 Cloudflare Tunnel 访问（推荐）

## 前置条件

1. 已有 Kubernetes 集群
2. 已配置 `kubectl` 并能访问集群
3. Docker 镜像已推送到 GitHub Container Registry

## 配置步骤

### 1. 选择部署环境

项目提供两个部署配置：

- **`deployment.yaml`** - 开发/测试环境，使用 `latest` tag，自动更新
- **`deployment-prod.yaml`** - 生产环境，使用固定版本号，稳定可控

### 2. 调整资源限制（可选）

根据实际需求修改 `k8s/deployment.yaml` 中的资源配置：

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

## 部署方法

### 方法 1: 使用 kubectl 直接部署

```bash
# 开发环境（使用 latest tag）
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# 生产环境（使用固定版本）
kubectl apply -f k8s/deployment-prod.yaml
kubectl apply -f k8s/service.yaml

# 查看部署状态
kubectl get pods -l app=ivy-thoughts
kubectl get svc ivy-thoughts
```

### 方法 2: 使用 Kustomize 部署

```bash
# 部署
kubectl apply -k k8s/

# 查看资源
kubectl get all -l project=ivy-thoughts
```

## 访问服务

### 集群内访问

在集群内的 Pod 中，可以通过 Service 名称访问：

```bash
# 通过 Service 名称访问
curl http://ivy-thoughts

# 通过完整域名访问
curl http://ivy-thoughts.default.svc.cluster.local
```

### 通过 Cloudflare Tunnel 访问

使用 Cloudflare Tunnel 可以安全地将服务暴露到公网，详见下面的"Cloudflare Tunnel 配置"部分。

### 端口转发（临时测试）

```bash
# 转发到本地
kubectl port-forward svc/ivy-thoughts 8080:80

# 访问
curl http://localhost:8080
```

## 更新部署

### 更新镜像

```bash
# 方法 1: 修改 deployment.yaml 后重新应用
kubectl apply -f k8s/deployment.yaml

# 方法 2: 直接设置新镜像
kubectl set image deployment/ivy-thoughts \
  ivy-thoughts=ghcr.io/<your-username>/ivy-thoughts:v2.0.0

# 查看滚动更新状态
kubectl rollout status deployment/ivy-thoughts
```

### 回滚

```bash
# 查看历史版本
kubectl rollout history deployment/ivy-thoughts

# 回滚到上一个版本
kubectl rollout undo deployment/ivy-thoughts

# 回滚到指定版本
kubectl rollout undo deployment/ivy-thoughts --to-revision=2
```

## 扩缩容

```bash
# 手动扩容
kubectl scale deployment/ivy-thoughts --replicas=3

# 查看副本状态
kubectl get pods -l app=ivy-thoughts
```

## 监控和日志

### 查看 Pod 状态

```bash
# 查看 Pods
kubectl get pods -l app=ivy-thoughts

# 查看详细信息
kubectl describe pod <pod-name>
```

### 查看日志

```bash
# 查看某个 Pod 的日志
kubectl logs <pod-name>

# 实时查看日志
kubectl logs -f <pod-name>

# 查看所有副本的日志
kubectl logs -l app=ivy-thoughts --all-containers=true
```

### 进入容器

```bash
kubectl exec -it <pod-name> -- /bin/sh
```

## 健康检查

部署包含了健康检查配置：

- **Liveness Probe**: 检查容器是否存活，失败会重启容器
- **Readiness Probe**: 检查容器是否就绪，未就绪不会接收流量

## 删除部署

```bash
# 删除所有资源
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/ingress.yaml

# 或使用 Kustomize
kubectl delete -k k8s/
```

## Cloudflare Tunnel 配置

Cloudflare Tunnel 可以安全地将 K8s 集群内的服务暴露到互联网，无需公网 IP 或复杂的网络配置。

### 前置条件

1. 拥有 Cloudflare 账号
2. 域名已添加到 Cloudflare
3. 安装 `cloudflared` CLI（用于创建 tunnel）

### 创建 Cloudflare Tunnel

```bash
# 1. 登录 Cloudflare
cloudflared tunnel login

# 2. 创建 tunnel
cloudflared tunnel create ivy-thoughts

# 3. 记录输出的 Tunnel ID 和凭证文件路径
# 凭证文件通常在: ~/.cloudflared/<tunnel-id>.json
```

### 配置 DNS

在 Cloudflare 控制台中添加 DNS 记录：

```bash
# 使用 CLI 添加 DNS 记录
cloudflared tunnel route dns ivy-thoughts ivy-thoughts.ivy

# 或在 Cloudflare Dashboard 手动添加 CNAME 记录：
# 名称: ivy-thoughts
# 目标: <tunnel-id>.cfargotunnel.com
```

### 部署到 Kubernetes

1. **创建 Secret（存储 Cloudflare 凭证）**：

```bash
# 从本地凭证文件创建 Secret
kubectl create secret generic cloudflared-credentials \
  --from-file=credentials.json=$HOME/.cloudflared/<tunnel-id>.json
```

2. **修改 `cloudflare-tunnel.yaml` 中的配置**：

```yaml
# 更新 ConfigMap 中的配置
data:
  config.yaml: |
    tunnel: <your-tunnel-id>  # 替换为你的 Tunnel ID
    credentials-file: /etc/cloudflared/creds/credentials.json

    ingress:
      - hostname: ivy-thoughts.ivy  # 替换为你的域名
        service: http://ivy-thoughts.default.svc.cluster.local:80
      - service: http_status:404
```

3. **部署 Cloudflared**：

```bash
# 部署 cloudflared
kubectl apply -f k8s/cloudflare-tunnel.yaml

# 查看状态
kubectl get pods -l app=cloudflared
kubectl logs -l app=cloudflared
```

### 验证访问

```bash
# 通过域名访问
curl https://ivy-thoughts.ivy

# 或在浏览器中打开
# https://ivy-thoughts.ivy
```

### Cloudflare Tunnel 优势

✅ **安全**: 无需暴露公网 IP，所有流量通过 Cloudflare 加密传输  
✅ **简单**: 不需要配置 Ingress Controller 或 LoadBalancer  
✅ **免费 SSL/TLS**: Cloudflare 自动提供 HTTPS  
✅ **DDoS 防护**: 自动获得 Cloudflare 的 DDoS 防护  
✅ **CDN 加速**: 静态资源自动通过 Cloudflare CDN 加速

## 故障排查

### Pod 无法启动

```bash
# 查看 Pod 事件
kubectl describe pod <pod-name>

# 查看日志
kubectl logs <pod-name>
```

### 无法访问服务

```bash
# 检查 Service
kubectl get svc ivy-thoughts
kubectl describe svc ivy-thoughts

# 检查 Endpoints
kubectl get endpoints ivy-thoughts

# 测试集群内访问
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- http://ivy-thoughts
```

### Cloudflare Tunnel 不工作

```bash
# 检查 cloudflared Pods
kubectl get pods -l app=cloudflared
kubectl describe pod -l app=cloudflared

# 查看 cloudflared 日志
kubectl logs -l app=cloudflared

# 检查配置
kubectl get configmap cloudflared-config -o yaml
kubectl get secret cloudflared-credentials

# 常见问题：
# 1. Tunnel ID 或凭证不正确
# 2. Service 名称或命名空间不匹配
# 3. DNS 记录未正确配置
```

## 配置示例

### 使用 ConfigMap 自定义 Nginx 配置

如果需要自定义 Nginx 配置，可以使用 ConfigMap：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ivy-thoughts-nginx-config
data:
  default.conf: |
    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files $uri $uri/ $uri.html =404;
        }
    }
---
# 在 Deployment 中挂载
spec:
  template:
    spec:
      containers:
        - name: ivy-thoughts
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf
      volumes:
        - name: nginx-config
          configMap:
            name: ivy-thoughts-nginx-config
```

## 参考资料

- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [kubectl 备忘单](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Cloudflare Tunnel 文档](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflared GitHub](https://github.com/cloudflare/cloudflared)
