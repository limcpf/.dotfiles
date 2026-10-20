#!/usr/bin/env bash
# 네트워크를 사용해 임시 디렉터리에 플러그인과 npm 의존성을 새로 설치합니다.
set -euo pipefail
dotfiles_ubuntu=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
source "$dotfiles_ubuntu/locks/versions.env"
dotfiles_tmp=$(mktemp -d -t dotfiles-vim-test.XXXXXXXX)
trap '[[ $dotfiles_tmp == /tmp/dotfiles-vim-test.* || $dotfiles_tmp == "${TMPDIR:-/tmp}"/dotfiles-vim-test.* ]] && rm -rf -- "$dotfiles_tmp"' EXIT
mkdir -p -- "$dotfiles_tmp/vim/autoload"
curl -fsSL --retry 3 "https://raw.githubusercontent.com/junegunn/vim-plug/$VIM_PLUG_COMMIT/plug.vim" -o "$dotfiles_tmp/vim/autoload/plug.vim"
printf '%s  %s\n' "$VIM_PLUG_SHA256" "$dotfiles_tmp/vim/autoload/plug.vim" | sha256sum -c -
vim --cmd "let g:dotfiles_vim_home = '$dotfiles_tmp/vim'" \
  -Nu "$dotfiles_ubuntu/config/vim/.vimrc" -i NONE -n -es \
  -V1"$dotfiles_tmp/install.log" +'PlugInstall! --sync' +qa || {
  tail -70 "$dotfiles_tmp/install.log" >&2; exit 1;
}
while IFS=$'\t' read -r dotfiles_repo dotfiles_commit; do
  [[ -n $dotfiles_repo && $dotfiles_repo != \#* ]] || continue
  dotfiles_plugin="$dotfiles_tmp/vim/plugged/${dotfiles_repo##*/}"
  [[ $(git -C "$dotfiles_plugin" rev-parse HEAD) == "$dotfiles_commit" ]]
done < "$dotfiles_ubuntu/locks/vim-plugins.tsv"
npm ls --omit=dev --prefix "$dotfiles_tmp/vim/plugged/markdown-preview.nvim/app"
cmp "$dotfiles_ubuntu/locks/markdown-preview-package-lock.json" \
  "$dotfiles_tmp/vim/plugged/markdown-preview.nvim/app/package-lock.json"
vim --cmd "let g:dotfiles_vim_home = '$dotfiles_tmp/vim'" \
  -Nu "$dotfiles_ubuntu/config/vim/.vimrc" -i NONE -n -es \
  -V1"$dotfiles_tmp/check.log" -S "$dotfiles_ubuntu/scripts/check.vim" || {
  tail -70 "$dotfiles_tmp/check.log" >&2; exit 1;
}
printf '신규 Vim 플러그인 설치·고정 커밋·npm 잠금 파일·Markdown 편집 기능 검증: 정상\n'
