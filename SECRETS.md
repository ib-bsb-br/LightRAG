# LightRAG Secrets Configuration Guide

This document provides guidance on setting up the required secrets for your LightRAG deployment.

## Required Secrets

The following secrets need to be configured in your GitHub repository and/or your deployment environment:

### Docker Image Configuration
- `DOCKER_REGISTRY_HOST`: The Docker registry host (default: ghcr.io)
- `DOCKER_IMAGE_NAME`: The Docker image name (default: ib-bsb-br/LightRAG)
- `IMAGE_TAG`: The Docker image tag (default: latest)

### Database Credentials
- `POSTGRES_USER`: PostgreSQL username (default: lightrag_user)
- `POSTGRES_PASSWORD`: PostgreSQL password (required, no default)
- `POSTGRES_DB`: PostgreSQL database name (default: lightrag_db)
- `NEO4J_PASSWORD`: Neo4j password (required, no default)

### OpenAI API Configuration
- `OPENAI_API_KEY`: Your OpenAI API key (required, no default)
- `OPENAI_API_BASE`: OpenAI API base URL (default: https://api.openai.com/v1)
- `LLM_MODEL`: The LLM model to use (default: gpt-4o-mini)
- `EMBEDDING_MODEL`: The embedding model to use (default: text-embedding-3-small)
- `EMBEDDING_DIM`: The embedding dimension (default: 1536)

### LightRAG Application Authentication & Settings
- `AUTH_ACCOUNTS`: User accounts for authentication (default: admin:AnotherStrongPassword123!)
- `TOKEN_SECRET`: Secret for JWT token generation (required, no default)
- `TOKEN_EXPIRE_HOURS`: Token expiration in hours (default: 4)
- `TIMEOUT`: Request timeout in seconds (default: 300)
- `LOG_LEVEL`: Logging level (default: INFO)
- `ENABLE_LLM_CACHE_FOR_EXTRACT`: Whether to enable LLM cache (default: true)

### Server Configuration
- `HOST`: Host to bind the server to (default: 0.0.0.0)
- `PORT`: Port to run the server on (default: 8000)
- `WEBUI_TITLE`: Title for the web UI (default: 'My Graph KB')
- `WEBUI_DESCRIPTION`: Description for the web UI (default: 'Simple and Fast Graph Based RAG System')

## Setting Up Secrets in GitHub

To set up secrets in your GitHub repository:

1. Go to your repository on GitHub
2. Click on the "Settings" tab
3. In the left sidebar, click on "Secrets and variables" > "Actions"
4. Click on "New repository secret"
5. Enter the name of the secret (e.g., POSTGRES_PASSWORD)
6. Enter the value for the secret
7. Click "Add secret"
8. Repeat for all required secrets

## Setting Up Secrets for Local Development

For local development, create a `.env` file in the root of your repository based on the `.env.example` template. This file should contain all the required environment variables with their values.

## Setting Up Secrets for Ansible Deployment

For Ansible deployment, you can use Ansible Vault to securely store and manage your secrets. Here's a basic example of how to set up secrets in Ansible:

```yaml
# vars/secrets.yml (encrypted with ansible-vault)
postgres_user: lightrag_user
postgres_password: your_secure_postgres_password
postgres_db: lightrag_db
neo4j_password: your_secure_neo4j_password
openai_api_key: your_openai_api_key
token_secret: your_secure_token_secret
```

Then, in your Ansible playbook:

```yaml
- name: Deploy LightRAG
  hosts: your_server
  vars_files:
    - vars/secrets.yml
  tasks:
    - name: Create .env file
      template:
        src: templates/env.j2
        dest: /path/to/deployment/.env
        mode: '0600'
```

With a template file (`templates/env.j2`) that looks like:

```
# Database Credentials
POSTGRES_USER={{ postgres_user }}
POSTGRES_PASSWORD={{ postgres_password }}
POSTGRES_DB={{ postgres_db }}
NEO4J_PASSWORD={{ neo4j_password }}

# OpenAI API Configuration
OPENAI_API_KEY={{ openai_api_key }}
# ... other variables ...
```

This approach ensures your secrets are securely managed and deployed to your server.
