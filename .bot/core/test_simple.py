#!/usr/bin/env python3
"""
Simple test without external dependencies
"""

import os
import sys

# Add parent directory to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

print("Testing imports...")

try:
    # Test integration imports
    import os
    import sys

    sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

    from integration.huggingface import HuggingFaceIntegration

    print("✅ HuggingFace integration imported successfully")

    from integration.openai import OpenAIIntegration

    print("✅ OpenAI integration imported successfully")

    # Test functionality
    hf = HuggingFaceIntegration()
    openai = OpenAIIntegration()

    print("✅ Integration classes instantiated successfully")

    # Test queries (mock responses)
    hf_response = hf.query("Hello world")
    print(f"✅ HuggingFace query: {hf_response}")

    openai_response = openai.query("Hello world")
    print(f"✅ OpenAI query: {openai_response}")

    print("\n🎉 All tests passed! Integrations work correctly.")

except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
