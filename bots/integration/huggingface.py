import os
import requests  # noqa


class HuggingFaceIntegration:
    def __init__(self, model="gpt2"):
        self.api_key = os.getenv("HF_API_KEY")
        self.model = model

    def query(self, text: str) -> str:
        if not self.api_key:
            return f"[MOCK HF response] Text: {text}"
        headers = {"Authorization": f"Bearer {self.api_key}"}
        data = {"inputs": text}
        try:
            r = requests.post(
                f"https://api-inference.huggingface.co/models/{self.model}",
                headers=headers,
                json=data,
                timeout=10,
            )
            return r.json()
        except Exception as e:
            return f"[HF ERROR] {str(e)}"
