#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

# shellcheck disable=SC1090
source "$script_dir/shutdown-notify.sh"

SCHEDULED_FILE="$test_dir/scheduled"
printf 'USEC=7500000000\nMODE=poweroff\n' > "$SCHEDULED_FILE"
# The sourced run function passes this ID to close_notification.
# shellcheck disable=SC2034
notification_id=42

read_scheduled_values() {
    rm "$SCHEDULED_FILE"
    while IFS= read -r _; do :; done < "$SCHEDULED_FILE"
}

busctl() {
    printf '%s\n' "$*" >> "$test_dir/busctl.log"
}

(
    # shellcheck disable=SC2317
    sleep() { exit 0; }
    run
)

grep -qx -- '--user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications CloseNotification u 42' "$test_dir/busctl.log"
