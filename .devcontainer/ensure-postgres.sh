#!/bin/bash
set -euo pipefail

POSTGRES_CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-postgres-dev}"
POSTGRES_IMAGE="${POSTGRES_IMAGE:-postgres:18}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-dev}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-dev}"
POSTGRES_DB="${POSTGRES_DB:-appdb}"

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

configure_iptables_backend() {
  # Docker en este entorno falla con iptables-legacy; forzamos nft.
  if command -v update-alternatives >/dev/null 2>&1; then
    run_as_root update-alternatives --set iptables /usr/sbin/iptables-nft >/dev/null 2>&1 || true
    run_as_root update-alternatives --set ip6tables /usr/sbin/ip6tables-nft >/dev/null 2>&1 || true
    
    # Fuerzas el reinicio de docker tras aplicar el cambio para que tome la nueva configuración de red
    run_as_root pkill dockerd || true
  fi
}

start_docker_daemon_if_needed() {
  if docker info >/dev/null 2>&1; then
    return 0
  fi

  if [ -x /usr/local/share/docker-init.sh ]; then
    echo ">>> Docker no responde; iniciando daemon..."
    run_as_root /usr/local/share/docker-init.sh >/tmp/docker-init-run.log 2>&1 &
  fi
}

wait_for_docker_daemon() {
  local max_attempts="${1:-90}"
  local sleep_seconds="${2:-2}"
  local attempt=1

  while [ "$attempt" -le "$max_attempts" ]; do
    if docker info >/dev/null 2>&1; then
      return 0
    fi

    if [ "$attempt" -eq 1 ]; then
      echo ">>> Esperando a que Docker este listo..."
    fi

    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
  done

  return 1
}

wait_for_postgres_ready() {
  local max_attempts="${1:-30}"
  local sleep_seconds="${2:-2}"
  local attempt=1

  while [ "$attempt" -le "$max_attempts" ]; do
    if docker exec "$POSTGRES_CONTAINER_NAME" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
      return 0
    fi

    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
  done

  return 1
}

if ! command -v docker >/dev/null 2>&1; then
  echo "    WARNING: Docker CLI no esta disponible en el PATH."
  exit 1
fi

configure_iptables_backend
start_docker_daemon_if_needed

echo ">>> Levantando PostgreSQL 18..."
if ! wait_for_docker_daemon; then
  echo "    WARNING: Docker no estuvo disponible a tiempo."
  exit 1
fi

if docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER_NAME}$"; then
  echo "    ${POSTGRES_CONTAINER_NAME} ya esta en ejecucion"
elif docker ps -a --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER_NAME}$"; then
  docker start "$POSTGRES_CONTAINER_NAME" >/dev/null
else
  docker run -d \
    --name "$POSTGRES_CONTAINER_NAME" \
    --restart unless-stopped \
    -e POSTGRES_USER="$POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_DB="$POSTGRES_DB" \
    -p "$POSTGRES_PORT:5432" \
    "$POSTGRES_IMAGE" >/dev/null
fi

if wait_for_postgres_ready; then
  echo "    ✓ PostgreSQL listo en localhost:${POSTGRES_PORT}"
else
  echo "    WARNING: PostgreSQL no estuvo listo a tiempo."
  exit 1
fi