#!/bin/bash
# Installs Glance into /Applications:  curl -fsSL https://kaizarraja.github.io/glance/install.sh | bash
set -euo pipefail

URL="${GLANCE_URL:-https://github.com/kaizarraja/glance/releases/latest/download/Glance.zip}"
DEST="/Applications/Glance.app"

if [[ "$(uname)" != "Darwin" ]]; then echo "Glance is a Mac app."; exit 1; fi
major=$(sw_vers -productVersion | cut -d. -f1)
if (( major < 15 )); then echo "Glance needs macOS 15 or later (this Mac has $(sw_vers -productVersion))."; exit 1; fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "› Downloading Glance…"
curl -fL --progress-bar "$URL" -o "$tmp/Glance.zip"
ditto -x -k "$tmp/Glance.zip" "$tmp"
[[ -d "$tmp/Glance.app" ]] || { echo "The download didn't contain Glance.app. Please try again."; exit 1; }

echo "› Installing to /Applications"
pkill -x TasksWidget 2>/dev/null || true
pkill -x TasksWidgetExtension 2>/dev/null || true
# Early builds were called "Tasks Widget" (same app); keep just one copy.
OLD="/Applications/Tasks Widget.app"
if [[ -d "$OLD" ]]; then
  pluginkit -r "$OLD/Contents/PlugIns/TasksWidgetExtension.appex" >/dev/null 2>&1 || true
  rm -rf "$OLD" 2>/dev/null || sudo rm -rf "$OLD"
fi
if [[ -w /Applications ]]; then
  rm -rf "$DEST"; ditto "$tmp/Glance.app" "$DEST"
else
  echo "  (your password is needed to write to /Applications)"
  sudo rm -rf "$DEST"; sudo ditto "$tmp/Glance.app" "$DEST"
fi
# Downloaded with curl, so macOS doesn't quarantine it; clear the flag anyway in case it was set.
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "$DEST" >/dev/null 2>&1 || true
pluginkit -a "$DEST/Contents/PlugIns/TasksWidgetExtension.appex" >/dev/null 2>&1 || true

echo "› Opening Glance"
open "$DEST"
echo "✓ Glance is ready. Sign in with Google to begin."
