"""pip-audit: dependency CVE checking, SBOM generation. Requires: pip-audit (extra secure).

Provides run_pip_audit, parse_pip_audit_json, dependency_vulns_from_audit, generate_audit_report,
suggest_fixes, suggest_fixes_flat, generate_sbom, audit_dependencies, check_package, etc.
Install with: uv sync --extra secure. All comments in English.
"""

from __future__ import annotations

import json
import subprocess
import sys

from secure.models import AuditConfig, AuditReport, CVEEntry, DependencyVuln

# -----------------------------------------------------------------------------
# pip-audit execution
# -----------------------------------------------------------------------------


def _run_pip_audit(args: list[str]) -> subprocess.CompletedProcess:
    """Run pip-audit subprocess. Raises ImportError if pip_audit not installed."""
    try:
        return subprocess.run(
            [sys.executable, "-m", "pip_audit", *args],
            capture_output=True,
            text=True,
            timeout=120,
        )
    except FileNotFoundError as e:
        raise ImportError(
            "audit requires pip-audit; install: uv sync --extra secure"
        ) from e


def run_pip_audit(
    format: str = "json",
    require_audit: bool = True,
) -> tuple[int, str, str]:
    """Run pip-audit. Returns (returncode, stdout, stderr)."""
    args = ["-f", format]
    if require_audit:
        args.append("--require-audit")
    proc = _run_pip_audit(args)
    return proc.returncode, proc.stdout, proc.stderr


# -----------------------------------------------------------------------------
# CVE database checking
# -----------------------------------------------------------------------------


def parse_pip_audit_json(stdout: str) -> list[dict]:
    """Parse JSON from pip-audit -f json (dependencies with vulns)."""
    try:
        data = json.loads(stdout)
        return data.get("dependencies", [])
    except json.JSONDecodeError:
        return []


def dependency_vulns_from_audit(deps: list[dict]) -> list[DependencyVuln]:
    """Convert pip-audit output to list[DependencyVuln]."""
    out = []
    for d in deps:
        name = d.get("name", "")
        version = d.get("version", "")
        vulns = []
        for v in d.get("vulns", []):
            vulns.append(
                CVEEntry(
                    id=v.get("id", ""),
                    description=v.get("description", ""),
                    fix_versions=v.get("fix_versions", []),
                    severity=v.get("severity", ""),
                )
            )
        out.append(DependencyVuln(name=name, version=version, vulns=vulns))
    return out


# -----------------------------------------------------------------------------
# Dependency tree analysis
# -----------------------------------------------------------------------------


def run_audit_tree(format: str = "json") -> tuple[int, str]:
    """Run pip-audit with given format (e.g. tree if needed)."""
    code, stdout, stderr = run_pip_audit(format=format)
    return code, stdout if code == 0 else stderr


# -----------------------------------------------------------------------------
# Vulnerability reports
# -----------------------------------------------------------------------------


def generate_audit_report(config: AuditConfig | None = None) -> AuditReport:
    """Run pip-audit and return AuditReport."""
    cfg = config or AuditConfig()
    code, stdout, stderr = run_pip_audit(
        format=cfg.format,
        require_audit=cfg.require_audit,
    )
    deps_raw = parse_pip_audit_json(stdout) if stdout else []
    dependencies = dependency_vulns_from_audit(deps_raw)
    total = sum(len(d.vulns) for d in dependencies)
    return AuditReport(
        dependencies=dependencies,
        total_vulns=total,
        success=code == 0 and total == 0,
        error=stderr.strip() or None if code != 0 else None,
    )


# -----------------------------------------------------------------------------
# Auto-fix suggestions
# -----------------------------------------------------------------------------


def suggest_fixes(report: AuditReport) -> list[tuple[str, str, list[str]]]:
    """For each vulnerable dependency return (name, version, fix_versions)."""
    out = []
    for d in report.dependencies:
        if not d.vulns:
            continue
        fix_versions = []
        for v in d.vulns:
            fix_versions.extend(v.fix_versions)
        out.append((d.name, d.version, list(dict.fromkeys(fix_versions))))
    return out


def suggest_fixes_flat(report: AuditReport) -> list[dict]:
    """Flat list of dicts: name, version, fix_versions, cve."""
    out = []
    for d in report.dependencies:
        for v in d.vulns:
            out.append(
                {
                    "name": d.name,
                    "version": d.version,
                    "fix_versions": v.fix_versions,
                    "cve": v.id,
                }
            )
    return out


# -----------------------------------------------------------------------------
# SBOM generation
# -----------------------------------------------------------------------------


def generate_sbom(format: str = "cyclonedx-json") -> str:
    """Generate SBOM. format: cyclonedx-json, spdx-json, etc."""
    args = ["-f", format]
    proc = _run_pip_audit(args)
    return proc.stdout if proc.returncode == 0 else ""


def audit_dependencies(requirements_path: str | None = None) -> AuditReport:
    """Run pip-audit; optional requirements_path for audit of specific file. Returns AuditReport."""
    args = ["-f", "json"]
    if requirements_path:
        args.extend(["-r", requirements_path])
    proc = _run_pip_audit(args)
    deps_raw = parse_pip_audit_json(proc.stdout) if proc.stdout else []
    dependencies = dependency_vulns_from_audit(deps_raw)
    total = sum(len(d.vulns) for d in dependencies)
    return AuditReport(
        dependencies=dependencies,
        total_vulns=total,
        success=proc.returncode == 0 and total == 0,
        error=proc.stderr.strip() or None if proc.returncode != 0 else None,
    )


def check_package(package_name: str, version: str | None = None) -> list[dict]:
    """Check single package for CVEs. Returns list of CVE dicts."""
    report = generate_audit_report()
    for d in report.dependencies:
        if d.name == package_name and (version is None or d.version == version):
            return [{"id": v.id, "description": v.description, "fix_versions": v.fix_versions, "severity": v.severity} for v in d.vulns]
    return []


def update_vulnerability_db() -> None:
    """Update pip-audit vulnerability database (if supported)."""
    try:
        subprocess.run([sys.executable, "-m", "pip_audit", "--update-cache"], capture_output=True, timeout=60, check=False)
    except Exception:
        pass


def get_db_version() -> str:
    """Return vulnerability DB version string if available."""
    return ""


def list_vulnerabilities(report: AuditReport | None = None, severity: list[str] | None = None) -> list[dict]:
    """List all CVEs from report. Optionally filter by severity."""
    r = report or generate_audit_report()
    out = []
    for d in r.dependencies:
        for v in d.vulns:
            if severity is None or (v.severity and v.severity.upper() in {s.upper() for s in severity}):
                out.append({"package": d.name, "version": d.version, "cve": v.id, "severity": v.severity})
    return out


def auto_fix_dependencies(requirements_path: str, dry_run: bool = True) -> str:
    """Suggest or apply fixes. dry_run: only return suggested changes. Returns diff or message."""
    report = audit_dependencies(requirements_path)
    fixes = suggest_fixes(report)
    if dry_run:
        return "\n".join(f"{n}=={v} -> {f}" for n, v, f in fixes)
    return "Apply fixes manually or use pip install -U"
