#!/usr/bin/env bash
set -euo pipefail

test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
passed=0

for test_file in "$test_dir"/*.sh; do
    [[ "$test_file" == "$test_dir/run.sh" ]] && continue
    printf 'Running %s ... ' "${test_file##*/}"
    bash "$test_file"
    printf 'passed\n'
    ((passed += 1))
done

printf '%s tests passed\n' "$passed"
