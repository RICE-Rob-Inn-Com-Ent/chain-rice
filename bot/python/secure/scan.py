"""Bandit: code vulnerability scanning, AST analysis, report generation. Requires: bandit (extra secure).

Provides run_bandit, parse_bandit_json, findings_from_bandit_results, generate_scan_report,
run_scan_ci, load_custom_rules, run_bandit_scan, scan_directory, filter_findings, etc.
Install with: uv sync --extra secure. All comments in English.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from secure.models import Finding, ScanConfig, ScanReport, Severity

# -----------------------------------------------------------------------------
# Bandit runner i config
# -----------------------------------------------------------------------------


def _run_bandit(
    args: list[str], cwd: str | Path | None = None
) -> subprocess.CompletedProcess:
    """Run bandit subprocess. Returns CompletedProcess. Raises ImportError if bandit not installed."""
    try:
        result = subprocess.run(
            [sys.executable, "-m", "bandit", *args],
            capture_output=True,
            text=True,
            cwd=cwd,
            timeout=300,
            check=False,
        )
        return result
    except FileNotFoundError as e:
        raise ImportError(
            "scan requires bandit; install: uv sync --extra secure"
        ) from e


def get_bandit_config(config: ScanConfig | None = None) -> dict:
    """Return dict of Bandit config (exclude_dirs, severity_level, confidence_level)."""
    cfg = config or ScanConfig()
    return {
        "exclude_dirs": cfg.exclude_dirs,
        "severity_level": cfg.severity,
        "confidence_level": cfg.confidence,
    }


# -----------------------------------------------------------------------------
# Code vulnerability detection
# -----------------------------------------------------------------------------


def run_bandit(
    targets: list[str] | None = None,
    severity: int = 1,
    confidence: int = 1,
    config_file: str | None = None,
    cwd: str | Path | None = None,
) -> tuple[int, str, str]:
    """Run bandit on targets. Returns (returncode, stdout, stderr)."""
    args = ["-r", "-f", "json", "-ll", str(severity), "-ii", str(confidence)]
    if config_file:
        args.extend(["-c", config_file])
    if targets:
        args.extend(targets)
    else:
        args.extend(ScanConfig().targets)
    proc = _run_bandit(args, cwd=cwd)
    return proc.returncode, proc.stdout, proc.stderr


# -----------------------------------------------------------------------------
# AST analysis dla security issues
# -----------------------------------------------------------------------------


def parse_bandit_json(stdout: str) -> list[dict]:
    """Parse JSON from bandit -f json (list of results)."""
    try:
        data = json.loads(stdout)
        return data.get("results", [])
    except json.JSONDecodeError:
        return []


def findings_from_bandit_results(results: list[dict]) -> list[Finding]:
    """Convert Bandit result dicts to list[Finding]."""
    severity_map = {
        "LOW": Severity.LOW,
        "MEDIUM": Severity.MEDIUM,
        "HIGH": Severity.HIGH,
    }
    out = []
    for r in results:
        sev = severity_map.get(r.get("issue_severity", "MEDIUM"), Severity.MEDIUM)
        out.append(
            Finding(
                filename=r.get("filename", ""),
                line=int(r.get("line_number", 0)),
                test_id=r.get("test_id", ""),
                severity=sev,
                message=r.get("issue_text", ""),
                confidence=r.get("issue_confidence", "MEDIUM"),
                cwe_id=(
                    r.get("issue_cwe", {}).get("id")
                    if isinstance(r.get("issue_cwe"), dict)
                    else None
                ),
            )
        )
    return out


# -----------------------------------------------------------------------------
# Report generation
# -----------------------------------------------------------------------------


def generate_scan_report(
    targets: list[str] | None = None,
    config: ScanConfig | None = None,
    cwd: str | Path | None = None,
) -> ScanReport:
    """Run Bandit scan and return ScanReport."""
    cfg = config or ScanConfig()
    code, stdout, stderr = run_bandit(
        targets=targets or cfg.targets,
        severity=cfg.severity,
        confidence=cfg.confidence,
        config_file=cfg.config_file,
        cwd=cwd,
    )
    results = parse_bandit_json(stdout) if stdout else []
    findings = findings_from_bandit_results(results)
    metrics = {}
    if results:
        try:
            data = json.loads(stdout)
            metrics = data.get("metrics", {})
        except json.JSONDecodeError:
            pass
    return ScanReport(
        findings=findings,
        metrics=metrics,
        success=code == 0 and len(findings) == 0,
        error=stderr.strip() or None if code != 0 else None,
    )


# -----------------------------------------------------------------------------
# Custom rules (placeholder - Bandit używa pliku config)
# -----------------------------------------------------------------------------


def load_custom_rules(path: str | Path) -> list[str]:
    """Load paths to custom rule files (for bandit -r with config)."""
    p = Path(path)
    if not p.exists():
        return []
    return [str(p)]


# -----------------------------------------------------------------------------
# CI/CD integration helpers
# -----------------------------------------------------------------------------


def run_scan_ci(
    fail_on_high: bool = True,
    config: ScanConfig | None = None,
    cwd: str | Path | None = None,
) -> bool:
    """Run scan; return True if pass (no high/critical). For CI."""
    report = generate_scan_report(config=config, cwd=cwd)
    if not fail_on_high:
        return report.success
    high_or_critical = any(
        f.severity in (Severity.HIGH, Severity.CRITICAL) for f in report.findings
    )
    return report.success and not high_or_critical


def run_bandit_scan(path: str | Path, config: dict | ScanConfig | None = None) -> ScanReport:
    """Run Bandit scan on path. config: dict or ScanConfig. Returns ScanReport."""
    cfg = config if isinstance(config, ScanConfig) else None
    if isinstance(config, dict):
        cfg = ScanConfig(**{k: v for k, v in config.items() if hasattr(ScanConfig, k)})
    return generate_scan_report(targets=[str(path)], config=cfg, cwd=Path(path).parent if Path(path).is_file() else path)


def scan_directory(path: str | Path, recursive: bool = True, config: ScanConfig | None = None) -> ScanReport:
    """Scan directory. recursive: include subdirs (Bandit -r). Returns ScanReport."""
    targets = [str(path)]
    return generate_scan_report(targets=targets, config=config, cwd=path)


def load_bandit_config(path: str | Path) -> dict:
    """Load Bandit config from file. Returns dict (e.g. exclude, severity)."""
    p = Path(path)
    if not p.exists():
        return {}
    try:
        import yaml
        return yaml.safe_load(p.read_text()) or {}
    except Exception:
        try:
            import json
            return json.loads(p.read_text()) or {}
        except Exception:
            return {}


def customize_rules(exclude: list[str] | None = None, severity: str = "MEDIUM") -> dict:
    """Build config dict: exclude dirs, severity level. For Bandit."""
    cfg = ScanConfig()
    if exclude is not None:
        cfg.exclude_dirs = list(exclude)
    return get_bandit_config(cfg)


def generate_report(results: list[dict] | list[Finding], format: str = "json") -> str:
    """Generate report string from results. format: json, yaml, text."""
    if results and isinstance(results[0], Finding):
        results = [f.model_dump() if hasattr(f, "model_dump") else f for f in results]
    if format == "json":
        return json.dumps({"findings": results}, indent=2)
    if format == "yaml":
        try:
            import yaml
            return yaml.dump({"findings": results})
        except ImportError:
            return json.dumps({"findings": results})
    return "\n".join(str(r) for r in results)


def filter_findings(results: list[Finding], severity: list[str]) -> list[Finding]:
    """Return findings with severity in the given list (e.g. ['HIGH', 'CRITICAL'])."""
    sev_set = {s.upper() for s in severity}
    return [f for f in results if f.severity.value.upper() in sev_set]


def fail_on_high_severity(results: list[Finding]) -> bool:
    """Return True if any finding is HIGH or CRITICAL (CI fail)."""
    return any(f.severity in (Severity.HIGH, Severity.CRITICAL) for f in results)


def compare_with_baseline(current: ScanReport, baseline: ScanReport) -> dict:
    """Compare current scan with baseline. Returns diff dict (new, fixed, same)."""
    base_ids = {(f.filename, f.line, f.test_id) for f in baseline.findings}
    curr_ids = {(f.filename, f.line, f.test_id) for f in current.findings}
    return {"new": len(curr_ids - base_ids), "fixed": len(base_ids - curr_ids), "same": len(curr_ids & base_ids)}
