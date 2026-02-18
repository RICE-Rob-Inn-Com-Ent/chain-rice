"""
Example integration of unified AI bot in Ceramix project
"""

import sys
import os

# Add devcontainer bot to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../../.devcontainer/bot"))

from unified import chat, ModelType

async def dental_assistant(message: str):
    """Dental clinic assistant using unified AI bot"""
    result = await chat(
        message,
        model=ModelType.OPENAI_GPT4,
        system_prompt="You are a helpful dental clinic assistant. Answer questions about dental procedures, appointments, and oral health.",
        max_tokens=500,
        temperature=0.7
    )
    
    if "error" in result:
        return f"Error: {result['error']}"
    
    return result["response"]

async def auto_model_assistant(message: str):
    """Use auto-selected model"""
    result = await chat(message)
    return result.get("response", "No response")

