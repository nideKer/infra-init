#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

SRC_CONF="$BASE_DIR/common/conf/sshd-hardening.conf"
DST_CONF="/etc/ssh/sshd_config.d/10-infra-hardening.conf"
MOTD_DST="/etc/motd"

echo "Applying SSH hardening..."

if [ ! -f "$SRC_CONF" ]; then
  echo "Source SSH hardening config not found: $SRC_CONF"
  exit 1
fi

# Install hardening snippet
install -m 0644 "$SRC_CONF" "$DST_CONF"

# Install custom MOTD
if [ -f "$MOTD_SRC" ]; then
  echo "Installing custom MOTD..."
  install -m 0644 "$ROOT_DIR/common/templates/ssh/motd" "$MOTD_DST"
fi

echo "Testing sshd configuration..."
if ! sshd -t 2>/tmp/sshd_test_err.$$; then
  echo "ERROR: sshd config test failed. See details below:"
  cat /tmp/sshd_test_err.$$
  echo "Your current sshd is still running with old config."
  echo "Please fix the configuration and run this script again."
  exit 1
fi

rm -f /tmp/sshd_test_err.$$

echo "Reloading SSH service..."
if systemctl reload ssh 2>/dev/null; then
  echo "SSH reloaded via 'systemctl reload ssh'"
elif systemctl reload sshd 2>/dev/null; then
  echo "SSH reloaded via 'systemctl reload sshd'"
else
  echo "WARNING: Could not reload ssh via systemctl; please reload manually."
fi

echo "SSH hardening applied."
echo ""
echo "IMPORTANT: Open a NEW terminal and check that you can login via SSH before closing this session."
