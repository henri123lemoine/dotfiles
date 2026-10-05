#!/bin/bash
# Install the Material Darker palette (matching Ghostty/WezTerm) into Spotifast.
# Spotifast ignores symlinked theme files, so this copies rather than links.

set -e

if [[ "$(uname)" == "Darwin" ]]; then
	THEMES_DIR="$HOME/Library/Application Support/me.paolino.spotifast/themes"
else
	THEMES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/spotifast/themes"
fi

mkdir -p "$THEMES_DIR"
cat >"$THEMES_DIR/material-darker.json" <<'JSON'
{
  "base": "dark",
  "colors": {
    "window": "#212121",
    "panel": "#1a1a1a",
    "surface": "#303030",
    "surface_hover": "#353535",
    "surface_active": "#4a4a4a",
    "outline": "#353535",
    "text": "#eeffff",
    "secondary": "#b2ccd6",
    "dim": "#757575",
    "accent": "#82aaff",
    "accent_hover": "#a3c1ff",
    "on_accent": "#212121",
    "danger": "#f07178",
    "warning": "#ffcb6b"
  }
}
JSON

echo "Installed $THEMES_DIR/material-darker.json"
echo "In Spotifast: Settings → Appearance → Theme → material-darker (restart the app if it was open)."
echo "Also turn off the cover-colour option there if you want fixed colors."
