#!/bin/sh
set -eu
naiyou_root=${1:-${CODEX_HOME:-"$HOME/.codex"}}
naiyou_target="$naiyou_root/pets/naiyou-community"
if [ ! -f "$naiyou_target/.naiyou-package" ]; then printf 'Naiyou is not installed by this package.\n'; exit 0; fi
if [ "$(cat "$naiyou_target/.naiyou-package")" != 'naiyou-codex-v1' ]; then printf 'Unexpected ownership marker.\n' >&2; exit 1; fi
naiyou_backup="$naiyou_root/naiyou-backups/uninstall-$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$naiyou_backup"
for naiyou_file in pet.json spritesheet.png .naiyou-package; do
  if [ -f "$naiyou_target/$naiyou_file" ]; then
    cp "$naiyou_target/$naiyou_file" "$naiyou_backup/$naiyou_file"
    rm -- "$naiyou_target/$naiyou_file"
  fi
done
rmdir "$naiyou_target" 2>/dev/null || true
printf 'Uninstalled. Backup: %s\nRefresh Codex pet settings.\n' "$naiyou_backup"

