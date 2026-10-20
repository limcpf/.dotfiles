# Codex 공통 설정

Codex는 여러 운영체제에서 사용하는 도구이므로 모델 설정은 `ubuntu/`와 분리해 `common/codex/`에 둡니다. 확인 기준은 2026-10-20, Codex CLI 0.163.0입니다. 파일은 Windows와 Linux에서 공통으로 사용하며 로그인과 실행 파일 설치는 각 PC에서 진행합니다.

## 모델 선택

| 용도 | 실행 명령 | 모델 | 추론 수준 |
| --- | --- | --- | --- |
| 일반 질문 기본값 | `codex` | GPT-6 Luna | low |
| 빠른 질문을 명시적으로 선택 | `codex --profile fast` | GPT-6 Luna | low |
| 개발·고난도 작업 | `codex --profile dev` | GPT-6.1 Sol | max |

현재 로컬 설정의 `gpt-6.1-sol` / `max`를 개발 프로필에 보존했습니다. 단순한 질문에는 Luna / low를 속도 우선 출발점으로 선택했습니다. 공식 [모델 안내](https://learn.chatgpt.com/docs/models)와 [모델 선택 가이드](https://developers.openai.com/api/docs/guides/model-selection)를 참고했으며, 이 PC의 모델 목록에서도 두 모델과 지정한 추론 수준을 확인했습니다. 실측으로 항상 가장 빠르다고 보장하는 설정은 아닙니다.

Max는 복잡한 작업에 더 많은 추론 시간을 배정합니다. 일상적인 개발에서 너무 오래 걸리면 개발 프로필을 `high`나 `medium`으로 낮춰 비교할 수 있습니다. 다른 계정에서는 모델 선택기에 표시되는 사용 가능한 모델을 확인하세요.

## 자동 전환의 범위

이 구성은 **기본값과 수동 선택 프로필**입니다. 일반 질문을 시작하면 기본 Luna를 쓰고, 개발을 시작할 때 `--profile dev`를 지정합니다. 프로필이 질문 문장을 분석해 자동으로 바뀌는 것은 아닙니다. 확인한 공식 설정 문서에는 질문 난이도별 모델 자동 라우팅 옵션이 제시되어 있지 않습니다.

한 대화에서 질문과 개발을 이어갈 때는 Codex CLI의 `/model`로 모델과 추론 수준을 바꾼 뒤 `/status`로 확인합니다. 데스크톱 앱이나 IDE에서는 제공되는 모델 선택기를 사용합니다. [CLI 모델 전환 안내](https://learn.chatgpt.com/docs/developer-commands?surface=cli#set-the-active-model-with-model)를 참고하세요.

질문별 완전 자동 선택은 별도 분류·라우팅 구현이 필요합니다. 이 저장소에는 그것을 위한 API 호출이나 분류기를 추가하지 않았습니다. `AGENTS.md`에 문장을 적는 것만으로 실행 중인 부모 모델이 교체된다고 가정하지 않습니다.

## 적용

Python 3.11 이상에서 저장소 루트 기준으로 실행합니다. Ubuntu의 복원 패키지 목록에는 Python이 포함되어 있습니다.

```bash
# 현재 설정을 건드리지 않고 변경 대상 확인
python3 common/codex/install.py --dry-run

# 기본 모델 두 항목만 병합하고 fast/dev 프로필 설치
python3 common/codex/install.py

# 기본 모델은 바꾸지 않고 선택용 프로필만 추가하는 경우
python3 common/codex/install.py --profiles-only
```

Windows 네이티브 환경에서는 Python 3.11 이상을 설치한 뒤 `python` 또는 `py -3`로 같은 스크립트를 실행할 수 있습니다.

```powershell
py -3 common/codex/install.py --dry-run
py -3 common/codex/install.py
```

기본 위치는 Linux/WSL의 `~/.codex`, Windows의 `%USERPROFILE%\.codex`입니다. 이미 사용자 지정 `CODEX_HOME`을 사용한다면 그 위치를 따릅니다. 이 스크립트가 `CODEX_HOME`을 변경하지는 않습니다. WSL과 Windows 네이티브 Codex의 사용자 폴더는 서로 다를 수 있으므로 실제로 쓰는 환경에서 적용하세요. [설정 위치와 계층](https://learn.chatgpt.com/docs/config-file/config-basic)을 참고하세요.

```text
~/.codex/
├── config.toml          # model / model_reasoning_effort만 기본값으로 병합
├── fast.config.toml     # 빠른 질문 프로필
└── dev.config.toml      # 개발 프로필
```

설치기는 기존 `config.toml`의 프로젝트 신뢰 설정·UI·MCP·권한 등 다른 값을 파싱해 보존 여부를 확인합니다. 변경할 기존 파일은 같은 사용자 폴더의 `.dotfiles-backups/날짜-고유값/`에 먼저 백업합니다. 기존 개인 설정을 저장소로 복사하지는 않습니다. 다시 실행해 내용이 같으면 파일이나 백업을 추가로 만들지 않습니다.

드문 TOML 표현을 자동으로 병합할 수 없으면 쓰기 전에 중단합니다. 그때는 기존 `config.toml`의 **최상위** `model`과 `model_reasoning_effort`만 `config.toml` 예제의 값으로 바꾸고, 두 프로필을 해당 Codex 폴더로 복사하세요. `[tui]`나 `[projects...]` 테이블 내부에 기본 모델을 붙여 넣지 마세요. 백업 복원은 백업 폴더에서 해당 파일을 확인한 뒤 원래 위치에 복사하면 됩니다.

이 파일들은 복사 방식으로 설치하므로 저장소의 모델을 수정한 뒤에는 설치기를 다시 실행합니다. 이미 열린 대화는 현재 선택이 유지될 수 있어 새 CLI 세션에서 확인하거나 `/model`로 직접 전환합니다. 프로젝트 설정이나 명시적인 실행 옵션이 기본값보다 우선할 수 있습니다.

## 프로필 파일 형식

현재 CLI는 `fast.config.toml`처럼 프로필별 파일을 사용합니다. **0.134.0 이상**에서는 예전 `[profiles.fast]` 테이블이나 `profile = "fast"` 기본 선택기를 사용하지 않습니다. 파일의 모델 항목을 최상위에 두고 `--profile fast`로 선택합니다. [공식 프로필 문서](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles)에 따른 형식입니다.

`fast`는 여기서 정한 프로필 이름입니다. Codex의 `/fast`는 현재 모델의 서비스 속도 등급을 바꾸는 별도 기능이고 사용량이 증가할 수 있으므로, 이번 설정에는 서비스 등급을 추가하지 않았습니다. [속도 모드 안내](https://learn.chatgpt.com/docs/agent-configuration/speed)를 참고하세요.

## 저장소에 넣는 범위

모델명과 추론 수준만 공유합니다. 인증 파일, 대화 기록, 모델 캐시 원문, 프로젝트 경로별 신뢰 설정, 계정 식별자는 수록하지 않습니다. Codex 설치기와 한국어 문서를 함께 보관하고, Linux의 패키지/폰트/셸 설치는 기존 `ubuntu/`에서 관리합니다.

```bash
# API 요청 없이 임시 폴더에서 병합·백업·반복 실행 검증
python3 -m unittest discover -s common/codex/tests -v
```

현재 WSL에서 8개 검증 항목(설정 보존·백업·재실행·dry-run·프로필만 설치·잘못된 TOML 처리 등)을 통과했습니다. CLI의 로컬 설정 로드와 모델 목록의 추론 수준도 확인했습니다. 실제 사용자 설정에는 dry-run만 실행했습니다. Windows 네이티브 설치, 모델 실제 요청 및 속도 벤치마크는 실행하지 않았습니다.
