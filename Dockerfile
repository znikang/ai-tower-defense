FROM node:18-alpine

WORKDIR /app

# 複製導出的所有檔案 (export/web 資料夾中的所有內容)
COPY ./export/web .

# 安裝全域 http-server
RUN npm install -g http-server

# 暴露連接埠
EXPOSE 8080

# 啟動伺服器
CMD ["http-server", "-p", "8080", "-c-1"]
