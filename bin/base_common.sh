#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$BASE_DIR/.." && pwd)"

# Disabling IPv6 via separate sysctl file
if [ -f "$ROOT_DIR/common/sysctl-disable-ipv6.conf" ]; then
  echo "Disabling IPv6 via /etc/sysctl.d/99-disable-ipv6.conf"
  install -m 0644 "$ROOT_DIR/common/sysctl-disable-ipv6.conf" /etc/sysctl.d/99-disable-ipv6.conf
  sysctl -p /etc/sysctl.d/99-disable-ipv6.conf || true
fi


