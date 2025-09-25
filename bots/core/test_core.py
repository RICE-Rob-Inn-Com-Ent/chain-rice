#!/usr/bin/env python3
"""
Test file for AI Bot Core functionality.
"""

import pytest
import asyncio
from unittest.mock import Mock, patch
from app import AIBotCore, app
from fastapi.testclient import TestClient


class TestAIBotCore:
    """Test cases for AIBotCore class."""

    def setup_method(self):
        """Set up test fixtures."""
        self.bot_core = AIBotCore()

    def test_initialization(self):
        """Test AIBotCore initialization."""
        assert self.bot_core.device is not None
        assert self.bot_core.models is not None

    @patch("app.transformers.AutoModel")
    def test_load_transformer_model(self, mock_model):
        """Test loading a transformer model."""
        mock_model.from_pretrained.return_value = Mock()
        result = self.bot_core.load_model("test-model", "transformer")
        assert result is True

    @patch("app.StableDiffusionPipeline")
    def test_load_diffusion_model(self, mock_pipeline):
        """Test loading a diffusion model."""
        mock_pipeline.from_pretrained.return_value = Mock()
        result = self.bot_core.load_model("test-model", "diffusion")
        assert result is True

    def test_load_unknown_model_type(self):
        """Test loading an unknown model type."""
        result = self.bot_core.load_model("test-model", "unknown")
        assert result is False


class TestAPI:
    """Test cases for FastAPI endpoints."""

    def setup_method(self):
        """Set up test fixtures."""
        self.client = TestClient(app)

    def test_root_endpoint(self):
        """Test root endpoint."""
        response = self.client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "version" in data

    def test_health_endpoint(self):
        """Test health check endpoint."""
        response = self.client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    def test_generate_text_missing_prompt(self):
        """Test text generation with missing prompt."""
        response = self.client.post("/generate/text", json={})
        assert response.status_code == 400

    def test_generate_image_missing_prompt(self):
        """Test image generation with missing prompt."""
        response = self.client.post("/generate/image", json={})
        assert response.status_code == 400

    def test_load_model_missing_name(self):
        """Test model loading with missing model name."""
        response = self.client.post("/models/load", json={})
        assert response.status_code == 400

    def test_list_models(self):
        """Test listing models."""
        response = self.client.get("/models")
        assert response.status_code == 200
        data = response.json()
        assert "loaded_models" in data


if __name__ == "__main__":
    pytest.main([__file__])
