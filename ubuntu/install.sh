#!/usr/bin/env bash
set -euo pipefail

dotfiles_ubuntu=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=locks/versions.env
source "$dotfiles_ubuntu/locks/versions.env"
dotfiles_packages=1
dotfiles_starship=1
dotfiles_plugins=1
dotfiles_change_shell=0
dotfiles_with_java=0
dotfiles_link_only=0
dotfiles_dry_run=0
dotfiles_target=$HOME

usage() {
  printf '%s\n' \
    '사용법: bash ubuntu/install.sh [옵션]' \
    '  --dry-run           실행 계획만 출력(파일 변경·다운로드 없음)' \
    '  --link-only         apt/Starship/Vim 플러그인 설치 없이 설정만 연결' \
    '  --skip-packages     apt 설치 생략' \
    '  --skip-starship     Starship 설치 생략' \
    '  --skip-vim-plugins  Vim 플러그인 설치 생략' \
    '  --change-shell      현재 계정의 기본 셸을 zsh로 변경' \
    '  --with-java         기본 JDK 추가 설치(최초 환경에는 Java 없음)' \
    '  --target-home DIR   별도 홈에 설정 연결(--link-only와 함께 사용)' \
    '  -h, --help          도움말'
}
while (($#)); do
  case "$1" in
    --dry-run) dotfiles_dry_run=1; shift ;;
    --link-only) dotfiles_link_only=1; dotfiles_packages=0; dotfiles_starship=0; dotfiles_plugins=0; shift ;;
    --skip-packages) dotfiles_packages=0; shift ;;
    --skip-starship) dotfiles_starship=0; shift ;;
    --skip-vim-plugins) dotfiles_plugins=0; shift ;;
    --change-shell) dotfiles_change_shell=1; shift ;;
    --with-java) dotfiles_with_java=1; shift ;;
    --target-home) dotfiles_target=${2:?--target-home 경로가 필요합니다}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf '알 수 없는 옵션: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
[[ $dotfiles_target == /* && $dotfiles_target != / ]] || { printf '대상 홈 경로를 확인하세요.\n' >&2; exit 2; }
dotfiles_target=$(realpath -m -- "$dotfiles_target")
[[ $dotfiles_target != / ]] || { printf '루트 디렉터리는 대상 홈으로 사용할 수 없습니다.\n' >&2; exit 2; }
if [[ $dotfiles_target != "$HOME" && $dotfiles_link_only != 1 ]]; then
  printf '--target-home은 --link-only와 함께 사용하세요.\n' >&2; exit 2
fi
if ((dotfiles_link_only && (dotfiles_change_shell || dotfiles_with_java))); then
  printf '--link-only와 --change-shell/--with-java는 함께 사용할 수 없습니다.\n' >&2; exit 2
fi

# shellcheck disable=SC1091
source /etc/os-release
if ((dotfiles_packages)); then
  [[ $ID == ubuntu ]] || { printf '패키지 자동 설치는 Ubuntu용입니다. --link-only를 사용하세요.\n' >&2; exit 1; }
  [[ ${VERSION_ID%%.*} -ge 24 ]] || { printf '패키지 자동 설치는 Ubuntu 24.04 이상을 대상으로 합니다.\n' >&2; exit 1; }
fi
mapfile -t dotfiles_apt < <(awk 'NF && $1 !~ /^#/ {print $1}' "$dotfiles_ubuntu/packages/apt.txt")
((dotfiles_with_java)) && dotfiles_apt+=(default-jdk)

if ((dotfiles_dry_run)); then
  ((dotfiles_packages)) && printf 'apt 설치 예정: %s\n' "${dotfiles_apt[*]}"
  ((dotfiles_starship)) && printf 'Starship: v%s, 필요하면 ~/.local/bin에 설치\n' "$STARSHIP_VERSION"
  ((dotfiles_plugins)) && printf 'Vim: 고정된 vim-plug/플러그인 커밋, npm ci로 설치\n'
  ((dotfiles_change_shell)) && printf '기본 셸: zsh로 변경 예정\n'
  bash "$dotfiles_ubuntu/scripts/deploy.sh" link --target-home "$dotfiles_target" --dry-run
  exit 0
fi

if [[ $EUID == 0 ]]; then
  printf 'root 대신 설정을 사용할 일반 사용자로 실행하세요(sudo는 apt 단계에서만 사용).\n' >&2
  exit 1
fi
if ((dotfiles_packages)); then
  printf 'Ubuntu 패키지를 설치합니다. sudo 비밀번호는 이 터미널에 직접 입력하세요.\n'
  sudo apt-get update
  sudo apt-get install -y "${dotfiles_apt[@]}"
  sudo locale-gen ko_KR.UTF-8
fi

dotfiles_tmp=$(mktemp -d -t dotfiles-install.XXXXXXXX)
cleanup() {
  [[ $dotfiles_tmp == /tmp/dotfiles-install.* || $dotfiles_tmp == "${TMPDIR:-/tmp}"/dotfiles-install.* ]] && rm -rf -- "$dotfiles_tmp"
}
trap cleanup EXIT
if ((dotfiles_starship)); then
  if command -v starship >/dev/null 2>&1; then
    printf '기존 Starship 사용: %s\n' "$(starship --version | head -1)"
  else
    mkdir -p -- "$dotfiles_target/.local/bin"
    curl -fsSL --retry 3 https://starship.rs/install.sh -o "$dotfiles_tmp/starship-install.sh"
    sh "$dotfiles_tmp/starship-install.sh" --yes --version "v$STARSHIP_VERSION" --bin-dir "$dotfiles_target/.local/bin"
  fi
fi

bash "$dotfiles_ubuntu/scripts/deploy.sh" link --target-home "$dotfiles_target"
if ((dotfiles_plugins)); then
  for dotfiles_cmd in vim git curl npm node; do
    command -v "$dotfiles_cmd" >/dev/null 2>&1 || { printf '필요한 프로그램 없음: %s\n' "$dotfiles_cmd" >&2; exit 1; }
  done
  dotfiles_autoload="$dotfiles_target/.vim/autoload/plug.vim"
  mkdir -p -- "$(dirname -- "$dotfiles_autoload")"
  curl -fsSL --retry 3 "https://raw.githubusercontent.com/junegunn/vim-plug/$VIM_PLUG_COMMIT/plug.vim" -o "$dotfiles_tmp/plug.vim"
  printf '%s  %s\n' "$VIM_PLUG_SHA256" "$dotfiles_tmp/plug.vim" | sha256sum -c -
  if [[ -e $dotfiles_autoload ]] && ! cmp -s "$dotfiles_tmp/plug.vim" "$dotfiles_autoload"; then
    cp -a -- "$dotfiles_autoload" "$dotfiles_autoload.before-dotfiles.$(date -u +%Y%m%dT%H%M%SZ)"
  fi
  cp -- "$dotfiles_tmp/plug.vim" "$dotfiles_autoload"
  vim -Nu "$dotfiles_target/.vimrc" -i NONE -n -es -V1"$dotfiles_tmp/vim-install.log" +'PlugInstall! --sync' +qa || {
    tail -60 "$dotfiles_tmp/vim-install.log" >&2; exit 1;
  }
  while IFS=$'\t' read -r dotfiles_repo dotfiles_commit; do
    [[ -n $dotfiles_repo && $dotfiles_repo != \#* ]] || continue
    dotfiles_plugin="$dotfiles_target/.vim/plugged/${dotfiles_repo##*/}"
    [[ $(git -C "$dotfiles_plugin" rev-parse HEAD) == "$dotfiles_commit" ]] || {
      printf '플러그인 커밋 불일치: %s\n' "$dotfiles_repo" >&2; exit 1;
    }
  done < "$dotfiles_ubuntu/locks/vim-plugins.tsv"
  # PlugInstall이 일부 빌드 오류를 성공 코드로 반환하는 경우도 확인합니다.
  npm ls --omit=dev --prefix "$dotfiles_target/.vim/plugged/markdown-preview.nvim/app" >/dev/null
fi

if ((dotfiles_change_shell)); then
  dotfiles_zsh=$(command -v zsh)
  if [[ $(getent passwd "$(id -un)" | cut -d: -f7) != "$dotfiles_zsh" ]]; then
    chsh -s "$dotfiles_zsh"
  fi
fi
printf '\n완료. 새 터미널을 열거나 zsh에서 source ~/.zshrc 를 실행하세요.\n'
printf 'tmux의 기존 세션에는 Ctrl+b r 로 설정을 적용하세요.\n'
printf 'Git 사용자 정보와 WSL 글꼴 설정은 README의 복원 절차를 확인하세요.\n'
