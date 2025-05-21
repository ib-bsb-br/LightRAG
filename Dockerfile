# syntax=docker/dockerfile:1.7

# ---- Builder Stage: Install dependencies with uv ----
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

# Set uv environment variables for optimal behavior in Docker
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Copy dependency definition files first to leverage Docker's layer caching
COPY requirements.txt .
COPY lightrag/api/requirements.txt ./lightrag/api/
COPY setup.py .

# Copy the entire application source code
COPY . .

# Install dependencies defined in requirements.txt and install the project itself
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --no-cache -r requirements.txt && \
    uv pip install --system --no-cache -r lightrag/api/requirements.txt && \
    uv pip install --system --no-cache ".[api]" && \
    # Install dependencies for default storage
    uv pip install --system --no-cache nano-vectordb networkx && \
    # Install dependencies for default LLM
    uv pip install --system --no-cache openai ollama tiktoken && \
    # Install dependencies for default document loader
    uv pip install --system --no-cache pypdf2 python-docx python-pptx openpyxl && \
    # Install database connectors
    uv pip install --system --no-cache psycopg2-binary neo4j

# ---- Runtime Stage: Minimal final image ----
FROM python:3.11-slim-bookworm AS final

# Set environment variables for Python runtime and LightRAG
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    # Change default port from 9621 to 8000
    PORT="8000" \
    # Define LightRAG's data storage directories
    WORKING_DIR="/app/data/rag_storage" \
    INPUT_DIR="/app/data/inputs" \
    # Ensure Python can find modules within the /app directory
    PYTHONPATH="/app:${PYTHONPATH}"

WORKDIR /app

# Create a dedicated non-root user and group for security
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid 1001 -m -s /bin/bash appuser

# Copy installed Python packages from the builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
# Copy any executables installed by uv/pip
COPY --from=builder /usr/local/bin /usr/local/bin
# Copy the application code itself from the builder stage
COPY --from=builder --chown=appuser:appgroup /app /app

# Create LightRAG's data directories and set correct ownership
RUN mkdir -p ${WORKING_DIR} ${INPUT_DIR} && \
    chown -R appuser:appgroup /app/data

# Switch to the non-root user
USER appuser

# Expose the port that LightRAG will listen on
EXPOSE 8000

# Set the entrypoint to run the LightRAG API server module
ENTRYPOINT ["python", "-m", "lightrag.api.lightrag_server"]
