#!/usr/bin/env python3
"""
Test Ra - God of Light
Sprawdza generowanie obrazów
"""

import requests
import json

RA_URL = "http://localhost:8002"

def test_creepy():
    """Test generowania creepy obrazka"""
    
    # 1. Sprawdź health
    print("🔍 Sprawdzam status Ra...")
    health = requests.get(f"{RA_URL}/health")
    print(json.dumps(health.json(), indent=2))
    
    # 2. Wake up Ra
    print("\n⚡ Budzę Ra...")
    wake = requests.post(f"{RA_URL}/wake")
    print(json.dumps(wake.json(), indent=2))
    
    # 3. Generuj creepy obrazek z DOBRYM promptem
    print("\n🎨 Generuję creepy obrazek...")
    print("Prompt: 'dark horror creature, disturbing monster, nightmare fuel, creepy atmosphere, dark shadows, photorealistic, high detail, 8k'")
    
    payload = {
        "prompt": "dark horror creature, disturbing monster, nightmare fuel, creepy atmosphere, dark shadows, photorealistic, high detail, 8k",
        "negative_prompt": "mountains, landscape, nature, beautiful, bright, colorful, happy, cartoon",
        "steps": 50,
        "cfg_scale": 9.0,
        "width": 512,
        "height": 512
    }
    
    print("\n⏳ Czekam na generowanie (może potrwać 1-2 minuty przy pierwszym użyciu - pobiera model)...")
    
    try:
        result = requests.post(f"{RA_URL}/generate", json=payload, timeout=300)
        
        if result.status_code == 200:
            print("\n✅ Sukces!")
            print(json.dumps(result.json(), indent=2))
            print(f"\n📸 Obrazek zapisany: {result.json()['image_path']}")
        else:
            print(f"\n❌ Błąd: {result.status_code}")
            print(result.text)
            
    except requests.exceptions.Timeout:
        print("\n⏰ Timeout - model się prawdopodobnie wciąż pobiera. Spróbuj ponownie za chwilę.")
    except Exception as e:
        print(f"\n❌ Błąd: {e}")

if __name__ == "__main__":
    test_creepy()

