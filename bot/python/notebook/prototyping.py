# --- Prototyping notebook (Marimo .py) ---
# Test new features before adding to codebase. Run with: marimo edit prototyping.py
# Exercises app.utils (is_safe_sql, detect_prompt_injection) and app.data (run_sql, is_safe_query).
# English only.


def __get_mo():
    try:
        import marimo as mo

        return mo
    except ImportError:
        return None


mo = __get_mo()

# Config
import os

os.environ.setdefault("LITELLM_API_KEY", "")

# Test app.utils validators
from app.utils import is_safe_sql, detect_prompt_injection

print("is_safe_sql('SELECT 1'):", is_safe_sql("SELECT 1"))
print("detect_prompt_injection('hello'):", detect_prompt_injection("hello"))

# Test data facade
from app.data import run_sql, is_safe_query

ok, _ = is_safe_query("SELECT 1")
print("is_safe_query:", ok)
print("run_sql:", run_sql("SELECT 1 AS x")[:1])

# Reactive: when marimo available
if mo and hasattr(mo, "ui"):
    text = mo.ui.text_area(label="Paste SQL (read-only)")
else:
    text = None
