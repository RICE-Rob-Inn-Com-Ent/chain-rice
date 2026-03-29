"""Bandit + pip-audit — uruchomienie z raportem (wywoływane z CI lub ręcznie)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

# TODO:
# [ ] implement bandit scan runner:
# [ ]     run bandit -r function/ -ll (medium severity and above)
# [ ]     fail on any HIGH severity finding
# [ ]     output format from RICE_BANDIT_FORMAT env var (default: json)
# [ ] implement pip-audit runner:
# [ ]     run pip-audit --requirement uv.lock --format json
# [ ]     fail on any CRITICAL or HIGH CVE
# [ ] implement secrets scan:
# [ ]     run trufflehog filesystem function/ --only-verified
# [ ] implement license compliance check:
# [ ]     verify all dependencies have OSI-approved licenses
# [ ]     blocked licenses list from RICE_BLOCKED_LICENSES env var
# [ ] emit audit results to NATS subject audit.sage.security
# [ ]     CLERK subscribes and stores in immutable audit log


def run_bandit(paths: list[str] | None = None, *, exclude: str | None = None) -> int:
    """SAST Python — zwraca kod wyjścia bandit."""
    root = Path(__file__).resolve().parents[3]
    target = paths or ["function"]
    cmd = [sys.executable, "-m", "bandit", "-r", *target]
    if exclude:
        cmd.extend(["--exclude", exclude])
    r = subprocess.run(cmd, cwd=root, check=False)
    return r.returncode


def run_pip_audit() -> int:
    """Skan CVE zależności w aktywnym venv."""
    r = subprocess.run([sys.executable, "-m", "pip_audit"], check=False)
    return r.returncode


def write_report_md(path: Path, bandit_rc: int, pip_audit_rc: int) -> None:
    path.write_text(
        f"# Security audit\n\n- bandit exit: {bandit_rc}\n- pip-audit exit: {pip_audit_rc}\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    b = run_bandit()
    p = run_pip_audit()
    write_report_md(Path("security-audit.md"), b, p)
    sys.exit(0 if b == 0 and p == 0 else 1)
