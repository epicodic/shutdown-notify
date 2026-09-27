#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

# Load the functions without running the script's command dispatcher.
# shellcheck disable=SC1090
source <(sed '$d' "$script_dir/shutdown-notify.sh")

export TZ=UTC
SCHEDULED_FILE="$test_dir/scheduled"
printf 'USEC=7500000000\nMODE=poweroff\n' > "$SCHEDULED_FILE"

date() {
    if [[ "$1" == '+%s%6N' ]]; then
        printf '0\n'
    else
        command date "$@"
    fi
}

notify() {
    printf '%s|%s\n' "$1" "$2" >> "$test_dir/notifications"
}

(
    polls=0
    # The sourced run function calls this test replacement for sleep.
    # shellcheck disable=SC2317
    sleep() {
        ((polls += 1))
        if (( polls == 1 )); then
            # Both times have two whole hours remaining.
            printf 'USEC=7800000000\nMODE=poweroff\n' > "$SCHEDULED_FILE"
        else
            exit 0
        fi
    }
    run
)

mapfile -t notifications < "$test_dir/notifications"
[[ ${#notifications[@]} -eq 2 ]]
[[ ${notifications[0]} == *'02:05:00'* ]]
[[ ${notifications[1]} == *'02:10:00'* ]]
