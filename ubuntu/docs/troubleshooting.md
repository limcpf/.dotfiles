# 문제 해결

## 한글 파일명이 `$'\354...'`처럼 보임

파일명이 손상됐다고 단정할 수 없습니다. ls가 출력 가능한 문자로 판단하지 못해 이스케이프한 표현일 수 있습니다. `C.UTF-8`도 한글을 표현할 수 있으므로 해당 값만 보고 원인을 결정하지 마세요.

```bash
locale
locale -a
command ls --quoting-style=literal
```

로케일 관련 경고가 있고 한국어 로케일이 없다면:

```bash
sudo apt install -y locales language-pack-ko
sudo locale-gen ko_KR.UTF-8
exec zsh
```

글리프가 네모로 나오면 Windows Terminal의 폰트와 Windows 한글 대체 글꼴도 확인합니다. WSL 안에 폰트만 설치해도 Windows Terminal 글꼴은 바뀌지 않습니다.

## `ll` 또는 `bat` 명령이 없음

```zsh
command -v eza
command -v batcat
source ~/.zshrc
alias ll
alias cat
```

Ubuntu의 bat 패키지는 `batcat` 실행 파일을 제공합니다. eza가 설치되기 전에는 조건부 별칭이 만들어지지 않으므로 설치 후 zsh 설정을 다시 읽어야 합니다.

## zsh의 `_docker` compinit 경고

Docker Desktop WSL 통합용 링크가 있는데 Docker Desktop 마운트가 없는 경우 발생할 수 있습니다.

```bash
ls -l /usr/share/zsh/vendor-completions/_docker
readlink /usr/share/zsh/vendor-completions/_docker
```

Docker를 사용한다면 Docker Desktop을 실행하고 해당 배포판의 WSL Integration을 켭니다. 사용하지 않고 **실제로 깨진 링크일 때만** 아래처럼 숨김 파일로 이동해 비활성화할 수 있습니다. 관리자 권한이 필요하며 원본 링크는 보존됩니다.

```bash
if [ -L /usr/share/zsh/vendor-completions/_docker ] && \
   [ ! -e /usr/share/zsh/vendor-completions/_docker ]; then
  sudo mv -n -- /usr/share/zsh/vendor-completions/_docker \
    /usr/share/zsh/vendor-completions/.docker-completion-disabled
fi
# 자동 생성 캐시만 지웁니다. 명령어 기록은 건드리지 않습니다.
rm -f -- ~/.zcompdump
exec zsh
```

통합 복구 후 Docker Desktop이 링크를 다시 제공할 수 있습니다. 설치 스크립트가 이 시스템 파일을 임의로 지우지는 않습니다.

## fzf 키가 동작하지 않음

`source ~/.zshrc` 후 `bindkey '^R'`로 `fzf-history-widget` 연결을 확인하세요. Alt+c가 터미널 바로가기와 충돌하면 Esc를 누른 다음 c를 눌러 비교할 수 있습니다. 기록이 없다면 Ctrl+r 결과가 비어 있을 수 있습니다.

## Starship에서 Node.js / Java가 안 보임

```bash
node --version
java --version
starship explain
```

해당 런타임이 있고 프로젝트 감지 조건을 만족해야 합니다. Java는 최초 환경에 설치되어 있지 않습니다. `package.json`이나 `pom.xml` 등이 있는 프로젝트에서 확인하세요. 일반 파일 확인을 위해 임의로 프로젝트 파일을 만들 필요는 없습니다.

## bat 색이 어둡거나 페이지가 나타남

기존 설정은 `ansi`라 터미널 ANSI 팔레트를 사용합니다. 테마를 비교하려면:

```bash
batcat --list-themes
batcat --theme='Monokai Extended' README.md
```

원하면 `~/.zshrc.local`에 `export BAT_THEME='Monokai Extended'`를 넣습니다. 긴 파일은 페이저에서 열리며 `q`로 닫습니다. 페이저를 쓰지 않으려면 `bat --paging=never 파일`을 사용합니다.

## Vim 미리보기가 열리지 않음

```bash
node --version
npm --version
bash ubuntu/install.sh --skip-packages --skip-starship
```

이미 플러그인이 설치되어 빌드가 생략된 경우 Vim에서 `:PlugInstall!`로 후처리를 다시 실행할 수 있습니다. `.vimrc`를 저장소 파일 하나만 떼어 복사하면 `locks/` 경로를 찾지 못하므로 저장소를 통째로 복제한 뒤 링크로 연결하세요.

WSL에서 브라우저 열기가 안 되면 미리보기의 `:messages`를 확인합니다. Windows/WSLg의 URL 연결 설정은 PC별입니다. 예를 들어 `wslview`를 별도로 설치했다면 개인 `~/.vimrc.local`에서 `let g:mkdp_browser='wslview'`를 사용할 수 있습니다. 기본 복원 과정에서는 wslu를 추가 설치하지 않습니다.

이 저장소 생성 시 미리보기 npm 의존성에서 **10개(낮음 2, 보통 2, 높음 5, 심각 1)** 경고가 보고되었습니다. 기존 플러그인과 그 의존성을 재현하기 위해 lockfile을 보존했습니다. `npm audit fix --force`로 임의로 바꾸면 호환성이 깨질 수 있으므로 버전 변경을 별도로 검토합니다. 서버를 외부에 공개하도록 설정하지 않았습니다.

## tmux 색상이나 글자 폭이 어긋남

```bash
locale
infocmp tmux-256color
tmux show-options -g default-terminal
```

terminfo가 없으면 `sudo apt install ncurses-term`을 확인합니다. 기존 세션에는 `tmux source-file ~/.tmux.conf`를 실행합니다. `$TERM`을 zshrc에서 강제로 덮어쓰지는 마세요. Vim만 기호 폭이 어긋나면 `:set ambiwidth=single`과 비교합니다.

## apt 버전과 최초 환경이 다름

Ubuntu 릴리스와 CPU가 다르면 정상입니다. `inventory/`는 최초 상태의 기록이며 핵심 도구는 현재 릴리스의 패키지로 복원합니다. 특정 과거 OS/라이브러리까지 정확히 같아야 한다면 별도의 이미지/컨테이너가 필요합니다. Java와 Node의 프로젝트별 버전은 프로젝트 요구 사항에 맞게 관리합니다.
