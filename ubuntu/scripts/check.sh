#!/usr/bin/env bash
# 실제 설정을 별도 셸·Vim·tmux 서버에서 불러와 점검합니다.
set -euo pipefail
dotfiles_ubuntu=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

for dotfiles_script in "$dotfiles_ubuntu/install.sh" "$dotfiles_ubuntu"/scripts/*.sh "$dotfiles_ubuntu"/tests/*.sh; do
  bash -n "$dotfiles_script"
done
zsh -n "$dotfiles_ubuntu/config/zsh/.zshrc"
python3 - "$dotfiles_ubuntu" <<'PY'
import ast
import json
from pathlib import Path
import sys
import tomllib
root = Path(sys.argv[1])
for path in root.rglob('*.json'):
    json.loads(path.read_text(encoding='utf-8'))
for path in root.rglob('*.toml'):
    tomllib.loads(path.read_text(encoding='utf-8'))
ast.parse((root / 'scripts/snapshot.py').read_text(encoding='utf-8'))
print('Bash/zsh/Python/JSON/TOML 문법: 정상')
PY

for dotfiles_cmd in zsh starship fzf zoxide eza batcat tmux vim git node npm; do
  command -v "$dotfiles_cmd" >/dev/null || { printf '설치 안 됨: %s\n' "$dotfiles_cmd" >&2; exit 1; }
done

dotfiles_tmp=$(mktemp -d -t dotfiles-check.XXXXXXXX)
cleanup() {
  tmux -S "$dotfiles_tmp/tmux.sock" kill-server >/dev/null 2>&1 || true
  [[ $dotfiles_tmp == /tmp/dotfiles-check.* || $dotfiles_tmp == "${TMPDIR:-/tmp}"/dotfiles-check.* ]] && rm -rf -- "$dotfiles_tmp"
}
trap cleanup EXIT

mkdir -p -- "$dotfiles_tmp/zsh" "$dotfiles_tmp/cache"
dotfiles_term=${TERM:-xterm-256color}
[[ $dotfiles_term == dumb ]] && dotfiles_term=xterm-256color
TERM="$dotfiles_term" ZDOTDIR="$dotfiles_tmp/zsh" XDG_CACHE_HOME="$dotfiles_tmp/cache" \
  zsh -dfi -c '
    source "$1"
    HISTFILE="$ZDOTDIR/.zsh_history"
    whence -w z zi
    bindkey "^R"
    alias ll cat
  ' dotfiles-check "$dotfiles_ubuntu/config/zsh/.zshrc"
printf 'zsh 초기화와 도구 연결: 정상\n'

TERM="$dotfiles_term" STARSHIP_CONFIG="$dotfiles_ubuntu/config/starship/starship.toml" \
  STARSHIP_CACHE="$dotfiles_tmp/cache" starship explain >/dev/null
eza -lah --git --icons --color=never "$dotfiles_ubuntu" >/dev/null
BAT_THEME=ansi batcat --paging=never --color=never "$dotfiles_ubuntu/../README.md" >/dev/null
printf 'Starship/eza/bat 설정: 정상\n'

# 현재 사용 중인 tmux 서버와 겹치지 않는 전용 소켓을 사용합니다.
tmux -S "$dotfiles_tmp/tmux.sock" -f "$dotfiles_ubuntu/config/tmux/.tmux.conf" \
  new-session -d -s dotfiles-check /bin/sh
tmux -S "$dotfiles_tmp/tmux.sock" show-options -g status-position
tmux -S "$dotfiles_tmp/tmux.sock" show-options -g mouse

# 사용자 파일은 열거나 저장하지 않고 임시 버퍼에서 미리보기와 표 정렬을 확인합니다.
vim -Nu "$dotfiles_ubuntu/config/vim/.vimrc" -i NONE -n -es \
  -V1"$dotfiles_tmp/vim.log" -S "$dotfiles_ubuntu/scripts/check.vim" || {
  tail -60 "$dotfiles_tmp/vim.log" >&2; exit 1;
}
printf 'Vim Markdown/미리보기 명령/단축키/한글 설정/표 정렬: 정상\n'

if command -v powershell.exe >/dev/null 2>&1; then
  dotfiles_windows_file=$(wslpath -w "$dotfiles_ubuntu/wsl/install-nerd-font.ps1")
  printf '%s\n' "$dotfiles_windows_file" | powershell.exe -NoProfile -NonInteractive -Command \
    '[Console]::InputEncoding=[Text.UTF8Encoding]::new($false); [Console]::OutputEncoding=[Text.UTF8Encoding]::new($false); $file=[Console]::In.ReadToEnd().Trim(); $tokens=$null; $parseErrors=$null; [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$parseErrors) | Out-Null; if ($parseErrors.Count) { $parseErrors | ForEach-Object { $_.Message }; exit 1 }; Write-Output "PowerShell 구문: 정상"'
fi
printf '점검 완료. 현재 홈 설정과 실행 중인 tmux 세션은 변경하지 않았습니다.\n'
