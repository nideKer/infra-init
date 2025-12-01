#!/usr/bin/env bash
set -e

# визначаємо ОС
. /etc/os-release

OS_ID="$ID"
OS_VER="$VERSION_CODENAME"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Base system initialization, common for all hosts
if [ -x "$SCRIPT_DIR/bin/base_common.sh" ]; then
  "$SCRIPT_DIR/bin/base_common.sh"
fi

# If there's an OS/version-specific script – run it
if [ -x "$SCRIPT_DIR/bin/os/${OS_ID}/${OS_VER}/base.sh" ]; then
  "$SCRIPT_DIR/bin/os/${OS_ID}/${OS_VER}/base.sh"
else
  echo "No OS-specific script for ${OS_ID} ${OS_VER}, skipping..."
fi

echo
echo "========================================"
echo "Installing common devops tools"
echo "========================================"
echo

apt-get update && apt-get -y upgrade
apt-get install -y \
  mc micro tree ncdu gdu \
  htop iotop iftop mtr iperf3 \
  git tig curl wget \
  sudo needrestart etckeeper \
  lvm2 parted \
  iproute2 dnsutils

# SMB support packages:
# nbtscan smbclient cifs-utils
# dos2unix sshfs

# Docker installation
"$SCRIPT_DIR/bin/docker/install.sh" "${SUDO_USER:-$USER}"

echo 
echo "Cleaning up..."

apt-get autoremove -y --purge || true
apt-get clean || true

echo 
echo "Bootstrap completed."
echo 

echo "Creating /opt/repo directory..."
REPO_OWNER="${SUDO_USER:-$USER}"
mkdir -p /opt/repo

if [ "$REPO_OWNER" != "root" ]; then
    chown "$REPO_OWNER:$REPO_OWNER" /opt/repo
fi

# User-specific bootstrap
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  echo
  echo "Running user bootstrap for $SUDO_USER..."
  su - "$SUDO_USER" -c "$SCRIPT_DIR/bin/bootstrap_user.sh"
fi

echo
echo "========================================"
echo "  infra-init: initial bootstrap finished"
echo "----------------------------------------"
echo "  Host : $(hostname)"
echo "  User : ${SUDO_USER:-$USER}"
echo "  OS   : ${OS_ID} ${OS_VER}"
echo "========================================"
echo
echo "Next steps:"
echo "  - re-login as ${SUDO_USER:-$USER} to apply new groups and shell config"
echo "  - verify Docker:    docker ps"
echo "  - check groups:     id ${SUDO_USER:-$USER}"
echo "  - (optional) run:   sudo ./ssh_hardening.sh"
echo

# Auto re-login as original sudo user (optional)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  echo "Spawning a new login shell for $SUDO_USER..."
  su - "$SUDO_USER"
fi