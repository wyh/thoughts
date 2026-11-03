# Kubernetes Secrets 配置指南

本文档介绍如何配置 GitHub Actions 自动部署到 Kubernetes 所需的 secrets。

## 🔑 需要配置的 Secrets

在 GitHub 仓库中需要配置以下 secrets：

- `K8S_SERVER` - Kubernetes API Server 地址（如 `https://k8s.example.com:6443`）
- `K8S_TOKEN` - ServiceAccount 的访问 Token

## 📋 配置步骤（Server + Token 方式）⭐ 推荐

### 1. 获取 K8s API Server 地址

```bash
# 查看 API Server 地址
kubectl cluster-info | grep 'Kubernetes control plane'

# 或者
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```

### 2. 创建 ServiceAccount 和获取 Token

```bash
# 创建 ServiceAccount（在 ivy namespace）
kubectl create serviceaccount github-actions -n ivy

# 创建 ClusterRoleBinding（给予部署权限）
kubectl create clusterrolebinding github-actions-deployer \
  --clusterrole=cluster-admin \
  --serviceaccount=ivy:github-actions

# 为 ServiceAccount 创建 Token（Kubernetes 1.24+）
kubectl create token github-actions -n ivy --duration=87600h

# 或者创建永久 Secret（Kubernetes < 1.24）
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: github-actions-token
  annotations:
    kubernetes.io/service-account.name: github-actions
type: kubernetes.io/service-account-token
EOF

# 获取 Token
kubectl get secret github-actions-token -o jsonpath='{.data.token}' | base64 -d
```

### 3. 在 GitHub 添加 Secrets

添加两个 secrets：

#### 添加 K8S_SERVER

1. 进入你的 GitHub 仓库
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**
4. 名称: `K8S_SERVER`
5. 值: 你的 K8s API Server 地址，例如 `https://k8s.example.com:6443`
6. 点击 **Add secret**

#### 添加 K8S_TOKEN

1. 点击 **New repository secret**
2. 名称: `K8S_TOKEN`
3. 值: 粘贴上面获取的 ServiceAccount Token（**不需要** base64 编码）
4. 点击 **Add secret**

### 4. 完成！

配置完成后，workflow 会自动使用这两个 secrets 连接到你的 K8s 集群。

---

## 📝 替代方法：使用完整的 kubeconfig 文件

如果你更喜欢使用完整的 kubeconfig 文件，可以使用以下方式：

<details>
<summary>点击展开查看 kubeconfig 方式配置</summary>

### 获取并配置 kubeconfig

```bash
# 1. 查看你的 kubeconfig 文件
cat ~/.kube/config

# 2. Base64 编码
cat ~/.kube/config | base64 -w 0
```

### 在 GitHub 添加 Secret

- 名称: `K8S_CONFIG`
- 值: base64 编码后的 kubeconfig

### 修改 workflow

需要修改 `.github/workflows/docker-publish.yml` 中的配置步骤：

```yaml
- name: Configure kubectl
  run: |
    mkdir -p $HOME/.kube
    echo "${{ secrets.K8S_CONFIG }}" | base64 -d > $HOME/.kube/config
    chmod 600 $HOME/.kube/config
```

</details>

## 🔒 安全建议

### 1. 使用最小权限原则

不要给 ServiceAccount `cluster-admin` 权限，而是创建特定的 Role：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
  namespace: default
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: github-actions-deployment
  namespace: default
subjects:
  - kind: ServiceAccount
    name: github-actions
    namespace: default
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
```

### 2. 限制 Token 有效期

```bash
# 创建有效期为 30 天的 Token
kubectl create token github-actions --duration=720h
```

### 3. 使用命名空间隔离

```bash
# 只给特定命名空间的权限
kubectl create namespace production
kubectl create serviceaccount github-actions -n production
kubectl create rolebinding github-actions-deployer \
  --role=deployment-manager \
  --serviceaccount=production:github-actions \
  -n production
```

### 4. 定期轮换 Token

建议每 3-6 个月更换一次 Token。

## ✅ 验证配置

### 测试配置是否正确

```bash
# 1. 手动测试连接
kubectl config set-cluster test-cluster \
  --server=YOUR_K8S_SERVER \
  --insecure-skip-tls-verify=true

kubectl config set-credentials test-user \
  --token=YOUR_K8S_TOKEN

kubectl config set-context test-context \
  --cluster=test-cluster \
  --user=test-user

kubectl config use-context test-context

# 2. 测试连接
kubectl get nodes

# 3. 测试权限
kubectl auth can-i update deployments
kubectl auth can-i get pods -l app=ivy-thoughts
```

### 测试 GitHub Actions

1. 推送到 main：

```bash
git push origin main
```

2. 查看 GitHub Actions 运行情况：

   - 访问 `https://github.com/YOUR_USERNAME/thoughts/actions`
   - 查看 workflow 执行日志
   - 检查是否有错误

## 🔧 故障排查

### 问题 1: kubectl 连接失败

```bash
# 错误: Unable to connect to the server

# 解决方案:
# 1. 检查 K8S_SERVER 地址是否正确
# 2. 确保网络可达
# 3. 检查 token 是否有效
```

### 问题 2: 权限不足

```bash
# 错误: forbidden: User "system:serviceaccount:default:github-actions" cannot update resource "deployments"

# 解决方案:
# 检查 ServiceAccount 的 RBAC 权限
kubectl describe serviceaccount github-actions
kubectl describe rolebinding github-actions-deployer
```

### 问题 3: Base64 解码失败

```bash
# 错误: illegal base64 data

# 解决方案:
# 确保 base64 编码时使用 -w 0 参数去掉换行符
cat ~/.kube/config | base64 -w 0
```

## 📚 相关文档

- [GitHub Actions Secrets 文档](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Kubernetes RBAC 文档](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [kubectl 配置文档](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)

## 🎯 完整部署流程

配置完成后，完整的部署流程是：

```bash
# 1. 提交并推送到 main（触发构建和部署）
git add .
git commit -m "feat: add new feature"
git push origin main

# 2. GitHub Actions 自动执行：
#    ✅ 构建 Docker 镜像
#    ✅ 推送到 ghcr.io（latest 和本次 commit SHA）
#    ✅ 部署到 Kubernetes
#    ✅ 验证部署状态

# 3. 检查部署
kubectl get pods -l app=ivy-thoughts
kubectl get deployment ivy-thoughts
```

现在你只需要推送到 main，剩下的都会自动完成！🎉
