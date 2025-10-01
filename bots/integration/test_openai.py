#!/usr/bin/env python3
"""
Test for OpenAI integration
"""

import unittest
from openai import OpenAIIntegration


class TestOpenAIIntegration(unittest.TestCase):
    def setUp(self):
        self.openai = OpenAIIntegration()

    def test_initialization(self):
        """Test that OpenAI integration initializes correctly"""
        self.assertIsNotNone(self.openai)

    def test_query_without_api_key(self):
        """Test query without API key (should return mock response)"""
        response = self.openai.query("Hello world")
        self.assertIsInstance(response, str)
        self.assertIn("MOCK OpenAI response", response)
        self.assertIn("Hello world", response)

    def test_query_with_empty_prompt(self):
        """Test query with empty prompt"""
        response = self.openai.query("")
        self.assertIsInstance(response, str)


if __name__ == "__main__":
    unittest.main()
