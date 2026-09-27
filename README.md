# shutdown-notify

[![CI](https://github.com/epicodic/shutdown-notify/actions/workflows/ci.yml/badge.svg)](https://github.com/epicodic/shutdown-notify/actions/workflows/ci.yml)

Desktop reminders for scheduled Linux shutdowns and reboots.

`shutdown-notify` runs as a systemd user service and checks the shutdown scheduled by `systemd-logind` every 20 seconds.
It sends an hourly reminder until the final five minutes, then sends a reminder each minute.
New reminders update the previous notification when it is still open.
If the shutdown is cancelled, the service closes its notification.

## Requirements

- Linux with `systemd-logind` and a systemd user session
- A graphical desktop with a notification service
- Bash, GNU `date`, and `busctl` (provided by systemd)
- `notify-send` with `--print-id` and `--replace-id` support (provided by `libnotify-bin` on Debian and Ubuntu, or `libnotify` on Fedora and Arch Linux)

Install `notify-send` if needed:

```bash
# Debian or Ubuntu
sudo apt install libnotify-bin

# Fedora
sudo dnf install libnotify

# Arch Linux
sudo pacman -S libnotify
```

## Install

Download the script, then install the user service without `sudo`:

```bash
curl -fsSLO https://raw.githubusercontent.com/epicodic/shutdown-notify/main/shutdown-notify.sh
chmod +x shutdown-notify.sh
./shutdown-notify.sh install
```

The installer copies the script to `~/.local/bin/`, writes a user service to `~/.config/systemd/user/`, and enables and starts it.
Run `./shutdown-notify.sh install` again after updating the script; the installer restarts an existing service so it uses the new version.

## Use

Schedule a shutdown or reboot as usual:

```bash
sudo shutdown -h +120  # Shut down in two hours
sudo shutdown -r +15   # Reboot in 15 minutes
sudo shutdown -c       # Cancel a scheduled shutdown
```

Hourly reminders use normal urgency.
Reminders during the final five minutes use critical urgency.
The scheduled date appears when shutdown is at least 24 hours away.
Some desktop notification services ignore expiration times, particularly for critical alerts.

Check the service or remove it with:

```bash
./shutdown-notify.sh status
./shutdown-notify.sh uninstall
```

## Troubleshooting

If reminders do not appear, check the user service and its logs:

```bash
systemctl --user status shutdown-notify.service
journalctl --user -u shutdown-notify.service -n 50 --no-pager
notify-send 'Notification test'
```

Make sure you are in a graphical session and that `notify-send` is installed.
The service checks every 20 seconds, so a reminder or cancellation may take up to 20 seconds to appear.

## Development

Run the same checks as [CI](.github/workflows/ci.yml):

```bash
for file in shutdown-notify.sh tests/*.sh; do bash -n "$file"; done
shellcheck shutdown-notify.sh tests/*.sh
bash tests/run.sh
```

The tests use temporary directories and stub system commands; they do not schedule a real shutdown.

## License

[MIT](LICENSE) © 2026 epicodic.
