"""
Hugging Face Cloud Integration - Full Featured
Comprehensive HF wrapper with:
- Inference API (free tier)
- Inference Endpoints (dedicated)
- Spaces deployment & hosting
- Model hub access
- Custom model deployment
- Task-specific pipelines
"""

import os
import time
from typing import Any
import requests
from huggingface_hub import (
    HfApi,
    InferenceClient,
    create_inference_endpoint,
    list_inference_endpoints,
)


# ============================================================
# 🌥️ Hugging Face Cloud Manager
# ============================================================

class HuggingFaceCloud:
    """
    Comprehensive Hugging Face Cloud Integration
    Supports: Inference API, Inference Endpoints, Spaces, Model Hub
    """

    def __init__(
        self,
        api_key: str | None = None,
        default_model: str = "mistralai/Mistral-7B-Instruct-v0.2",
    ):
        self.api_key = api_key or os.getenv(
            "HF_API_KEY", os.getenv("HUGGINGFACE_TOKEN")
        )
        self.default_model = default_model
        auth = f"Bearer {self.api_key}" if self.api_key else ""
        self.headers = {"Authorization": auth} if self.api_key else {}

        # Initialize HF API clients
        self.api = HfApi(token=self.api_key) if self.api_key else None
        client = InferenceClient(token=self.api_key) if self.api_key else None
        self.inference_client = client

    # ============================================================
    # 🚀 SUPERBORÓWKI - Text Generation
    # ============================================================

    async def chat_superborowka(
        self,
        message: str,
        model: str | None = None,
        system_prompt: str = "You are a helpful AI assistant.",
        max_tokens: int = 1000,
        temperature: float = 0.7,
        *,
        use_endpoint: bool = False,
        endpoint_name: str | None = None,
    ) -> dict[str, Any]:
        """
        🫐 Superborówki AI Chat using Hugging Face

        Args:
            message: User message
            model: HF model to use (default: Mistral-7B)
            system_prompt: System instructions
            max_tokens: Max response tokens
            temperature: Creativity (0-1)
            use_endpoint: Use dedicated Inference Endpoint
            endpoint_name: Custom endpoint name
        """
        start_time = time.time()
        model = model or self.default_model

        try:
            # Construct prompt with system message
            full_prompt = f"{system_prompt}\n\nUser: {message}\nAssistant:"

            if use_endpoint and endpoint_name:
                # Use dedicated Inference Endpoint
                result = await self._query_inference_endpoint(
                    endpoint_name=endpoint_name,
                    inputs=full_prompt,
                    parameters={
                        "max_new_tokens": max_tokens,
                        "temperature": temperature,
                        "return_full_text": False,
                    },
                )
            else:
                # Use free Inference API
                result = await self._query_inference_api(
                    model=model,
                    inputs=full_prompt,
                    parameters={
                        "max_new_tokens": max_tokens,
                        "temperature": temperature,
                        "return_full_text": False,
                    },
                )

            latency = (time.time() - start_time) * 1000

            if isinstance(result, dict) and "error" in result:
                return {
                    "model": model,
                    "error": result["error"],
                    "latency_ms": round(latency, 2),
                }

            # Extract response text
            response_text = ""
            if isinstance(result, list) and len(result) > 0:
                response_text = result[0].get("generated_text", "")
            elif isinstance(result, dict):
                response_text = result.get("generated_text", "")

            return {
                "model": model,
                "response": response_text,
                "latency_ms": round(latency, 2),
                "endpoint": endpoint_name if use_endpoint else "inference-api",
            }

        except Exception as e:
            return {
                "model": model,
                "error": str(e),
                "latency_ms": round((time.time() - start_time) * 1000, 2),
            }

    # ============================================================
    # 🔌 Inference API - Free Tier
    # ============================================================

    async def _query_inference_api(
        self,
        model: str,
        inputs: str,
        parameters: dict | None = None,
        task: str | None = None,
    ) -> Any:
        """Query Hugging Face Inference API (free, rate-limited)."""
        url = f"https://api-inference.huggingface.co/models/{model}"

        payload = {"inputs": inputs}
        if parameters:
            payload["parameters"] = parameters
        if task:
            payload["task"] = task

        try:
            response = requests.post(
                url,
                headers=self.headers,
                json=payload,
                timeout=30,
            )

            if response.status_code == 503:
                # Model is loading
                error_msg = "Model is loading. Retry in 20 seconds."
                return {"error": error_msg, "loading": True}

            response.raise_for_status()
            return response.json()

        except requests.exceptions.RequestException as e:
            return {"error": str(e)}

    # ============================================================
    # ⚡ Inference Endpoints - Dedicated Cloud
    # ============================================================

    async def _query_inference_endpoint(
        self,
        endpoint_name: str,
        inputs: str,
        parameters: dict | None = None,
    ) -> Any:
        """Query dedicated Inference Endpoint (paid, no rate limit)."""
        api_error = "HF API key required for Inference Endpoints"
        if not self.api_key:
            return {"error": api_error}

        try:
            # Get endpoint URL
            endpoints = list_inference_endpoints(token=self.api_key)
            endpoint = next(
                (e for e in endpoints if e.name == endpoint_name), None
            )

            if not endpoint:
                return {"error": f"Endpoint '{endpoint_name}' not found"}

            endpoint_url = endpoint.url

            payload = {"inputs": inputs}
            if parameters:
                payload["parameters"] = parameters

            response = requests.post(
                endpoint_url,
                headers=self.headers,
                json=payload,
                timeout=60,
            )

            response.raise_for_status()
            return response.json()

        except Exception as e:
            return {"error": str(e)}

    async def create_inference_endpoint(
        self,
        endpoint_name: str,
        model: str,
        instance_type: str = "cpu-medium",
        region: str = "us-east-1",
        min_replica: int = 1,
        max_replica: int = 1,
    ) -> dict[str, Any]:
        """Create dedicated Inference Endpoint.

        Args:
            endpoint_name: Unique name for endpoint
            model: HF model to deploy
            instance_type: cpu/gpu type
            region: us-east-1, eu-west-1, etc.
            min_replica: Min instances (scaling)
            max_replica: Max instances (scaling)

        Returns:
            Endpoint details and URL.
        """
        api_error = "HF API key required"
        if not self.api_key:
            return {"error": api_error}

        try:
            endpoint = create_inference_endpoint(
                name=endpoint_name,
                repository=model,
                framework="pytorch",
                accelerator=instance_type,
                region=region,
                vendor="aws",
                min_replica=min_replica,
                max_replica=max_replica,
                type="protected",
                token=self.api_key,
            )

            return {
                "success": True,
                "endpoint_name": endpoint_name,
                "url": endpoint.url,
                "status": endpoint.status,
                "model": model,
                "instance_type": instance_type,
                "region": region,
            }

        except Exception as e:
            return {"error": str(e)}

    async def list_inference_endpoints(self) -> dict[str, Any]:
        """List all active Inference Endpoints."""
        api_error = "HF API key required"
        if not self.api_key:
            return {"error": api_error}

        try:
            endpoints = list_inference_endpoints(token=self.api_key)

            return {
                "endpoints": [
                    {
                        "name": e.name,
                        "url": e.url,
                        "status": e.status,
                        "model": e.repository,
                        "instance_type": e.type,
                    }
                    for e in endpoints
                ],
                "count": len(endpoints),
            }

        except Exception as e:
            return {"error": str(e)}

    # ============================================================
    # 🚀 Spaces Deployment
    # ============================================================

    async def deploy_to_space(
        self,
        space_name: str,
        app_file: str,
        requirements: list[str],
        hardware: str = "cpu-basic",
        sdk: str = "gradio",
    ) -> dict[str, Any]:
        """Deploy app to Hugging Face Spaces.

        Args:
            space_name: Space name (username/space-name)
            app_file: Path to app.py
            requirements: List of Python packages
            hardware: cpu-basic, t4-small, etc.
            sdk: gradio, streamlit, docker, static
        """
        api_error = "HF API key required"
        if not self.api_key:
            return {"error": api_error}

        try:
            # Create Space
            self.api.create_repo(
                repo_id=space_name,
                repo_type="space",
                space_sdk=sdk,
                space_hardware=hardware,
                exist_ok=True,
            )

            # Upload files
            with open(app_file, "r") as f:
                app_content = f.read()

            self.api.upload_file(
                path_or_fileobj=app_content.encode(),
                path_in_repo="app.py",
                repo_id=space_name,
                repo_type="space",
            )

            # Upload requirements
            requirements_content = "\n".join(requirements)
            self.api.upload_file(
                path_or_fileobj=requirements_content.encode(),
                path_in_repo="requirements.txt",
                repo_id=space_name,
                repo_type="space",
            )

            space_url = f"https://huggingface.co/spaces/{space_name}"

            return {
                "success": True,
                "space_name": space_name,
                "url": space_url,
                "hardware": hardware,
                "sdk": sdk,
            }

        except Exception as e:
            return {"error": str(e)}

    # ============================================================
    # 🎨 Task-Specific Methods
    # ============================================================

    async def generate_image(
        self,
        prompt: str,
        model: str = "stabilityai/stable-diffusion-xl-base-1.0",
        negative_prompt: str | None = None,
        num_inference_steps: int = 50,
    ) -> dict[str, Any]:
        """Generate image with Stable Diffusion."""
        parameters = {
            "negative_prompt": negative_prompt,
            "num_inference_steps": num_inference_steps,
        }

        result = await self._query_inference_api(
            model=model,
            inputs=prompt,
            parameters=parameters,
            task="text-to-image",
        )

        return result

    async def generate_embeddings(
        self,
        texts: list[str],
        model: str = "sentence-transformers/all-MiniLM-L6-v2",
    ) -> dict[str, Any]:
        """Generate text embeddings."""
        start_time = time.time()

        try:
            embeddings = []
            for text in texts:
                result = await self._query_inference_api(
                    model=model,
                    inputs=text,
                    task="feature-extraction",
                )
                if isinstance(result, dict) and "error" not in result:
                    embeddings.append(result)

            latency = (time.time() - start_time) * 1000

            return {
                "embeddings": embeddings,
                "model": model,
                "count": len(embeddings),
                "latency_ms": round(latency, 2),
            }

        except Exception as e:
            return {"error": str(e)}

    async def analyze_sentiment(
        self,
        text: str,
        model: str = "distilbert-base-uncased-finetuned-sst-2-english",
    ) -> dict[str, Any]:
        """Analyze text sentiment."""
        result = await self._query_inference_api(
            model=model,
            inputs=text,
            task="sentiment-analysis",
        )
        return result


# ============================================================
# 🛠️ Legacy - Backward Compatibility
# ============================================================

class HuggingFaceIntegration:
    """Legacy class for backward compatibility"""

    def __init__(self, model="gpt2"):
        self.api_key = os.getenv("HF_API_KEY")
        self.model = model
        self.cloud = HuggingFaceCloud(api_key=self.api_key, default_model=model)

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
