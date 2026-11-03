# Thoughts

Thoughts on Software Engineering, Science and Life

这是一个基于 Hugo 构建的个人博客，使用 Docker 进行部署。

## 功能特性

- 🚀 使用 Hugo 静态网站生成器
- 🎨 采用 PaperMod 主题
- 🐳 Docker 容器化部署
- 🔄 GitHub Actions 自动构建和发布
- 📦 支持推送到 GitHub Container Registry

## 快速开始

### 本地开发

#### 方法 1: 使用 Docker Compose (推荐)

```bash
# 启动开发服务器
docker-compose up hugo-dev

# 访问 http://localhost:1313
```

#### 方法 2: 直接使用 Hugo

```bash
# 确保已安装 Hugo
hugo version

# 启动开发服务器
hugo server -D

# 访问 http://localhost:1313
```

### 创建新文章

```bash
# 创建新文章
hugo new posts/my-first-post.md

# 使用 Makefile
make new-post TITLE=my-first-post

# 编辑 content/posts/my-first-post.md
```

**📖 详细的写作指南请查看 [WRITING_GUIDE.md](WRITING_GUIDE.md)**

### 构建静态网站

```bash
# 构建生产环境的静态文件
hugo --minify

# 输出将在 public/ 目录中
```

## Docker 部署

### 本地构建和运行

```bash
# 构建 Docker 镜像
docker build -t ivy-thoughts:latest .

# 运行容器
docker run -d -p 8080:80 --name thoughts ivy-thoughts:latest

# 访问 http://localhost:8080
```

### 使用 Docker Compose

```bash
# 构建并运行生产环境容器
docker-compose up hugo-prod

# 后台运行
docker-compose up -d hugo-prod

# 停止容器
docker-compose down
```

## GitHub Container Registry

### 自动构建和发布

**推送到 main 分支：**

1. ✅ 构建 Docker 镜像
2. ✅ 推送到 GitHub Container Registry（`latest` 和本次 commit SHA）
3. ✅ **自动部署到 Kubernetes**（需要配置 K8S_SERVER 和 K8S_TOKEN）
4. 镜像地址: `ghcr.io/<your-username>/ivy-thoughts:latest`

**Pull Request：** 只构建镜像，不推送、不部署。

📖 配置自动部署：

- **快速开始（5 分钟）**: [.github/QUICK_START.md](.github/QUICK_START.md) ⭐
- 详细配置指南: [.github/K8S_SECRETS_SETUP.md](.github/K8S_SECRETS_SETUP.md)

### 手动推送

```bash
# 登录 GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 标记镜像
docker tag ivy-thoughts:latest ghcr.io/<your-username>/ivy-thoughts:latest

# 推送镜像
docker push ghcr.io/<your-username>/ivy-thoughts:latest
```

### 拉取和运行

```bash
# 拉取镜像
docker pull ghcr.io/<your-username>/ivy-thoughts:latest

# 运行容器
docker run -d -p 8080:80 ghcr.io/<your-username>/ivy-thoughts:latest
```

## Kubernetes 部署

### 快速部署

```bash
# 修改 k8s/deployment.yaml 中的镜像地址
# 然后部署到 K8s 集群
kubectl apply -k k8s/

# 查看部署状态
kubectl get pods -l app=ivy-thoughts -n ivy
```

### 通过 Service 访问

服务会通过 ClusterIP 在集群内暴露：

```bash
# 集群内访问
curl http://ivy-thoughts.ivy.svc.cluster.local

# 通过 Cloudflare Tunnel 访问（推荐）
# 配置 Cloudflare Tunnel 后，可通过自定义域名访问
# 例如: https://ivy-thoughts.ivy
```

**📖 详细的部署文档：**

- [Kubernetes 部署指南](k8s/README.md)
- [发布和更新指南](RELEASE_GUIDE.md)

## 项目结构

```
.
├── .github/
│   ├── workflows/
│   │   └── docker-publish.yml  # GitHub Actions 工作流（构建+部署）
│   ├── QUICK_START.md          # 快速开始（5 分钟配置）
│   └── K8S_SECRETS_SETUP.md    # K8s 详细配置指南
├── archetypes/                 # 文章模板
├── content/                    # 博客内容
│   └── posts/                  # 文章目录
├── k8s/                        # Kubernetes 部署配置
│   ├── deployment.yaml         # K8s Deployment
│   ├── service.yaml            # K8s Service
│   ├── kustomization.yaml      # Kustomize 配置
│   └── README.md               # K8s 部署文档
├── scripts/                    # 工具脚本
│   └── setup.sh                # 项目设置脚本
├── themes/                     # Hugo 主题
│   └── PaperMod/              # PaperMod 主题
├── .dockerignore              # Docker 忽略文件
├── .gitignore                  # Git 忽略文件
├── Dockerfile                  # Docker 构建文件
├── docker-compose.yml         # Docker Compose 配置
├── hugo.toml                   # Hugo 配置文件
├── Makefile                    # 常用命令
├── nginx.conf                  # Nginx 配置
├── README.md                   # 项目说明
├── RELEASE_GUIDE.md           # 发布和部署指南
└── WRITING_GUIDE.md           # 写作指南
```

## 配置

主要配置文件是 `hugo.toml`，你可以修改：

- `baseURL`: 你的网站地址
- `title`: 网站标题
- `params`: 主题参数
- `menu`: 导航菜单

## 主题定制

PaperMod 主题支持丰富的定制选项，详见：

- [PaperMod 文档](https://github.com/adityatelange/hugo-PaperMod)
- [Hugo 文档](https://gohugo.io/documentation/)

## 常用命令

```bash
# 创建新文章
hugo new posts/my-post.md

# 本地预览（包含草稿）
hugo server -D

# 构建生产版本
hugo --minify

# 清理生成的文件
rm -rf public/ resources/

# 更新主题
git submodule update --remote --merge
```

## 故障排查

### 主题未找到

```bash
# 初始化并更新子模块
git submodule update --init --recursive
```

### Docker 构建失败

```bash
# 清理 Docker 缓存
docker builder prune

# 重新构建
docker build --no-cache -t ivy-thoughts:latest .
```

## 许可证

本项目采用 MIT 许可证。

## 贡献

欢迎提交 Issue 和 Pull Request！
