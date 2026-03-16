# shutdown-notify

Desktop notifications for scheduled system shutdown/reboot on Linux systems using systemd.

This project runs a small background script in your user session. It watches
`/run/systemd/shutdown/scheduled` and sends desktop notifications with
`notify-send`:

- hourly while shutdown is more than 5 minutes away
- every minute during the final 5 minutes

## Files

- `shutdown-notify.sh` - main script with subcommands: `install`, `uninstall`, `status`, `run`, `help`

## Requirements

- Linux with `systemd --user` support
- A graphical desktop session (notifications are sent to your user session)
- `notify-send` (usually provided by `libnotify` / `libnotify-bin`)

### Install notify-send (if needed)

Debian/Ubuntu:

```bash
sudo apt install libnotify-bin
```

Fedora:

```bash
sudo dnf install libnotify
```

Arch Linux:

```bash
sudo pacman -S libnotify
```

## Installation

Download shutdown-notify.sh and run the install command:

```bash
chmod +x shutdown-notify.sh
./shutdown-notify.sh install
```

The installer will:

1. Copy `shutdown-notify.sh` to `$HOME/.local/bin/`
2. Make it executable
3. Write `shutdown-notify.service` to `$HOME/.config/systemd/user/`
4. Enable and start the user service (`systemctl --user enable --now`)

## Usage

After installation, schedule a shutdown or reboot as usual.

Examples:

```bash
# Shutdown in 2 hours
sudo shutdown -h +120

# Reboot in 15 minutes
sudo shutdown -r +15
```

When a shutdown is scheduled, you should see desktop notifications.

## Check service status

```bash
./shutdown-notify.sh status
```

## Uninstall

```bash
./shutdown-notify.sh uninstall
```


## Troubleshooting

- No notifications appear:
  - Ensure you are in a graphical session.
  - Verify `notify-send` is installed.
  - Check service status `./shutdown-notify.sh status`.
- Service not running after reboot/login:
  - Check whether user services are enabled and running in your session.
- Notifications stop after cancelling shutdown:
  - This is expected; the script resets when no shutdown is scheduled.

## License

Add a license file if you plan to publish this project.
