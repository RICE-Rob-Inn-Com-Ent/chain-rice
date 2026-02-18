"""Rice-bot application package: FastAPI HTTP API and core orchestration.

This package provides the top-level application layer:
- FastAPI app, routes, and request/response models (main, models)
- Configuration from environment (config)
- LangGraph agent state machine (agent)
- LiteLLM client and prompts (llm)
- Data facade re-exporting data/ (data)
- Agent-callable tools (tools)
- Shared utilities: logging, retry, exceptions, validators (utils)

All code and comments in this package are in English.
"""
