#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
log_file="$test_dir/notify-send.log"

notify-send() {
    printf '<%s>' "$@" >> "$log_file"
    printf '\n' >> "$log_file"
    printf '42\n'
}

# Load the functions without running the script's command dispatcher.
# shellcheck disable=SC1090
source <(sed '$d' "$script_dir/shutdown-notify.sh")

notify 'First countdown' '5 minutes left'
notify 'Second countdown' '4 minutes left'

mapfile -t calls < "$log_file"
[[ ${#calls[@]} -eq 2 ]]
[[ ${calls[0]} == *'<--print-id>'* ]]
[[ ${calls[0]} != *'<--replace-id='* ]]
[[ ${calls[1]} == *'<--print-id>'* ]]
[[ ${calls[1]} == *'<--replace-id=42>'* ]]
