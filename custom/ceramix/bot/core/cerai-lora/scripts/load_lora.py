#!/usr/bin/env python3
"""
LoRA Adapter Loading Script

Loads trained LoRA adapters for inference.
"""

import os
import logging
from pathlib import Path
from typing import Optional

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel, PeftConfig

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class LoRALoader:
    """Load and manage LoRA adapters for inference."""
    
    def __init__(self, adapters_dir: str = "/app/adapters"):
        self.adapters_dir = Path(adapters_dir)
        
    def load_adapter(
        self,
        base_model_name: str,
        adapter_name: str,
        device: str = "cuda" if torch.cuda.is_available() else "cpu",
    ):
        """Load base model with LoRA adapter."""
        adapter_path = self.adapters_dir / adapter_name
        
        if not adapter_path.exists():
            raise FileNotFoundError(f"Adapter not found: {adapter_path}")
        
        logger.info(f"Loading base model: {base_model_name}")
        tokenizer = AutoTokenizer.from_pretrained(
            base_model_name,
            trust_remote_code=True,
        )
        
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token
        
        model = AutoModelForCausalLM.from_pretrained(
            base_model_name,
            torch_dtype=torch.float16 if device == "cuda" else torch.float32,
            device_map="auto" if device == "cuda" else None,
            trust_remote_code=True,
        )
        
        logger.info(f"Loading LoRA adapter: {adapter_path}")
        model = PeftModel.from_pretrained(model, str(adapter_path))
        model.eval()
        
        return model, tokenizer
    
    def list_adapters(self):
        """List available adapters."""
        adapters = []
        if self.adapters_dir.exists():
            for adapter_dir in self.adapters_dir.iterdir():
                if adapter_dir.is_dir():
                    adapters.append(adapter_dir.name)
        return adapters


if __name__ == "__main__":
    loader = LoRALoader()
    adapters = loader.list_adapters()
    print(f"Available adapters: {adapters}")



