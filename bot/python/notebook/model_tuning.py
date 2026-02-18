# --- Model tuning notebook (Marimo .py) ---
# Hyperparameter search for embeddings/models. Run with: marimo edit model_tuning.py
# Uses model.embeddings (load_model, generate_embeddings_batch) when extra model installed.
# English only.


def __get_mo():
    try:
        import marimo as mo

        return mo
    except ImportError:
        return None


mo = __get_mo()

# Config: model name and batch size from env or widget
import os

model_name = os.environ.get("EMBEDDING_MODEL", "default")
batch_size = int(os.environ.get("BATCH_SIZE", "32"))

# Placeholder: when job extra installed, load_model and generate_embeddings_batch
try:
    from model.embeddings import load_model, generate_embeddings_batch

    model = load_model(model_name)
    texts = ["hello", "world"]
    emb = generate_embeddings_batch(texts, model=model, batch_size=batch_size)
    print("Embedding shape:", getattr(emb, "shape", type(emb)))
except ImportError:
    print("Install extra 'job' for embedding models")

# Hyperparameters: learning rate, steps (for variational/optimization)
if mo and hasattr(mo, "ui"):
    lr = mo.ui.slider(0.01, 0.5, value=0.1, step=0.01, label="Learning rate")
    steps = mo.ui.slider(10, 500, value=100, label="Steps")
else:
    lr, steps = 0.1, 100

# Export: save config
# with open("tuning_config.json", "w") as f: json.dump({"lr": lr, "steps": steps}, f)
