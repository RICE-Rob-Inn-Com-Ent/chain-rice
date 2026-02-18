#!/usr/bin/env python3
"""
Test script for receipt OCR processing
Tests CerAI OCR functionality with sample receipts
"""
import os
import json
import base64
import asyncio
import httpx
from pathlib import Path

RECEIPTS_DIR = Path(__file__).parent / "receipts"
CERAI_API_URL = os.getenv("CERAI_API_URL", "http://localhost:8000")


async def test_ocr_receipt(receipt_path: Path):
    """Test OCR on a single receipt"""
    print(f"\n📄 Testing OCR on: {receipt_path.name}")
    
    # Read image as base64
    with open(receipt_path, "rb") as f:
        image_data = f.read()
        base64_data = base64.b64encode(image_data).decode("utf-8")
    
    # Send to OCR API
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{CERAI_API_URL}/api/ocr/base64",
                json={
                    "image_base64": base64_data,
                    "document_type": "receipt"
                },
                timeout=30.0
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ OCR successful!")
                print(f"   Text length: {len(data.get('text', ''))} characters")
                print(f"   Lines extracted: {len(data.get('extracted_data', {}).get('lines', []))}")
                
                # Show first few lines
                lines = data.get('extracted_data', {}).get('lines', [])[:5]
                if lines:
                    print(f"   First lines:")
                    for i, line in enumerate(lines, 1):
                        print(f"      {i}. {line}")
                
                return data
            else:
                print(f"❌ OCR failed: {response.status_code}")
                print(f"   Error: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Error: {e}")
            return None


async def test_chat_with_receipt_data(receipt_data: dict):
    """Test chat API with extracted receipt data"""
    if not receipt_data:
        return
    
    print(f"\n💬 Testing chat with receipt data...")
    
    text = receipt_data.get('text', '')
    if not text:
        print("   No text extracted, skipping chat test")
        return
    
    # Create a prompt to analyze the receipt
    prompt = f"""Przeanalizuj ten paragon i wyciągnij kluczowe informacje:
    
{text[:500]}...

Wyciągnij:
- Data wystawienia
- Numer paragonu
- Sprzedawca (nazwa, NIP)
- Pozycje z cenami
- Kwota całkowita
- Metoda płatności
"""
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{CERAI_API_URL}/api/chat",
                json={
                    "message": prompt,
                    "bot_type": "accounting",
                    "context": "receipt_analysis"
                },
                timeout=60.0
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Chat response received!")
                print(f"   Response: {data.get('response', '')[:200]}...")
                return data
            else:
                print(f"❌ Chat failed: {response.status_code}")
                return None
                
        except Exception as e:
            print(f"❌ Error: {e}")
            return None


async def main():
    """Main test function"""
    print("🧪 CerAI Receipt OCR Testing")
    print("=" * 50)
    
    # Check if receipts directory exists
    if not RECEIPTS_DIR.exists():
        print(f"❌ Receipts directory not found: {RECEIPTS_DIR}")
        return
    
    # Find all image files
    image_extensions = ['.jpg', '.jpeg', '.png', '.pdf']
    receipt_files = [
        f for f in RECEIPTS_DIR.iterdir()
        if f.is_file() and f.suffix.lower() in image_extensions
        and not f.name.startswith('.')
    ]
    
    if not receipt_files:
        print(f"⚠️  No receipt images found in {RECEIPTS_DIR}")
        print(f"   Supported formats: {', '.join(image_extensions)}")
        return
    
    print(f"📁 Found {len(receipt_files)} receipt file(s)")
    
    # Test each receipt
    results = []
    for receipt_file in receipt_files:
        result = await test_ocr_receipt(receipt_file)
        if result:
            results.append({
                "file": receipt_file.name,
                "ocr_result": result
            })
            
            # Test chat with extracted data
            await test_chat_with_receipt_data(result)
    
    # Summary
    print(f"\n📊 Summary:")
    print(f"   Processed: {len(results)}/{len(receipt_files)} receipts")
    print(f"   Successful: {len([r for r in results if r.get('ocr_result')])}")


if __name__ == "__main__":
    asyncio.run(main())




