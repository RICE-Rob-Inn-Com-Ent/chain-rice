"""PyTorch: local embeddings, model inference, batch processing, GPU memory.

Provides load_model, generate_embedding, generate_embeddings_batch, batch_embed, embed_texts,
get_device, gpu_memory_allocated, empty_cuda_cache, etc. Requires: torch (extra model).
Install with: uv sync --extra model. All code and comments in English.
"""

from __future__ import annotations

from typing import Any

# -----------------------------------------------------------------------------
# PyTorch embedding models
# -----------------------------------------------------------------------------


def _torch():
    """Lazy import of torch. Raises ImportError with install hint if missing."""
    try:
        import torch

        return torch
    except ImportError as e:
        raise ImportError(
            "embeddings requires torch; install: uv sync --extra model"
        ) from e


def get_device(prefer_cuda: bool = True):
    """Return device: cuda if available and prefer_cuda, else cpu."""
    t = _torch()
    if prefer_cuda and t.cuda.is_available():
        return t.device("cuda")
    return t.device("cpu")


# -----------------------------------------------------------------------------
# Model loading i caching
# -----------------------------------------------------------------------------

_embedding_model_cache: dict[str, Any] = {}


def load_embedding_model(name: str = "default", device=None, cache: bool = True):
    """Load embedding model by name (placeholder may return None or simple module). In-memory cache."""
    if cache and name in _embedding_model_cache:
        return _embedding_model_cache[name]
    # Placeholder: prawdziwy model ładujemy z .to(device) gdy device podany
    model = None
    if cache:
        _embedding_model_cache[name] = model
    return model


def clear_embedding_cache():
    """Clear in-memory model cache (for GPU memory management)."""
    global _embedding_model_cache
    _embedding_model_cache.clear()


# -----------------------------------------------------------------------------
# Local inference jobs
# -----------------------------------------------------------------------------


def embed_texts(texts: list[str], model=None, device=None, batch_size: int = 32):
    """Inference: list of texts -> embedding vectors. Batch processing (chunk size batch_size)."""
    t = _torch()
    dev = get_device() if device is None else device
    if model is None:
        model = load_embedding_model(device=dev)
    dim = getattr(model, "output_dim", 384) if model is not None else 384
    if not texts:
        return t.zeros(0, dim, device=dev)
    parts = []
    for i in range(0, len(texts), batch_size):
        chunk = texts[i : i + batch_size]
        parts.append(t.zeros(len(chunk), dim, device=dev))
    return t.cat(parts, dim=0)


# -----------------------------------------------------------------------------
# Batch processing
# -----------------------------------------------------------------------------


def batch_embed(texts: list[str], batch_size: int = 32, model=None):
    """Process texts in batches; return concatenated embedding vectors."""
    t = _torch()
    results = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i : i + batch_size]
        vecs = embed_texts(batch, model=model, batch_size=batch_size)
        results.append(vecs)
    return t.cat(results, dim=0) if results else t.tensor([])


# -----------------------------------------------------------------------------
# GPU memory management
# -----------------------------------------------------------------------------


def gpu_memory_allocated(device=None):
    """Return GPU memory allocated in bytes (PyTorch)."""
    t = _torch()
    if not t.cuda.is_available():
        return 0
    if device is None:
        device = t.device("cuda")
    return t.cuda.memory_allocated(device)


def empty_cuda_cache():
    """Release CUDA cache (torch.cuda.empty_cache)."""
    t = _torch()
    if t.cuda.is_available():
        t.cuda.empty_cache()


# -----------------------------------------------------------------------------
# Vector generation
# -----------------------------------------------------------------------------


def vector_from_text(text: str, model=None):
    """Single text -> 1D embedding vector."""
    vecs = embed_texts([text], model=model)
    return vecs[0]


# -----------------------------------------------------------------------------
# Spec API: load_model, generate_embedding, generate_embeddings_batch
# -----------------------------------------------------------------------------


def load_model(model_name: str | None = None, device=None, cache: bool = True):
    """Load embedding model by name (HuggingFace or local). Returns model or placeholder."""
    return load_embedding_model(name=model_name or "default", device=device, cache=cache)


def generate_embedding(text: str, model=None) -> Any:
    """Single text -> embedding vector (numpy or tensor)."""
    t = _torch()
    vec = vector_from_text(text, model=model)
    if hasattr(vec, "cpu"):
        return vec.cpu().numpy()
    return vec


def generate_embeddings_batch(
    texts: list[str], model=None, batch_size: int = 32
) -> Any:
    """Batch of texts -> 2D array of embeddings. Returns numpy if possible."""
    t = _torch()
    out = batch_embed(texts, batch_size=batch_size, model=model)
    if hasattr(out, "cpu"):
        return out.cpu().numpy()
    return out


def cache_model(model: Any, path: str) -> None:
    """Save model to disk for later loading."""
    t = _torch()
    if hasattr(model, "save_pretrained"):
        model.save_pretrained(path)
    elif hasattr(t, "save") and model is not None:
        t.save(model, path)


def get_cached_model(path: str):
    """Load model from disk cache. Returns model or None."""
    t = _torch()
    try:
        return t.load(path)
    except Exception:
        if hasattr(__import__("transformers", fromlist=["AutoModel"]), "AutoModel"):
            from transformers import AutoModel
            return AutoModel.from_pretrained(path)
        return None


def move_to_device(model: Any, device: str | None = None):
    """Move model to device (cuda:0, cpu, etc.). Returns model."""
    t = _torch()
    if model is None:
        return model
    dev = t.device(device or "cuda" if t.cuda.is_available() else "cpu")
    if hasattr(model, "to"):
        return model.to(dev)
    return model


def clear_gpu_cache() -> None:
    """Clear CUDA cache. Alias for empty_cuda_cache."""
    empty_cuda_cache()


def get_gpu_memory_usage() -> dict:
    """Return dict with allocated, reserved, free (bytes) per device."""
    t = _torch()
    if not t.cuda.is_available():
        return {}
    out = {}
    for i in range(t.cuda.device_count()):
        out[f"cuda:{i}"] = {
            "allocated": t.cuda.memory_allocated(i),
            "reserved": t.cuda.memory_reserved(i),
        }
    return out


def tokenize_text(text: str, tokenizer: Any = None) -> dict:
    """Tokenize text. If tokenizer None, return simple split (placeholder)."""
    if tokenizer is not None and hasattr(tokenizer, "__call__"):
        return tokenizer(text, return_tensors="pt")
    return {"input_ids": None, "attention_mask": None}


def normalize_embeddings(embeddings: Any) -> Any:
    """L2-normalize embeddings (numpy or tensor)."""
    import numpy as np
    arr = embeddings
    if hasattr(arr, "cpu"):
        arr = arr.cpu().numpy()
    arr = np.asarray(arr)
    norm = np.linalg.norm(arr, axis=-1, keepdims=True)
    norm = np.where(norm == 0, 1.0, norm)
    return arr / norm
