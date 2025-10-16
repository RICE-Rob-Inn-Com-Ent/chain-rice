import os


class HuggingFaceIntegration:
    def __init__(self, model="gpt2"):
        self.api_key = os.getenv("HF_API_KEY")
        self.model = model

    def query(self, text: str) -> str:
        if not self.api_key:
            return f"[MOCK HF response] Text: {text}"
        # In real implementation, this would make HTTP request
        return f"[MOCK HF response with API key] Text: {text}"
