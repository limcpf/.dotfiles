#!/usr/bin/env bash
# 임시 홈에서 미리보기·백업·반복 실행·해제·복원을 검증합니다.
set -euo pipefail
dotfiles_ubuntu=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
dotfiles_tmp=$(mktemp -d -t dotfiles-deploy-test.XXXXXXXX)
trap '[[ $dotfiles_tmp == /tmp/dotfiles-deploy-test.* || $dotfiles_tmp == "${TMPDIR:-/tmp}"/dotfiles-deploy-test.* ]] && rm -rf -- "$dotfiles_tmp"' EXIT
dotfiles_target="$dotfiles_tmp/home with spaces"
mkdir -p -- "$dotfiles_target/.config"
cp -- "$dotfiles_ubuntu/tests/fixtures/.zshrc" "$dotfiles_target/.zshrc"
cp -- "$dotfiles_ubuntu/config/starship/starship.toml" "$dotfiles_target/.config/starship.toml"
ln -s -- "$dotfiles_tmp/missing-tmux-config" "$dotfiles_target/.tmux.conf"

bash "$dotfiles_ubuntu/install.sh" --link-only --target-home "$dotfiles_target" --dry-run > "$dotfiles_tmp/dry-run.log"
[[ ! -e "$dotfiles_target/.vimrc" && ! -e "$dotfiles_target/.local" ]]
[[ ! -L "$dotfiles_target/.zshrc" ]]

bash "$dotfiles_ubuntu/install.sh" --link-only --target-home "$dotfiles_target" > "$dotfiles_tmp/link.log"
for dotfiles_path in .zshrc .vimrc .tmux.conf .config/starship.toml; do
  [[ -L "$dotfiles_target/$dotfiles_path" && -f "$dotfiles_target/$dotfiles_path" ]]
done
dotfiles_backups=("$dotfiles_target/.local/state/dotfiles/backups/"*)
[[ ${#dotfiles_backups[@]} == 1 ]]
dotfiles_backup=${dotfiles_backups[0]}
cmp "$dotfiles_ubuntu/tests/fixtures/.zshrc" "$dotfiles_backup/.zshrc"
[[ -L "$dotfiles_backup/.tmux.conf" && ! -e "$dotfiles_backup/.tmux.conf" ]]

bash "$dotfiles_ubuntu/install.sh" --link-only --target-home "$dotfiles_target" > "$dotfiles_tmp/repeat.log"
dotfiles_backups=("$dotfiles_target/.local/state/dotfiles/backups/"*)
[[ ${#dotfiles_backups[@]} == 1 ]]

# 연결 후 다른 파일로 교체된 대상은 덮어쓰지 않는지 확인합니다.
unlink -- "$dotfiles_target/.vimrc"
cp -- "$dotfiles_ubuntu/tests/fixtures/.zshrc" "$dotfiles_target/.vimrc"
bash "$dotfiles_ubuntu/scripts/deploy.sh" unlink --target-home "$dotfiles_target" --restore "$dotfiles_backup" > "$dotfiles_tmp/restore.log"
cmp "$dotfiles_ubuntu/tests/fixtures/.zshrc" "$dotfiles_target/.zshrc"
cmp "$dotfiles_ubuntu/tests/fixtures/.zshrc" "$dotfiles_target/.vimrc"
cmp "$dotfiles_ubuntu/config/starship/starship.toml" "$dotfiles_target/.config/starship.toml"
[[ $(readlink -- "$dotfiles_target/.tmux.conf") == "$dotfiles_tmp/missing-tmux-config" ]]
[[ -f "$dotfiles_backup/.zshrc" ]]

if bash "$dotfiles_ubuntu/install.sh" --link-only --target-home / --dry-run >/dev/null 2>&1; then
  printf '루트 경로 검증 실패\n' >&2; exit 1
fi
if bash "$dotfiles_ubuntu/install.sh" --link-only --target-home /tmp/.. --dry-run >/dev/null 2>&1; then
  printf '정규화된 루트 경로 검증 실패\n' >&2; exit 1
fi
if bash "$dotfiles_ubuntu/install.sh" --link-only --with-java --dry-run >/dev/null 2>&1; then
  printf '상충하는 옵션 검증 실패\n' >&2; exit 1
fi
printf '배포 검증: 미리보기/백업/재실행/공백 경로/깨진 링크/원본 복원/사용자 변경 보존 정상\n'
