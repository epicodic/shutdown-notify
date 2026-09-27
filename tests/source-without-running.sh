#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output=$(bash -c 'source "$1"; printf "sourced\n"' _ "$script_dir/shutdown-notify.sh")
[[ "$output" == sourced ]]
