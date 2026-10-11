#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

# shellcheck disable=SC1090
source "$script_dir/shutdown-notify.sh"

SCHEDULED_FILE="$test_dir/scheduled"
printf 'USEC=240000000\nMODE=reboot\n' > "$SCHEDULED_FILE"

date() {
    if [[ "$1" == '+%s%6N' ]]; then printf '0\n'; else command date "$@"; fi
}

notify() {
    printf '%s\n' "$1" > "$test_dir/title"
}

(
    # shellcheck disable=SC2317
    sleep() { exit 0; }
    run
)

grep -q -- 'Reboot in' "$test_dir/title"
