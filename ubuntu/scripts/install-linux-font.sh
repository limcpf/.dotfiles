#!/usr/bin/env bash
# 일반 Ubuntu 데스크톱용. WSL의 Windows Terminal에는 wsl/install-nerd-font.ps1을 사용하세요.
set -euo pipefail
dotfiles_ubuntu=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
source "$dotfiles_ubuntu/locks/versions.env"
for dotfiles_cmd in curl python3 fc-cache; do
  command -v "$dotfiles_cmd" >/dev/null || { printf '필요한 프로그램: %s (python3/fontconfig 패키지 확인)\n' "$dotfiles_cmd" >&2; exit 1; }
done
dotfiles_tmp=$(mktemp -d -t dotfiles-font.XXXXXXXX)
trap '[[ $dotfiles_tmp == /tmp/dotfiles-font.* || $dotfiles_tmp == "${TMPDIR:-/tmp}"/dotfiles-font.* ]] && rm -rf -- "$dotfiles_tmp"' EXIT
curl -fL --retry 3 "https://github.com/ryanoasis/nerd-fonts/releases/download/v$NERD_FONTS_VERSION/$NERD_FONTS_ARCHIVE" -o "$dotfiles_tmp/font.zip"
printf '%s  %s\n' "$NERD_FONTS_SHA256" "$dotfiles_tmp/font.zip" | sha256sum -c -
python3 -m zipfile -e "$dotfiles_tmp/font.zip" "$dotfiles_tmp/font"
dotfiles_font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/CaskaydiaCoveNerdFont"
mkdir -p -- "$dotfiles_font_dir"
find "$dotfiles_tmp/font" -type f -name '*.ttf' -exec cp -- {} "$dotfiles_font_dir/" \;
fc-cache -f "$dotfiles_font_dir"
printf '설치 완료. 터미널 글꼴을 CaskaydiaCove Nerd Font Mono로 선택하세요.\n'
