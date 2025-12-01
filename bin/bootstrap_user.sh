#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$BASE_DIR/.." && pwd)"

# === Shell / Git configs (always overwrite) ===

install -m 0644 "$ROOT_DIR/common/templates/bashrc"             "$HOME/.bashrc"
install -m 0644 "$ROOT_DIR/common/templates/bash_aliases"       "$HOME/.bash_aliases"

install -m 0600 "$ROOT_DIR/common/templates/gitconfig"          "$HOME/.gitconfig"
install -m 0600 "$ROOT_DIR/common/templates/gitignore_global"   "$HOME/.gitignore_global"

if [ -f "$HOME/.git_credentials" ]; then
  echo "Keeping existing $HOME/.git_credentials (not overwritten)"
else
  if [ -f "$ROOT_DIR/common/templates/git_credentials" ]; then
    install -m 0600 "$ROOT_DIR/common/templates/git_credentials"    "$HOME/.git_credentials"
    echo "Installed template git_credentials for $USER"
  else
    echo "No template git_credentials found; skipping"
  fi
fi

# === SSH config ===

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

install -m 0600 "$ROOT_DIR/common/templates/ssh/config"         "$HOME/.ssh/config"

# Authorized keys: only install if not already present
if [ -f "$HOME/.ssh/authorized_keys" ]; then
  echo "Keeping existing $HOME/.ssh/authorized_keys (not overwritten)"
else
  if [ -f "$ROOT_DIR/common/templates/authorized_keys" ]; then
    install -m 0600 "$ROOT_DIR/common/templates/authorized_keys" "$HOME/.ssh/authorized_keys"
    echo "Installed template authorized_keys for $USER"
  else
    echo "No template authorized_keys found; skipping"
  fi
fi

source ~/.bashrc

