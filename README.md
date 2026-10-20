# dotfiles

Ubuntu의 터미널과 Markdown 작성 환경을 다른 PC에서도 복원하기 위한 개인 설정 저장소입니다. 2026-10-20까지 구성한 실제 파일과 설치 상태를 기준으로 만들었습니다. 운영체제별로 분리하며, 현재 설정은 모두 `ubuntu/`에 있습니다. 추후 Windows 전용 설정은 루트의 `windows/`로 확장하면 됩니다.

## 현재 환경과 구성

| 항목 | 확인된 상태 |
| --- | --- |
| 운영체제 | Ubuntu 26.04.1 LTS, Resolute Raccoon |
| 실행 환경 | Windows의 WSL2 |
| CPU | ARM64 / aarch64 |
| 커널 | 6.18.54.1-microsoft-standard-WSL2 |
| 기본 셸 | zsh 5.9 |
| 프롬프트 | Starship 1.27.0, 경로·Git·Node.js·Java·실행 시간 |
| 검색 / 디렉터리 이동 | fzf 0.67.0 / zoxide 0.9.8 |
| 파일 목록 / 파일 보기 | eza 0.23.4 / bat 0.25.0 (`batcat`) |
| 세션 관리 | tmux 3.6, 상태 표시줄 위쪽 |
| 편집기 | Vim 9.1 + vim-plug + Markdown 플러그인 3개 |
| Node.js / npm | v22.22.1 / 9.2.0, Ubuntu 패키지 |
| Java | 설치되지 않음. Starship 표시 설정만 준비 |
| 글꼴 / 터미널 테마 | CaskaydiaCove Nerd Font Mono 3.5.1 / IBM 5153 |
| 선택 도구 | Atuin, zinit, sheldon, Oh My Zsh는 설치하지 않음 |

표의 버전은 최초 환경의 **실행 파일 기준**입니다. 예를 들어 apt의 tmux 패키지 버전은 `3.6a-2ubuntu0.1`이지만 `tmux -V` 출력은 `tmux 3.6`입니다. 전체 패키지와 정확한 버전은 [환경 기록](ubuntu/inventory/)을 확인하세요. 시스템 Python은 Ubuntu의 구성 요소로 존재하며, Starship의 Python 표시는 사용하지 않습니다.

## 새 Ubuntu에서 복원

자동 설치 대상은 Ubuntu **24.04 이상**의 ARM64 / x86_64입니다. 실제 검증 환경은 위의 Ubuntu 26.04 WSL2 ARM64이며, 다른 릴리스에서는 apt가 제공하는 버전을 사용합니다. Ubuntu 24.04 및 x86_64 실기기는 아직 검증하지 않았습니다.

먼저 일반 사용자로 실행합니다. `YOUR_GITHUB_USER`는 실제 GitHub 계정명으로 바꾸세요.

```bash
sudo apt update
sudo apt install -y git ca-certificates
mkdir -p ~/dev
git clone https://github.com/YOUR_GITHUB_USER/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# 파일 변경 없이 실행 계획 확인
bash ubuntu/install.sh --dry-run

# 패키지 + 한국어 로케일 + Starship + 설정 + Vim 플러그인
# 마지막에 기본 셸도 zsh로 변경
bash ubuntu/install.sh --change-shell
```

`sudo` 및 `chsh`의 비밀번호는 터미널에 직접 입력합니다. 설치 스크립트 전체를 `sudo bash ...`로 실행하지 마세요. 기본 셸을 이미 zsh로 변경했다면 `--change-shell`은 생략해도 됩니다.

설치가 끝나면 새 터미널을 열거나 `exec zsh`를 실행합니다. 이미 zsh라면 `source ~/.zshrc`로 적용할 수 있습니다. 기존 tmux 세션에는 `Ctrl+b`를 누른 뒤 `r`을 누르거나 `tmux source-file ~/.tmux.conf`를 실행합니다.

설치 옵션:

```bash
# 프로그램이 이미 있다면 설정만 연결
bash ubuntu/install.sh --link-only

# apt만 생략하고 Starship/Vim 설치 및 설정 연결
bash ubuntu/install.sh --skip-packages

# 실제 Java 개발도 할 경우에만 JDK 추가
bash ubuntu/install.sh --with-java --change-shell

bash ubuntu/install.sh --help
```

Java 기본 JDK의 버전은 Ubuntu 릴리스에 따라 달라집니다. 특정 프로젝트가 요구하는 JDK가 있으면 해당 버전을 별도로 설치하세요. Node.js도 최초 환경과 같은 Ubuntu 패키지 방식이며, nvm 등 별도 버전 관리자는 포함하지 않습니다.

Git의 기본 브랜치와 본인 정보를 설정합니다. 기존 `~/.gitconfig`는 자동 교체하지 않습니다.

```bash
git config --global init.defaultBranch main
git config --global user.name "본인 이름"
git config --global user.email "본인 이메일 또는 GitHub noreply 주소"
```

설정 확인:

```bash
bash ubuntu/scripts/check.sh

# 프로그램 설치 없이 배포·백업·복원 동작을 임시 홈에서 검증
bash ubuntu/tests/deploy.sh

# 선택: 네트워크를 사용해 Vim 플러그인을 임시 경로에 새로 설치해 검증
bash ubuntu/tests/vim-install.sh
```

## 파일 배치와 백업

```text
dotfiles/
├── README.md
└── ubuntu/
    ├── install.sh                # Ubuntu 복원 진입점
    ├── links.tsv                 # 원본 → 홈 디렉터리 연결 목록
    ├── config/
    │   ├── zsh/                  # .zshrc와 개인 설정 예제
    │   ├── starship/             # starship.toml
    │   ├── tmux/                 # .tmux.conf
    │   ├── vim/                  # .vimrc
    │   └── git/                  # 사용자 정보 없는 참고 예제
    ├── packages/apt.txt          # 복원할 핵심 apt 패키지
    ├── locks/                    # 도구 버전·체크섬·Vim 커밋·npm lockfile
    ├── inventory/                # 전체 설치 패키지 및 OS/도구 기록
    ├── snapshots/initial-home/   # 생성 전 설정값 보관본, 주석은 한국어
    ├── scripts/                 # 연결·해제·확인·환경 기록·Linux 글꼴 설치
    ├── wsl/                     # WSL용 Windows Terminal/글꼴 예제
    └── docs/                    # 구성 결정, 수정 내역, 문제 해결
```

자동 연결 대상은 아래 네 파일입니다. 저장소를 삭제하거나 이동하면 링크가 끊어지므로, 이동 후에는 새 위치에서 `--link-only`를 다시 실행하세요.

| 저장소 파일 | 적용 위치 |
| --- | --- |
| `ubuntu/config/zsh/.zshrc` | `~/.zshrc` |
| `ubuntu/config/starship/starship.toml` | `~/.config/starship.toml` |
| `ubuntu/config/tmux/.tmux.conf` | `~/.tmux.conf` |
| `ubuntu/config/vim/.vimrc` | `~/.vimrc` |

기존 파일이나 심볼릭 링크가 있으면 `~/.local/state/dotfiles/backups/날짜.고유값/` 아래로 먼저 이동합니다. 이미 올바르게 연결된 파일은 건드리지 않으므로 반복 실행할 수 있습니다. 설치 스크립트가 다운로드하는 vim-plug가 기존 파일과 다르면 `plug.vim.before-dotfiles.날짜`로도 보관합니다.

연결 해제 및 기존 설정 복원:

```bash
# 링크만 해제(설치된 프로그램과 사용 기록은 유지)
bash ubuntu/scripts/deploy.sh unlink

# 출력되었던 실제 백업 경로를 지정하면 원본도 복원
bash ubuntu/scripts/deploy.sh unlink \
  --restore ~/.local/state/dotfiles/backups/실제-백업-디렉터리
```

연결 후 직접 다른 파일로 교체한 대상은 해제/복원 시 덮어쓰지 않습니다. 백업도 남겨둡니다. 여러 번 적용했다면 각 실행의 백업에 그때 교체한 파일만 들어 있다는 점을 확인하세요.

PC별 경로와 환경 변수는 `~/.zshrc.local`, Vim 추가 설정은 `~/.vimrc.local`에 작성합니다. 이 파일들은 저장소에 올리지 않습니다.

## zsh와 파일 도구

`~/.local/bin`을 PATH 앞쪽에 추가하고, 한국어 로케일이 생성되어 있으면 `ko_KR.UTF-8`, 없으면 `C.UTF-8`을 사용합니다. 히스토리는 `~/.zsh_history`에 최대 10,000개를 보관하고 셸 간에 공유합니다. 공백으로 시작하는 명령어는 기록하지 않도록 설정했습니다.

| 명령 / 키 | 동작 |
| --- | --- |
| `Ctrl+r` | fzf로 명령어 기록 검색 |
| `Ctrl+t` | 파일을 찾아 현재 명령줄에 삽입 |
| `Alt+c` | 디렉터리를 검색해 이동 |
| `z backend` | 방문 기록에서 backend와 일치하는 경로로 이동 |
| `zi` | fzf로 zoxide 경로 선택 |
| `ls` | eza로 파일 목록 |
| `ll` | 숨김 파일·상세 정보·Git 상태·아이콘 |
| `la` | 숨김 파일 포함 목록·아이콘 |
| `bat file` / `cat file` | batcat의 문법 강조·줄 번호·페이저 |
| `command cat file` | 별칭을 거치지 않고 원래 cat 실행 |

zoxide는 먼저 `cd`로 방문한 디렉터리를 기억합니다. 새 PC에서 기존 방문 기록이나 명령어 기록이 자동으로 복원되지는 않습니다. 별칭은 대화형 zsh에 적용되며, 그 셸에서 실행하는 파이프라인에도 별칭 자체는 적용됩니다. bat은 출력이 파이프로 연결되면 기본적으로 꾸밈을 줄입니다. 기존 스크립트는 `.zshrc`를 직접 불러오지 않는 한 영향을 받지 않습니다.

검은 배경에서 eza의 디렉터리는 밝은 청록, 일반 파일은 밝은 회색, 링크는 밝은 보라, 실행 파일은 밝은 초록입니다. `--color=always`를 보존했으므로 파일 출력을 다른 명령으로 넘길 때 색 코드가 필요 없다면 `eza --color=never`를 직접 사용하세요. bat은 기존의 `BAT_THEME=ansi`를 유지하며 실제 색상은 터미널의 ANSI 팔레트에 영향을 받습니다.

## Starship

경로 → Git 브랜치/상태 → Node.js → Java → 오래 걸린 명령어 시간 → 다음 줄의 입력 기호 순서입니다. 실행 시간은 2초 이상일 때 표시합니다. Python과 시계 모듈은 표시하지 않습니다.

Node.js와 Java 버전은 해당 실행 파일이 있고 프로젝트 파일 등 표시 조건을 만족할 때만 나옵니다. 아무 디렉터리에서나 항상 나오는 설정은 아닙니다. 현재 Java는 설치하지 않은 상태이며, 나중에 JDK를 설치하면 관련 프로젝트에서 표시됩니다.

## tmux

기본 접두키는 **Ctrl+b**입니다. 한 번 누르고 손을 뗀 뒤 다음 키를 누릅니다.

| 키 / 명령 | 동작 |
| --- | --- |
| `tmux new-session -A -s main` | main 세션 생성 또는 재접속 |
| `Ctrl+b c` | 새 창 |
| `Ctrl+b n` / `Ctrl+b p` | 다음 / 이전 창 |
| `Ctrl+b %` | 좌우 분할 |
| `Ctrl+b "` | 위아래 분할 |
| `Ctrl+b 방향키` | 패널 이동 |
| `Ctrl+b [` | 복사 / 스크롤 모드, `q`로 나가기 |
| `Ctrl+b d` | 세션 분리. 실행 중인 프로그램은 유지 |
| `Ctrl+b r` | 설정 다시 불러오기 |
| `exit` | 현재 패널의 셸 종료. 마지막 패널이면 세션 종료 |

상태 표시줄은 **위쪽**, 현재 패널 테두리는 밝은 청록색입니다. 마우스로 패널 선택·분할 크기 조절·스크롤이 가능하고, 창/패널 번호는 1부터 시작합니다. 스크롤 기록은 패널당 10,000줄입니다. `tmux-256color`와 True Color 설정도 포함합니다.

tmux에는 오래된 `utf8` 옵션을 추가하지 않았습니다. 한글 입력과 표시는 UTF-8 로케일, 터미널 글꼴 및 Windows 입력기를 함께 사용합니다. tmux가 한글 입력기를 설치하거나 전환하는 것은 아닙니다.

## Vim Markdown

설치된 플러그인:

| 플러그인 | 역할 |
| --- | --- |
| [vim-markdown](https://github.com/preservim/vim-markdown) | 문법 강조·헤더 이동·목록 편집 |
| [tabular](https://github.com/godlygeek/tabular) | Markdown 표 정렬 |
| [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) | 브라우저 미리보기. Vim에서도 사용 |

vim-plug와 세 플러그인은 최초 환경에서 확인한 커밋으로 고정했습니다. 미리보기의 npm 의존성도 `ubuntu/locks/markdown-preview-package-lock.json`을 복사한 뒤 `npm ci`로 설치합니다. 바이너리와 `node_modules` 자체는 저장하지 않습니다.

```bash
vim README.md
```

| Vim 일반 모드 명령 / 키 | 동작 |
| --- | --- |
| `Space p` | Markdown 브라우저 미리보기 |
| `:MarkdownPreviewStop` | 미리보기 종료 |
| `Space w` | 저장 |
| `Space q` | 현재 창 종료. 저장하지 않은 변경이 있으면 확인 필요 |
| `Space h` | 검색 강조 제거 |
| `:Tabularize /\|` | 선택한 표 범위에서 세로줄 기준 정렬 |
| `:setlocal nospell` | 현재 파일의 맞춤법 표시 끄기 |

표 정렬 시 표의 여러 줄을 `V`로 선택하고 `:Tabularize /|`를 입력하세요. 이 사용자 명령은 `|`를 그대로 인수로 받습니다. 실제 tabular 동작은 [검증 스크립트](ubuntu/scripts/check.sh)에서도 확인합니다.

UTF-8 저장, UTF-8/EUC-KR/CP949 순서 인코딩 감지, 공백 2칸 들여쓰기, 화면 줄바꿈, 줄 번호와 상대 줄 번호, 현재 줄 강조, 마우스, 대소문자 자동 검색 설정을 포함합니다. Markdown 접기는 현재 설정대로 **꺼져 있습니다**.

한국어 전용 사전을 설치한 것은 아닙니다. 영어 맞춤법 검사와 `cjk` 예외를 사용해 한글을 일괄 오탈자로 표시하지 않도록 했습니다. 원래 `spelllang=en_us,ko`에서 사전 누락 메시지가 날 수 있어 바로잡았습니다. `ambiwidth=double`은 애매한 폭의 기호 설정이며, 한글 지원 자체를 켜는 옵션은 아닙니다.

기존 입력 매핑 `,,` → 줄 끝의 `。`도 빠뜨리지 않고 보존했습니다. 필요 없다면 `~/.vimrc.local`에서 Markdown FileType 이벤트에 해당 매핑을 해제하면 됩니다. 미리보기 단축키는 원래 설정에서 localleader가 빠져 `\p`였던 문제를 수정해, 설명대로 `Space p`가 되도록 했습니다.

## WSL의 Windows Terminal과 Nerd Font

WSL 터미널을 표시하는 글꼴은 **Windows 쪽**에 설치해야 합니다. 현재 폰트는 Nerd Fonts 3.5.1의 `CascadiaCode.zip`에서 설치한 38개 TTF이며, 실제 선택한 패밀리는 `CaskaydiaCove Nerd Font Mono`입니다.

Windows PowerShell에서 저장소의 [폰트 설치 스크립트](ubuntu/wsl/install-nerd-font.ps1)를 실행하거나, WSL에서 다음과 같이 호출합니다. 현재 Windows 사용자 계정에만 설치하며, 다운로드의 SHA256을 확인합니다.

```bash
cd ~/dev/dotfiles
powershell.exe -NoProfile -ExecutionPolicy Bypass -File \
  "$(wslpath -w "$PWD/ubuntu/wsl/install-nerd-font.ps1")"
```

Windows Terminal을 재시작하고 `Ctrl+,` → Ubuntu 프로필 → 모양에서 글꼴을 선택합니다. 현재 색 구성표는 `IBM 5153`입니다. 없는 버전이라면 설치된 어두운 색 구성표를 선택하고, 디렉터리 대비는 eza 설정으로 유지하세요.

프로필의 명령줄은 아래와 같습니다. 배포판 이름은 Windows PowerShell에서 `wsl -l -q`로 확인한 실제 이름으로 바꿉니다.

```text
wsl.exe -d Ubuntu-26.04 -- tmux new-session -A -s main
```

세션이 없으면 생성하고 있으면 재접속합니다. 여러 탭에서 같은 `main`에 연결하면 같은 tmux 화면을 공유합니다. `Ctrl+b d`로 분리했을 때 이 명령으로 열린 탭은 종료 설정에 따라 닫힐 수 있지만 tmux 세션은 계속 살아 있습니다.

[WSL 프로필 예제](ubuntu/wsl/windows-terminal-profile.json)와 [전역 설정 조각](ubuntu/wsl/windows-terminal-global.example.json)을 기존 `settings.json`의 해당 부분에 병합하세요. 전체 설정 파일로 덮어쓰는 예제가 아닙니다. 다른 PC의 프로필 GUID는 유지해야 합니다. 프로필 예제를 새 항목으로 직접 추가한다면 그 PC에서 새 GUID를 생성합니다.

현재 전역 설정에 있던 `copyFormatting=none`, `copyOnSelect=false`, 복사/붙여넣기/검색/분할 키 바인딩도 조각 파일에 기록했습니다. 현재 Ubuntu 프로필을 기본 프로필로 선택한 것은 Windows Terminal UI에서 다시 지정합니다. PC별 GUID나 Windows 사용자 경로는 저장하지 않습니다.

현재 `/etc/wsl.conf`는 systemd 사용과 기본 Linux 사용자 지정만 포함합니다. [wsl.conf 예제](ubuntu/wsl/wsl.conf.example)의 사용자 이름을 바꾸고 기존 시스템 설정과 병합하세요. 변경 후 Windows PowerShell에서 `wsl --shutdown`을 하면 전체 WSL이 중지되므로 작업을 저장한 뒤 적용합니다. 설치 스크립트가 이 파일을 자동으로 덮어쓰거나 WSL을 종료하지는 않습니다.

일반 Ubuntu 데스크톱이라면:

```bash
sudo apt install -y python3 fontconfig fonts-noto-cjk
bash ubuntu/scripts/install-linux-font.sh
```

그 뒤 사용하는 터미널의 글꼴을 선택합니다. CaskaydiaCove의 아이콘과 한글 대체 글꼴은 별개의 역할이며, Linux에서는 `fonts-noto-cjk`가 한글 표시에 도움이 됩니다.

## 기록 범위와 업데이트

- `inventory/apt-installed.tsv`: 설치 완료 상태인 전체 apt 패키지, 버전, 아키텍처. 최초 1,027개.
- `inventory/apt-manual.txt`: 수동 설치로 표시된 패키지. WSL 기본 패키지도 포함됩니다.
- `inventory/apt-held.txt`: 버전 고정 상태. 최초 환경에서는 없음.
- `inventory/tools.json`: 주요 실행 파일 위치와 실제 버전. 설치 안 된 도구도 구분합니다.
- `inventory/npm-global.json`, `pip-packages.json`, `other-package-managers.json`: 추가 패키지 관리자 상태.
- `inventory/environment.json`: OS·커널·아키텍처·기본 셸·사용 가능한 로케일 및 수집 시점.
- `inventory/vim-plugins.json`: 설치된 플러그인 커밋과 작업 트리 변경 상태.
- `snapshots/initial-home/`: 생성 전 zsh/Vim/tmux/Starship/Bash/profile 설정값 보관본. 주석은 한국어로 통일하고 Bash의 사용자 절대 경로는 `$HOME`으로 정규화했습니다.

최초 환경의 전체 패키지 기록과 다른 PC에서 설치할 핵심 목록은 구분했습니다. Ubuntu/CPU가 달라지면 같은 패키지의 버전과 의존성도 달라지고 과거 버전이 저장소에서 사라질 수 있으므로, 1,027개를 버전 고정으로 일괄 설치하지 않습니다. Starship은 없을 때 기록된 버전으로 설치하고, 이미 있으면 그 버전을 유지합니다. Vim 플러그인과 미리보기 npm 의존성은 고정합니다.

전체 디스크 이미지, 프로젝트 소스, Docker Desktop 본체, Windows 프로그램, OS 업데이트 전체를 복제하는 저장소는 아닙니다. 현재 Docker 명령은 Windows Docker Desktop의 안내용 스크립트만 보이며, 버전 확인은 WSL 통합 미활성화 메시지와 함께 실패합니다. 정상 설치로 간주하지 않고 실패 내용까지 기록합니다. Ubuntu에 `docker.io`를 추가 설치하지 않습니다. 현재 외부에서 제공된 Codex CLI도 설치 여부와 버전만 기록합니다. 제품 로그인과 개인 인증은 PC별로 진행합니다.

기록을 현재 PC 기준으로 갱신하려면:

```bash
python3 ubuntu/scripts/snapshot.py
git diff -- ubuntu/inventory
```

현재 홈의 설정을 자동으로 마구 수집하지는 않습니다. 설정 변경은 `ubuntu/config/`에서 하고, 새 PC의 비밀값은 `*.local` 파일에 둡니다. 플러그인 버전을 변경할 때는 `.vimrc`의 커밋과 `locks/vim-plugins.tsv`를 함께 갱신하고 필요한 경우 npm lockfile도 갱신합니다. 기존 미리보기 플러그인의 의존성에는 npm 보안 경고가 있으므로, 최초 환경을 보존한 채 관련 내용은 [문제 해결 문서](ubuntu/docs/troubleshooting.md)에 기록했습니다.

## GitHub에 올리기

이 디렉터리는 `main` 브랜치의 로컬 Git 저장소로 초기화되어 있으며, 초기 커밋을 검토할 수 있도록 파일을 스테이징했습니다. 원격 저장소 생성과 업로드는 별도입니다.

```bash
cd ~/dev/dotfiles
git status --short
git add .
git diff --cached --stat
git commit -m "Add Ubuntu terminal and Markdown dotfiles"

# GitHub에서 빈 dotfiles 저장소를 만든 뒤 실제 계정으로 변경
git remote add origin https://github.com/YOUR_GITHUB_USER/dotfiles.git
git push -u origin main
```

설정은 명시적으로 선정한 파일만 넣었습니다. SSH/AWS/Codex 인증, Git 자격 증명, 개인 이메일·이름, 명령어 기록, zoxide DB, 캐시, 다운로드한 폰트 및 `node_modules`는 수록하지 않았습니다. `.gitignore`도 이를 제외하도록 구성했습니다. 대화 전체 원문 대신 [구성 결정 및 변경 기록](ubuntu/docs/decisions.md)에 이번 구성의 선택과 수정 사항을 정리했습니다.

설치 방식과 옵션은 [Starship 공식 가이드](https://starship.rs/guide/), [fzf 셸 통합](https://github.com/junegunn/fzf#setting-up-shell-integration), [vim-plug](https://github.com/junegunn/vim-plug), [Markdown 미리보기](https://github.com/iamcco/markdown-preview.nvim), [Windows Terminal 프로필 모양](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)을 참고했습니다.
