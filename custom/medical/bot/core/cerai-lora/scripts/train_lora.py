#!/usr/bin/env python3
"""
LoRA Training Script for CerAI Models

Trains LoRA adapters for:
1. Bielik (Polish language understanding)
2. Formatter model (JSON/structured output)
"""

import os
import json
import logging
from pathlib import Path
from typing import Optional, Dict, Any

import torch
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    TrainingArguments,
    Trainer,
    DataCollatorForLanguageModeling,
)
from peft import (
    LoraConfig,
    get_peft_model,
    prepare_model_for_kbit_training,
    TaskType,
)
from datasets import Dataset, load_dataset
from accelerate import Accelerator

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class LoRATrainer:
    """Trainer for LoRA adapters on Polish invoice data."""
    
    def __init__(
        self,
        model_name: str,
        output_dir: str,
        adapter_name: str,
        lora_r: int = 8,
        lora_alpha: int = 16,
        lora_dropout: float = 0.1,
        batch_size: int = 4,
        gradient_accumulation_steps: int = 4,
        learning_rate: float = 2e-4,
        num_epochs: int = 3,
        max_length: int = 512,
    ):
        self.model_name = model_name
        self.output_dir = Path(output_dir)
        self.adapter_name = adapter_name
        self.lora_r = lora_r
        self.lora_alpha = lora_alpha
        self.lora_dropout = lora_dropout
        self.batch_size = batch_size
        self.gradient_accumulation_steps = gradient_accumulation_steps
        self.learning_rate = learning_rate
        self.num_epochs = num_epochs
        self.max_length = max_length
        
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize accelerator
        self.accelerator = Accelerator()
        
    def load_model_and_tokenizer(self):
        """Load base model and tokenizer."""
        logger.info(f"Loading model: {self.model_name}")
        
        # Load tokenizer
        self.tokenizer = AutoTokenizer.from_pretrained(
            self.model_name,
            trust_remote_code=True,
        )
        
        # Add padding token if missing
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
            
        # Load model with 8-bit quantization for memory efficiency
        self.model = AutoModelForCausalLM.from_pretrained(
            self.model_name,
            torch_dtype=torch.float16,
            device_map="auto",
            trust_remote_code=True,
            load_in_8bit=True,
        )
        
        # Prepare model for k-bit training
        self.model = prepare_model_for_kbit_training(self.model)
        
        logger.info("Model and tokenizer loaded successfully")
        
    def setup_lora(self):
        """Configure and apply LoRA adapters."""
        logger.info("Setting up LoRA configuration")
        
        lora_config = LoraConfig(
            r=self.lora_r,
            lora_alpha=self.lora_alpha,
            target_modules=self._get_target_modules(),
            lora_dropout=self.lora_dropout,
            bias="none",
            task_type=TaskType.CAUSAL_LM,
        )
        
        self.model = get_peft_model(self.model, lora_config)
        self.model.print_trainable_parameters()
        
        logger.info("LoRA adapters configured")
        
    def _get_target_modules(self) -> list:
        """Get target modules for LoRA based on model architecture."""
        # Common target modules for different architectures
        if "qwen" in self.model_name.lower():
            return ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]
        elif "llama" in self.model_name.lower() or "mistral" in self.model_name.lower():
            return ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]
        elif "herbert" in self.model_name.lower() or "polish" in self.model_name.lower():
            return ["query", "key", "value", "dense"]
        else:
            # Default: try common attention modules
            return ["q_proj", "k_proj", "v_proj", "o_proj"]
    
    def prepare_dataset(self, data_path: Optional[str] = None) -> Dataset:
        """Prepare training dataset."""
        logger.info("Preparing dataset")
        
        if data_path and os.path.exists(data_path):
            # Load from local file
            with open(data_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        else:
            # Use default sample data for invoice extraction
            data = self._get_default_invoice_data()
        
        # Convert to dataset format
        dataset = Dataset.from_list(data)
        
        # Tokenize
        def tokenize_function(examples):
            texts = examples.get("text", examples.get("input", []))
            return self.tokenizer(
                texts,
                truncation=True,
                padding="max_length",
                max_length=self.max_length,
                return_tensors="pt",
            )
        
        tokenized_dataset = dataset.map(
            tokenize_function,
            batched=True,
            remove_columns=dataset.column_names,
        )
        
        logger.info(f"Dataset prepared: {len(tokenized_dataset)} examples")
        return tokenized_dataset
    
    def _get_default_invoice_data(self) -> list:
        """Get default training data for Polish invoice extraction."""
        return [
            {
                "text": """Przeanalizuj tę fakturę i wyciągnij kluczowe informacje:

FAKTURA
Numer: 11646/F/229/25
Data wystawienia: 02-11-2025 15:22
Data sprzedaży: 02-11-2025

Sprzedawca:
MOL Polska sp. z o.o.
al. Grunwaldzka 50 A, 80-241 Gdańsk
BDO: 000021875
Stacja Paliw Nr: 229 - Rybnik
44-203 Rybnik ul. Żorska 83
KASA: 2
NIP: 583-10-23-182

Nabywca:
RICE PROSTA SPÓŁKA AKCYJNA
ul. Kościelna 13, 44-200 Rybnik
NIP: 9691666521

Forma płatności: Gotówka

Produkt: EVO Diesel Plus CN27102011,27101944 D:5 26.7100 Ltr*6.04
Wartość Netto: 131.16
Stawka VAT: 23%
Podatek: 30.17
Wartość Brutto: 161.33

SUMA: PLN 161.33

Wyciągnij: numer faktury, data, sprzedawca, nabywca, kwoty, VAT."""
            },
            {
                "text": """Sformatuj te dane do JSON:

Numer faktury: 11646/F/229/25
Data: 2025-11-02
Sprzedawca: MOL Polska sp. z o.o.
Nabywca: RICE PROSTA SPÓŁKA AKCYJNA
Kwota netto: 131.16
VAT: 30.17
Kwota brutto: 161.33

Zwróć JSON z polami: invoice_number, date, seller, buyer, net_amount, vat_amount, gross_amount."""
            },
        ]
    
    def train(self, dataset: Dataset):
        """Train LoRA adapter."""
        logger.info("Starting training")
        
        # Data collator
        data_collator = DataCollatorForLanguageModeling(
            tokenizer=self.tokenizer,
            mlm=False,  # Causal LM, not masked LM
        )
        
        # Training arguments
        training_args = TrainingArguments(
            output_dir=str(self.output_dir / self.adapter_name),
            overwrite_output_dir=True,
            num_train_epochs=self.num_epochs,
            per_device_train_batch_size=self.batch_size,
            gradient_accumulation_steps=self.gradient_accumulation_steps,
            learning_rate=self.learning_rate,
            fp16=True,
            logging_steps=10,
            save_steps=100,
            save_total_limit=3,
            report_to="tensorboard" if os.getenv("WANDB_API_KEY") else "none",
            run_name=f"{self.adapter_name}-lora",
        )
        
        # Trainer
        trainer = Trainer(
            model=self.model,
            args=training_args,
            train_dataset=dataset,
            data_collator=data_collator,
        )
        
        # Train
        trainer.train()
        
        # Save adapter
        adapter_path = self.output_dir / self.adapter_name
        self.model.save_pretrained(str(adapter_path))
        self.tokenizer.save_pretrained(str(adapter_path))
        
        logger.info(f"Training completed. Adapter saved to: {adapter_path}")
        
    def run(self, data_path: Optional[str] = None):
        """Run full training pipeline."""
        self.load_model_and_tokenizer()
        self.setup_lora()
        dataset = self.prepare_dataset(data_path)
        self.train(dataset)


def main():
    """Main entry point."""
    # Configuration from environment variables
    model_name_bielik = os.getenv("MODEL_NAME_BIELIK", "allegro/herbert-base-cased")
    model_name_formatter = os.getenv("MODEL_NAME_FORMATTER", "Qwen/Qwen2.5-3B-Instruct")
    
    adapters_dir = os.getenv("ADAPTERS_DIR", "/app/adapters")
    data_dir = os.getenv("DATA_DIR", "/app/data")
    
    lora_r = int(os.getenv("LORA_R", "8"))
    lora_alpha = int(os.getenv("LORA_ALPHA", "16"))
    lora_dropout = float(os.getenv("LORA_DROPOUT", "0.1"))
    batch_size = int(os.getenv("BATCH_SIZE", "4"))
    gradient_accumulation_steps = int(os.getenv("GRADIENT_ACCUMULATION_STEPS", "4"))
    learning_rate = float(os.getenv("LEARNING_RATE", "2e-4"))
    num_epochs = int(os.getenv("NUM_EPOCHS", "3"))
    max_length = int(os.getenv("MAX_LENGTH", "512"))
    
    # Train Bielik adapter
    logger.info("Training Bielik adapter for Polish invoice extraction")
    bielik_trainer = LoRATrainer(
        model_name=model_name_bielik,
        output_dir=adapters_dir,
        adapter_name="bielik-invoice-extraction",
        lora_r=lora_r,
        lora_alpha=lora_alpha,
        lora_dropout=lora_dropout,
        batch_size=batch_size,
        gradient_accumulation_steps=gradient_accumulation_steps,
        learning_rate=learning_rate,
        num_epochs=num_epochs,
        max_length=max_length,
    )
    
    bielik_data_path = os.path.join(data_dir, "bielik_training.json")
    bielik_trainer.run(data_path=bielik_data_path if os.path.exists(bielik_data_path) else None)
    
    # Train Formatter adapter
    logger.info("Training Formatter adapter for JSON output")
    formatter_trainer = LoRATrainer(
        model_name=model_name_formatter,
        output_dir=adapters_dir,
        adapter_name="formatter-json-output",
        lora_r=lora_r,
        lora_alpha=lora_alpha,
        lora_dropout=lora_dropout,
        batch_size=batch_size,
        gradient_accumulation_steps=gradient_accumulation_steps,
        learning_rate=learning_rate,
        num_epochs=num_epochs,
        max_length=max_length,
    )
    
    formatter_data_path = os.path.join(data_dir, "formatter_training.json")
    formatter_trainer.run(data_path=formatter_data_path if os.path.exists(formatter_data_path) else None)
    
    logger.info("All adapters trained successfully!")


if __name__ == "__main__":
    main()



