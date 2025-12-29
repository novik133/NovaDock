# NovaDock Plugin Guide

Create custom plugins to add functionality to your dock.

## Plugin Types

NovaDock supports two types of plugins:

1. **Launcher** - Buttons that run a command when clicked
2. **Widget** - Display dynamic content like clock, system info, etc.

## Plugin Structure

A plugin is a folder containing a `plugin.ini` file:

```
myplugin/
├── plugin.ini
└── script.sh (optional)
```

## Plugin File Format

### Launcher Plugin
```ini
[Plugin]
id=myplugin
name=My Plugin
icon=application-x-executable
command=xdg-open https://example.com
```

### Widget Plugin (Clock)
```ini
[Plugin]
id=clock
name=Clock
type=widget
format=%H:%M
interval=1
```

### Widget Plugin (Script Output)
```ini
[Plugin]
id=cpu-usage
name=CPU
type=widget
script=cpu.sh
interval=2
```

## Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier (lowercase, no spaces) |
| `name` | Yes | Display name shown in settings |
| `type` | No | `launcher` (default) or `widget` |
| `icon` | Launcher | Icon name or path |
| `command` | No | Command to run when clicked |
| `format` | Widget | Date/time format string (uses strftime) |
| `script` | Widget | Script that outputs text to display |
| `interval` | Widget | Update interval in seconds (default: 1) |

## Widget Format Strings

For clock/date widgets, use strftime format codes:

| Code | Output |
|------|--------|
| `%H` | Hour (24h) |
| `%I` | Hour (12h) |
| `%M` | Minute |
| `%S` | Second |
| `%p` | AM/PM |
| `%a` | Weekday (short) |
| `%A` | Weekday (full) |
| `%d` | Day of month |
| `%m` | Month number |
| `%b` | Month (short) |
| `%B` | Month (full) |
| `%Y` | Year |

Examples:
- `%H:%M` → 14:30
- `%I:%M %p` → 02:30 PM
- `%a %d` → Mon 29
- `%d/%m` → 29/12

## Installing Plugins

### Method 1: Settings UI
1. Create a zip file of your plugin folder
2. Open NovaDock Settings → Plugins
3. Click "Install Plugin..."
4. Select your `.zip` file
5. Enable the plugin with the toggle switch
6. Click Save

### Method 2: Manual Installation
Copy your plugin folder to:
```
~/.local/share/novadock/plugins/
```

## Example Plugins

### Clock
```ini
[Plugin]
id=clock
name=Clock
type=widget
format=%H:%M
interval=1
command=gnome-clocks
```

### Date
```ini
[Plugin]
id=date
name=Date
type=widget
format=%a %d
interval=60
```

### CPU Usage
`plugin.ini`:
```ini
[Plugin]
id=cpu
name=CPU
type=widget
script=cpu.sh
interval=2
command=xfce4-taskmanager
```

`cpu.sh`:
```bash
#!/bin/bash
top -bn1 | grep "Cpu(s)" | awk '{print int($2)}%'
```

### Memory Usage
`plugin.ini`:
```ini
[Plugin]
id=mem
name=RAM
type=widget
script=mem.sh
interval=5
```

`mem.sh`:
```bash
#!/bin/bash
free | awk '/Mem:/ {printf "%.0f%%", $3/$2 * 100}'
```

### Battery
`plugin.ini`:
```ini
[Plugin]
id=battery
name=Battery
type=widget
script=battery.sh
interval=30
```

`battery.sh`:
```bash
#!/bin/bash
cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "AC"
```

### Web Launcher
```ini
[Plugin]
id=web
name=Website
icon=web-browser
command=xdg-open https://example.com
```

### Terminal
```ini
[Plugin]
id=terminal
name=Terminal
icon=utilities-terminal
command=xfce4-terminal
```

## Creating a Plugin Package

```bash
# Create plugin folder
mkdir clock
cd clock

# Create plugin.ini
cat > plugin.ini << EOF
[Plugin]
id=clock
name=Clock
type=widget
format=%H:%M
interval=1
EOF

# Create zip package
cd ..
zip -r clock.zip clock/
```

## Tips

- Widget text scales with dock icon size
- Use short text for widgets (4-6 characters ideal)
- For scripts, always add `#!/bin/bash` at the top
- Make scripts executable with `chmod +x`
- Set appropriate intervals (don't update too frequently)
- Restart NovaDock after installing plugins

## Plugin Location

Installed plugins are stored in:
```
~/.local/share/novadock/plugins/
```
