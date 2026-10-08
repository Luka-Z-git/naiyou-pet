#!/bin/sh
set -eu
naiyou_source=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
naiyou_root=${1:-${CODEX_HOME:-"$HOME/.codex"}}
naiyou_target="$naiyou_root/pets/naiyou-community"
if [ -e "$naiyou_target" ] && { [ ! -f "$naiyou_target/.naiyou-package" ] || [ "$(cat "$naiyou_target/.naiyou-package")" != 'naiyou-codex-v1' ]; }; then
  printf 'Existing directory is not owned by this installer: %s\n' "$naiyou_target" >&2
  exit 1
fi
if [ -d "$naiyou_target" ]; then
  naiyou_backup="$naiyou_root/naiyou-backups/$(date +%Y%m%d-%H%M%S)-$$"
  mkdir -p "$naiyou_backup"
  for naiyou_file in pet.json spritesheet.png .naiyou-package; do
    [ ! -f "$naiyou_target/$naiyou_file" ] || cp "$naiyou_target/$naiyou_file" "$naiyou_backup/$naiyou_file"
  done
fi
mkdir -p "$naiyou_target"
cp "$naiyou_source/pet/pet.json" "$naiyou_target/pet.json"
cp "$naiyou_source/pet/spritesheet.png" "$naiyou_target/spritesheet.png"
printf 'naiyou-codex-v1' > "$naiyou_target/.naiyou-package"
printf 'Installed: %s\nOpen Codex pet settings, refresh, and select Naiyou.\n' "$naiyou_target"

