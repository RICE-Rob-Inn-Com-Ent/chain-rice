# --- Analysis notebook (Marimo .py) ---
# Correlations, clustering. Run with: marimo edit analysis.py
# Uses data.query (run_sql) and data.compute (correlation_matrix when extra data installed).
# All comments in this file are in English.


def __get_mo():
    try:
        import marimo as mo

        return mo
    except ImportError:
        return None


mo = __get_mo()

# Config
import os

os.environ.setdefault("DUCKDB_PATH", ":memory:")

# Data: sample or load from query
from data.query import run_sql

rows = run_sql("SELECT 1 AS a, 2 AS b UNION ALL SELECT 3, 4")
print("Data:", rows)

# Correlation (when data extra)
try:
    from data.compute import correlation_matrix
    import numpy as np

    M = np.array([[r["a"], r["b"]] for r in rows])
    corr = correlation_matrix(M)
    print("Correlation matrix:", corr)
except ImportError:
    print("Install extra 'data' for correlation_matrix")

# Interactive: dropdown for analysis type
if mo and hasattr(mo, "ui"):
    choice = mo.ui.dropdown(
        ["correlation", "summary"], value="correlation", label="Analysis"
    )
else:
    choice = None
