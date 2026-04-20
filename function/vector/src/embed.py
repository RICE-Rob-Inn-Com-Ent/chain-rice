"""Torch — modele embeddingów, kodowanie tekstu (i opcjonalnie obrazów), batch, urządzenie."""

# TODO(rice):
# [ ] SAGE / function — ML & orchestration; no secrets in code.
# [ ] Soft-code: pydantic-settings / env vars; never API keys in repo.
# [ ] Contracts: gRPC/proto from gen when wired; schema changes via MASON.
# [ ] Stack surface: numpy, pydantic, httpx, langgraph, qdrant-client, etc. — extend per package.
#
from __future__ import annotations

import hashlib
from collections.abc import Callable, Sequence
from typing import Any, Protocol, runtime_checkable

import numpy as np
import torch
import torch.nn.functional as F
from loguru import logger

# TODO:
# [ ] implement embedding model loader:
# [ ]     model from RICE_EMBEDDING_MODEL env var
# [ ]     backends: sentence-transformers, openai-compatible API, Ollama embed API
# [ ]     backend from RICE_EMBED_BACKEND env var
# [ ] implement batched embedding:
# [ ]     batch_size from RICE_EMBED_BATCH_SIZE env var
# [ ]     async batching via asyncio.gather
# [ ] implement embedding caching:
# [ ]     cache via Qdrant lookup before re-embedding
# [ ]     cache_collection from RICE_EMBED_CACHE_COLLECTION env var
# [ ] implement embedding normalization: L2 normalize before storing
# [ ] implement dimensionality reduction: PCA/UMAP when RICE_EMBED_REDUCE=true
# [ ]     target_dim from RICE_EMBED_TARGET_DIM env var
# [ ] implement multi-lingual embeddings:
# [ ]     detect language, route to language-specific model


def pick_device(prefer_cuda: bool = True) -> torch.device:
    """Wybór urządzenia: CUDA jeśli dostępne, inaczej CPU."""
    if prefer_cuda and torch.cuda.is_available():
        return torch.device("cuda")
    if getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def to_device(batch: torch.Tensor, device: torch.device | None) -> torch.Tensor:
    if device is None:
        return batch
    return batch.to(device=device, non_blocking=device.type == "cuda")


@runtime_checkable
class TextEmbedder(Protocol):
    """Protokół enkodera tekstu → wektory znormalizowane L2."""

    embedding_dim: int

    def encode(
        self,
        texts: Sequence[str],
        *,
        batch_size: int = 32,
        normalize: bool = True,
    ) -> torch.Tensor:
        """Zwraca tensor float32 [N, D] na `pick_device()` lub CPU wg implementacji."""


class HashProjectionEmbedder:
    """Deterministyczne wektory (dev/test) — bez pobierania modeli; nie do produkcji."""

    def __init__(self, dim: int = 384, seed: bytes = b"rice-vector") -> None:
        self.embedding_dim = dim
        self._seed = seed

    def encode(
        self,
        texts: Sequence[str],
        *,
        batch_size: int = 32,
        normalize: bool = True,
    ) -> torch.Tensor:
        device = pick_device(prefer_cuda=False)
        out: list[torch.Tensor] = []
        for i in range(0, len(texts), batch_size):
            chunk = texts[i : i + batch_size]
            vecs = []
            for t in chunk:
                h = hashlib.blake2b(
                    self._seed + t.encode("utf-8"),
                    digest_size=64,
                ).digest()
                buf = (h * (self.embedding_dim // len(h) + 1))[: self.embedding_dim]
                arr = np.frombuffer(buf, dtype=np.uint8).astype(np.float32)
                arr = arr / 255.0 * 2.0 - 1.0
                vecs.append(arr)
            batch = torch.tensor(np.stack(vecs), dtype=torch.float32, device=device)
            if normalize:
                batch = F.normalize(batch, p=2, dim=-1)
            out.append(batch)
        return torch.cat(out, dim=0)


class SentenceTransformerEmbedder:
    """Wrapper na `sentence_transformers` (opcjonalna zależność)."""

    def __init__(self, model_name: str, device: torch.device | None = None) -> None:
        try:
            from sentence_transformers import SentenceTransformer
        except ImportError as e:
            msg = "Zainstaluj opcjonalnie: pip install sentence-transformers"
            raise ImportError(msg) from e
        self._device = device or pick_device()
        self._model = SentenceTransformer(model_name, device=str(self._device))
        self.embedding_dim = self._model.get_sentence_embedding_dimension()

    def encode(
        self,
        texts: Sequence[str],
        *,
        batch_size: int = 32,
        normalize: bool = True,
    ) -> torch.Tensor:
        emb = self._model.encode(
            list(texts),
            batch_size=batch_size,
            convert_to_tensor=True,
            normalize_embeddings=normalize,
            show_progress_bar=False,
        )
        if not isinstance(emb, torch.Tensor):
            emb = torch.tensor(emb, dtype=torch.float32, device=self._device)
        return emb


def encode_text_batches(
    texts: Sequence[str],
    forward: Callable[[torch.Tensor], torch.Tensor],
    tokenizer: Callable[[Sequence[str]], dict[str, torch.Tensor]],
    *,
    batch_size: int = 16,
    device: torch.device | None = None,
) -> torch.Tensor:
    """Niskopoziomowe batchowanie dla własnego `nn.Module` + tokenizera HuggingFace."""
    device = device or pick_device()
    outs: list[torch.Tensor] = []
    texts_list = list(texts)
    for i in range(0, len(texts_list), batch_size):
        batch = texts_list[i : i + batch_size]
        toks = tokenizer(batch)
        toks = {k: v.to(device) for k, v in toks.items()}
        with torch.inference_mode():
            vec = forward(**toks)
        outs.append(vec.detach().float().cpu())
    return torch.cat(outs, dim=0)


def encode_image_batch_dummy(images: Sequence[Any], *, dim: int = 512) -> torch.Tensor:
    """Placeholder na potok wizualny — podłącz torchvision/CLIP w deploymencie."""
    logger.warning("encode_image_batch_dummy: zwraca zera — podłącz model obrazów.")
    return torch.zeros(len(images), dim, dtype=torch.float32)
