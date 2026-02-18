"""Security layer: Bandit (code scan), pip-audit (CVE audit), Guardrails AI (guards), Pydantic (models).

Exports scan (run_bandit, generate_scan_report), audit (run_pip_audit, generate_audit_report),
guards (validate_prompt_guardrails, detect_pii, scrub_pii, is_toxic, validate_schema), and
models (Finding, ScanReport, AuditReport, GuardrailReport, PIIEntity, etc.). Optional extra: secure.
All code and comments in this package are in English.
"""

from secure.models import (
    AuditConfig,
    AuditReport,
    CVEEntry,
    DependencyVuln,
    Finding,
    GuardrailReport,
    GuardrailViolation,
    GuardsConfig,
    PIIEntity,
    PIIDetectionResult,
    ScanConfig,
    ScanReport,
    Severity,
)
from secure.scan import (
    generate_scan_report,
    get_bandit_config,
    load_custom_rules,
    run_bandit,
    run_scan_ci,
)
from secure.audit import (
    generate_audit_report,
    generate_sbom,
    run_pip_audit,
    suggest_fixes,
    suggest_fixes_flat,
)
from secure.guards import (
    detect_pii,
    is_prompt_injection,
    is_toxic,
    sanitize_response,
    scrub_pii,
    validate_prompt_guardrails,
    validate_schema,
    validate_toxicity,
)

__all__ = [
    "AuditConfig",
    "AuditReport",
    "CVEEntry",
    "DependencyVuln",
    "Finding",
    "GuardrailReport",
    "GuardrailViolation",
    "GuardsConfig",
    "PIIEntity",
    "PIIDetectionResult",
    "ScanConfig",
    "ScanReport",
    "Severity",
    "generate_scan_report",
    "get_bandit_config",
    "load_custom_rules",
    "run_bandit",
    "run_scan_ci",
    "generate_audit_report",
    "generate_sbom",
    "run_pip_audit",
    "suggest_fixes",
    "suggest_fixes_flat",
    "detect_pii",
    "is_prompt_injection",
    "is_toxic",
    "sanitize_response",
    "scrub_pii",
    "validate_prompt_guardrails",
    "validate_schema",
    "validate_toxicity",
]
