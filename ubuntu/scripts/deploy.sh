#!/usr/bin/env bash
# 설정 파일 연결/해제. 기존 파일은 홈 디렉터리의 상태 저장소로 이동합니다.
set -euo pipefail

dotfiles_ubuntu=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
dotfiles_action=${1:-link}
if (($#)); then shift; fi
dotfiles_target=$HOME
dotfiles_dry_run=0
dotfiles_restore=''

while (($#)); do
  case "$1" in
    --target-home) dotfiles_target=${2:?--target-home 경로가 필요합니다}; shift 2 ;;
    --dry-run) dotfiles_dry_run=1; shift ;;
    --restore) dotfiles_restore=${2:?--restore 백업 경로가 필요합니다}; shift 2 ;;
    *) printf '알 수 없는 옵션: %s\n' "$1" >&2; exit 2 ;;
  esac
done
[[ $dotfiles_action == link || $dotfiles_action == unlink ]] || {
  printf '사용법: %s link|unlink [--target-home DIR] [--dry-run] [--restore BACKUP_DIR]\n' "$0" >&2
  exit 2
}
[[ $dotfiles_target == /* && $dotfiles_target != / ]] || {
  printf '대상 홈은 / 이외의 절대 경로여야 합니다.\n' >&2; exit 2;
}
dotfiles_target=$(realpath -m -- "$dotfiles_target")
[[ $dotfiles_target != / ]] || { printf '루트 디렉터리는 대상 홈으로 사용할 수 없습니다.\n' >&2; exit 2; }
if [[ -n $dotfiles_restore ]]; then
  [[ $dotfiles_action == unlink && -d $dotfiles_restore ]] || {
    printf '--restore는 unlink 및 존재하는 백업 디렉터리와 함께 사용하세요.\n' >&2; exit 2;
  }
fi

dotfiles_state="$dotfiles_target/.local/state/dotfiles/backups"
dotfiles_backup=''
dotfiles_count=0
while IFS=$'\t' read -r dotfiles_source dotfiles_relative; do
  [[ -n $dotfiles_source && $dotfiles_source != \#* ]] || continue
  [[ $dotfiles_relative != /* && $dotfiles_relative != *..* ]] || {
    printf '유효하지 않은 대상 경로: %s\n' "$dotfiles_relative" >&2; exit 2;
  }
  dotfiles_source="$dotfiles_ubuntu/$dotfiles_source"
  dotfiles_destination="$dotfiles_target/$dotfiles_relative"
  [[ -f $dotfiles_source ]] || { printf '원본 파일 없음: %s\n' "$dotfiles_source" >&2; exit 1; }
  dotfiles_managed=0
  if [[ -L $dotfiles_destination ]] && \
     [[ $(readlink -f -- "$dotfiles_destination" || true) == "$dotfiles_source" ]]; then
    dotfiles_managed=1
  fi

  if [[ $dotfiles_action == link ]]; then
    if ((dotfiles_managed)); then
      printf '유지: %s\n' "$dotfiles_destination"
      continue
    fi
    printf '연결: %s -> %s\n' "$dotfiles_destination" "$dotfiles_source"
    ((dotfiles_dry_run)) && continue
    if [[ -e $dotfiles_destination || -L $dotfiles_destination ]]; then
      if [[ -z $dotfiles_backup ]]; then
        mkdir -p -- "$dotfiles_state"
        dotfiles_backup=$(mktemp -d "$dotfiles_state/$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")
      fi
      mkdir -p -- "$dotfiles_backup/$(dirname -- "$dotfiles_relative")"
      printf '백업: %s\n' "$dotfiles_backup/$dotfiles_relative"
      mv -- "$dotfiles_destination" "$dotfiles_backup/$dotfiles_relative"
    fi
    mkdir -p -- "$(dirname -- "$dotfiles_destination")"
    ln -s -- "$dotfiles_source" "$dotfiles_destination"
    dotfiles_count=$((dotfiles_count + 1))
  else
    if ((dotfiles_managed)); then
      printf '연결 해제: %s\n' "$dotfiles_destination"
      ((dotfiles_dry_run)) || unlink -- "$dotfiles_destination"
    elif [[ -e $dotfiles_destination || -L $dotfiles_destination ]]; then
      printf '건너뜀(다른 파일로 변경됨): %s\n' "$dotfiles_destination"
      continue
    fi
    if [[ -n $dotfiles_restore && ( -e "$dotfiles_restore/$dotfiles_relative" || -L "$dotfiles_restore/$dotfiles_relative" ) ]]; then
      printf '백업 복원: %s\n' "$dotfiles_destination"
      if (( ! dotfiles_dry_run )); then
        mkdir -p -- "$(dirname -- "$dotfiles_destination")"
        cp -a -- "$dotfiles_restore/$dotfiles_relative" "$dotfiles_destination"
      fi
    fi
  fi
done < "$dotfiles_ubuntu/links.tsv"

if [[ -n $dotfiles_backup ]]; then
  printf '\n기존 설정 백업: %s\n' "$dotfiles_backup"
fi
printf '\n%s 작업 완료%s\n' "$dotfiles_action" "$([[ $dotfiles_dry_run == 1 ]] && printf ' (미리보기)' || true)"
