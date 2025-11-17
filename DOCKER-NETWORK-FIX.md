# Docker 网络问题解决方案

## 问题诊断

当前遇到的问题：
```
ERROR: Get "https://registry-1.docker.io/v2/": net/http: request canceled
```

**原因**：Docker无法访问Docker Hub官方镜像仓库，这在中国大陆地区很常见。

---

## 解决方案1：配置Docker镜像加速器（推荐）

### 步骤1：创建Docker daemon配置文件

```bash
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com",
    "https://dockerproxy.com",
    "https://docker.nju.edu.cn"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF
```

### 步骤2：重启Docker服务

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 步骤3：验证配置

```bash
docker info | grep -A 10 "Registry Mirrors"
```

应该显示配置的镜像源。

### 步骤4：重新启动HKD开发环境

```bash
cd /home/judy/codebase/HKD/hkd-infrastructure
./scripts/start-dev.sh
```

---

## 解决方案2：使用阿里云镜像加速器（更快）

### 步骤1：获取专属加速地址

访问：https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors

登录后获取您的专属加速器地址，格式类似：
```
https://xxxxxx.mirror.aliyuncs.com
```

### 步骤2：配置Docker

```bash
sudo tee /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://xxxxxx.mirror.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## 解决方案3：轻量级启动（仅核心服务）

如果上述方案仍有问题，可以先启动最基本的服务进行测试：

### 创建精简版docker-compose

我已为您创建了 `docker-compose.minimal.yml`，只包含：
- PostgreSQL
- Redis
- MongoDB

启动方式：
```bash
cd /home/judy/codebase/HKD/hkd-infrastructure
docker-compose -f docker-compose.minimal.yml up -d
```

---

## 解决方案4：手动下载镜像（最后手段）

如果网络问题无法解决，可以使用代理手动拉取镜像：

### 方法A：使用HTTP代理

```bash
# 设置Docker daemon使用代理（需要重启Docker）
sudo mkdir -p /etc/systemd/system/docker.service.d

sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf <<'EOF'
[Service]
Environment="HTTP_PROXY=http://your-proxy:port"
Environment="HTTPS_PROXY=http://your-proxy:port"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 方法B：手动pull关键镜像

```bash
docker pull postgres:16-alpine
docker pull redis:7.2-alpine
docker pull mongo:7
docker pull confluentinc/cp-kafka:7.5.0
docker pull nacos/nacos-server:v2.3.0
# ... 其他镜像
```

---

## 验证Docker网络

### 测试1：检查DNS解析

```bash
ping -c 3 registry-1.docker.io
```

### 测试2：测试HTTPS连接

```bash
curl -I https://registry-1.docker.io/v2/
```

应该返回 401 Unauthorized（说明能连接，只是未认证）

### 测试3：拉取测试镜像

```bash
docker pull hello-world
```

---

## 故障排查

### 问题1：重启Docker后仍无法连接

**检查**：
```bash
sudo journalctl -u docker -n 50
```

### 问题2：镜像源配置不生效

**检查**：
```bash
docker info
```

查看 "Registry Mirrors" 是否包含配置的镜像源。

### 问题3：daemon.json格式错误

**验证JSON格式**：
```bash
cat /etc/docker/daemon.json | jq .
```

---

## 推荐配置（综合方案）

```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "insecure-registries": []
}
```

---

## 下一步

配置完成后，运行：

```bash
cd /home/judy/codebase/HKD/hkd-infrastructure
./scripts/start-dev.sh
```

如果仍有问题，请查看日志：
```bash
./scripts/logs.sh <service-name>
```

---

**最后更新**: 2025-11-17
