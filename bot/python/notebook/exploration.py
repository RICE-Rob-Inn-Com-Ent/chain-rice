# --- Exploration notebook (Marimo .py) ---
# Load data, basic stats, plots. Run with: marimo edit exploration.py
# Uses data.query (run_sql) and data.compute (calculate_stats when extra data installed).
# English only.


def __get_mo():
    try:
        import marimo as mo

        return mo
    except ImportError:
        return None


mo = __get_mo()

# Config: use app.config or local overrides
import os

os.environ.setdefault("DUCKDB_PATH", ":memory:")

# Data loading
from data.query import run_sql

rows = run_sql("SELECT 1 AS n UNION ALL SELECT 2")
print("Rows:", rows)

# Basic stats (when data layer has calculate_stats)
try:
    from data.compute import calculate_stats
    import numpy as np

    arr = np.array([r["n"] for r in rows])
    stats = calculate_stats(arr)
    print("Stats:", stats)
except ImportError:
    print("Stats: install extra 'data' for calculate_stats")

# Visualization (Plotly/Matplotlib when available)
if mo and hasattr(mo, "ui"):
    slider = mo.ui.slider(0, 10, value=5, label="Sample")
    display = mo.hstack([slider], justify="start")
else:
    display = None

# Export placeholder
# pd.DataFrame(rows).to_csv("out.csv")  # when pandas available
