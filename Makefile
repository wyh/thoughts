.PHONY: help dev build docker-build docker-run docker-push clean

help: ## 显示帮助信息
	@echo "可用命令:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

dev: ## 启动本地开发服务器
	hugo server -D --bind 0.0.0.0

dev-docker: ## 使用 Docker 启动开发服务器
	docker-compose up hugo-dev

build: ## 构建静态网站
	hugo --minify --gc

docker-build: ## 构建 Docker 镜像
	docker build -t ivy-thoughts:latest .

docker-run: ## 运行 Docker 容器
	docker run -d -p 8080:80 --name thoughts ivy-thoughts:latest

docker-stop: ## 停止 Docker 容器
	docker stop thoughts && docker rm thoughts

docker-prod: ## 使用 Docker Compose 运行生产环境
	docker-compose up -d hugo-prod

docker-push: ## 推送镜像到 GitHub Container Registry (需要先登录)
	@echo "请确保已设置 GITHUB_USERNAME 环境变量"
	docker tag ivy-thoughts:latest ghcr.io/$(GITHUB_USERNAME)/ivy-thoughts:latest
	docker push ghcr.io/$(GITHUB_USERNAME)/ivy-thoughts:latest

new-post: ## 创建新文章 (使用: make new-post TITLE=my-post)
	hugo new posts/$(TITLE).md

clean: ## 清理生成的文件
	rm -rf public/ resources/_gen/

update-theme: ## 更新主题
	git submodule update --remote --merge

