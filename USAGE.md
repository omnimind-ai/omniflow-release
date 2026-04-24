# OmniFlow Provider 使用指南

OmniFlow Provider 的 Cython 编译版本，专为 OOB (OpenOmniBot) Alpine 环境优化。

## 安装

### OOB 自动安装（推荐）

OOB 启动时会自动下载并安装最新版本：

```
https://github.com/omnimind-ai/omniflow-release/raw/main/wheels/omniflow-latest-alpine.whl
```

### 手动安装

```bash
# 下载
wget https://github.com/omnimind-ai/omniflow-release/raw/main/wheels/omniflow-latest-alpine.whl

# 安装（最小依赖）
pip install omniflow-latest-alpine.whl

# 安装（含 LLM 支持）
pip install omniflow-latest-alpine.whl
pip install litellm openai dashscope
```

### ADB 推送到设备

```bash
adb push omniflow-latest-alpine.whl /data/local/tmp/omnibot/packages/
```

## 启动 Provider

```bash
# 默认端口 9417
omniflow-provider

# 指定端口
omniflow-provider --port 9417

# 指定 host（允许外部访问）
omniflow-provider --host 0.0.0.0 --port 9417
```

## 验证安装

```bash
# 检查版本
curl http://localhost:9417/health

# 返回示例
{
  "success": true,
  "version": "0.3.0",
  "build_type": "cython",
  "port": 9417,
  "store": {
    "path": "...",
    "function_count": 0,
    "run_log_count": 0
  },
  "embedding_type": "local",
  "embedding_dim": 64
}
```

## 特性

### Cython 编译

核心模块已编译为 `.so` 文件，提供：
- 代码保护（源码不可见）
- 更快的执行速度
- 更小的内存占用

编译模块列表：
```
src/utg/core/models.so
src/utg/core/actions.so
src/utg/core/graph_ops.so
src/utg/execution/executor.so
src/utg/execution/compile.so
src/utg/assets/embedding/page_match.so
src/utg/assets/embedding/element_match.so
... (共 16 个模块)
```

### 本地向量引擎

- **类型**: 规则向量（无需外部 API）
- **维度**: 64 维
- **计算**: 完全本地，无网络依赖

### 精简依赖

核心依赖仅 10 个包：
```
fastapi, uvicorn, pydantic, pydantic-settings, jinja2
aiohttp, python-dotenv, jsonschema, requests, numpy
```

LLM 功能为可选（懒加载），不使用时无需安装。

## API 端点

### 核心端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/health` | GET | Provider 状态 |
| `/compile` | POST | 编译 Goal |
| `/functions/execute` | POST | 执行 Function |
| `/run_logs` | GET | 列出 Run Logs |
| `/functions` | GET | 列出 Functions |

### 页面端点

| 端点 | 说明 |
|------|------|
| `/compile_test` | Compile 测试页 |
| `/editor` | Function 编辑器 |
| `/xml_compare` | XML 对比工具 |
| `/browse/functions` | Function 浏览 |
| `/browse/run_logs` | Run Log 浏览 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `OMNIFLOW_UTG_API_PORT` | 9417 | Provider 端口 |
| `OMNIFLOW_UTG_STORE_PATH` | `~/.omniflow/utg_store.json` | 数据存储路径 |
| `DASHSCOPE_API_KEY` | - | DashScope API Key（可选，用于 LLM） |
| `OPENAI_API_KEY` | - | OpenAI API Key（可选，用于 LLM） |

## 故障排除

### 端口被占用

```bash
# 检查端口
lsof -i :9417

# 使用其他端口
omniflow-provider --port 9418
```

### 模块导入错误

确保使用正确的 Python 版本：
```bash
python3.11 -m src.integrations.utg_api
```

### LLM 功能不可用

LLM 是可选功能，需要额外安装：
```bash
pip install litellm openai dashscope
```

## 版本信息

- **当前版本**: 见 `LATEST_VERSION` 文件
- **构建类型**: Cython (musl libc)
- **Python 版本**: 3.11
- **目标平台**: Alpine Linux / OOB

## 更新

OOB 会在启动时自动检查并下载最新版本。

手动更新：
```bash
pip install --upgrade https://github.com/omnimind-ai/omniflow-release/raw/main/wheels/omniflow-latest-alpine.whl
```
