#!/usr/bin/env bash
set -euo pipefail


# this file is written by systemd-logind when a shutdown/reboot is scheduled, e.g. via `shutdown -h +10`
SCHEDULED_FILE="/run/systemd/shutdown/scheduled"
SCRIPT_NAME="shutdown-notify.sh"
SERVICE_NAME="shutdown-notify.service"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
INSTALLED_SCRIPT_PATH="$BIN_DIR/$SCRIPT_NAME"
INSTALLED_SERVICE_PATH="$SYSTEMD_USER_DIR/$SERVICE_NAME"

last_notif_hour=-1
last_notif_min=-1

usage() {
    cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  install      Install script and user service, then enable and start it
  uninstall    Disable service and remove installed files
  status       Show systemd user service status
  run          Run notification polling loop in foreground (usually run by systemd, not manually)
  help         Show this help message
EOF
}

notify() {
    local title="$1" body="$2"
    notify-send -u "critical" -t 15000 "$title" "$body"
}

# Reads the scheduled shutdown info from $SCHEDULED_FILE and updates global variables:
read_scheduled_values() {
    local line key value
    parsed_usec=""
    parsed_mode="shutdown"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        key="${line%%=*}"
        value="${line#*=}"

        case "$key" in
            USEC)
                parsed_usec="$value"
                ;;
            MODE)
                parsed_mode="$value"
                ;;
        esac
    done < "$SCHEDULED_FILE"
}

write_service_file() {
    mkdir -p "$SYSTEMD_USER_DIR"
    cat > "$INSTALLED_SERVICE_PATH" <<EOF
[Unit]
Description=Desktop notifications for scheduled system shutdown
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/shutdown-notify.sh run
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
}

install() {
    mkdir -p "$BIN_DIR"
    cp "$0" "$INSTALLED_SCRIPT_PATH"
    chmod +x "$INSTALLED_SCRIPT_PATH"

    write_service_file

    systemctl --user daemon-reload
    systemctl --user enable --now "$SERVICE_NAME"

    echo "Installed and started $SERVICE_NAME"
}

uninstall() {
    systemctl --user disable --now "$SERVICE_NAME" 2>/dev/null || true
    rm -f "$INSTALLED_SCRIPT_PATH"
    rm -f "$INSTALLED_SERVICE_PATH"
    systemctl --user daemon-reload

    echo "Uninstalled $SERVICE_NAME"
}


status() {
    systemctl --user status "$SERVICE_NAME"
}

run() {
    while true; do
        if [[ -f "$SCHEDULED_FILE" ]]; then
            read_scheduled_values

            if [[ -n "$parsed_usec" ]]; then
                now_usec=$(date +%s%6N)
                remaining_usec=$(( parsed_usec - now_usec ))

                if (( remaining_usec > 0 )); then
                    remaining_sec=$(( remaining_usec / 1000000 ))
                    shutdown_at=$(date -d "@$(( parsed_usec / 1000000 ))" '+%H:%M:%S')

                    if (( remaining_sec <= 300 )); then
                        # Last 5 minutes -> notify each minute
                        current_min=$(( remaining_sec / 60 ))
                        if (( current_min != last_notif_min )); then
                            if (( remaining_sec >= 60 )); then
                                disp="${current_min}m $((remaining_sec % 60))s"
                            else
                                disp="${remaining_sec}s"
                            fi
                            notify \
                                "⚠️  Shutdown in ${disp}!" \
                                "System ${parsed_mode} scheduled at ${shutdown_at}"
                            last_notif_min=$current_min
                            last_notif_hour=-1
                        fi
                    else
                        # More than 5 minutes -> notify each hour
                        current_hour=$(( remaining_sec / 3600 ))
                        if (( current_hour != last_notif_hour )); then
                            h=$(( remaining_sec / 3600 ))
                            m=$(( (remaining_sec % 3600) / 60 ))
                            notify \
                                "🕐  Shutdown scheduled" \
                                "System ${parsed_mode} in ~${h}h ${m}m  (at ${shutdown_at})"
                            last_notif_hour=$current_hour
                            last_notif_min=-1
                        fi
                    fi
                fi
            fi
        else
            # Shutdown cancelled or not scheduled -> reset state
            last_notif_hour=-1
            last_notif_min=-1
        fi

        sleep 20
    done
}

main() {
    case "${1:-}" in
        install)
            install
            ;;
        uninstall)
            uninstall
            ;;
        status)
            status
            ;;
        run)
            run
            ;;
        help|-h|--help)
            usage
            ;;
        "")
            usage
            exit 1
            ;;
        *)
            echo "Unknown command: $1" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"