"""실제 사용자 폴더나 API에 접근하지 않고 Codex 설정 복원을 검증합니다."""
import contextlib
import importlib.util
import io
from pathlib import Path
import tempfile
import tomllib
import unittest

SPEC = importlib.util.spec_from_file_location("codex_dotfiles_install", Path(__file__).resolve().parents[1] / "install.py")
INSTALLER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(INSTALLER)


class MergeTests(unittest.TestCase):
    def setUp(self):
        self.defaults = (INSTALLER.SOURCE / "config.toml").read_text(encoding="utf-8")

    def test_other_settings_and_comments_survive(self):
        current = '''# 기존 주석
model = "gpt-6.1-sol"
model_reasoning_effort = "max" # 기존 선택
approval_policy = "on-request"

[tui]
status_line = ["model-with-reasoning"]
[projects."/example/project"]
trust_level = "trusted"
[mcp_servers.example.env]
EXAMPLE_SETTING = "local-only"
'''
        updated = INSTALLER.merge_defaults(current, self.defaults)
        expected = tomllib.loads(current)
        expected.update(tomllib.loads(self.defaults))
        self.assertEqual(tomllib.loads(updated), expected)
        self.assertIn("# 기존 주석", updated)

    def test_identical_defaults_leave_file_unchanged(self):
        current = '# 개인 주석\n' + self.defaults + '\n[tui]\nstatus_line = []\n'
        self.assertEqual(INSTALLER.merge_defaults(current, self.defaults), current)

    def test_nested_model_is_not_removed(self):
        current = 'model = "previous"\n[agents.example]\nmodel = "keep-this-model"\n'
        updated = tomllib.loads(INSTALLER.merge_defaults(current, self.defaults))
        self.assertEqual(updated["agents"]["example"]["model"], "keep-this-model")

    def test_complex_multiline_content_stops_before_writing(self):
        current = 'description = """\n[not_a_table]\nmodel = "literal"\n"""\nmodel = "previous"\n'
        with self.assertRaises(ValueError):
            INSTALLER.merge_defaults(current, self.defaults)


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-codex-test-")
        self.addCleanup(self.temporary.cleanup)
        self.target = Path(self.temporary.name) / "home with spaces" / ".codex"

    def install(self, **kwargs):
        with contextlib.redirect_stdout(io.StringIO()):
            return INSTALLER.install(self.target, **kwargs)

    def test_dry_run_does_not_create_target(self):
        self.install(dry_run=True)
        self.assertFalse(self.target.exists())

    def test_backup_and_idempotent_reinstall_preserve_auth_file(self):
        self.target.mkdir(parents=True)
        original = 'model = "previous"\n[tui]\nstatus_line = []\n'
        (self.target / "config.toml").write_text(original, encoding="utf-8")
        (self.target / "auth.json").write_text('{"note":"fixture"}', encoding="utf-8")
        backup = self.install()
        self.assertEqual((backup / "config.toml").read_text(encoding="utf-8"), original)
        self.assertEqual((self.target / "auth.json").read_text(), '{"note":"fixture"}')
        first_mtime = (self.target / "config.toml").stat().st_mtime_ns
        self.assertIsNone(self.install())
        self.assertEqual((self.target / "config.toml").stat().st_mtime_ns, first_mtime)
        self.assertEqual(len(list((self.target / ".dotfiles-backups").iterdir())), 1)
        self.assertEqual(tomllib.loads((self.target / "dev.config.toml").read_text())["model"], "gpt-6.1-sol")

    def test_profiles_only_preserves_existing_default(self):
        self.target.mkdir(parents=True)
        original = 'model = "previous"\n'
        (self.target / "config.toml").write_text(original, encoding="utf-8")
        self.install(profiles_only=True)
        self.assertEqual((self.target / "config.toml").read_text(), original)
        self.assertTrue((self.target / "fast.config.toml").is_file())

    def test_identical_default_link_is_detached_without_changing_source(self):
        self.target.mkdir(parents=True)
        source = Path(self.temporary.name) / "shared.toml"
        original = (INSTALLER.SOURCE / "config.toml").read_text(encoding="utf-8")
        original += '\n[projects."/example/project"]\ntrust_level = "trusted"\n'
        source.write_text(original, encoding="utf-8")
        destination = self.target / "config.toml"
        try:
            destination.symlink_to(source)
        except (OSError, NotImplementedError):
            self.skipTest("이 환경에서는 심볼릭 링크를 만들 수 없습니다.")
        backup = self.install()
        self.assertFalse(destination.is_symlink())
        self.assertEqual(destination.read_text(encoding="utf-8"), original)
        self.assertEqual((backup / "config.toml").read_text(encoding="utf-8"), original)
        destination.write_text(original + '\n# local change\n', encoding="utf-8")
        self.assertEqual(source.read_text(encoding="utf-8"), original)

    def test_dry_run_keeps_default_link_and_source(self):
        self.target.mkdir(parents=True)
        source = Path(self.temporary.name) / "shared.toml"
        original = (INSTALLER.SOURCE / "config.toml").read_text(encoding="utf-8")
        source.write_text(original, encoding="utf-8")
        destination = self.target / "config.toml"
        try:
            destination.symlink_to(source)
        except (OSError, NotImplementedError):
            self.skipTest("이 환경에서는 심볼릭 링크를 만들 수 없습니다.")
        self.install(dry_run=True)
        self.assertTrue(destination.is_symlink())
        self.assertEqual(source.read_text(encoding="utf-8"), original)
        self.assertFalse((self.target / ".dotfiles-backups").exists())

    def test_invalid_config_is_not_replaced(self):
        self.target.mkdir(parents=True)
        original = 'model = "unterminated'
        (self.target / "config.toml").write_text(original, encoding="utf-8")
        with self.assertRaises(tomllib.TOMLDecodeError):
            self.install()
        self.assertEqual((self.target / "config.toml").read_text(), original)
        self.assertFalse((self.target / "fast.config.toml").exists())
        self.assertFalse((self.target / ".dotfiles-backups").exists())


if __name__ == "__main__":
    unittest.main()
