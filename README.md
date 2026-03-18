# 🎮 Godot Tower Defense - Docker

將塔防遊戲打包到 Docker，方便部署到任何地方！

## 📋 前置需求

- Docker 已安裝 ([下載](https://www.docker.com/products/docker-desktop))
- Docker Compose (通常隨 Docker 安裝)

## 🚀 快速開始

### 方式 1: 使用 Docker Compose (推薦)

```bash
# 進入 docker 目錄
cd docker

# 啟動遊戲
docker-compose up -d

# 訪問遊戲
# 打開瀏覽器進入: http://localhost:8080
```

### 方式 2: 使用 build.sh 腳本

```bash
cd docker

# 賦予執行權限
chmod +x build.sh

# 執行腳本
./build.sh
```

### 方式 3: 手動 Docker 命令

```bash
cd docker

# 構建映像
docker build -t godot-tower-defense:latest .

# 執行容器
docker run -d \
  --name godot-tower-defense \
  -p 8080:8080 \
  -v $(pwd)/godot-tower-defense-web:/app \
  godot-tower-defense:latest
```

## 📱 訪問遊戲

遊戲啟動後，在瀏覽器中訪問：

```
http://localhost:8080
```

## 🛑 停止遊戲

```bash
cd docker

# 使用 Docker Compose
docker-compose down

# 或手動命令
docker stop godot-tower-defense
docker rm godot-tower-defense
```

## 📊 查看日誌

```bash
docker logs godot-tower-defense

# 實時查看
docker logs -f godot-tower-defense
```

## 📂 目錄結構

```
docker/
├── Dockerfile              # Node.js Docker 配置
├── Dockerfile.nginx        # Nginx Docker 配置
├── docker-compose.yml      # Node.js 啟動配置
├── docker-compose-nginx.yml # Nginx 啟動配置
├── nginx.conf             # Nginx 伺服器配置
├── build.sh               # 自動化構建腳本
├── .dockerignore          # Docker 忽略檔案
├── .env.example           # 環境變數範例
└── README.md              # 本文件
```

## 🎯 使用提示

✅ **開發** - 用 Node.js 版本 (docker-compose.yml)  
⚡ **生產** - 用 Nginx 版本 (docker-compose-nginx.yml)  
🔧 **快速** - 用 build.sh 腳本

---

🎮 **享受遊戲！** | 🐳 **Happy Dockering!**
