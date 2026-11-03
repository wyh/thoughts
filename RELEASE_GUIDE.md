# 发布和部署指南

本文档介绍如何发布新版本并部署到 Kubernetes 集群。

## 📦 镜像 Tag 策略

推送到 `main` 时，GitHub Actions 会构建镜像并打上这些 tag：

| 操作               | 生成的 Tags              | 说明                         |
| ------------------ | ------------------------ | ---------------------------- |
| 推送到 `main` 分支 | `latest`、`main`、commit SHA | 构建、推送，并部署到 Kubernetes |
| 创建 PR            | `pr-123`                 | 只构建，不推送、不部署       |

## ⚙️ 自动部署配置（可选）

推送到 `main` 会自动部署到 Kubernetes。先配置 GitHub Secrets：

📖 **详细配置步骤：** [.github/K8S_SECRETS_SETUP.md](../.github/K8S_SECRETS_SETUP.md)

**快速配置：**

```bash
# 1. 获取 K8s API Server 地址
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

# 2. 创建 ServiceAccount 并获取 Token（在 ivy namespace）
kubectl create serviceaccount github-actions -n ivy
kubectl create clusterrolebinding github-actions-deployer \
  --clusterrole=cluster-admin \
  --serviceaccount=ivy:github-actions

# 获取 Token（Kubernetes 1.24+）
kubectl create token github-actions -n ivy --duration=87600h

# 3. 在 GitHub 仓库添加两个 Secrets
# Settings → Secrets and variables → Actions
# - K8S_SERVER: API Server 地址（如 https://k8s.example.com:6443）
# - K8S_TOKEN: 上面获取的 Token
```

配置完成后，推送到 `main` 即可自动部署。

## 🚀 发布流程

推送到 `main` 即发布。GitHub Actions 会构建镜像、推送到 ghcr.io，并用本次 commit SHA 滚动更新 Kubernetes。

```bash
# 1. 提交并推送到 main
git add .
git commit -m "feat: add new feature"
git push origin main

# 2. GitHub Actions 自动执行：
#    ✅ 构建 Docker 镜像
#    ✅ 推送 latest、main 和本次 commit SHA
#    ✅ 用 commit SHA 部署到 Kubernetes
#    ✅ 等待滚动更新完成

# 3. 查看进度
# https://github.com/wyh/thoughts/actions

# 4. 验证部署
kubectl get pods -l app=ivy-thoughts
kubectl describe deployment ivy-thoughts
```

如果还没有配置 Kubernetes 自动部署，请参考 [Kubernetes Secrets 配置指南](.github/K8S_SECRETS_SETUP.md)。配置完成后，只需要 `git push origin main`。

## 🎯 部署环境配置

### 开发环境 (development.yaml)

```yaml
image: ghcr.io/wyh/ivy-thoughts:latest
imagePullPolicy: Always # 每次都拉取最新
replicas: 1 # 单副本
resources:
  requests:
    memory: "32Mi"
    cpu: "50m"
```

### 生产环境 (deployment-prod.yaml)

```yaml
image: ghcr.io/wyh/ivy-thoughts:1.0.0 # 固定版本
imagePullPolicy: IfNotPresent # 使用缓存
replicas: 2 # 多副本
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
```

## 🔄 更新和回滚

### 更新到新版本

```bash
# 方法 1: 使用 kubectl set image
kubectl set image deployment/ivy-thoughts \
  ivy-thoughts=ghcr.io/wyh/ivy-thoughts:1.1.0

# 方法 2: 修改 YAML 后应用
# 编辑 k8s/deployment-prod.yaml，修改 image 版本
kubectl apply -f k8s/deployment-prod.yaml

# 方法 3: 使用 kubectl patch
kubectl patch deployment ivy-thoughts \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"ivy-thoughts","image":"ghcr.io/wyh/ivy-thoughts:1.1.0"}]}}}}'
```

### 回滚到上一个版本

```bash
# 查看部署历史
kubectl rollout history deployment/ivy-thoughts

# 回滚到上一个版本
kubectl rollout undo deployment/ivy-thoughts

# 回滚到指定版本
kubectl rollout undo deployment/ivy-thoughts --to-revision=2
```

### 验证部署

```bash
# 查看 Pods 状态
kubectl get pods -l app=ivy-thoughts

# 查看当前使用的镜像版本
kubectl get deployment ivy-thoughts -o jsonpath='{.spec.template.spec.containers[0].image}'

# 查看部署详情
kubectl describe deployment ivy-thoughts

# 查看 Pod 日志
kubectl logs -l app=ivy-thoughts --tail=50

# 测试访问
kubectl port-forward svc/ivy-thoughts 8080:80
curl http://localhost:8080
```

## 📋 发布检查清单

### 发布前

- [ ] 代码已合并到 main 分支
- [ ] 所有测试通过
- [ ] 更新了 CHANGELOG（如果有）

### 发布中

- [ ] 已推送到 main
- [ ] GitHub Actions 构建成功
- [ ] 镜像已推送到 ghcr.io
- [ ] Kubernetes 滚动更新完成

### 发布后

- [ ] 更新 K8s 部署配置
- [ ] 验证新版本正常运行
- [ ] 检查服务健康状态
- [ ] 监控日志无异常
- [ ] 测试主要功能

## 🔍 查看镜像信息

### 在 GitHub 查看

1. 访问仓库页面
2. 点击右侧 **"Packages"**
3. 查看 `ivy-thoughts` package
4. 查看所有 tags 和版本

### 使用 Docker CLI

```bash
# 拉取镜像
docker pull ghcr.io/wyh/ivy-thoughts:latest

# 查看本地镜像
docker images | grep ivy-thoughts

# 查看镜像详情
docker inspect ghcr.io/wyh/ivy-thoughts:1.0.0
```

## 🐛 故障排查

### 镜像拉取失败

```bash
# 检查镜像是否存在
docker pull ghcr.io/wyh/ivy-thoughts:1.0.0

# 检查 K8s 权限
kubectl get secret | grep github

# 创建 GitHub Container Registry 认证（如果需要）
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=wyh \
  --docker-password=<YOUR_GITHUB_TOKEN> \
  --docker-email=your-email@example.com

# 在 deployment 中使用 secret
spec:
  imagePullSecrets:
  - name: ghcr-secret
```

### Pod 无法启动

```bash
# 查看 Pod 事件
kubectl describe pod <pod-name>

# 查看日志
kubectl logs <pod-name>

# 检查镜像拉取状态
kubectl get events --sort-by='.lastTimestamp' | grep ivy-thoughts
```

## 📚 相关资源

- [Semantic Versioning 规范](https://semver.org/)
- [GitHub Container Registry 文档](https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Kubernetes Deployment 文档](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

## 快速命令参考

```bash
# 推送到 main 即发布
git push origin main

# 手动把 K8s 指到某次提交（一般不需要，workflow 会做）
kubectl set image deployment/ivy-thoughts ivy-thoughts=ghcr.io/wyh/ivy-thoughts:<commit-sha>

# 查看当前版本
kubectl get deployment ivy-thoughts -o jsonpath='{.spec.template.spec.containers[0].image}'

# 回滚
kubectl rollout undo deployment/ivy-thoughts

# 重启（使用 latest tag 时）
kubectl rollout restart deployment/ivy-thoughts
```
