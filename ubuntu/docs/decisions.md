# 구성 결정과 대화에서 바로잡은 내용

이 문서는 2026-10-19~20에 구성한 환경의 결정 사항을 기록합니다. 대화 원문, 화면의 프로젝트 경로, 개인 이름·이메일은 공개하지 않습니다. 실제 적용 전 설정값은 `snapshots/initial-home/`에 별도로 보관하며 주석은 한국어로 통일했습니다.

## 채택한 구성

- Ubuntu WSL2를 사용하며, 셸을 Bash에서 zsh로 변경했습니다.
- Oh My Zsh 없이 개별 도구를 조합합니다. Starship은 프롬프트를 담당하며 프레임워크의 모든 기능을 대체하는 도구는 아닙니다.
- Starship: 경로·Git 브랜치/변경·Node.js·Java·2초 이상 걸린 명령어의 시간. Python과 시계는 제외했습니다.
- fzf: Ctrl+r 기록 검색, Ctrl+t 파일 삽입, Alt+c 디렉터리 이동.
- zoxide: `z`/`zi`. eza: `ls`/`ll`/`la`. bat: `bat`과 `cat` 별칭.
- 검은 터미널 배경에서 eza의 어두운 파랑이 잘 안 보여 256색 팔레트의 밝은 청록·회색·보라·초록으로 바꿨습니다. bat은 `ansi` 테마를 선택했습니다.
- Windows 사용자 범위에 Cascadia Code Nerd Font를 설치했습니다. 정식 선택 이름은 `CaskaydiaCove Nerd Font Mono`, 릴리스 파일은 `CascadiaCode.zip`입니다.
- tmux: Ctrl+b 유지, 마우스 사용, 1부터 번호, 기록 10,000줄, 밝은 상태 표시줄/활성 테두리, 상태 표시줄 위쪽, Ctrl+b r로 다시 읽기.
- Windows Terminal Ubuntu 프로필은 `main` tmux 세션에 생성/재접속하도록 설정했습니다. 프로필의 실제 색 구성표는 IBM 5153입니다.
- Vim: vim-plug, vim-markdown, tabular, markdown-preview.nvim. 한글 인코딩 감지와 Markdown 작성 편의 설정을 추가했습니다.
- Atuin, zinit, sheldon, Oh My Zsh, Neovim은 현재 구성에 설치하지 않았습니다.
- Java는 표시 설정만 있고 JDK는 아직 없습니다. Node.js/npm은 실제로 설치되어 있습니다.

## 복원용 설정에서 수정한 부분

### Vim 미리보기 키

원본은 `<localleader>p`에 미리보기를 연결했지만 `maplocalleader`를 설정하지 않았고, `mapleader`도 플러그인 초기화 뒤에 설정했습니다. 따라서 안내했던 Space p와 실제 매핑이 달랐습니다. 복원용 파일에서는 두 leader를 처음부터 Space로 선언해 설명과 실제 키를 일치시켰습니다.

### 한글과 맞춤법

원본의 `spelllang=en_us,ko`는 한국어 사전이 설치되어 있다는 뜻이 아닙니다. 현재 `ko` Vim 사전이 없어 경고가 생길 수 있습니다. `en_us,cjk`로 바꿔 영어 검사와 한글 예외를 사용합니다. 한국어 맞춤법 검사 기능을 새로 추가한 것은 아닙니다.

`ambiwidth=double`은 모호한 폭의 문자에 대한 옵션이며, 한글 인코딩을 켜는 옵션이 아닙니다. 현재 값을 보존했으며 터미널과 폭이 맞지 않으면 `single`과 비교할 수 있습니다. `C.UTF-8`도 정상적인 UTF-8 로케일이므로 그 값 자체가 한글 파일명 문제의 증거는 아닙니다.

### Markdown 접기와 입력 매핑

원본의 `g:vim_markdown_folding_disabled=1`에 맞춰 접기는 계속 꺼져 있습니다. 과거 대화의 '접기 지원을 켰다'는 설명은 실제 설정과 달랐습니다. 입력 모드의 쉼표 두 번(`,,`)을 `。`로 바꾸는 매핑도 실제 파일에 있어 보존했습니다.

### zsh의 이식성

Starship이 아직 설치되지 않았을 때도 시작하도록 명령 존재 여부를 확인합니다. 한국어 로케일이 없으면 C.UTF-8로 시작하고, 사용자 바이너리 경로 `~/.local/bin`을 추가합니다. 기존 Bash에만 들어 있던 사용자 바이너리 경로도 zsh에서 사용할 수 있습니다.

fzf는 신버전의 `fzf --zsh`와 배포판 제공 스크립트를 모두 지원합니다. 셸 사이에서 Ctrl+r 기록을 사용할 수 있도록 히스토리 파일과 10,000개 보관을 명시했습니다. 기존 기록 내용은 수집하지 않습니다.

### 외부 의존성 고정

기존 Vim 플러그인의 실제 커밋과 vim-plug SHA256을 확인했습니다. 미리보기 앱에서 생성되었던 `package-lock.json`을 보관하여 새 PC에서는 `npm install` 대신 `npm ci`를 사용합니다. 원본 플러그인 앱에 남은 `yarn.lock` 변경은 inventory에 기록하며 npm 방식 복원에는 사용하지 않습니다.

## 과거 문제와 현재 상태

- 초기 자동 점검은 WSL 홈의 `.aws` 심볼릭 링크와 실행 샌드박스가 충돌해 막혔습니다. 현재 설정 복원과 무관하며 `.aws`를 복사하거나 변경하지 않습니다.
- apt 설치는 자동 실행에서 sudo 인증을 받을 수 없어 사용자가 직접 완료했습니다. 실제 설치 상태는 현재 실행 파일과 dpkg 목록을 다시 조회해 확정했습니다.
- Docker Desktop이 만든 `_docker` 자동완성 심볼릭 링크가 없는 `/mnt/wsl/docker-desktop/...`를 가리켜 compinit 경고가 났습니다. 당시 링크를 정리했고 현재 링크는 없습니다. 재발 시 Docker Desktop WSL 통합을 확인합니다.
- Nerd Font의 처음 다운로드 주소 `CaskaydiaCove.zip`은 404였습니다. 실제 릴리스 이름 `CascadiaCode.zip`으로 설치했습니다.
- 당시 WSL에 unzip이 없었으므로 Windows PowerShell로 38개 TTF를 설치했습니다. 재현 스크립트도 Windows 사용자 범위 설치를 제공합니다.
- tmux 분리는 세션 종료가 아닙니다. Windows Terminal이 tmux를 직접 실행했다면 분리할 때 해당 탭은 닫힐 수 있습니다.
- bat 별칭은 대화형 셸의 파이프라인에서도 확장됩니다. 원래 cat이 필요하면 `command cat`을 사용합니다.

## 공개 저장소에 보관하지 않는 내용

개인 인증 정보, 실제 Git 이름·이메일, Windows/Linux 사용자명과 PC별 GUID, 명령어 기록, zoxide 경로 DB, 프로그램의 인증/세션 파일은 제외합니다. 기존 `.bashrc`와 `.profile`은 설정값 참고용으로 보관하며 자동 배포하지 않습니다. 모든 설명 주석을 한국어로 바꾸고 `.bashrc`에 있었던 절대 사용자 경로는 `$HOME`으로 바꿨습니다. Git 설정은 기본 브랜치와 계정별 예제로만 남깁니다.

추후 Windows 자체의 설정을 추가할 때는 루트 `windows/`에 분리합니다. 현재 `ubuntu/wsl/`은 Ubuntu 터미널을 호스팅하는 Windows 측 의존성을 재현하기 위한 작은 예제 모음입니다.
