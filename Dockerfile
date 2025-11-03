# 多阶段构建 Dockerfile
# 第一阶段：构建 Hugo 静态网站
FROM hugomods/hugo:latest AS builder

# 设置工作目录
WORKDIR /src

# 复制整个项目到容器中
COPY . .

# 构建静态网站
RUN hugo --minify --gc

# 第二阶段：使用 Nginx 服务静态文件
FROM nginx:alpine

# 从构建阶段复制生成的静态文件到 Nginx 的默认目录
COPY --from=builder /src/public /usr/share/nginx/html

# 复制自定义 Nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Nginx 在容器内监听 80 端口
# 在 Kubernetes 环境中，通过 Service 来暴露端口
# 在 Docker 直接运行时，使用 -p 参数映射端口
EXPOSE 80

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]

