import os


class OpenAIIntegration:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")

    def query(self, prompt: str) -> str:
        if not self.api_key:
            return f"[MOCK OpenAI response] Prompt: {prompt}"
        # In real implementation, this would make API call
        return f"[MOCK OpenAI response with API key] Prompt: {prompt}"
