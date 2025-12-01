#!/usr/bin/env bash
set -e

# Add user to group if group exists and user not already in it
add_user_to_group_if_needed() {
  local user="$1"
  local group="$2"

  # IF the group does not exist, do nothing
  if ! getent group "$group" >/dev/null 2>&1; then
    return 0
  fi

  # If the user is already in the group, do nothing
  if id -nG "$user" | grep -qw "$group"; then
    return 0
  fi

  usermod -aG "$group" "$user"
  echo
  echo "Added $user to group $group (relogin needed)."
  echo
}

# Set system timezone
set_timezone() {
  local TZ_NAME="Europe/Kyiv"

  echo
  echo "Configuring timezone: $TZ_NAME"

  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl set-timezone "$TZ_NAME"
	# Enable NTP, but don't fail if something goes wrong
    timedatectl set-ntp true || true
  else
	# Fallback for older systems without systemd
    if [ -f "/usr/share/zoneinfo/$TZ_NAME" ]; then
      ln -sf "/usr/share/zoneinfo/$TZ_NAME" /etc/localtime
      echo "$TZ_NAME" > /etc/timezone
    else
      echo "Timezone file /usr/share/zoneinfo/$TZ_NAME not found, skipping..."
    fi
  fi
  echo "Current timezone settings:"
  timedatectl status || true
  echo
}