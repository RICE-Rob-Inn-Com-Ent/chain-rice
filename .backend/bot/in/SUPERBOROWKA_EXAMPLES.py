"""
🫐 Superborówki AI Integration - Usage Examples
==============================================

This file demonstrates how to use the enhanced OpenAI and Hugging Face
integrations for the Superborówki IoT project.

Setup:
    export OPENAI_API_KEY="sk-..."
    export HF_API_KEY="hf_..."
"""

import asyncio
from open_ai import (
    chat_superborowka,
    generate_image,
    transcribe_audio,
    get_embeddings,
    analyze_image,
)
from hugging_face import HuggingFaceCloud


# ============================================================
# Example 1: OpenAI GPT-4 Chat (Superborówki Assistant)
# ============================================================


async def example_gpt4_chat():
    """Basic GPT-4 chat for IoT assistance."""
    response = await chat_superborowka(
        message="Jak zintegrować czujnik temperatury z Raspberry Pi?",
        system_prompt=(
            "Jesteś ekspertem od IoT i systemów wbudowanych. "
            "Odpowiadasz po polsku, konkretnie i profesjonalnie."
        ),
        model="gpt-4-turbo-preview",
        max_tokens=1500,
        temperature=0.7,
    )

    print("🤖 GPT-4 Response:")
    print(f"   Model: {response['model']}")
    print(f"   Latency: {response['latency_ms']}ms")
    print(f"   Response: {response['response']}")
    print(f"   Tokens: {response['usage']['total_tokens']}")


# ============================================================
# Example 2: OpenAI Function Calling
# ============================================================


async def example_function_calling():
    """Use GPT-4 with function calling for IoT device control."""
    functions = [
        {
            "name": "control_device",
            "description": "Control IoT device (on/off, dimming, etc.)",
            "parameters": {
                "type": "object",
                "properties": {
                    "device_id": {
                        "type": "string",
                        "description": "Unique device identifier",
                    },
                    "action": {
                        "type": "string",
                        "enum": ["on", "off", "dim"],
                        "description": "Action to perform",
                    },
                    "value": {
                        "type": "integer",
                        "description": "Value for dimming (0-100)",
                    },
                },
                "required": ["device_id", "action"],
            },
        }
    ]

    response = await chat_superborowka(
        message="Wyłącz światło w kuchni i przyciemnij lampę w salonie do 50%",
        functions=functions,
        model="gpt-4-turbo-preview",
    )

    if "tool_calls" in response:
        print("🔧 Function Calls:")
        for call in response["tool_calls"]:
            print(f"   Function: {call['function']}")
            print(f"   Arguments: {call['arguments']}")


# ============================================================
# Example 3: DALL-E 3 Image Generation
# ============================================================


async def example_image_generation():
    """Generate images with DALL-E 3."""
    result = await generate_image(
        prompt=(
            "Modern IoT dashboard with real-time temperature sensors, "
            "clean minimalist design, dark mode, futuristic"
        ),
        model="dall-e-3",
        size="1792x1024",
        quality="hd",
        style="vivid",
    )

    print("🎨 DALL-E 3:")
    print(f"   Image URL: {result['image_url']}")
    print(f"   Revised Prompt: {result['revised_prompt']}")
    print(f"   Latency: {result['latency_ms']}ms")


# ============================================================
# Example 4: Whisper Audio Transcription
# ============================================================


async def example_audio_transcription():
    """Transcribe IoT voice commands with Whisper."""
    result = await transcribe_audio(
        audio_file_path="/tmp/voice_command.mp3",
        language="pl",  # Polish
    )

    print("🎤 Whisper Transcription:")
    print(f"   Text: {result['text']}")
    print(f"   Language: {result['language']}")


# ============================================================
# Example 5: Text Embeddings for Search
# ============================================================


async def example_embeddings():
    """Generate embeddings for IoT device search."""
    devices = [
        "Czujnik temperatury DHT22",
        "Moduł WiFi ESP8266",
        "Silnik krokowy NEMA 17",
        "Wyświetlacz OLED 128x64",
    ]

    result = await get_embeddings(
        texts=devices,
        model="text-embedding-3-large",
    )

    print("🧮 Embeddings:")
    print(f"   Count: {result['usage']['total_tokens']} tokens")
    print(f"   Dimensions: {len(result['embeddings'][0])}D vectors")


# ============================================================
# Example 6: GPT-4 Vision for IoT Images
# ============================================================


async def example_vision():
    """Analyze IoT circuit diagram with GPT-4 Vision."""
    result = await analyze_image(
        image_url="https://example.com/circuit.jpg",
        prompt=(
            "Przeanalizuj ten schemat elektroniczny. "
            "Jakie komponenty są użyte i czy schemat jest poprawny?"
        ),
        model="gpt-4-turbo",
    )

    print("👁️ GPT-4 Vision:")
    print(f"   Analysis: {result['response']}")


# ============================================================
# Example 7: Hugging Face Inference API (Free)
# ============================================================


async def example_huggingface_chat():
    """Use Hugging Face Mistral-7B (free tier)."""
    hf = HuggingFaceCloud()

    response = await hf.chat_superborowka(
        message="Co to jest protokół MQTT?",
        model="mistralai/Mistral-7B-Instruct-v0.2",
        max_tokens=500,
    )

    print("🤗 Hugging Face Mistral:")
    print(f"   Response: {response['response']}")
    print(f"   Latency: {response['latency_ms']}ms")
    print(f"   Endpoint: {response['endpoint']}")


# ============================================================
# Example 8: Hugging Face Inference Endpoint (Dedicated)
# ============================================================


async def example_huggingface_endpoint():
    """Use dedicated Hugging Face Inference Endpoint."""
    hf = HuggingFaceCloud()

    response = await hf.chat_superborowka(
        message="Jak działa protokół Zigbee?",
        use_endpoint=True,
        endpoint_name="superborowka-mistral-7b",
    )

    print("⚡ HF Inference Endpoint:")
    print(f"   Response: {response['response']}")


# ============================================================
# Example 9: Create Inference Endpoint
# ============================================================


async def example_create_endpoint():
    """Create dedicated Inference Endpoint on HF Cloud."""
    hf = HuggingFaceCloud()

    result = await hf.create_inference_endpoint(
        endpoint_name="superborowka-mistral-7b",
        model="mistralai/Mistral-7B-Instruct-v0.2",
        instance_type="gpu-medium",  # T4 GPU
        region="us-east-1",
        min_replica=1,
        max_replica=3,  # Auto-scaling
    )

    print("🚀 Created Endpoint:")
    print(f"   Name: {result['endpoint_name']}")
    print(f"   URL: {result['url']}")
    print(f"   Status: {result['status']}")
    print(f"   Instance: {result['instance_type']}")


# ============================================================
# Example 10: Deploy to Hugging Face Spaces
# ============================================================


async def example_deploy_space():
    """Deploy Gradio app to Hugging Face Spaces."""
    hf = HuggingFaceCloud()

    result = await hf.deploy_to_space(
        space_name="superborowka/iot-assistant",
        app_file="./demo_app.py",
        requirements=[
            "gradio>=4.0.0",
            "transformers",
            "torch",
        ],
        hardware="t4-small",  # Free GPU tier
        sdk="gradio",
    )

    print("🌐 Deployed Space:")
    print(f"   URL: {result['url']}")
    print(f"   Hardware: {result['hardware']}")


# ============================================================
# Example 11: Stable Diffusion on Hugging Face
# ============================================================


async def example_hf_image_generation():
    """Generate images with Stable Diffusion on HF."""
    hf = HuggingFaceCloud()

    result = await hf.generate_image(
        prompt="IoT sensor network diagram, technical illustration",
        model="stabilityai/stable-diffusion-xl-base-1.0",
        negative_prompt="blurry, low quality",
        num_inference_steps=50,
    )

    print("🎨 Stable Diffusion XL:")
    print(f"   Image: {result}")


# ============================================================
# Example 12: Sentiment Analysis
# ============================================================


async def example_sentiment():
    """Analyze sentiment of user feedback."""
    hf = HuggingFaceCloud()

    result = await hf.analyze_sentiment(
        text="Ten czujnik jest świetny! Działa bez zarzutu.",
    )

    print("😊 Sentiment Analysis:")
    print(f"   Result: {result}")


# ============================================================
# Run All Examples
# ============================================================


async def main():
    """Run all examples."""
    print("=" * 60)
    print("🫐 Superborówki AI Integration Examples")
    print("=" * 60)
    print()

    examples = [
        ("GPT-4 Chat", example_gpt4_chat),
        ("Function Calling", example_function_calling),
        ("DALL-E 3", example_image_generation),
        ("Whisper", example_audio_transcription),
        ("Embeddings", example_embeddings),
        ("GPT-4 Vision", example_vision),
        ("HF Chat (Free)", example_huggingface_chat),
        ("HF Endpoint", example_huggingface_endpoint),
        ("HF Sentiment", example_sentiment),
    ]

    for name, func in examples:
        try:
            print(f"\n📍 {name}")
            print("-" * 60)
            await func()
        except Exception as e:
            print(f"   ❌ Error: {e}")

    print("\n" + "=" * 60)
    print("✅ All examples completed!")


if __name__ == "__main__":
    asyncio.run(main())

