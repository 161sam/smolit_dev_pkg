#!/usr/bin/env bash
# plugins/docker/plugin.sh - Docker helper plugin
set -Eeuo pipefail
IFS=$'\n\t'

# ===== Docker Helper Functions =====
docker_smart_build() {
  local project="$(basename "$PWD")"
  local tag="${1:-$project:latest}"
  
  if ! command -v docker >/dev/null 2>&1; then
    sd_die "Docker not available"
  fi
  
  if [[ ! -f "Dockerfile" ]]; then
    sd_die "No Dockerfile found in current directory"
  fi
  
  echo "🐳 Smart Docker build for $project..."
  echo "Tag: $tag"
  echo
  
  # Check for .dockerignore
  if [[ ! -f ".dockerignore" ]]; then
    echo "⚠️  No .dockerignore found. Creating one..."
    cat > .dockerignore << 'EOF'
node_modules
.git
.env
.env.*
*.log
.DS_Store
Thumbs.db
.vscode
.idea
*.md
Dockerfile*
docker-compose*
.dockerignore
EOF
    echo "✓ Created .dockerignore"
    echo
  fi
  
  # Build with build context info
  local build_args=()
  
  # Add common build args if env vars exist
  [[ -n "${NODE_ENV:-}" ]] && build_args+=(--build-arg "NODE_ENV=$NODE_ENV")
  [[ -n "${BUILD_VERSION:-}" ]] && build_args+=(--build-arg "BUILD_VERSION=$BUILD_VERSION")
  
  # Build with progress and build info
  docker build \
    --progress=plain \
    --tag "$tag" \
    "${build_args[@]}" \
    --label "build.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "build.project=$project" \
    --label "build.version=${BUILD_VERSION:-unknown}" \
    . || sd_die "Docker build failed"
  
  echo
  echo "✅ Built: $tag"
  
  # Show image size
  local size="$(docker images --format "table {{.Size}}" "$tag" | tail -n+2)"
  echo "Size: $size"
  
  # Show layers (top 5)
  echo
  echo "Recent layers:"
  docker history --no-trunc "$tag" | head -6 | tail -n+2 | cut -c1-100
}

docker_smart_run() {
  local project="$(basename "$PWD")"
  local tag="${1:-$project:latest}"
  shift || true
  local args=("$@")
  
  if ! command -v docker >/dev/null 2>&1; then
    sd_die "Docker not available"
  fi
  
  # Check if image exists
  if ! docker images --quiet "$tag" | grep -q .; then
    echo "Image $tag not found. Building..."
    docker_smart_build "$tag"
  fi
  
  # Default run args for development
  local run_args=(
    --rm
    --interactive
    --tty
    --name "${project}_dev"
    --publish "3000:3000"  # Common web port
    --publish "8000:8000"  # Common API port
  )
  
  # Mount current directory if it looks like source code
  if [[ -f "package.json" ]] || [[ -f "requirements.txt" ]] || [[ -f "go.mod" ]] || [[ -f "Cargo.toml" ]]; then
    run_args+=(--volume "$PWD:/app")
    run_args+=(--workdir "/app")
  fi
  
  # Add .env file if it exists
  if [[ -f ".env" ]]; then
    run_args+=(--env-file ".env")
  fi
  
  echo "🐳 Running $tag..."
  echo "Command: docker run ${run_args[*]} $tag ${args[*]}"
  echo
  
  # Remove existing container if running
  docker rm -f "${project}_dev" 2>/dev/null || true
  
  docker run "${run_args[@]}" "$tag" "${args[@]}"
}

docker_cleanup() {
  if ! command -v docker >/dev/null 2>&1; then
    sd_die "Docker not available"
  fi
  
  echo "🧹 Docker cleanup..."
  
  # Remove stopped containers
  local stopped_containers="$(docker ps -aq --filter status=exited)"
  if [[ -n "$stopped_containers" ]]; then
    echo "Removing stopped containers..."
    echo "$stopped_containers" | xargs docker rm
    echo "✓ Stopped containers removed"
  else
    echo "No stopped containers to remove"
  fi
  
  # Remove dangling images
  local dangling_images="$(docker images -qf dangling=true)"
  if [[ -n "$dangling_images" ]]; then
    echo "Removing dangling images..."
    echo "$dangling_images" | xargs docker rmi
    echo "✓ Dangling images removed"
  else
    echo "No dangling images to remove"
  fi
  
  # Remove unused volumes (with confirmation)
  local unused_volumes="$(docker volume ls -qf dangling=true)"
  if [[ -n "$unused_volumes" ]]; then
    echo "Found unused volumes:"
    echo "$unused_volumes" | sed 's/^/  /'
    read -r -p "Remove unused volumes? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "$unused_volumes" | xargs docker volume rm
      echo "✓ Unused volumes removed"
    fi
  else
    echo "No unused volumes found"
  fi
  
  # System prune (with confirmation)
  read -r -p "Run 'docker system prune' to reclaim space? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    docker system prune -f
    echo "✓ System prune completed"
  fi
  
  echo "✅ Docker cleanup completed"
}

docker_status() {
  if ! command -v docker >/dev/null 2>&1; then
    sd_die "Docker not available"
  fi
  
  echo "🐳 Docker Status"
  echo
  
  # Docker version
  echo "=== Version ==="
  docker version --format "Client: {{.Client.Version}}, Server: {{.Server.Version}}"
  echo
  
  # System info
  echo "=== System Info ==="
  docker system df
  echo
  
  # Running containers
  echo "=== Running Containers ==="
  local running="$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}")"
  if [[ "$(echo "$running" | wc -l)" -gt 1 ]]; then
    echo "$running"
  else
    echo "No running containers"
  fi
  echo
  
  # Recent images
  echo "=== Recent Images ==="
  docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | head -6
  echo
  
  # Networks
  echo "=== Networks ==="
  docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
}

docker_logs() {
  local container="${1:-}"
  
  if ! command -v docker >/dev/null 2>&1; then
    sd_die "Docker not available"
  fi
  
  if [[ -z "$container" ]]; then
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo
    read -r -p "Enter container name: " container
  fi
  
  [[ -n "$container" ]] || sd_die "No container specified"
  
  echo "📋 Following logs for: $container"
  echo "Press Ctrl+C to stop"
  echo
  
  docker logs -f --tail=100 "$container"
}

docker_exec() {
  local container="${1:-}"
  local cmd="${2:-bash}"
  
  if ! command -v docker >/dev/null 2>&1; then
    sd_die "Docker not available"
  fi
  
  if [[ -z "$container" ]]; then
    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo
    read -r -p "Enter container name: " container
  fi
  
  [[ -n "$container" ]] || sd_die "No container specified"
  
  # Try bash first, then sh
  if docker exec -it "$container" bash -c "exit" 2>/dev/null; then
    docker exec -it "$container" bash
  elif docker exec -it "$container" sh -c "exit" 2>/dev/null; then
    docker exec -it "$container" sh
  else
    # Try the specified command
    docker exec -it "$container" "$cmd"
  fi
}

docker_init() {
  local project_type="${1:-auto}"
  
  if [[ -f "Dockerfile" ]]; then
    sd_warn "Dockerfile already exists"
    return 0
  fi
  
  # Auto-detect project type
  if [[ "$project_type" == "auto" ]]; then
    if [[ -f "package.json" ]]; then
      project_type="node"
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
      project_type="python"
    elif [[ -f "go.mod" ]]; then
      project_type="go"
    elif [[ -f "Cargo.toml" ]]; then
      project_type="rust"
    else
      project_type="generic"
    fi
  fi
  
  echo "🐳 Creating Dockerfile for $project_type project..."
  
  case "$project_type" in
    node)
      cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Install dependencies first (for better caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

USER nextjs

EXPOSE 3000

CMD ["npm", "start"]
EOF
      ;;
    python)
      cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd --create-home --shell /bin/bash app
USER app

EXPOSE 8000

CMD ["python", "app.py"]
EOF
      ;;
    go)
      cat > Dockerfile << 'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
EOF
      ;;
    rust)
      cat > Dockerfile << 'EOF'
FROM rust:1.70 as builder

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/app /usr/local/bin/app

EXPOSE 8080

CMD ["app"]
EOF
      ;;
    generic)
      cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

# Install common tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy application files
COPY . .

EXPOSE 8080

CMD ["bash"]
EOF
      ;;
  esac
  
  echo "✓ Created Dockerfile for $project_type"
  
  # Create docker-compose.yml if it doesn't exist
  if [[ ! -f "docker-compose.yml" ]]; then
    local project="$(basename "$PWD")"
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  $project:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    restart: unless-stopped

  # Uncomment to add a database
  # db:
  #   image: postgres:15-alpine
  #   environment:
  #     POSTGRES_DB: ${project}
  #     POSTGRES_USER: user
  #     POSTGRES_PASSWORD: password
  #   volumes:
  #     - db_data:/var/lib/postgresql/data
  #   ports:
  #     - "5432:5432"

# volumes:
#   db_data:
EOF
    echo "✓ Created docker-compose.yml"
  fi
  
  echo "✅ Docker setup completed"
  echo "   Run 'sd docker:build' to build the image"
}

# ===== Register Commands =====
sd_register "docker:build" "Context-aware Docker builds" docker_smart_build
sd_register "docker:run" "Smart container runner with dev setup" docker_smart_run  
sd_register "docker:cleanup" "Clean up containers, images and volumes" docker_cleanup
sd_register "docker:status" "Show Docker system status" docker_status
sd_register "docker:logs" "Follow container logs" docker_logs
sd_register "docker:exec" "Execute shell in container" docker_exec
sd_register "docker:init" "Initialize Dockerfile for project type" docker_init
