#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

# shellcheck disable=SC1090
source "$script_dir/shutdown-notify.sh"

SCHEDULED_FILE="$test_dir/scheduled"
printf 'USEC=360000000\nMODE=poweroff\n' > "$SCHEDULED_FILE"
now_usec=0

date() {
    if [[ "$1" == '+%s%6N' ]]; then printf '%s\n' "$now_usec"; else command date "$@"; fi
}

notify-send() {
    printf '<%s>' "$@" >> "$test_dir/notify-send.log"
    printf '\n' >> "$test_dir/notify-send.log"
    printf '42\n'
}

(
    polls=0
    # shellcheck disable=SC2317
    sleep() {
        ((polls += 1))
        if (( polls == 1 )); then now_usec=60000000; else exit 0; fi
    }
    run
)

mapfile -t calls < "$test_dir/notify-send.log"
[[ ${#calls[@]} -eq 2 ]]
[[ ${calls[0]} == *'<-u><normal>'* ]]
[[ ${calls[1]} == *'<-u><critical>'* ]]
