#!/usr/bin/env python3
"""
⛓️ Chain Rice Blockchain Simulator - Where Blocks Come Alive!
This is like having a mini blockchain in your Python script! 🚀
"""
import hashlib
import time
import json
from datetime import datetime
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict
from rich.console import Console
from loguru import logger

console = Console()

@dataclass
class Transaction:
    """
    A transaction in our blockchain - the bread and butter! 🍞
    """
    sender: str
    receiver: str
    amount: float
    timestamp: float
    tx_id: str
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for hashing"""
        return asdict(self)
    
    def __str__(self) -> str:
        return f"TX {self.tx_id[:8]}...: {self.sender} → {self.receiver} ({self.amount} RICE)"

@dataclass
class Block:
    """
    A block in our blockchain - the container of truth! 📦
    """
    index: int
    timestamp: float
    transactions: List[Transaction]
    previous_hash: str
    hash: str
    nonce: int
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for hashing"""
        return {
            'index': self.index,
            'timestamp': self.timestamp,
            'transactions': [tx.to_dict() for tx in self.transactions],
            'previous_hash': self.previous_hash,
            'nonce': self.nonce
        }
    
    def __str__(self) -> str:
        return f"Block {self.index}: {len(self.transactions)} transactions, hash: {self.hash[:16]}..."

class BlockchainSimulator:
    """
    The Blockchain Simulator - Your personal blockchain! ⛓️
    
    This class simulates a real blockchain with mining, transactions,
    and all the cool stuff that makes blockchain tick!
    """
    
    def __init__(self, difficulty: int = 4):
        """
        Initialize the blockchain simulator.
        
        Args:
            difficulty: Mining difficulty (number of leading zeros)
        """
        self.chain: List[Block] = []
        self.pending_transactions: List[Transaction] = []
        self.difficulty = difficulty
        self.mining_reward = 50.0
        self.miner_address = "miner@chain-rice.com"
        
        # Create genesis block (the first block - like the big bang!)
        self._create_genesis_block()
        
        logger.info(f"Blockchain initialized with difficulty {difficulty}")
    
    def _create_genesis_block(self):
        """Create the genesis block - the beginning of everything! 🌟"""
        genesis_transaction = Transaction(
            sender="genesis",
            receiver="miner@chain-rice.com",
            amount=self.mining_reward,
            timestamp=time.time(),
            tx_id=self._generate_tx_id("genesis", "miner", self.mining_reward)
        )
        
        genesis_block = Block(
            index=0,
            timestamp=time.time(),
            transactions=[genesis_transaction],
            previous_hash="0",
            hash="",
            nonce=0
        )
        
        # Mine the genesis block
        genesis_block.hash = self._mine_block(genesis_block)
        self.chain.append(genesis_block)
        
        logger.info("Genesis block created and mined!")
    
    def _generate_tx_id(self, sender: str, receiver: str, amount: float) -> str:
        """Generate a unique transaction ID"""
        data = f"{sender}{receiver}{amount}{time.time()}"
        return hashlib.sha256(data.encode()).hexdigest()
    
    def _calculate_hash(self, block: Block) -> str:
        """Calculate the hash of a block"""
        block_string = json.dumps(block.to_dict(), sort_keys=True)
        return hashlib.sha256(block_string.encode()).hexdigest()
    
    def _mine_block(self, block: Block) -> str:
        """
        Mine a block - this is where the magic happens! ⛏️
        
        Mining is like solving a puzzle. You keep trying different numbers
        until you find one that makes the hash start with the right number of zeros!
        """
        target = "0" * self.difficulty
        block.nonce = 0
        
        while True:
            block.hash = self._calculate_hash(block)
            if block.hash.startswith(target):
                break
            block.nonce += 1
        
        return block.hash
    
    def add_transaction(self, sender: str, receiver: str, amount: float) -> str:
        """
        Add a transaction to the pending pool.
        
        Args:
            sender: Who's sending the money
            receiver: Who's receiving the money
            amount: How much money
            
        Returns:
            Transaction ID
        """
        tx_id = self._generate_tx_id(sender, receiver, amount)
        
        transaction = Transaction(
            sender=sender,
            receiver=receiver,
            amount=amount,
            timestamp=time.time(),
            tx_id=tx_id
        )
        
        self.pending_transactions.append(transaction)
        logger.info(f"Transaction added: {transaction}")
        
        return tx_id
    
    def add_block(self, transactions_per_block: int = 5) -> Block:
        """
        Add a new block to the blockchain.
        
        Args:
            transactions_per_block: How many transactions to include
            
        Returns:
            The newly created block
        """
        if not self.pending_transactions:
            logger.warning("No pending transactions to mine!")
            return None
        
        # Take transactions for this block
        block_transactions = self.pending_transactions[:transactions_per_block]
        self.pending_transactions = self.pending_transactions[transactions_per_block:]
        
        # Add mining reward transaction
        reward_transaction = Transaction(
            sender="system",
            receiver=self.miner_address,
            amount=self.mining_reward,
            timestamp=time.time(),
            tx_id=self._generate_tx_id("system", self.miner_address, self.mining_reward)
        )
        block_transactions.append(reward_transaction)
        
        # Create new block
        new_block = Block(
            index=len(self.chain),
            timestamp=time.time(),
            transactions=block_transactions,
            previous_hash=self.chain[-1].hash,
            hash="",
            nonce=0
        )
        
        # Mine the block
        new_block.hash = self._mine_block(new_block)
        
        # Add to chain
        self.chain.append(new_block)
        
        logger.info(f"Block {new_block.index} mined with {len(block_transactions)} transactions!")
        
        return new_block
    
    def get_balance(self, address: str) -> float:
        """
        Calculate the balance of an address.
        
        Args:
            address: The address to check
            
        Returns:
            Current balance
        """
        balance = 0.0
        
        for block in self.chain:
            for tx in block.transactions:
                if tx.sender == address:
                    balance -= tx.amount
                if tx.receiver == address:
                    balance += tx.amount
        
        return balance
    
    def is_chain_valid(self) -> bool:
        """
        Validate the entire blockchain.
        
        Returns:
            True if chain is valid, False otherwise
        """
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i - 1]
            
            # Check if current block hash is correct
            if current_block.hash != self._calculate_hash(current_block):
                logger.error(f"Block {i} hash is invalid!")
                return False
            
            # Check if previous hash matches
            if current_block.previous_hash != previous_block.hash:
                logger.error(f"Block {i} previous hash is invalid!")
                return False
        
        return True
    
    def get_blockchain_info(self) -> Dict[str, Any]:
        """
        Get comprehensive blockchain information.
        
        Returns:
            Dictionary with blockchain stats
        """
        total_transactions = sum(len(block.transactions) for block in self.chain)
        total_mined = len(self.chain) * self.mining_reward
        
        return {
            'total_blocks': len(self.chain),
            'total_transactions': total_transactions,
            'pending_transactions': len(self.pending_transactions),
            'difficulty': self.difficulty,
            'mining_reward': self.mining_reward,
            'total_mined': total_mined,
            'chain_valid': self.is_chain_valid(),
            'latest_hash': self.chain[-1].hash if self.chain else None
        }
    
    def print_blockchain(self):
        """Print the entire blockchain in a nice format"""
        console.print(Panel(
            f"[bold green]⛓️ Chain Rice Blockchain[/bold green]\n"
            f"Blocks: {len(self.chain)}\n"
            f"Difficulty: {self.difficulty}\n"
            f"Valid: {'✅' if self.is_chain_valid() else '❌'}",
            title="Blockchain Status",
            border_style="green"
        ))
        
        for block in self.chain:
            console.print(f"\n[bold cyan]Block {block.index}[/bold cyan]")
            console.print(f"  Hash: {block.hash[:32]}...")
            console.print(f"  Previous: {block.previous_hash[:32]}...")
            console.print(f"  Transactions: {len(block.transactions)}")
            console.print(f"  Nonce: {block.nonce}")
            console.print(f"  Timestamp: {datetime.fromtimestamp(block.timestamp).strftime('%Y-%m-%d %H:%M:%S')}")
            
            for tx in block.transactions:
                console.print(f"    {tx}")
    
    def simulate_transactions(self, num_transactions: int = 10):
        """
        Simulate some random transactions for demo purposes.
        
        Args:
            num_transactions: Number of transactions to create
        """
        addresses = [
            "alice@chain-rice.com",
            "bob@chain-rice.com", 
            "charlie@chain-rice.com",
            "diana@chain-rice.com",
            "eve@chain-rice.com"
        ]
        
        console.print(f"[yellow]🎲 Simulating {num_transactions} random transactions...[/yellow]")
        
        for i in range(num_transactions):
            import random
            sender = random.choice(addresses)
            receiver = random.choice([addr for addr in addresses if addr != sender])
            amount = round(random.uniform(1, 100), 2)
            
            tx_id = self.add_transaction(sender, receiver, amount)
            console.print(f"  {i+1}. {sender} → {receiver} ({amount} RICE)")
        
        console.print(f"[green]✅ Created {num_transactions} transactions![/green]")

# Demo function for testing
def demo_blockchain():
    """
    Run a demo of the blockchain simulator.
    This is like a fireworks show of blockchain magic! 🎆
    """
    console.print(Panel(
        "[bold blue]🎆 Chain Rice Blockchain Demo[/bold blue]\n"
        "Let's see some blockchain magic in action!",
        title="Blockchain Demo",
        border_style="blue"
    ))
    
    # Create blockchain
    blockchain = BlockchainSimulator(difficulty=3)
    
    # Simulate some transactions
    blockchain.simulate_transactions(15)
    
    # Mine some blocks
    console.print("\n[yellow]⛏️ Mining blocks...[/yellow]")
    for i in range(3):
        block = blockchain.add_block(5)
        console.print(f"  Mined block {block.index} with {len(block.transactions)} transactions")
    
    # Show blockchain info
    info = blockchain.get_blockchain_info()
    console.print(f"\n[bold]📊 Blockchain Stats:[/bold]")
    for key, value in info.items():
        console.print(f"  {key}: {value}")
    
    # Show balances
    console.print(f"\n[bold]💰 Address Balances:[/bold]")
    addresses = ["alice@chain-rice.com", "bob@chain-rice.com", "miner@chain-rice.com"]
    for addr in addresses:
        balance = blockchain.get_balance(addr)
        console.print(f"  {addr}: {balance:.2f} RICE")
    
    # Print blockchain
    blockchain.print_blockchain()

if __name__ == "__main__":
    demo_blockchain()
