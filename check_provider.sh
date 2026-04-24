#!/bin/sh
#
# OOB Provider 检测脚本
# 用法: sh check_provider.sh [port]
#
set -e

PORT="${1:-9417}"
TIMEOUT=5

echo "=== OmniFlow Provider 检测 ==="

# 1. 检查 wheel 是否安装
echo "[1/4] 检查安装..."
if python3 -c "import src.integrations.utg_api" 2>/dev/null; then
    echo "  ✓ omniflow 已安装"
else
    echo "  ✗ omniflow 未安装"
    echo "  安装命令: pip install omniflow-latest-alpine.whl"
    exit 1
fi

# 2. 检查构建类型
echo "[2/4] 检查构建类型..."
BUILD_TYPE=$(python3 -c "
from src.utg.core import models
import os
f = getattr(models, '__file__', '')
print('cython' if f.endswith('.so') else 'python')
" 2>/dev/null || echo "unknown")
echo "  构建类型: $BUILD_TYPE"

# 3. 检查端口是否可用
echo "[3/4] 检查端口 $PORT..."
if command -v nc >/dev/null 2>&1; then
    if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
        echo "  ⚠ 端口 $PORT 已被占用"
    else
        echo "  ✓ 端口 $PORT 可用"
    fi
elif command -v curl >/dev/null 2>&1; then
    if curl -s --connect-timeout 1 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
        echo "  ⚠ 端口 $PORT 已有服务"
    else
        echo "  ✓ 端口 $PORT 可用"
    fi
else
    echo "  ? 无法检测端口（缺少 nc/curl）"
fi

# 4. 尝试启动并检测
echo "[4/4] 启动 Provider..."
python3 -m src.integrations.utg_api --port "$PORT" &
PID=$!
sleep 2

# 检查进程是否存活
if kill -0 "$PID" 2>/dev/null; then
    # 检查 health 端点
    if command -v curl >/dev/null 2>&1; then
        HEALTH=$(curl -s --connect-timeout "$TIMEOUT" "http://127.0.0.1:$PORT/health" 2>/dev/null || echo "{}")
        VERSION=$(echo "$HEALTH" | python3 -c "import sys,json; print(json.load(sys.stdin).get('version','?'))" 2>/dev/null || echo "?")
        echo "  ✓ Provider 启动成功"
        echo "  版本: $VERSION"
        echo "  地址: http://127.0.0.1:$PORT"
    else
        echo "  ✓ Provider 进程已启动 (PID: $PID)"
    fi
    # 停止测试进程
    kill "$PID" 2>/dev/null || true
else
    echo "  ✗ Provider 启动失败"
    exit 1
fi

echo ""
echo "=== 检测完成 ==="
echo "启动命令: omniflow-provider --port $PORT"
