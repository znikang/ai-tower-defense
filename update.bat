@echo off
chcp 65001 >nul

echo.
echo === Godot Tower Defense - Docker Update ===
echo.

REM 檢查 Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not found!
    pause
    exit /b 1
)

REM 選擇版本
echo Select version:
echo 1 - Node.js (port 8080)
echo 2 - Nginx (port 80)
echo.
set /p choice="Enter 1 or 2: "

if "%choice%"=="1" (
    set COMPOSE=docker-compose.yml
    set PORT=8080
    echo.
    echo Building Node.js version...
) else if "%choice%"=="2" (
    set COMPOSE=docker-compose-nginx.yml
    set PORT=80
    echo.
    echo Building Nginx version...
) else (
    echo Invalid choice!
    pause
    exit /b 1
)

echo.
docker-compose -f %COMPOSE% up -d --build

if errorlevel 1 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo === Success! ===
echo Visit: http://localhost:%PORT%
echo.
pause
