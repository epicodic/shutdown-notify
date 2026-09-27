#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

test_home="$test_dir/home"
mkdir -p "$test_home/.local/bin" "$test_dir/bin"
installed_script="$test_home/.local/bin/shutdown-notify.sh"
cp "$script_dir/shutdown-notify.sh" "$installed_script"
chmod +x "$installed_script"

cat > "$test_dir/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$test_dir/bin/systemctl"

HOME="$test_home" PATH="$test_dir/bin:$PATH" "$installed_script" install
[[ -x "$installed_script" ]]
[[ -f "$test_home/.config/systemd/user/shutdown-notify.service" ]]
