# 검증 기록

검증일: 2026-10-20. 환경은 Ubuntu 26.04.1 LTS / WSL2 / ARM64입니다.

| 점검 | 결과 |
| --- | --- |
| Bash/zsh/Python/JSON/TOML 구문 | 정상 |
| 임시 홈에서 변경 없는 dry-run | 정상 |
| 기존 파일의 백업 후 심볼릭 링크 연결 | 정상 |
| 같은 설치의 반복 실행 | 추가 백업이나 링크 중복 없음 |
| 공백을 포함한 홈 경로 | 정상 |
| 기존의 깨진 심볼릭 링크 보관·복원 | 정상 |
| 연결 해제 및 기존 파일 복원 | 정상, 백업 유지 |
| 사용자가 링크 대신 다른 파일을 만든 경우 | 덮어쓰지 않음 |
| 루트 경로 및 충돌하는 옵션 거부 | 정상 |
| zsh의 z/zi, fzf Ctrl+r, ll/cat 별칭 | 정상 |
| Starship 설정 로드, eza/bat 실행 | 정상 |
| 별도 tmux 소켓의 설정 로드 | 상태 표시줄 top, mouse on |
| Vim Markdown 명령·Space p·영어 검사/한글 예외·표 정렬 | 정상 |
| 임시 디렉터리에 Vim 플러그인 신규 다운로드 | 정상, 세 커밋 일치 |
| 신규 미리보기 앱의 npm ci | 정상, 저장된 lockfile과 일치 |
| Windows PowerShell의 폰트 스크립트 구문 검사 | 정상 |
| 핵심 apt 패키지 목록의 모의 설치 | 현재 시스템에서 모두 제공됨, 패키지 변경 없음 |
| 전체 apt 상태 기록 | 설치 완료 패키지 1,027개 |
| 개인 경로·이메일·대표적인 인증키 형식 검색 | 공개할 파일에서 해당 값 검출 없음 |
| 일본어 가나 검색과 설명 주석 검토 | 일본어 주석 없음, 작성 주석은 한국어 |
| GitHub 업로드 | 실행하지 않음 |

실행 명령:

```bash
bash ubuntu/tests/deploy.sh
bash ubuntu/scripts/check.sh
bash ubuntu/tests/vim-install.sh
bash ubuntu/install.sh --dry-run
```

신규 Vim 설치 검증은 전용 임시 경로의 `g:dotfiles_vim_home`을 사용했습니다. tmux 검증도 별도의 소켓을 사용했으므로 현재 `main` 세션에는 설정을 덮어쓰지 않았습니다. 기존 홈의 네 설정 파일도 파일 상태 그대로 유지했습니다. 테스트가 만든 임시 파일과 전용 서버만 정리했습니다.

실제 sudo 패키지 설치와 기본 셸 변경은 현재 환경에서 재실행하지 않았습니다. Windows/Linux 글꼴 설치는 스크립트와 기존 아카이브 체크섬을 확인했으며, 현재 시스템에 다시 설치하지 않았습니다. GUI 브라우저 미리보기 창, 새로운 Ubuntu 24.04 실기기, x86_64 PC에서의 전체 설치는 아직 확인하지 않았습니다.

Docker는 Windows 쪽 명령 경로가 존재하지만, WSL Integration 안내를 출력하며 버전 조회에 실패했습니다. `inventory/tools.json`에 그 실패 상태를 보관했습니다. Java는 설치되어 있지 않으며 설치 옵션으로만 제공됩니다.
