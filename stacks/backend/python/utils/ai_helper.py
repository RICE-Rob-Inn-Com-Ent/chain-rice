#!/usr/bin/env python3
"""
🤖 Chain Rice AI Helper - Your AI Sidekick!
This module provides AI capabilities for the Chain Rice ecosystem! 🚀
"""
import os
import openai
from typing import Optional, List, Dict, Any
from rich.console import Console
from loguru import logger
import json

console = Console()

class AIHelper:
    """
    The AI Helper - Your blockchain AI buddy! 🤖
    
    This class provides AI capabilities for Chain Rice applications.
    It's like having a blockchain expert AI assistant!
    """
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize the AI helper.
        
        Args:
            api_key: OpenAI API key (optional, will use env var if not provided)
        """
        self.api_key = api_key or os.getenv("OPENAI_API_KEY")
        self.model = "gpt-3.5-turbo"
        self.max_tokens = 1000
        self.temperature = 0.7
        
        if self.api_key:
            openai.api_key = self.api_key
            logger.info("AI Helper initialized with OpenAI API")
        else:
            logger.warning("No OpenAI API key found - using demo mode")
    
    def chat(self, message: str, model: Optional[str] = None, context: Optional[str] = None) -> str:
        """
        Chat with the AI about blockchain topics.
        
        Args:
            message: The user's message
            model: AI model to use (optional)
            context: Additional context (optional)
            
        Returns:
            AI response
        """
        if not self.api_key:
            return self._demo_response(message)
        
        try:
            # Prepare the prompt with context
            system_prompt = self._get_system_prompt(context)
            
            response = openai.ChatCompletion.create(
                model=model or self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": message}
                ],
                max_tokens=self.max_tokens,
                temperature=self.temperature
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            logger.error(f"AI chat error: {e}")
            return f"Sorry, I had a brain fart! 🤯 Error: {e}"
    
    def analyze_transaction(self, transaction_data: Dict[str, Any]) -> str:
        """
        Analyze a blockchain transaction using AI.
        
        Args:
            transaction_data: Transaction data to analyze
            
        Returns:
            AI analysis of the transaction
        """
        if not self.api_key:
            return self._demo_transaction_analysis(transaction_data)
        
        try:
            prompt = f"""
            Analyze this blockchain transaction and provide insights:
            
            Transaction Data:
            {json.dumps(transaction_data, indent=2)}
            
            Please provide:
            1. Transaction type and purpose
            2. Risk assessment
            3. Interesting patterns or anomalies
            4. Recommendations
            """
            
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a blockchain transaction analyst. Provide detailed, technical analysis."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=self.max_tokens,
                temperature=0.3  # Lower temperature for more focused analysis
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            logger.error(f"Transaction analysis error: {e}")
            return f"Analysis failed: {e}"
    
    def generate_smart_contract(self, requirements: str) -> str:
        """
        Generate a smart contract based on requirements.
        
        Args:
            requirements: Smart contract requirements
            
        Returns:
            Generated smart contract code
        """
        if not self.api_key:
            return self._demo_smart_contract(requirements)
        
        try:
            prompt = f"""
            Generate a Solidity smart contract based on these requirements:
            
            {requirements}
            
            Please provide:
            1. Complete Solidity code
            2. Comments explaining the logic
            3. Security considerations
            4. Usage instructions
            """
            
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a smart contract developer. Generate secure, well-commented Solidity code."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=2000,
                temperature=0.2  # Lower temperature for more consistent code
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            logger.error(f"Smart contract generation error: {e}")
            return f"Contract generation failed: {e}"
    
    def explain_blockchain_concept(self, concept: str) -> str:
        """
        Explain a blockchain concept in simple terms.
        
        Args:
            concept: The concept to explain
            
        Returns:
            Simple explanation of the concept
        """
        if not self.api_key:
            return self._demo_concept_explanation(concept)
        
        try:
            prompt = f"""
            Explain this blockchain concept in simple, easy-to-understand terms:
            
            Concept: {concept}
            
            Please provide:
            1. Simple definition
            2. Real-world analogy
            3. How it works
            4. Why it's important
            5. Examples
            """
            
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a blockchain educator. Explain complex concepts in simple terms with analogies."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=self.max_tokens,
                temperature=0.7
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            logger.error(f"Concept explanation error: {e}")
            return f"Explanation failed: {e}"
    
    def _get_system_prompt(self, context: Optional[str] = None) -> str:
        """Get the system prompt for AI interactions."""
        base_prompt = """
        You are Chain Rice AI, a helpful assistant for blockchain development and Chain Rice platform.
        
        You are:
        - Knowledgeable about blockchain technology, smart contracts, and DeFi
        - Familiar with Chain Rice platform and its features
        - Helpful and friendly, using some Python slang when appropriate
        - Technical but accessible in your explanations
        - Focused on practical, actionable advice
        
        Always be helpful and provide accurate information about blockchain technology.
        """
        
        if context:
            base_prompt += f"\n\nAdditional context: {context}"
        
        return base_prompt
    
    def _demo_response(self, message: str) -> str:
        """Demo responses when no API key is available."""
        message_lower = message.lower()
        
        if "smart contract" in message_lower:
            return """
            🔥 **Smart Contracts - The Digital Agreements!**
            
            Smart contracts are like digital vending machines! You put in crypto,
            and out comes exactly what you programmed it to do - no human needed!
            
            **Key features:**
            - **Automatic execution**: Runs when conditions are met
            - **Trustless**: No need to trust a middleman
            - **Transparent**: Code is visible to everyone
            - **Immutable**: Can't be changed once deployed
            
            **Example**: A simple token contract that lets you transfer tokens
            between addresses automatically!
            
            Want to see a real example? Set your OPENAI_API_KEY! 🔑
            """
        
        elif "defi" in message_lower or "decentralized finance" in message_lower:
            return """
            🌊 **DeFi - The Financial Revolution!**
            
            DeFi is like traditional finance, but without banks! It's all
            running on smart contracts on the blockchain.
            
            **DeFi components:**
            - **DEXs**: Decentralized exchanges (like Uniswap)
            - **Lending**: Borrow/lend without banks (like Aave)
            - **Yield farming**: Earn rewards by providing liquidity
            - **Stablecoins**: Crypto pegged to real currencies
            
            **Why it's awesome:**
            - No KYC required
            - 24/7 availability
            - Global access
            - Transparent and auditable
            
            Chain Rice makes DeFi development easier! 🍚
            """
        
        elif "nft" in message_lower or "non-fungible" in message_lower:
            return """
            🎨 **NFTs - Digital Ownership Revolution!**
            
            NFTs are like digital certificates of ownership! They prove you
            own something unique on the blockchain.
            
            **What makes NFTs special:**
            - **Unique**: Each one is different
            - **Ownership**: Proves you own the digital item
            - **Transferable**: Can be sold or traded
            - **Verifiable**: Blockchain proves authenticity
            
            **Use cases:**
            - Digital art
            - Gaming items
            - Domain names
            - Identity verification
            
            **Chain Rice NFT support**: Coming soon! 🚀
            """
        
        else:
            return """
            🤔 **Interesting question!**
            
            I'm in demo mode right now (no API key), but I can help with:
            - Blockchain basics
            - Smart contracts
            - DeFi concepts
            - NFT explanations
            - Chain Rice platform
            
            Try asking about smart contracts, DeFi, or NFTs!
            Or set your OPENAI_API_KEY to unlock full AI powers! 🔑
            """
    
    def _demo_transaction_analysis(self, transaction_data: Dict[str, Any]) -> str:
        """Demo transaction analysis."""
        return f"""
        📊 **Transaction Analysis (Demo Mode)**
        
        **Transaction Summary:**
        - Amount: {transaction_data.get('amount', 'N/A')}
        - From: {transaction_data.get('sender', 'N/A')}
        - To: {transaction_data.get('receiver', 'N/A')}
        
        **Analysis:**
        This appears to be a standard token transfer transaction.
        The transaction looks normal with typical gas usage.
        
        **Recommendations:**
        - Monitor for unusual patterns
        - Verify recipient address
        - Check gas optimization opportunities
        
        *Set OPENAI_API_KEY for detailed AI analysis! 🔑*
        """
    
    def _demo_smart_contract(self, requirements: str) -> str:
        """Demo smart contract generation."""
        return f"""
        🔥 **Smart Contract Generator (Demo Mode)**
        
        **Requirements:** {requirements}
        
        **Generated Contract:**
        ```solidity
        // SPDX-License-Identifier: MIT
        pragma solidity ^0.8.0;
        
        contract ChainRiceContract {{
            address public owner;
            uint256 public totalSupply;
            
            constructor() {{
                owner = msg.sender;
                totalSupply = 1000000;
            }}
            
            function transfer(address to, uint256 amount) public {{
                // Transfer logic here
            }}
        }}
        ```
        
        **Security Notes:**
        - Add access controls
        - Implement reentrancy protection
        - Validate inputs
        
        *Set OPENAI_API_KEY for custom contract generation! 🔑*
        """
    
    def _demo_concept_explanation(self, concept: str) -> str:
        """Demo concept explanation."""
        return f"""
        📚 **Concept Explanation (Demo Mode)**
        
        **Concept:** {concept}
        
        **Simple Definition:**
        This is a fundamental blockchain concept that helps make
        decentralized systems work properly.
        
        **Real-world Analogy:**
        Think of it like a digital voting system where everyone
        can see the votes and verify they're correct!
        
        **How it works:**
        1. Data is processed
        2. Consensus is reached
        3. Results are recorded
        4. Everyone can verify
        
        **Why it's important:**
        - Ensures security
        - Maintains trust
        - Enables decentralization
        
        *Set OPENAI_API_KEY for detailed explanations! 🔑*
        """

# Demo function
def demo_ai_helper():
    """
    Demo the AI helper capabilities.
    This is like a showcase of AI superpowers! 🤖
    """
    console.print(Panel(
        "[bold blue]🤖 Chain Rice AI Helper Demo[/bold blue]\n"
        "Let's see what our AI buddy can do!",
        title="AI Helper Demo",
        border_style="blue"
    ))
    
    ai_helper = AIHelper()
    
    # Demo chat
    console.print("\n[yellow]💬 Testing AI chat...[/yellow]")
    response = ai_helper.chat("What is blockchain?")
    console.print(f"AI: {response}")
    
    # Demo transaction analysis
    console.print("\n[yellow]📊 Testing transaction analysis...[/yellow]")
    sample_tx = {
        "sender": "0x123...",
        "receiver": "0x456...",
        "amount": 100,
        "token": "RICE"
    }
    analysis = ai_helper.analyze_transaction(sample_tx)
    console.print(f"Analysis: {analysis}")
    
    # Demo concept explanation
    console.print("\n[yellow]📚 Testing concept explanation...[/yellow]")
    explanation = ai_helper.explain_blockchain_concept("consensus mechanism")
    console.print(f"Explanation: {explanation}")
    
    console.print("\n[green]🎉 AI Helper demo complete![/green]")

if __name__ == "__main__":
    demo_ai_helper()
