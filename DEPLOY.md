# 🚀 Godot Tower Defense - Docker 部署指南

## ⚠️ 重要：先導出遊戲

在使用 Docker 之前，需要先在 Godot 中導出 Web 版本。

### 步驟 1: 在 Godot Editor 中導出

1. 打開 Godot Editor
2. 進入 `Project` → `Export...`
3. 如果沒有 HTML5 預設值，點擊 `Add Preset` 並選擇 `HTML5`
4. 選擇導出位置（建議放在 `export/web` 或 `godot-tower-defense-web` 資料夾）
5. 點擊 `Export Project`

### 步驟 2: 驗證導出檔案

確保導出後的檔案結構如下：

```
godot-tower-defense/
├── export/
│   └── web/
│       ├── index.html
│       ├── godot.wasm.js
│       ├── godot.wasm
│       └── ...
```

或者：

```
godot-tower-defense/
├── godot-tower-defense-web/
│   ├── index.html
│   ├── godot.wasm.js
│   ├── godot.wasm
│   └── ...
```

## 📦 使用 Docker

### 方式 1: Docker Compose (推薦)

```bash
cd docker
docker-compose up -d
```

### 方式 2: 手動 Docker

```bash
cd docker
docker build -t godot-tower-defense:latest ..
docker run -d -p 8080:8080 godot-tower-defense:latest
```

## 訪問遊戲

在瀏覽器中打開：

```
http://localhost:8080
```

## 🛑 停止容器

```bash
cd docker
docker-compose down
```

## 🐛 常見問題

### Q: Docker 說找不到檔案？
A: 確保已在 Godot 中導出 Web 版本，並放在 `export/web` 或 `godot-tower-defense-web` 目錄中

### Q: 連接埠 8080 已被占用？
A: 編輯 `docker-compose.yml`，改為其他連接埠（如 3000）：
```yaml
ports:
  - "3000:8080"
```

### Q: 如何重新構建映像？
A: 執行
```bash
docker-compose up -d --build
```

---

🎮 **現在就部署吧！**
