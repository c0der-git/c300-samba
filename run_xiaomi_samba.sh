#!/usr/bin/env bash
set -euo pipefail

### CONFIG – adjust if needed ###
IMAGE_NAME="xiaomi-samba:latest"
CONTAINER_NAME="xiaomi-samba"

GIT_DIR="/home/user/dev/samba"
DATA_DIR="/home/user/dev/samba"

SMB_USER="xiaomi"
#################################

# --- SMB_PASS handling ---
if [ -z "${SMB_PASS:-}" ]; then
  read -s -p "Enter SMB_PASS: " SMB_PASS
  echo
  if [ -z "$SMB_PASS" ]; then
    echo "ERROR: SMB_PASS cannot be empty"
    exit 1
  fi
fi

# --- Build image only if missing ---
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "[*] Docker image $IMAGE_NAME not found. Building..."
  cd "$GIT_DIR"
  docker build --no-cache -t "$IMAGE_NAME" .
else
  echo "[*] Docker image $IMAGE_NAME already exists. Skipping build."
fi

# --- Stop & remove existing container (if any) ---
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  echo "[*] Removing existing container $CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME"
fi

# --- Prepare docker run args ---
DOCKER_ENV_ARGS=(
  -e "SMB_USER=$SMB_USER"
  -e "SMB_PASS=$SMB_PASS"
)

# Optional interface override
if [ -n "${SAMBA_IFACE:-}" ]; then
  echo "[*] Using overridden SAMBA_IFACE=$SAMBA_IFACE"
  DOCKER_ENV_ARGS+=(-e "SAMBA_IFACE=$SAMBA_IFACE")
else
  echo "[*] No SAMBA_IFACE specified – container will auto-detect"
fi

# --- Run container ---
echo "[*] Starting container $CONTAINER_NAME"

cd "$DATA_DIR"

docker run -d \
  --name "$CONTAINER_NAME" \
  --network host \
  "${DOCKER_ENV_ARGS[@]}" \
  -v "$DATA_DIR/data/recordings:/srv/samba/recordings" \
  "$IMAGE_NAME"

echo "[✓] Xiaomi Samba container started successfully"