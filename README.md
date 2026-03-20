# lazy-weather

A fast, cached CLI weather tool with fzf interactive city picker and status bar integration.

```
┌─────────────────────────────────────────────────────────┐
│  lazy-weather  Enter:default · ^R:refresh · ^N:new      │
│                ^X:delete · ^U:up · ^D:down · ^O:options  │
├─────────────────────────────────────────────────────────┤
│ ▶ London                  │ London                      │
│   Tokyo                   │ Last updated: 2m ago        │
│   New York                │                             │
│   Paris                   │      \   /  Sunny           │
│   Sydney                  │       .-.   +22°C           │
│   ── Exit ──              │    - (   ) - 14 km/h        │
│                           │       `-'   10 km           │
│                           │      /   \  0.0 mm          │
└─────────────────────────────────────────────────────────┘
```

## Features

- **Multi-city support** — configure a list of cities, pick with fzf
- **Per-city caching** — separate cache file per city with configurable TTL
- **Stale cache fallback** — serves last known data when network is unavailable
- **wttr.in provider** — no API key required, rich ASCII output
- **Mini mode** — one-line output for polybar, i3blocks, waybar
- **Units** — metric (m) or USCS (u) selectable via options menu
- **Forecast days** — 0–3 days configurable via options menu
- **Glyph version** — narrow (aligned) or wide (emoji) output
- **fzf preview** — instant preview using cached data, Ctrl-R to force-refresh
- **Default city** — Enter promotes a city to top; used automatically by `-m`
- **Debug mode** — `--debug` flag for troubleshooting
- **Graceful errors** — clear messages for missing deps and network failures

## Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| `curl`     | ✅ Yes   | Fetch weather data |
| `fzf`      | ✅ Yes   | Interactive city picker |
| `bash 4+`  | ✅ Yes   | Script runtime |

## Installation

### One-line install (curl)

```bash
curl -sSL https://raw.githubusercontent.com/<user>/lazy-weather/main/install.sh | bash
```

### From source

```bash
git clone https://github.com/<user>/lazy-weather.git
cd lazy-weather
bash install.sh
```

### Add to PATH (if needed)

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

```bash
lazy-weather                  # fzf city picker
lazy-weather -c "London"      # direct city lookup
lazy-weather -m               # mini mode — uses top city in config
lazy-weather -c "Tokyo" -m    # mini mode for a specific city
lazy-weather -c "Paris" -r    # force refresh (ignore cache)
lazy-weather --clear-cache    # clear all cached data
lazy-weather -v               # print version
lazy-weather -h               # show help
```

## fzf Keybindings

| Key       | Action |
|-----------|--------|
| `Enter`   | Set highlighted city as default (moves to top of list, saved to config) |
| `Ctrl-R`  | Force-refresh weather for highlighted city, update preview |
| `Ctrl-N`  | Add a new city (saved to config) |
| `Ctrl-X`  | Delete highlighted city (saved to config) |
| `Ctrl-U`  | Move highlighted city one step up (saved to config) |
| `Ctrl-D`  | Move highlighted city one step down (saved to config) |
| `Ctrl-O`  | Open options menu |
| `ESC`     | Quit |

## Options Menu (`Ctrl-O`)

| Option         | Values              | Description |
|----------------|---------------------|-------------|
| Forecast Days  | 0 / 1 / 2 / 3       | Days of forecast shown (0 = current only) |
| Version        | narrow / wide       | narrow uses ASCII-safe glyphs; wide uses Unicode emoji |
| Units          | metric (m) / USCS (u) | Temperature and wind speed units |
| Back to cities | —                   | Return to city picker |

## Status bar integration

The top city in the list (set via `Enter` in the picker) is used when `-m` is called without `-c`.

**polybar:**
```ini
[module/weather]
type = custom/script
exec = lazy-weather -m
interval = 1800
```

**i3blocks:**
```ini
[weather]
command=lazy-weather -m
interval=1800
```

**With explicit city:**
```ini
exec = lazy-weather -c "London" -m
```

## Configuration

Config file: `~/.config/lazy-weather/config`

```ini
# Cities shown in fzf picker (comma-separated, first = default for -m)
CITIES=London,Tokyo,New York,Paris,Sydney

# Cache TTL in seconds (default: 1800 = 30 min)
CACHE_TTL=1800

# Cache directory (default: /tmp)
CACHE_DIR=/tmp

# Mini mode format string (wttr.in format)
# %t=temperature %C=condition %h=humidity %w=wind
MINI_FORMAT=%t %C

# Forecast days: 0=current only, 1–3 days
FORECAST_DAYS=3

# Glyph version: narrow (ASCII-safe) | wide (Unicode emoji)
WTTR_VERSION=narrow

# Units: m=metric (°C, km/h) | u=USCS (°F, mph)
UNITS=m
```

## Project Structure

```
lazy-weather/
├── bin/
│   └── lazy-weather        # main executable
├── lib/
│   ├── cache.sh            # per-city cache with TTL
│   ├── weather.sh          # wttr.in provider
│   ├── config.sh           # config loading and saving
│   ├── ui.sh               # fzf picker and display
│   └── utils.sh            # logging, colors, helpers
├── config/
│   └── default.conf        # bundled defaults
├── tests/
│   ├── test_cache.bats     # cache unit tests
│   ├── test_weather.bats   # weather fetch tests (mocked)
│   └── test_utils.bats     # utility function tests
├── install.sh
├── uninstall.sh
├── README.md
└── .gitignore
```

## Running Tests

Requires [bats-core](https://github.com/bats-core/bats-core):

```bash
# Install bats
git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
/tmp/bats-core/install.sh ~/.local

# Run all tests
bats tests/

# Run individual suite
bats tests/test_weather.bats
```

## License

GPL-3.0 — see [LICENSE](LICENSE)
