#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

test_home="$test_dir/home"
mkdir -p "$test_home" "$test_dir/bin"

cat > "$test_dir/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SYSTEMCTL_LOG"
EOF
chmod +x "$test_dir/bin/systemctl"

export HOME="$test_home" PATH="$test_dir/bin:$PATH" SYSTEMCTL_LOG="$test_dir/systemctl.log"
bash "$script_dir/shutdown-notify.sh" install

installed_script="$test_home/.local/bin/shutdown-notify.sh"
installed_service="$test_home/.config/systemd/user/shutdown-notify.service"
cmp -s "$script_dir/shutdown-notify.sh" "$installed_script"
[[ -x "$installed_script" && -f "$installed_service" ]]
grep -qx -- '--user enable shutdown-notify.service' "$SYSTEMCTL_LOG"
grep -qx -- '--user restart shutdown-notify.service' "$SYSTEMCTL_LOG"

bash "$script_dir/shutdown-notify.sh" uninstall
[[ ! -e "$installed_script" && ! -e "$installed_service" ]]
grep -qx -- '--user disable --now shutdown-notify.service' "$SYSTEMCTL_LOG"
