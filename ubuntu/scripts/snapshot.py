#!/usr/bin/env python3
"""공개 가능한 OS/패키지/도구 메타데이터만 수집합니다. 설정이나 환경 변수 전체는 읽지 않습니다."""
import argparse
import datetime
import importlib.util
import json
import os
from pathlib import Path
import platform
import pwd
import re
import shlex
import shutil
import subprocess


def run(arguments, timeout=30):
    try:
        result = subprocess.run(
            arguments, capture_output=True, text=True, errors="replace", timeout=timeout
        )
        return (result.stdout.strip() or result.stderr.strip()) if result.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def portable(text):
    text = text.replace(str(Path.home()), "~")
    text = re.sub(r"/mnt/([a-z])/Users/[^/\s]+", r"/mnt/\1/Users/<windows-user>", text)
    return re.sub(r"[A-Z]:\\Users\\[^\\\s]+", r"C:\\Users\\<windows-user>", text)


def tool_version(executable, arguments):
    if not executable:
        return None, None
    try:
        result = subprocess.run(
            [executable, *arguments], capture_output=True, text=True, errors="replace", timeout=30
        )
        if result.returncode == 0:
            return portable(result.stdout.strip() or result.stderr.strip()), None
        message = result.stderr.strip() or result.stdout.strip()
        return None, {"exit_code": result.returncode, "message": portable(message)}
    except (OSError, subprocess.TimeoutExpired) as error:
        return None, {"message": portable(str(error))}


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "inventory")
    arguments = parser.parse_args()
    output = arguments.output.expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)

    os_release = {}
    for line in Path("/etc/os-release").read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, value = line.split("=", 1)
            os_release[key] = shlex.split(value)[0] if value else ""
    package_rows = run([
        "dpkg-query", "-W", "-f=${db:Status-Abbrev}\t${binary:Package}\t${Version}\t${Architecture}\n"
    ]).splitlines()
    installed = []
    for row in package_rows:
        columns = row.split("\t")
        if len(columns) == 4 and columns[0].strip() == "ii":
            installed.append(columns[1:])
    installed.sort()
    (output / "apt-installed.tsv").write_text(
        "package\tversion\tarchitecture\n" + "".join("\t".join(row) + "\n" for row in installed),
        encoding="utf-8",
    )
    for filename, command in (
        ("apt-manual.txt", ["apt-mark", "showmanual"]),
        ("apt-held.txt", ["apt-mark", "showhold"]),
    ):
        value = run(command)
        (output / filename).write_text(value + ("\n" if value else ""), encoding="utf-8")

    tool_arguments = {
        "zsh": ["--version"], "starship": ["--version"], "fzf": ["--version"],
        "zoxide": ["--version"], "eza": ["--version"], "batcat": ["--version"],
        "bat": ["--version"], "tmux": ["-V"], "vim": ["--version"],
        "nvim": ["--version"], "node": ["--version"], "npm": ["--version"],
        "java": ["--version"], "javac": ["--version"], "git": ["--version"],
        "curl": ["--version"], "docker": ["--version"], "codex": ["--version"],
        "atuin": ["--version"], "sheldon": ["--version"], "gh": ["--version"],
        "python3": ["--version"], "snap": ["version"],
    }
    tools = {}
    for name, version_arguments in tool_arguments.items():
        executable = shutil.which(name)
        version, version_error = tool_version(executable, version_arguments)
        tools[name] = {
            "installed": executable is not None,
            "path": portable(executable) if executable else None,
            "version": version,
            "version_error": version_error,
        }
    write_json(output / "tools.json", tools)

    npm_global = run(["npm", "list", "--global", "--depth=0", "--json"])
    write_json(output / "npm-global.json", json.loads(portable(npm_global)) if npm_global else {})
    if importlib.util.find_spec("pip"):
        pip_packages = run(["python3", "-m", "pip", "list", "--format=json"])
        write_json(output / "pip-packages.json", json.loads(pip_packages) if pip_packages else [])
    else:
        write_json(output / "pip-packages.json", {"pip_installed": False, "packages": []})

    other_packages = {}
    for name, command in (
        ("snap", ["snap", "list"]),
        ("flatpak", ["flatpak", "list", "--app"]),
    ):
        available = shutil.which(name) is not None
        other_packages[name] = {"available": available, "list": portable(run(command)) if available else ""}
    write_json(output / "other-package-managers.json", other_packages)

    is_wsl = "microsoft" in platform.release().lower()
    environment = {
        "captured_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "os_release": os_release,
        "kernel_release": platform.release(),
        "architecture": platform.machine(),
        "dpkg_architecture": run(["dpkg", "--print-architecture"]),
        "foreign_architectures": run(["dpkg", "--print-foreign-architectures"]).splitlines(),
        "wsl": is_wsl,
        "default_shell": pwd.getpwuid(os.getuid()).pw_shell,
        "available_locales": run(["locale", "-a"]).splitlines(),
        "collector_locale": run(["locale"]),
        "interactive_zsh_locale": run(["zsh", "-ic", "locale"]),
        "installed_apt_package_count": len(installed),
        "git_default_branch": run(["git", "config", "--global", "--get", "init.defaultBranch"]),
        "terminal_reference": {
            "baseline_host": "Windows Terminal",
            "baseline_font": "CaskaydiaCove Nerd Font Mono",
            "baseline_color_scheme": "IBM 5153",
            "note": "최초 환경에서 별도로 확인한 값입니다. 이 수집 스크립트는 Windows 설정을 조회하지 않습니다.",
        },
        "privacy": "사용자 이름, 이메일, 전체 환경 변수, 인증 설정과 사용 기록은 수집하지 않음",
    }
    write_json(output / "environment.json", environment)

    plugin_rows = []
    for repository in ("preservim/vim-markdown", "godlygeek/tabular", "iamcco/markdown-preview.nvim"):
        plugin = Path.home() / ".vim" / "plugged" / repository.split("/")[-1]
        plugin_rows.append({
            "repository": repository,
            "commit": run(["git", "-C", str(plugin), "rev-parse", "HEAD"]),
            "working_tree_changes": run(["git", "-C", str(plugin), "status", "--short"]),
        })
    write_json(output / "vim-plugins.json", plugin_rows)
    print(f"수집 완료: {output} (apt 패키지 {len(installed)}개)")


if __name__ == "__main__":
    main()
