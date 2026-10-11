#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

# shellcheck disable=SC1090
source "$script_dir/shutdown-notify.sh"

SCHEDULED_FILE="$test_dir/scheduled"
printf 'USEC=7500000000\nMODE=poweroff\n' > "$SCHEDULED_FILE"

date() {
    if [[ "$1" == '+%s%6N' ]]; then printf '0\n'; else command date "$@"; fi
}

notify-send() {
    printf '42\n'
}

busctl() {
    printf '%s\n' "$*" >> "$test_dir/busctl.log"
    return 1  # A dismissed notification may already be gone.
}

(
    polls=0
    # shellcheck disable=SC2317
    sleep() {
        ((polls += 1))
        if (( polls == 1 )); then
            rm "$SCHEDULED_FILE"
        elif (( polls >= 3 )); then
            exit 0
        fi
    }
    run
)

[[ $(wc -l < "$test_dir/busctl.log") -eq 1 ]]
grep -qx -- '--user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications CloseNotification u 42' "$test_dir/busctl.log"
