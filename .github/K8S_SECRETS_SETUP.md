# Kubernetes Secrets 配置指南

本文档介绍如何配置 GitHub Actions 自动部署到 Kubernetes 所需的 secrets。

## 🔑 需要配置的 Secrets

在 GitHub 仓库中需要配置以下 secrets：

- `K8S_TOKEN` - Kubernetes 集群的 kubeconfig 文件（base64 编码）

## 📋 配置步骤

### 方法 1: 使用完整的 kubeconfig 文件（推荐）

#### 1. 获取 kubeconfig 文件

```bash
# 查看你的 kubeconfig 文件
cat ~/.kube/config

# 或者从 K8s 集群导出特定的配置
kubectl config view --minify --flatten
```

#### 2. Base64 编码 kubeconfig

```bash
# 对 kubeconfig 进行 base64 编码
cat ~/.kube/config | base64 | tr -d '\n'

# 或者使用完整命令
cat ~/.kube/config | base64 -w 0
```

复制输出的完整字符串。

#### 3. 在 GitHub 添加 Secret

1. 进入你的 GitHub 仓库
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**
4. 名称: `K8S_TOKEN`
5. 值: 粘贴刚才复制的 base64 编码的字符串
6. 点击 **Add secret**

### 方法 2: 使用 Server + Token 方式

如果你想使用单独的 K8s API Server 地址和 Token：

#### 1. 获取 K8s API Server 地址

```bash
# 查看 API Server 地址
kubectl cluster-info | grep 'Kubernetes control plane'

# 或者
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```

#### 2. 创建 ServiceAccount 和获取 Token

```bash
# 创建 ServiceAccount
kubectl create serviceaccount github-actions

# 创建 ClusterRoleBinding（给予部署权限）
kubectl create clusterrolebinding github-actions-deployer \
  --clusterrole=cluster-admin \
  --serviceaccount=default:github-actions

# 为 ServiceAccount 创建 Token（Kubernetes 1.24+）
kubectl create token github-actions --duration=87600h

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

#### 3. 在 GitHub 添加 Secrets

添加两个 secrets：

1. **K8S_SERVER**

   - 名称: `K8S_SERVER`
   - 值: K8s API Server 地址，如 `https://k8s.example.com:6443`

2. **K8S_TOKEN**
   - 名称: `K8S_TOKEN`
   - 值: ServiceAccount 的 Token

#### 4. 修改 workflow 配置

如果使用方法 2，需要在 `.github/workflows/docker-publish.yml` 中取消注释相关代码：

```yaml
- name: Configure kubectl
  run: |
    # 使用 server + token 方式
    kubectl config set-cluster k8s-cluster \
      --server=${{ secrets.K8S_SERVER }} \
      --insecure-skip-tls-verify=true
    kubectl config set-credentials github-actions \
      --token=${{ secrets.K8S_TOKEN }}
    kubectl config set-context default \
      --cluster=k8s-cluster \
      --user=github-actions
    kubectl config use-context default
```

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

### 测试 Secret 是否正确

```bash
# 1. 手动测试（本地）
echo "YOUR_BASE64_TOKEN" | base64 -d > /tmp/kubeconfig
export KUBECONFIG=/tmp/kubeconfig
kubectl get nodes

# 2. 测试权限
kubectl auth can-i update deployments
kubectl auth can-i get pods
```

### 测试 GitHub Actions

1. 创建一个测试 tag：

```bash
git tag v0.0.1-test
git push origin v0.0.1-test
```

2. 查看 GitHub Actions 运行情况：

   - 访问 `https://github.com/YOUR_USERNAME/thoughts/actions`
   - 查看 workflow 执行日志
   - 检查是否有错误

3. 删除测试 tag：

```bash
git tag -d v0.0.1-test
git push origin :refs/tags/v0.0.1-test
```

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
# 1. 开发和测试代码
git add .
git commit -m "feat: add new feature"
git push origin main

# 2. 创建版本 tag（触发部署）
git tag v1.0.0
git push origin v1.0.0

# 3. GitHub Actions 自动执行：
#    ✅ 构建 Docker 镜像
#    ✅ 推送到 ghcr.io
#    ✅ 部署到 Kubernetes（只针对 tag）
#    ✅ 验证部署状态

# 4. 检查部署
kubectl get pods -l app=ivy-thoughts
kubectl get deployment ivy-thoughts
```

现在你只需要打 tag，剩下的都会自动完成！🎉
