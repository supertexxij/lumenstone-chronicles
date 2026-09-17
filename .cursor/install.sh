#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the Lumenstone Chronicles Godot 4.3 project.
# Downloads the Godot 4.3 editor + export templates, installs a software Vulkan
# driver (so the Forward+ renderer works without a GPU), and imports assets.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GODOT_DIR="$REPO_ROOT/tools/godot"
GODOT_BIN="$GODOT_DIR/Godot_v4.3-stable_linux.x86_64"
GODOT_ZIP_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
TEMPLATES_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz"
TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/4.3.stable"

# 1) Software Vulkan (Mesa lavapipe) so Godot's default Forward+ renderer can run
#    on this GPU-less VM. Harmless no-op when already present.
if [ ! -f /usr/share/vulkan/icd.d/lvp_icd.json ] && command -v sudo >/dev/null 2>&1; then
  echo "[install] Installing software Vulkan driver (mesa-vulkan-drivers)..."
  sudo apt-get update -q || true
  sudo apt-get install -y -q mesa-vulkan-drivers vulkan-tools || true
fi

# 2) Godot 4.3 editor/headless binary (repo-ignored; fetched on demand).
mkdir -p "$GODOT_DIR"
if [ ! -x "$GODOT_BIN" ]; then
  echo "[install] Downloading Godot 4.3 editor..."
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/godot.zip" "$GODOT_ZIP_URL"
  unzip -o -q "$tmp/godot.zip" -d "$GODOT_DIR"
  rm -rf "$tmp"
fi
chmod +x "$GODOT_BIN"
ln -sf "Godot_v4.3-stable_linux.x86_64" "$GODOT_DIR/godot"

# 3) Export templates (used by the documented Linux/Windows re-export flow).
if [ ! -f "$TEMPLATE_DIR/version.txt" ] || ! grep -q "4.3.stable" "$TEMPLATE_DIR/version.txt" 2>/dev/null; then
  echo "[install] Downloading Godot 4.3 export templates (~1 GB)..."
  mkdir -p "$TEMPLATE_DIR"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/templates.tpz" "$TEMPLATES_URL"; then
    unzip -o -q "$tmp/templates.tpz" -d "$tmp"
    cp -f "$tmp/templates/"* "$TEMPLATE_DIR/"
  else
    echo "[install] WARN: export templates download failed; running/testing still works, re-export will not."
  fi
  rm -rf "$tmp"
fi

# 4) Import assets so the first run and headless tests start fast.
echo "[install] Importing project assets..."
"$GODOT_BIN" --headless --path "$REPO_ROOT" --import >/dev/null 2>&1 \
  || "$GODOT_BIN" --headless --path "$REPO_ROOT" --editor --quit >/dev/null 2>&1 \
  || true

echo "[install] Lumenstone Godot 4.3 environment ready."
