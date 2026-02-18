"""Pydantic models for security: scan results, CVE reports, guardrail violations, audit configs.

Used by secure/scan, secure/audit, secure/guards. All descriptions in English.
"""

from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


# -----------------------------------------------------------------------------
# Security scan results schemas (Bandit)
# -----------------------------------------------------------------------------


class Severity(str, Enum):
    """Finding severity level."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class Finding(BaseModel):
    """Single scan finding (Bandit): file, line, test_id, severity, message, CWE."""

    filename: str = ""
    line: int = 0
    test_id: str = ""
    severity: Severity = Severity.MEDIUM
    message: str = ""
    confidence: str = "MEDIUM"
    cwe_id: str | None = None


class ScanReport(BaseModel):
    """Code scan report (Bandit): findings, metrics, success, error."""

    findings: list[Finding] = Field(default_factory=list)
    metrics: dict[str, int] = Field(default_factory=dict)
    success: bool = True
    error: str | None = None


# -----------------------------------------------------------------------------
# CVE report models (pip-audit)
# -----------------------------------------------------------------------------


class CVEEntry(BaseModel):
    """Single CVE entry (pip-audit): id, description, fix_versions, severity."""

    id: str = Field(description="CVE-YYYY-NNNNN")
    description: str = ""
    fix_versions: list[str] = Field(default_factory=list)
    severity: str = ""


class DependencyVuln(BaseModel):
    """Vulnerable dependency and associated CVE entries."""

    name: str = ""
    version: str = ""
    vulns: list[CVEEntry] = Field(default_factory=list)


class AuditReport(BaseModel):
    """Dependency audit report (pip-audit): dependencies, total_vulns, success, error."""

    dependencies: list[DependencyVuln] = Field(default_factory=list)
    total_vulns: int = 0
    success: bool = True
    error: str | None = None


# -----------------------------------------------------------------------------
# Guardrail violation models
# -----------------------------------------------------------------------------


class GuardrailViolation(BaseModel):
    """Single guardrail violation (validator name, message, optional field/snippet)."""

    validator: str = ""
    message: str = ""
    field: str | None = None
    value_snippet: str = ""


class GuardrailReport(BaseModel):
    """Guardrails validation result: valid, violations, optional sanitized_value."""

    valid: bool = True
    violations: list[GuardrailViolation] = Field(default_factory=list)
    sanitized_value: str | None = None


# -----------------------------------------------------------------------------
# PII detection results
# -----------------------------------------------------------------------------


class PIIEntity(BaseModel):
    """Detected PII entity: type (EMAIL, PHONE, SSN), span, score, text."""

    type: str = Field(description="e.g. EMAIL, PHONE, SSN")
    start: int = 0
    end: int = 0
    score: float = 1.0
    text: str = ""


class PIIDetectionResult(BaseModel):
    """PII detection result: entities, anonymized_text, has_pii."""

    entities: list[PIIEntity] = Field(default_factory=list)
    anonymized_text: str = ""
    has_pii: bool = False


# -----------------------------------------------------------------------------
# Audit configs
# -----------------------------------------------------------------------------


class ScanConfig(BaseModel):
    """Bandit scan configuration (scan.py): targets, severity, confidence, exclude_dirs."""

    targets: list[str] = Field(default_factory=lambda: ["app", "model", "data"])
    severity: int = Field(default=1, ge=0, le=3)
    confidence: int = Field(default=1, ge=0, le=3)
    exclude_dirs: list[str] = Field(default_factory=lambda: [".git", "__pycache__"])
    config_file: str | None = None


class AuditConfig(BaseModel):
    """pip-audit configuration (audit.py): require_audit, ignore_vulns, format, generate_sbom."""

    require_audit: bool = True
    ignore_vulns: list[str] = Field(default_factory=list)
    format: str = "json"
    generate_sbom: bool = False


class GuardsConfig(BaseModel):
    """Guardrails configuration (guards.py): enable_pii, enable_toxicity, enable_prompt_injection, pii_entities."""

    enable_pii: bool = True
    enable_toxicity: bool = True
    enable_prompt_injection: bool = True
    pii_entities: list[str] = Field(
        default_factory=lambda: ["EMAIL", "PHONE", "PERSON"]
    )
