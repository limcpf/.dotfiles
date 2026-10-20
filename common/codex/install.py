#!/usr/bin/env python3
"""OS 공통 Codex 모델 설정을 병합합니다. Python 3.11 이상이 필요합니다."""
import argparse
import datetime
import os
from pathlib import Path
import re
import shutil
import stat
import tempfile
import tomllib

SOURCE = Path(__file__).resolve().parent
MODEL_KEYS = {"model", "model_reasoning_effort"}


def merge_defaults(existing, defaults_text):
    """기존 설정값이 보존됨을 파싱 결과로 확인한 뒤 변경할 텍스트를 만듭니다."""
    original = tomllib.loads(existing)
    defaults = tomllib.loads(defaults_text)
    if set(defaults) != MODEL_KEYS:
        raise ValueError("공통 기본값에는 모델과 추론 수준 두 항목만 지정할 수 있습니다.")
    if all(original.get(key) == value for key, value in defaults.items()):
        return existing

    # 첫 테이블 앞의 최상위 설정만 변경합니다. 나머지 파일 내용은 유지합니다.
    table = re.search(r"(?m)^[ \t]*\[", existing)
    head, tail = (existing[:table.start()], existing[table.start():]) if table else (existing, "")
    head = re.sub(
        r"(?m)^[ \t]*(?:model|model_reasoning_effort)[ \t]*=[^\n]*(?:\n|$)", "", head
    )
    updated = defaults_text.rstrip() + "\n\n" + (head + tail).lstrip("\n")
    try:
        parsed = tomllib.loads(updated)
    except tomllib.TOMLDecodeError as error:
        raise ValueError("기존 TOML 표현을 자동 병합할 수 없습니다. README의 수동 병합을 사용하세요.") from error
    expected = dict(original)
    expected.update(defaults)
    if parsed != expected:
        raise ValueError("모델 외 설정 변경이 감지되어 병합을 중단합니다. 수동으로 병합하세요.")
    return updated


def atomic_write(path, text, mode):
    # 완성된 파일로 교체해 도중에 중단되어도 원래 설정이 잘리지 않게 합니다.
    pending = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", newline="\n", dir=path.parent,
            prefix=".dotfiles-", delete=False
        ) as stream:
            pending = Path(stream.name)
            stream.write(text)
        pending.chmod(mode)
        os.replace(pending, path)
        pending = None
    finally:
        if pending is not None:
            pending.unlink(missing_ok=True)


def install(codex_dir, dry_run=False, profiles_only=False):
    codex_dir = Path(codex_dir).expanduser().resolve()
    if codex_dir == codex_dir.parent or codex_dir == SOURCE:
        raise ValueError("루트 디렉터리나 저장소의 원본 폴더에는 설치할 수 없습니다.")
    filenames = ["fast.config.toml", "dev.config.toml"]
    if not profiles_only:
        filenames.insert(0, "config.toml")
    changes = []
    # 모든 파일의 형식과 병합 결과를 먼저 확인합니다.
    for name in filenames:
        destination = codex_dir / name
        if destination.is_symlink() and not destination.exists():
            raise ValueError(f"깨진 설정 링크가 있습니다. 먼저 확인하세요: {destination}")
        if destination.exists() and not destination.is_file():
            raise ValueError(f"대상은 일반 설정 파일이어야 합니다: {destination}")
        current = destination.read_text(encoding="utf-8-sig") if destination.exists() else ""
        desired = (SOURCE / name).read_text(encoding="utf-8")
        tomllib.loads(desired)
        if name == "config.toml":
            desired = merge_defaults(current, desired)
        if current == desired:
            print(f"유지: {destination}")
            continue
        print(f"{'변경 예정' if dry_run else '설치'}: {destination}")
        changes.append((destination, desired))
    if dry_run or not changes:
        return None

    codex_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    backup = None
    for destination, desired in changes:
        mode = stat.S_IMODE(destination.stat().st_mode) if destination.exists() else 0o600
        if destination.exists():
            if backup is None:
                backup_root = codex_dir / ".dotfiles-backups"
                backup_root.mkdir(exist_ok=True, mode=0o700)
                stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
                backup = Path(tempfile.mkdtemp(prefix=stamp + "-", dir=backup_root))
            shutil.copy2(destination, backup / destination.name)
            (backup / destination.name).chmod(0o600)
        atomic_write(destination, desired, mode)
    if backup is not None:
        print(f"기존 파일 백업: {backup}")
    return backup


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--codex-dir", type=Path,
        default=Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex"),
        help="설치 위치. 기본값은 기존 CODEX_HOME 또는 ~/.codex입니다.",
    )
    parser.add_argument("--dry-run", action="store_true", help="변경 계획만 출력합니다.")
    parser.add_argument("--profiles-only", action="store_true", help="기본 모델을 유지하고 프로필만 설치합니다.")
    arguments = parser.parse_args()
    try:
        install(arguments.codex_dir, arguments.dry_run, arguments.profiles_only)
    except (OSError, ValueError, tomllib.TOMLDecodeError) as error:
        parser.exit(1, f"설치 중단: {error}\n")


if __name__ == "__main__":
    main()
