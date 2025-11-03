#!/bin/bash

# Hugo 博客项目设置脚本

set -e

echo "🚀 开始设置 Hugo 博客项目..."

# 检查 Hugo 是否安装
if ! command -v hugo &> /dev/null; then
    echo "❌ Hugo 未安装"
    echo "在 macOS 上安装: brew install hugo"
    echo "在 Linux 上安装: snap install hugo"
    exit 1
fi

echo "✅ Hugo 已安装: $(hugo version)"

# 初始化 git submodules
echo "📦 初始化主题..."
git submodule update --init --recursive

# 构建测试
echo "🏗️  测试构建..."
hugo --minify

echo ""
echo "✨ 设置完成！"
echo ""
echo "📝 快速开始:"
echo "  1. 创建新文章: hugo new posts/my-post.md"
echo "  2. 启动开发服务器: hugo server -D"
echo "  3. 访问: http://localhost:1313"
echo ""
echo "🐳 Docker 命令:"
echo "  - 开发环境: docker-compose up hugo-dev"
echo "  - 生产环境: docker-compose up hugo-prod"
echo "  - 构建镜像: docker build -t ivy-thoughts:latest ."
echo ""

