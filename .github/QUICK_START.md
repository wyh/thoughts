# 快速开始：自动部署到 Kubernetes

## 🎯 一句话总结

打 tag 自动部署！配置 2 个 GitHub Secrets，剩下全自动。

## 🔑 需要配置的 Secrets

| Secret 名称  | 说明                       | 示例                           |
| ------------ | -------------------------- | ------------------------------ |
| `K8S_SERVER` | Kubernetes API Server 地址 | `https://k8s.example.com:6443` |
| `K8S_TOKEN`  | ServiceAccount Token       | `eyJhbGc...` (长字符串)        |

## ⚡ 5 分钟配置

### 1. 获取 K8s API Server 地址

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```

复制输出的地址。

### 2. 创建 ServiceAccount 并获取 Token

```bash
# 创建 ServiceAccount（在 ivy namespace）
kubectl create serviceaccount github-actions -n ivy

# 给予部署权限
kubectl create clusterrolebinding github-actions-deployer \
  --clusterrole=cluster-admin \
  --serviceaccount=ivy:github-actions

# 获取 Token（10 年有效期）
kubectl create token github-actions -n ivy --duration=87600h
```

复制输出的 Token。

### 3. 在 GitHub 添加 Secrets

访问: `https://github.com/YOUR_USERNAME/thoughts/settings/secrets/actions`

#### 添加 K8S_SERVER

- 点击 **New repository secret**
- Name: `K8S_SERVER`
- Value: 粘贴步骤 1 的 API Server 地址
- 点击 **Add secret**

#### 添加 K8S_TOKEN

- 点击 **New repository secret**
- Name: `K8S_TOKEN`
- Value: 粘贴步骤 2 的 Token
- 点击 **Add secret**

### 4. 完成！测试一下

```bash
# 创建测试 tag
git tag v0.0.1-test
git push origin v0.0.1-test

# 查看 GitHub Actions
# 访问: https://github.com/YOUR_USERNAME/thoughts/actions

# 验证部署
kubectl get pods -l app=ivy-thoughts -n ivy
```

## 🚀 日常使用

### 发布新版本

```bash
# 1. 提交代码
git add .
git commit -m "feat: awesome feature"
git push origin main

# 2. 打 tag（触发自动部署）
git tag v1.0.0
git push origin v1.0.0

# 3. 完成！GitHub Actions 会自动：
#    ✅ 构建镜像
#    ✅ 推送到 ghcr.io
#    ✅ 部署到 K8s
#    ✅ 验证部署状态
```

### 查看部署状态

```bash
# 在 GitHub 查看
# https://github.com/YOUR_USERNAME/thoughts/actions

# 在 K8s 查看（namespace: ivy）
kubectl get deployment ivy-thoughts -n ivy
kubectl get pods -l app=ivy-thoughts -n ivy
kubectl rollout status deployment/ivy-thoughts -n ivy
```

## 🔍 常见问题

### Q: Token 如何更新？

A: 重新生成 Token 并更新 GitHub Secret:

```bash
# 生成新 Token
kubectl create token github-actions --duration=87600h

# 在 GitHub 更新 K8S_TOKEN secret
```

### Q: 只想构建镜像，不想部署怎么办？

A: 推送到 main 分支即可，只有 **打 tag** 才会触发部署。

```bash
git push origin main        # ✅ 构建 + 推送，不部署
git push origin v1.0.0      # ✅ 构建 + 推送 + 部署
```

### Q: 部署失败了怎么办？

A: 查看 GitHub Actions 日志：

1. 访问 `https://github.com/YOUR_USERNAME/thoughts/actions`
2. 点击失败的 workflow
3. 查看 "Deploy to Kubernetes" 步骤的日志
4. 常见问题：
   - Token 过期或无效
   - API Server 地址不正确
   - ServiceAccount 权限不足

### Q: 需要更精细的权限控制？

A: 不要使用 `cluster-admin`，创建专门的 Role：

```bash
# 创建只有部署权限的 Role
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
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
subjects:
- kind: ServiceAccount
  name: github-actions
  namespace: default
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
EOF
```

## 📚 更多文档

- [详细配置指南](K8S_SECRETS_SETUP.md)
- [发布和部署指南](../RELEASE_GUIDE.md)
- [Kubernetes 部署文档](../k8s/README.md)

## 🎉 就是这么简单！

配置一次，终身受益。从此发布新版本只需要：

```bash
git tag v1.0.0 && git push origin v1.0.0
```

剩下的全自动！🚀
