#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

# shellcheck disable=SC1090
source "$script_dir/shutdown-notify.sh"

export TZ=UTC
SCHEDULED_FILE="$test_dir/scheduled"
printf 'USEC=90000000000\nMODE=poweroff\n' > "$SCHEDULED_FILE"

date() {
    if [[ "$1" == '+%s%6N' ]]; then printf '0\n'; else command date "$@"; fi
}

notify() {
    printf '%s\n' "$2" > "$test_dir/notification"
}

(
    # shellcheck disable=SC2317
    sleep() { exit 0; }
    run
)

grep -q -- '1970-01-02 01:00:00' "$test_dir/notification"
