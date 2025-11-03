# 写作指南

本文档介绍如何在这个 Hugo 博客中创建和编写文章。

## 创建新文章

```bash
# 方法 1: 使用 Hugo 命令
hugo new posts/my-article.md

# 方法 2: 使用 Makefile
make new-post TITLE=my-article
```

## 文章结构

### Front Matter（文章元数据）

每篇文章开头必须包含 Front Matter，使用 `+++` 包围：

```toml
+++
date = '2025-11-03T12:00:00+08:00'
draft = false                    # true=草稿, false=发布
title = '文章标题'
tags = ['标签1', '标签2']       # 文章标签
categories = ['分类']            # 文章分类
summary = '这是文章摘要，显示在列表页'  # 重要！控制列表显示
+++
```

### 摘要控制

**重要提示**：为了让文章列表显示正确的摘要，有两种方法：

#### 方法 1：使用 `summary` 字段（推荐）

在 Front Matter 中添加 `summary` 字段：

```toml
+++
...
summary = '简短的文章摘要，一两句话概括文章内容'
+++
```

#### 方法 2：使用 `<!--more-->` 分隔符

在文章中使用 `<!--more-->` 标记摘要结束位置：

```markdown
+++
title = '文章标题'
+++

这是文章的引言部分，会作为摘要显示。

<!--more-->

## 正文

这里开始是正文内容，不会在摘要中显示...
```

#### 推荐做法：两者结合

```markdown
+++
title = '文章标题'
summary = '精心编写的摘要'
+++

文章开头的引言...

<!--more-->

## 正文标题

正文内容...
```

## Markdown 语法

### 标题

```markdown
# 一级标题

## 二级标题

### 三级标题
```

### 文本格式

```markdown
**粗体**
_斜体_
~~删除线~~
`代码`
```

### 列表

```markdown
# 无序列表

- 项目 1
- 项目 2
  - 子项目 2.1
  - 子项目 2.2

# 有序列表

1. 第一项
2. 第二项
3. 第三项
```

### 链接和图片

```markdown
[链接文字](https://example.com)
![图片描述](/images/picture.jpg)
```

### 代码块

````markdown
```python
def hello():
    print("Hello, World!")
```
````

### 引用

```markdown
> 这是一段引用
> 可以多行
```

### 表格

```markdown
| 列 1   | 列 2   | 列 3   |
| ------ | ------ | ------ |
| 数据 1 | 数据 2 | 数据 3 |
| 数据 4 | 数据 5 | 数据 6 |
```

## 图片管理

将图片放在 `static/images/` 目录下，然后在文章中引用：

```markdown
![图片描述](/images/my-image.jpg)
```

或者使用文章同名目录（Page Bundle）：

```
content/
  posts/
    my-article/
      index.md
      image1.jpg
      image2.png
```

然后在 `index.md` 中引用：

```markdown
![图片](image1.jpg)
```

## 草稿与发布

### 草稿

```toml
+++
draft = true
+++
```

查看草稿：

```bash
hugo server -D
```

### 发布

将 `draft` 改为 `false`：

```toml
+++
draft = false
+++
```

## 标签和分类

### 使用标签

```toml
+++
tags = ['Hugo', 'Web开发', '博客']
+++
```

### 使用分类

```toml
+++
categories = ['技术', '教程']
+++
```

## 完整示例

````markdown
+++
date = '2025-11-03T15:00:00+08:00'
draft = false
title = 'Hugo 博客搭建指南'
tags = ['Hugo', '博客', '教程']
categories = ['技术']
summary = '本文介绍如何使用 Hugo 和 Docker 搭建个人博客，包括主题配置、文章编写和部署方法。'
+++

Hugo 是一个快速、灵活的静态网站生成器，非常适合用来搭建个人博客。

<!--more-->

## 为什么选择 Hugo？

Hugo 有以下优势：

- **速度快**：构建速度极快
- **易于使用**：Markdown 语法简单
- **主题丰富**：有大量精美主题

## 安装 Hugo

在 macOS 上：

```bash
brew install hugo
```
````

在 Linux 上：

```bash
snap install hugo
```

## 创建站点

```bash
hugo new site my-blog
cd my-blog
```

## 总结

通过本文，你学会了如何搭建 Hugo 博客...

````

## 预览和发布

### 本地预览

```bash
# 启动开发服务器
hugo server -D

# 访问 http://localhost:1313
````

### 构建静态文件

```bash
# 构建生产版本
hugo --minify

# 输出在 public/ 目录
```

### Docker 部署

```bash
# 构建镜像
docker build -t ivy-thoughts:latest .

# 运行容器
docker run -d -p 8080:80 ivy-thoughts:latest
```

## 常见问题

### Q: 文章列表的摘要显示有问题？

A: 确保在 Front Matter 中添加了 `summary` 字段，或使用 `<!--more-->` 分隔符。

### Q: 文章不显示？

A: 检查 `draft` 字段是否为 `false`，如果是 `true` 需要使用 `hugo server -D` 查看。

### Q: 图片不显示？

A: 确保图片路径正确，如果放在 `static/images/` 下，引用时使用 `/images/xxx.jpg`。

## 参考资源

- [Hugo 官方文档](https://gohugo.io/documentation/)
- [PaperMod 主题文档](https://github.com/adityatelange/hugo-PaperMod)
- [Markdown 语法指南](https://www.markdownguide.org/)
