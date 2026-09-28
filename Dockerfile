# ═══════════════════════════════════════════════════════════════════
# Stage 1: Builder
# Dùng để cài đặt thư viện. Stage này được phép nặng.
# ═══════════════════════════════════════════════════════════════════
FROM python:3.11-slim AS builder

WORKDIR /app

# COPY requirements.txt và cài đặt TRƯỚC khi copy source code
# Việc này giúp tận dụng cache của Docker, không phải cài lại thư viện 
# nếu bạn chỉ sửa đổi các dòng code Python.
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ═══════════════════════════════════════════════════════════════════
# Stage 2: Runtime
# Image thực sự được tạo ra. Chỉ chứa code và môi trường đã build.
# ═══════════════════════════════════════════════════════════════════
FROM python:3.11-slim AS runtime

WORKDIR /app

# Chỉ copy kết quả (thư viện) từ stage builder sang, vứt bỏ mọi compiler
COPY --from=builder /install /usr/local

# Copy toàn bộ mã nguồn vào (bạn nhớ cấu hình .dockerignore để bỏ qua .env, .git...)
COPY . .

# Tạo user thường (non-root) và chuyển quyền để bảo mật
RUN useradd --create-home --uid 10001 appuser
USER appuser

# Healthcheck gọi vào endpoint /health để Docker và Load Balancer biết app còn sống
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health').read()" || exit 1

# Lắng nghe IP 0.0.0.0 để nhận traffic từ ngoài container, và dùng biến $PORT linh hoạt
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]