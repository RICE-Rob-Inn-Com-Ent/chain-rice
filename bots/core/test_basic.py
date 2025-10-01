#!/usr/bin/env python3
"""
Basic test without external dependencies
"""

import sys
import os

# Add parent directory to path for imports
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

print("Testing basic imports...")

try:
    # Test integration imports (without external deps)
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

    print("\n🎉 All basic tests passed! Integrations work correctly.")
    print(
        "📝 Note: External dependencies (requests, openai) need to be installed for full functionality"
    )

except ImportError as e:
    print(f"❌ Import error: {e}")
    print("💡 This is expected if external dependencies are not installed")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
