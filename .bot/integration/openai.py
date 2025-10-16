import os

import openai


class OpenAIIntegration:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        if self.api_key:
            openai.api_key = self.api_key

    def query(self, prompt: str) -> str:
        if not self.api_key:
            return f"[MOCK OpenAI response] Prompt: {prompt}"
        try:
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=50
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"[OpenAI ERROR] {str(e)}"
