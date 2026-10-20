#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Start awww daemon if not running
if ! pgrep -x "awww-daemon" >/dev/null; then
    echo "Starting awww daemon..."
    awww-daemon &
    sleep 0.5
fi

# menu selector
SELECTION=$(
    find "$WALLPAPER_DIR" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) |
    fzf \
        --prompt="Select Theme For Ashton: " \
        --height=40% \
        --layout=reverse \
        --border
)

# Exit if nothing selected
[ -z "$SELECTION" ] && exit 0

# Generate colors FIRST (-n: don't let pywal set the wallpaper, awww does that)
if command -v wal >/dev/null 2>&1; then
    wal -i "$SELECTION" -n -s -q
    pkill -USR1 kitty
echo "file:"; grep -E "^(background|foreground|color2) " ~/.cache/wal/colors-kitty.conf
for sock in /tmp/kitty-*; do
    [ -S "$sock" ] || continue
    echo "$sock:"
    kitten @ --to "unix:$sock" get-colors | grep -E "^(background|foreground|color2) "
done

    # rofi background (first frame for gifs)
    if file --mime-type -b "$SELECTION" | grep -q "gif"; then
        magick "${SELECTION}[0]" /tmp/rofi_bg.png 2>/dev/null
    else
        cp -f "$SELECTION" /tmp/rofi_bg.png 2>/dev/null
    fi

    # Refresh Rofi theme cache
    touch "$HOME/.cache/wal/colors-rofi-dark.rasi"

    # Update Hyprland borders
    hyprctl reload >/dev/null
fi

# Apply wallpaper
awww img "$SELECTION" \
    --transition-type grow \
    --transition-pos center \
    --transition-duration 0.6 \
    --transition-fps 165 &
