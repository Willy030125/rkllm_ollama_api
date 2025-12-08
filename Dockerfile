FROM python:3.12-slim

# 1. 安装基础工具
# git: 用于克隆代码
# curl: 用于下载 uv
RUN apt-get update && apt-get install -y \
    curl \
    git \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 uv 包管理器
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# 设置工作目录
WORKDIR /app

# 3. 核心修改：直接从 GitHub 克隆代码
# 注意：这会拉取 main 分支的最新代码
RUN git clone https://github.com/huonwe/rkllm_openai_like_api.git .

# 4. 处理动态库
# 假设 git 仓库里包含 lib/ 目录和 .so 文件
# 将它们移动到系统库目录并刷新缓存
RUN cp lib/*.so /usr/lib/ && \
    ldconfig

# 5. 安装 Python 依赖
RUN uv sync

# 6. 设置环境变量 (支持用户覆盖)
ENV RKLLM_MODEL_PATH=default.rkllm
ENV TARGET_PLATFORM=rk3588

# 暴露端口
EXPOSE 8080

# 7. 启动命令
CMD echo "Starting RKLLM server with model path: $RKLLM_MODEL_PATH and target platform: $TARGET_PLATFORM"
CMD uv run server.py \
    --rkllm_model_path "$RKLLM_MODEL_PATH" \
    --target_platform "$TARGET_PLATFORM" \
    --port 8080 \
    --isDocker y