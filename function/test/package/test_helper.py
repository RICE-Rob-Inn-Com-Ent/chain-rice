"""Tests for `function/helper` — settings, log, schema, validation."""

# TODO:
# [ ] test settings: all required fields load from env
# [ ] test settings validation: missing required field raises ValidationError
# [ ] test log: loguru configured with correct level and format
# [ ] test retry: function retried n times before raising
# [ ] test circuit_breaker: opens after threshold failures
# [ ] test validate_payload: valid dict → model instance
# [ ] test validate_payload: invalid dict → ValidationError with clear message
# [ ] test convert: numpy float16 array → Python list without precision loss
# [ ] test convert: Polars DataFrame → list[dict] → Pydantic model list
# [ ] test error hierarchy: all custom exceptions inherit from RiceError
# [ ] test sensitive data masking: api_key not in log output
