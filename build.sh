#!/bin/bash

# 顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🐳 Godot Tower Defense - Docker Build & Run${NC}"
echo ""

# 檢查 Docker 是否安裝
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安裝！${NC}"
    exit 1
fi

# 構建 Docker 映像
echo -e "${YELLOW}📦 Building Docker image...${NC}"
docker build -t godot-tower-defense:latest .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

# 檢查是否已有容器執行
if docker ps | grep -q godot-tower-defense; then
    echo -e "${YELLOW}⏹️ Stopping existing container...${NC}"
    docker stop godot-tower-defense
    docker rm godot-tower-defense
fi

# 執行容器
echo -e "${YELLOW}🚀 Starting Docker container...${NC}"
docker run -d \
    --name godot-tower-defense \
    -p 8080:8080 \
    -v $(pwd)/godot-tower-defense-web:/app \
    godot-tower-defense:latest

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Container started successfully!${NC}"
    echo ""
    echo -e "${GREEN}🎮 遊戲已啟動！${NC}"
    echo -e "${GREEN}📱 訪問地址: http://localhost:8080${NC}"
    echo ""
    echo -e "${YELLOW}常用命令:${NC}"
    echo "  docker logs godot-tower-defense          # 查看日誌"
    echo "  docker stop godot-tower-defense          # 停止容器"
    echo "  docker rm godot-tower-defense            # 刪除容器"
else
    echo -e "${RED}❌ Failed to start container!${NC}"
    exit 1
fi
