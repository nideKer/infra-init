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
