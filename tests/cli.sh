#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script="$script_dir/shutdown-notify.sh"

help_output=$(bash "$script" --help)
[[ "$help_output" == *'Usage:'* && "$help_output" == *'uninstall'* ]]

if bash "$script" > /dev/null 2>&1; then
    printf 'Missing command unexpectedly succeeded\n' >&2
    exit 1
fi

if bash "$script" unexpected > /dev/null 2>&1; then
    printf 'Unknown command unexpectedly succeeded\n' >&2
    exit 1
fi
