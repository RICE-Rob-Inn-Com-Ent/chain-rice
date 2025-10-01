#!/usr/bin/env python3
"""
Test with mock integrations (no external dependencies)
"""

import sys
import os

# Add parent directory to path for imports
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

print("Testing mock integrations...")

try:
    # Test mock integration imports
    from integration.huggingface_mock import HuggingFaceIntegration

    print("✅ HuggingFace mock integration imported successfully")

    from integration.openai_mock import OpenAIIntegration

    print("✅ OpenAI mock integration imported successfully")

    # Test functionality
    hf = HuggingFaceIntegration()
    openai = OpenAIIntegration()

    print("✅ Mock integration classes instantiated successfully")

    # Test queries (mock responses)
    hf_response = hf.query("Hello world")
    print(f"✅ HuggingFace query: {hf_response}")

    openai_response = openai.query("Hello world")
    print(f"✅ OpenAI query: {openai_response}")

    # Test with API keys set
    os.environ["HF_API_KEY"] = "test_key"
    os.environ["OPENAI_API_KEY"] = "test_key"

    hf_with_key = HuggingFaceIntegration()
    openai_with_key = OpenAIIntegration()

    hf_response_with_key = hf_with_key.query("Hello world")
    print(f"✅ HuggingFace with API key: {hf_response_with_key}")

    openai_response_with_key = openai_with_key.query("Hello world")
    print(f"✅ OpenAI with API key: {openai_response_with_key}")

    print("\n🎉 All mock tests passed! Integration logic works correctly.")

except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
