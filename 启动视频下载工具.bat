@echo off
chcp 65001 >nul
title 全网视频下载工具

echo ========================================
echo    全网视频下载工具
echo ========================================
echo.
echo 正在启动服务器...
echo.

uv run python auto_download.py

pause
