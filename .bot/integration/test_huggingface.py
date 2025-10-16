#!/usr/bin/env python3
"""
Test for Hugging Face integration
"""

import unittest

from huggingface import HuggingFaceIntegration


class TestHuggingFaceIntegration(unittest.TestCase):
    def setUp(self):
        self.hf = HuggingFaceIntegration()

    def test_initialization(self):
        """Test that HuggingFace integration initializes correctly"""
        self.assertIsNotNone(self.hf)
        self.assertEqual(self.hf.model, "gpt2")

    def test_query_without_api_key(self):
        """Test query without API key (should return mock response)"""
        response = self.hf.query("Hello world")
        self.assertIsInstance(response, str)
        self.assertIn("MOCK HF response", response)
        self.assertIn("Hello world", response)

    def test_query_with_different_model(self):
        """Test query with different model"""
        self.hf.model = "bert-base-uncased"
        response = self.hf.query("Test text")
        self.assertIsInstance(response, str)


if __name__ == "__main__":
    unittest.main()
