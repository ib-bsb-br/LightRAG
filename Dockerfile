# syntax=docker/dockerfile:1.7

# ---- Builder Stage: Install dependencies with uv ----
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

# Define build arguments for GitHub secrets
ARG POSTGRES_PASSWORD
ARG NEO4J_PASSWORD
ARG OPENAI_API_KEY
ARG POSTGRES_USER
ARG POSTGRES_DB
ARG LLM_MODEL
ARG EMBEDDING_MODEL
ARG EMBEDDING_DIM

# Set uv environment variables for optimal behavior in Docker
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Copy dependency definition files first to leverage Docker's layer caching
COPY pyproject.toml uv.lock* ./

# Copy the entire application source code
# This makes all the project's Python modules and other assets available for the build
COPY . .

# Install dependencies defined in pyproject.toml and uv.lock,
# then install the project itself (the LightRAG application) into the system Python environment.
# The `.[api]` syntax installs the current project with its 'api' extras.
# Ensure psycopg2-binary and neo4j driver are listed in the pyproject.toml dependencies
# or under the [api] extra for lightrag-hku.
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --no-cache .[api] \
    psycopg2-binary \
    neo4j \
    nano-vectordb \
    networkx \
    openai \
    ollama \
    tiktoken \
    pypdf2 \
    python-docx \
    python-pptx \
    openpyxl
# Note: If 'lightrag-hku[api]' already pulls in these dependencies,
# we can remove them from the explicit install lines above.

# ---- Final Stage: Create a minimal runtime image ----
FROM python:3.11-slim-bookworm AS final

# Define build arguments for GitHub secrets in the final stage
ARG POSTGRES_PASSWORD
ARG NEO4J_PASSWORD
ARG OPENAI_API_KEY
ARG POSTGRES_USER=lightrag_user
ARG POSTGRES_DB=lightrag_db
ARG LLM_MODEL=gpt-4o-mini
ARG EMBEDDING_MODEL=text-embedding-3-small
ARG EMBEDDING_DIM=1536

# Set core environment variables for the runtime
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/usr/local/bin:$PATH" \
    WORKING_DIR="/app/data/rag_storage" \
    INPUT_DIR="/app/data/inputs" \
    PORT="8000" \
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    NEO4J_PASSWORD=${NEO4J_PASSWORD} \
    OPENAI_API_KEY=${OPENAI_API_KEY} \
    POSTGRES_USER=${POSTGRES_USER} \
    POSTGRES_DB=${POSTGRES_DB} \
    LLM_MODEL=${LLM_MODEL} \
    EMBEDDING_MODEL=${EMBEDDING_MODEL} \
    EMBEDDING_DIM=${EMBEDDING_DIM}

WORKDIR /app

# Create a dedicated non-root user and group for security best practices
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 -m -s /bin/bash appuser

# Copy installed Python packages from the builder stage's system site-packages
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
# Copy executables (like those installed by uv/pip to /usr/local/bin)
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the application code itself from the builder stage
COPY --from=builder --chown=appuser:appuser /app /app

# Create LightRAG's data directories and set correct ownership for the non-root user
# These directories will typically be mounted as volumes in docker-compose.
RUN mkdir -p ${WORKING_DIR} ${INPUT_DIR} && \
    chown -R appuser:appuser /app/data

# Switch to the non-root user
USER appuser

# Expose the port that LightRAG will listen on (matches PORT env var)
EXPOSE ${PORT}

# Set the entrypoint to run the LightRAG API server module
ENTRYPOINT ["python", "-m", "lightrag.api.lightrag_server"]
