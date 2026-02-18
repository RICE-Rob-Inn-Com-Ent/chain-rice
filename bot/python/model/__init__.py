"""Model layer: CrewAI (crew), Qdrant+BM25 (memory), instructor (extract), outlines (constrain), PyTorch (embeddings), job queue (scheduler), Pydantic (models).

Exports agents/tasks/crews, hybrid search, structured extraction, constrained generation,
embedding models, GPU scheduler, and shared model schemas. Requires extra: model.
All code and comments in this package are in English.
"""

from model.constrain import json_completion
from model.crew import SYSTEM_PROMPT, USER_PROMPT_TEMPLATE, create_crew
from model.extract import extract_structured
from model.memory import get_vector_store, hybrid_search
from model.models import (
    CheckpointMeta,
    DeviceType,
    EmbeddingModelConfig,
    ExtractionResult,
    ValidatedOutput,
)
from model.embeddings import (
    batch_embed,
    clear_embedding_cache,
    embed_texts,
    empty_cuda_cache,
    generate_embedding,
    generate_embeddings_batch,
    get_device,
    get_gpu_memory_usage,
    gpu_memory_allocated,
    load_embedding_model,
    load_model,
    vector_from_text,
)
from model.scheduler import (
    Job,
    JobQueue,
    Priority,
    assign_device,
    cuda_available,
    cuda_device_count,
    device_placement,
    gpu_memory_reserved,
    gpu_memory_summary,
    run_next,
    submit_job,
    get_job_status,
    suggest_batch_size,
)

__all__ = [
    "create_crew",
    "SYSTEM_PROMPT",
    "USER_PROMPT_TEMPLATE",
    "get_vector_store",
    "hybrid_search",
    "extract_structured",
    "json_completion",
    "ExtractionResult",
    "ValidatedOutput",
    "CheckpointMeta",
    "DeviceType",
    "EmbeddingModelConfig",
    "batch_embed",
    "clear_embedding_cache",
    "embed_texts",
    "empty_cuda_cache",
    "generate_embedding",
    "generate_embeddings_batch",
    "get_device",
    "get_gpu_memory_usage",
    "gpu_memory_allocated",
    "load_embedding_model",
    "load_model",
    "vector_from_text",
    "Job",
    "JobQueue",
    "Priority",
    "assign_device",
    "cuda_available",
    "cuda_device_count",
    "device_placement",
    "gpu_memory_reserved",
    "gpu_memory_summary",
    "run_next",
    "submit_job",
    "get_job_status",
    "suggest_batch_size",
]
