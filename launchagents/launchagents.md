# LaunchAgents Configuration

## Overview

LaunchAgents in macOS are used to automate tasks and services that run on user login.

## Features

- **Automated Keyboard Remapping**: Using `hidutil` for custom key mappings
- **System Service Management**: Control and customize system services
- **Auto-Startup Services**: Configure services to start automatically
- **Symlinked Management**: Individual plist symlinks for safe configuration

## Installation

First, add your `.plist` files to this directory, then run:

```bash
mkdir -p ~/Library/LaunchAgents

for plist in ~/.dotfiles/launchagents/*.plist; do
  [ -f "$plist" ] || continue
  ln -sf "$plist" ~/Library/LaunchAgents/
  launchctl unload "$plist" 2>/dev/null || true
  launchctl load "$plist"
done
```

## Adding Custom LaunchAgents

1. Create a new plist file in `~/.dotfiles/launchagents/`
2. Follow the standard LaunchAgent format:

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.username.servicename</string>
        <key>ProgramArguments</key>
        <array>
            <string>/path/to/executable</string>
            <string>argument1</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
    </plist>
    ```

3. Run the installation commands to link and load the new service
