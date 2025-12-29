# NovaDock Theme Guide

Create custom themes to personalize your dock's appearance.

## Theme Structure

A theme is a folder containing a `theme.ini` file:

```
mytheme/
└── theme.ini
```

## Theme File Format

```ini
[Theme]
name=My Custom Theme

[Background]
red=0.15
green=0.15
blue=0.15
alpha=0.75

[Border]
red=1.0
green=1.0
blue=1.0
alpha=0.15

[Indicator]
red=1.0
green=1.0
blue=1.0
alpha=0.9

[Style]
corner_radius=16
border_width=1
```

## Color Values

All color values use RGBA format with values from `0.0` to `1.0`:

| Value | Description |
|-------|-------------|
| `red` | Red component (0.0 - 1.0) |
| `green` | Green component (0.0 - 1.0) |
| `blue` | Blue component (0.0 - 1.0) |
| `alpha` | Transparency (0.0 = transparent, 1.0 = opaque) |

## Sections

### [Theme]
- `name` - Display name shown in settings

### [Background]
Dock panel background color and transparency.

### [Border]
Dock panel border color.

### [Indicator]
Running app indicator dot color.

### [Style]
- `corner_radius` - Rounded corner radius in pixels (default: 16)
- `border_width` - Border thickness in pixels (default: 1)

## Installing Themes

### Method 1: Settings UI
1. Create a zip file of your theme folder
2. Open NovaDock Settings → Appearance
3. Click the folder icon next to Theme dropdown
4. Select your `.zip` file

### Method 2: Manual Installation
Copy your theme folder to:
```
~/.local/share/novadock/themes/
```

## Example Themes

### Transparent Glass
```ini
[Theme]
name=Glass

[Background]
red=0.2
green=0.2
blue=0.2
alpha=0.4

[Border]
red=1.0
green=1.0
blue=1.0
alpha=0.2

[Style]
corner_radius=20
```

### Nord Dark
```ini
[Theme]
name=Nord Dark

[Background]
red=0.18
green=0.20
blue=0.25
alpha=0.9

[Border]
red=0.53
green=0.75
blue=0.82
alpha=0.3

[Indicator]
red=0.53
green=0.75
blue=0.82
alpha=1.0

[Style]
corner_radius=12
border_width=1
```

### Minimal Flat
```ini
[Theme]
name=Minimal

[Background]
red=0.1
green=0.1
blue=0.1
alpha=0.95

[Border]
alpha=0

[Style]
corner_radius=0
border_width=0
```

## Tips

- Use alpha values between 0.6-0.9 for a balanced look
- Lower corner_radius (8-12) for a modern flat look
- Set border alpha to 0 to hide the border completely
- Test your theme with both light and dark wallpapers
