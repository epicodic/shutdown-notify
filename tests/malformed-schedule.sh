#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

# shellcheck disable=SC1090
source "$script_dir/shutdown-notify.sh"

SCHEDULED_FILE="$test_dir/scheduled"
printf 'USEC=not-a-number\nMODE=poweroff\n' > "$SCHEDULED_FILE"

date() {
    if [[ "$1" == '+%s%6N' ]]; then printf '0\n'; else command date "$@"; fi
}

notify() {
    printf '%s\n' "$2" > "$test_dir/notification"
}

(
    polls=0
    # shellcheck disable=SC2317
    sleep() {
        ((polls += 1))
        if (( polls == 1 )); then
            printf 'USEC=7500000000\nMODE=poweroff\n' > "$SCHEDULED_FILE"
        else
            exit 0
        fi
    }
    run
)

grep -q -- 'Shutdown in' "$test_dir/notification"
