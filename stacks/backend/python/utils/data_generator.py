#!/usr/bin/env python3
"""
🎲 Chain Rice Data Generator - The Data Factory!
This module generates realistic sample data for testing and learning! 🏭
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import random
from faker import Faker
from rich.console import Console
from loguru import logger

console = Console()
fake = Faker()

class DataGenerator:
    """
    The Data Generator - Your personal data factory! 🏭
    
    This class creates realistic sample data for blockchain applications.
    Perfect for testing, demos, and learning!
    """
    
    def __init__(self):
        """Initialize the data generator with some sick defaults!"""
        self.fake = Faker()
        random.seed(42)  # For reproducible results
        np.random.seed(42)
        
        # Common blockchain addresses (because we're realistic!)
        self.addresses = [
            "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
            "0x8ba1f109551bD432803012645Hac136c4C8C8C8C",
            "0x1234567890123456789012345678901234567890",
            "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            "0x9876543210987654321098765432109876543210",
            "0x5555555555555555555555555555555555555555",
            "0x1111111111111111111111111111111111111111",
            "0x9999999999999999999999999999999999999999"
        ]
        
        # Common token symbols
        self.tokens = ["RICE", "ETH", "BTC", "USDC", "USDT", "DAI", "LINK", "UNI"]
        
        logger.info("Data generator initialized!")
    
    def generate_transactions(self, count: int = 1000) -> pd.DataFrame:
        """
        Generate realistic blockchain transactions.
        
        Args:
            count: Number of transactions to generate
            
        Returns:
            DataFrame with transaction data
        """
        console.print(f"[yellow]🎲 Generating {count} transactions...[/yellow]")
        
        transactions = []
        start_time = datetime.now() - timedelta(days=30)
        
        for i in range(count):
            # Random time within last 30 days
            random_seconds = random.randint(0, 30 * 24 * 60 * 60)
            timestamp = start_time + timedelta(seconds=random_seconds)
            
            # Random transaction data
            sender = random.choice(self.addresses)
            receiver = random.choice([addr for addr in self.addresses if addr != sender])
            
            # Amount with realistic distribution (most transactions are small)
            if random.random() < 0.7:  # 70% small transactions
                amount = round(random.uniform(0.001, 10), 6)
            elif random.random() < 0.9:  # 20% medium transactions
                amount = round(random.uniform(10, 1000), 2)
            else:  # 10% large transactions
                amount = round(random.uniform(1000, 10000), 2)
            
            # Gas price and limit (realistic Ethereum-like values)
            gas_price = random.randint(20, 200)  # Gwei
            gas_limit = random.randint(21000, 100000)
            gas_used = random.randint(21000, gas_limit)
            
            # Transaction fee
            tx_fee = (gas_used * gas_price) / 1e9  # Convert to ETH
            
            # Status (95% success rate)
            status = "success" if random.random() < 0.95 else "failed"
            
            # Block number (simulate blockchain growth)
            block_number = random.randint(1000000, 2000000)
            
            transaction = {
                'tx_hash': f"0x{fake.sha256()[:64]}",
                'block_number': block_number,
                'timestamp': timestamp,
                'sender': sender,
                'receiver': receiver,
                'amount': amount,
                'token': random.choice(self.tokens),
                'gas_price': gas_price,
                'gas_limit': gas_limit,
                'gas_used': gas_used,
                'tx_fee': tx_fee,
                'status': status,
                'nonce': random.randint(0, 1000)
            }
            
            transactions.append(transaction)
        
        df = pd.DataFrame(transactions)
        df = df.sort_values('timestamp').reset_index(drop=True)
        
        console.print(f"[green]✅ Generated {len(df)} transactions![/green]")
        return df
    
    def generate_blocks(self, count: int = 100) -> pd.DataFrame:
        """
        Generate blockchain blocks data.
        
        Args:
            count: Number of blocks to generate
            
        Returns:
            DataFrame with block data
        """
        console.print(f"[yellow]⛓️ Generating {count} blocks...[/yellow]")
        
        blocks = []
        start_time = datetime.now() - timedelta(days=30)
        
        for i in range(count):
            # Block timing (average 12 seconds per block)
            block_time = start_time + timedelta(seconds=i * 12)
            
            # Block data
            block_number = 1000000 + i
            tx_count = random.randint(50, 200)  # Transactions per block
            
            # Block size (realistic Ethereum-like values)
            block_size = random.randint(20000, 80000)  # bytes
            
            # Gas used (realistic values)
            gas_limit = 30000000  # Ethereum gas limit
            gas_used = random.randint(15000000, gas_limit)
            
            # Miner (random address)
            miner = random.choice(self.addresses)
            
            # Difficulty (increases over time)
            difficulty = 1000000000000 + (i * 1000000000)
            
            block = {
                'block_number': block_number,
                'timestamp': block_time,
                'hash': f"0x{fake.sha256()[:64]}",
                'parent_hash': f"0x{fake.sha256()[:64]}" if i > 0 else "0x0",
                'miner': miner,
                'tx_count': tx_count,
                'block_size': block_size,
                'gas_limit': gas_limit,
                'gas_used': gas_used,
                'gas_used_percentage': (gas_used / gas_limit) * 100,
                'difficulty': difficulty,
                'total_difficulty': difficulty * (i + 1),
                'uncles': random.randint(0, 2)  # Ethereum uncles
            }
            
            blocks.append(block)
        
        df = pd.DataFrame(blocks)
        console.print(f"[green]✅ Generated {len(df)} blocks![/green]")
        return df
    
    def generate_users(self, count: int = 100) -> pd.DataFrame:
        """
        Generate user data for blockchain applications.
        
        Args:
            count: Number of users to generate
            
        Returns:
            DataFrame with user data
        """
        console.print(f"[yellow]👥 Generating {count} users...[/yellow]")
        
        users = []
        
        for i in range(count):
            # User data
            user_id = f"user_{i:04d}"
            email = fake.email()
            username = fake.user_name()
            
            # Wallet address
            wallet_address = random.choice(self.addresses)
            
            # Registration date
            reg_date = fake.date_between(start_date='-2y', end_date='today')
            
            # User status
            status = random.choice(['active', 'inactive', 'suspended'])
            
            # KYC status
            kyc_status = random.choice(['verified', 'pending', 'rejected'])
            
            # Balance (realistic distribution)
            balance = round(random.uniform(0, 1000), 4)
            
            # Transaction count
            tx_count = random.randint(0, 500)
            
            user = {
                'user_id': user_id,
                'email': email,
                'username': username,
                'wallet_address': wallet_address,
                'registration_date': reg_date,
                'status': status,
                'kyc_status': kyc_status,
                'balance': balance,
                'transaction_count': tx_count,
                'last_login': fake.date_time_between(start_date='-30d', end_date='now'),
                'country': fake.country_code(),
                'timezone': fake.timezone()
            }
            
            users.append(user)
        
        df = pd.DataFrame(users)
        console.print(f"[green]✅ Generated {len(df)} users![/green]")
        return df
    
    def generate_dex_data(self, count: int = 500) -> pd.DataFrame:
        """
        Generate DEX (Decentralized Exchange) trading data.
        
        Args:
            count: Number of trades to generate
            
        Returns:
            DataFrame with DEX trading data
        """
        console.print(f"[yellow]📈 Generating {count} DEX trades...[/yellow]")
        
        trades = []
        start_time = datetime.now() - timedelta(days=7)  # Last week
        
        # Trading pairs
        pairs = ["RICE/ETH", "ETH/USDC", "BTC/ETH", "LINK/ETH", "UNI/ETH"]
        
        for i in range(count):
            # Trade timing
            random_seconds = random.randint(0, 7 * 24 * 60 * 60)
            timestamp = start_time + timedelta(seconds=random_seconds)
            
            # Trading pair
            pair = random.choice(pairs)
            base_token, quote_token = pair.split('/')
            
            # Trade type
            trade_type = random.choice(['buy', 'sell'])
            
            # Amount and price
            amount = round(random.uniform(0.1, 100), 4)
            price = round(random.uniform(100, 5000), 2)
            
            # Total value
            total_value = amount * price
            
            # Slippage (realistic DEX slippage)
            slippage = round(random.uniform(0.1, 2.0), 2)
            
            # Gas fee
            gas_fee = round(random.uniform(0.001, 0.01), 4)
            
            # Trade hash
            trade_hash = f"0x{fake.sha256()[:64]}"
            
            trade = {
                'trade_hash': trade_hash,
                'timestamp': timestamp,
                'pair': pair,
                'base_token': base_token,
                'quote_token': quote_token,
                'trade_type': trade_type,
                'amount': amount,
                'price': price,
                'total_value': total_value,
                'slippage': slippage,
                'gas_fee': gas_fee,
                'user_address': random.choice(self.addresses),
                'dex': random.choice(['Uniswap', 'SushiSwap', 'PancakeSwap']),
                'block_number': random.randint(1000000, 2000000)
            }
            
            trades.append(trade)
        
        df = pd.DataFrame(trades)
        df = df.sort_values('timestamp').reset_index(drop=True)
        
        console.print(f"[green]✅ Generated {len(df)} DEX trades![/green]")
        return df
    
    def generate_data(self, data_type: str, count: int = 1000) -> pd.DataFrame:
        """
        Generate data of specified type.
        
        Args:
            data_type: Type of data to generate
            count: Number of records to generate
            
        Returns:
            DataFrame with generated data
        """
        generators = {
            'transactions': self.generate_transactions,
            'blocks': self.generate_blocks,
            'users': self.generate_users,
            'dex': self.generate_dex_data,
            'trades': self.generate_dex_data  # Alias for dex
        }
        
        if data_type not in generators:
            raise ValueError(f"Unknown data type: {data_type}. Available: {list(generators.keys())}")
        
        return generators[data_type](count)
    
    def generate_complete_dataset(self) -> Dict[str, pd.DataFrame]:
        """
        Generate a complete dataset with all data types.
        
        Returns:
            Dictionary with all generated datasets
        """
        console.print("[bold blue]🎯 Generating complete Chain Rice dataset...[/bold blue]")
        
        datasets = {
            'transactions': self.generate_transactions(2000),
            'blocks': self.generate_blocks(200),
            'users': self.generate_users(500),
            'dex_trades': self.generate_dex_data(1000)
        }
        
        console.print("[green]✅ Complete dataset generated![/green]")
        return datasets

# Demo function
def demo_data_generation():
    """
    Demo the data generator capabilities.
    This is like a data factory tour! 🏭
    """
    console.print(Panel(
        "[bold blue]🏭 Chain Rice Data Generator Demo[/bold blue]\n"
        "Let's see what kind of data we can create!",
        title="Data Generator Demo",
        border_style="blue"
    ))
    
    generator = DataGenerator()
    
    # Generate sample data
    console.print("\n[yellow]📊 Generating sample data...[/yellow]")
    
    # Transactions
    transactions = generator.generate_transactions(100)
    console.print(f"Transactions: {len(transactions)} rows")
    console.print(transactions.head())
    
    # Users
    users = generator.generate_users(50)
    console.print(f"\nUsers: {len(users)} rows")
    console.print(users.head())
    
    # DEX trades
    trades = generator.generate_dex_data(200)
    console.print(f"\nDEX Trades: {len(trades)} rows")
    console.print(trades.head())
    
    console.print("\n[green]🎉 Data generation demo complete![/green]")

if __name__ == "__main__":
    demo_data_generation()
