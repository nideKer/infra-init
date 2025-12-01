#!/usr/bin/env bash
set -e

. /etc/os-release
ARCH="$(dpkg --print-architecture)"
CODENAME="$VERSION_CODENAME"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$BASE_DIR/../.." && pwd)" 
. "$ROOT_DIR/bin/bootstrap_lib.sh"

DOCKER_USER="${1:-${SUDO_USER:-$USER}}"

echo
echo "========================================"
echo "Starting docker installation for $ID $CODENAME ($ARCH), user=$DOCKER_USER"
echo "========================================"
echo

# Remove old versions if any
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Dependencies
apt-get update
apt-get -y install ca-certificates curl gnupg

# GPG-key Docker
mkdir -p /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Repo Docker
case "$ID" in
  debian|ubuntu)
    echo \
      "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID \
      $CODENAME stable" > /etc/apt/sources.list.d/docker.list
    ;;
  *)
    echo "Unsupported distribution: $ID" >&2
    exit 1
    ;;
esac

apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

if [ "$DOCKER_USER" != "root" ]; then
  add_user_to_group_if_needed "$DOCKER_USER" docker
fi

systemctl enable --now docker

echo
echo "========================================"
docker -v
docker compose version
echo "Docker installation completed successfully."
echo "========================================"
echo

add_user_to_group_if_needed "$DOCKER_USER" docker