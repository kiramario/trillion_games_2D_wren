#!/bin/bash
# 快速启动脚本
# 用法：./run.sh

# LÖVE2D 路径（我们安装的绿色版）
LOVE_BIN="$HOME/apps/squashfs-root/usr/bin/love"

# 检查是否存在
if [ ! -f "$LOVE_BIN" ]; then
    echo "❌ 未找到LÖVE2D，请先安装"
    echo "安装方法（Linux 64位）："
    echo "  mkdir -p ~/apps && cd ~/apps"
    echo "  wget https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage"
    echo "  chmod +x love-11.5-x86_64.AppImage"
    echo "  ./love-11.5-x86_64.AppImage --appimage-extract"
    echo "  然后把解压出来的 squashfs-root 重命名或者放 ~/apps 下"
    exit 1
fi

# 运行当前目录的游戏
cd "$(dirname "$0")"
"$LOVE_BIN" . "$@"
