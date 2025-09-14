#!/usr/bin/env python3
"""
🤖 Chain Rice AI Chat - Your Blockchain Buddy
This is where you chat with AI about all things blockchain! 
"""
import os
import asyncio
from typing import Optional, List, Dict, Any
from rich.console import Console
from rich.panel import Panel
from rich.markdown import Markdown
from rich.prompt import Prompt
from loguru import logger
import openai
from langchain.llms import OpenAI
from langchain.chat_models import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from langchain.prompts import ChatPromptTemplate
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain

console = Console()

class AIHelper:
    """
    The AI Helper - Your blockchain buddy! 🤖
    
    This class handles all the AI magic. It's like having a blockchain expert
    in your pocket, but way cooler because it's code!
    """
    
    def __init__(self):
        """Initialize the AI helper with some sick defaults!"""
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.model = "gpt-3.5-turbo"
        self.memory = ConversationBufferMemory()
        
        if not self.api_key:
            console.print("[yellow]⚠️  No OpenAI API key found![/yellow]")
            console.print("Set OPENAI_API_KEY environment variable to use AI features.")
            self.api_key = "demo-key"  # Fallback for demo mode
    
    def chat(self, message: str, model: Optional[str] = None) -> str:
        """
        Chat with the AI! This is where the magic happens! ✨
        
        Args:
            message: What you want to ask the AI
            model: Which AI model to use (optional)
            
        Returns:
            The AI's response (hopefully helpful!)
        """
        if not self.api_key or self.api_key == "demo-key":
            return self._demo_response(message)
        
        try:
            # Use the specified model or default
            current_model = model or self.model
            
            # Create the chat model
            chat = ChatOpenAI(
                openai_api_key=self.api_key,
                model_name=current_model,
                temperature=0.7
            )
            
            # Create a conversation chain with memory
            conversation = ConversationChain(
                llm=chat,
                memory=self.memory,
                verbose=False
            )
            
            # Add some context about Chain Rice
            context = """
            You are Chain Rice AI, a helpful assistant for blockchain development.
            You know about Chain Rice blockchain, Python development, and general blockchain concepts.
            Be helpful, friendly, and use some Python slang when appropriate!
            """
            
            # Get the response
            response = conversation.predict(input=f"{context}\n\nUser: {message}")
            
            return response
            
        except Exception as e:
            logger.error(f"AI chat error: {e}")
            return f"Sorry, I had a brain fart! 🤯 Error: {e}"
    
    def _demo_response(self, message: str) -> str:
        """
        Demo responses when no API key is available.
        These are pre-written responses for common questions.
        """
        message_lower = message.lower()
        
        if "blockchain" in message_lower:
            return """
            🚀 **Blockchain 101 with Chain Rice AI!**
            
            Blockchain is like a digital ledger that's distributed across many computers.
            Think of it as a Google Doc that everyone can see and verify, but no one can cheat!
            
            **Key concepts:**
            - **Blocks**: Containers for transactions
            - **Hash**: Digital fingerprint of data
            - **Consensus**: How everyone agrees on the truth
            - **Decentralization**: No single point of failure
            
            Chain Rice makes it easy to build on blockchain! 🍚
            """
        
        elif "python" in message_lower:
            return """
            🐍 **Python + Blockchain = Magic!**
            
            Python is perfect for blockchain development because:
            - **Simple syntax**: Easy to read and write
            - **Rich ecosystem**: Tons of libraries
            - **Fast development**: Rapid prototyping
            - **Great for AI**: Perfect for smart contracts with AI
            
            **Popular Python blockchain libraries:**
            - `web3.py`: Ethereum integration
            - `requests`: HTTP calls
            - `cryptography`: Security primitives
            - `pandas`: Data analysis
            
            Chain Rice SDK makes it even easier! 🚀
            """
        
        elif "chain rice" in message_lower:
            return """
            🍚 **Chain Rice - The Future of Blockchain!**
            
            Chain Rice is a next-generation blockchain platform that makes
            blockchain development accessible to everyone!
            
            **Features:**
            - **Easy Python SDK**: Build with familiar tools
            - **AI Integration**: Smart contracts with AI
            - **Fast Transactions**: Lightning-fast processing
            - **Developer Friendly**: Great docs and tools
            
            **Get started:**
            ```bash
            pip install chain-rice-sdk
            chain-rice demo
            ```
            
            Join the rice revolution! 🌾
            """
        
        elif "hello" in message_lower or "hi" in message_lower:
            return """
            👋 **Hey there, blockchain explorer!**
            
            I'm Chain Rice AI, your friendly blockchain assistant!
            I can help you with:
            - Blockchain concepts
            - Python development
            - Chain Rice platform
            - Smart contracts
            - And much more!
            
            What would you like to know? 🚀
            """
        
        else:
            return """
            🤔 **Interesting question!**
            
            I'm in demo mode right now (no API key), but I can still help with:
            - Blockchain basics
            - Python development
            - Chain Rice platform
            - General programming concepts
            
            Try asking about blockchain, Python, or Chain Rice!
            Or set your OPENAI_API_KEY to unlock full AI powers! 🔑
            """

class ChainRiceAI:
    """
    The main AI chat interface - where conversations happen! 💬
    """
    
    def __init__(self):
        self.ai_helper = AIHelper()
        self.conversation_history: List[Dict[str, str]] = []
    
    def start_chat(self):
        """
        Start an interactive chat session! 
        This is where the real fun begins! 🎉
        """
        console.print(Panel(
            "[bold blue]🤖 Chain Rice AI Chat[/bold blue]\n"
            "Ask me anything about blockchain, Python, or Chain Rice!\n"
            "Type 'quit' or 'exit' to leave. Type 'help' for commands.",
            title="AI Assistant",
            border_style="blue"
        ))
        
        while True:
            try:
                # Get user input
                user_input = Prompt.ask("\n[bold cyan]You[/bold cyan]")
                
                if user_input.lower() in ['quit', 'exit', 'bye']:
                    console.print("[yellow]👋 Goodbye! Thanks for chatting![/yellow]")
                    break
                
                if user_input.lower() == 'help':
                    self._show_help()
                    continue
                
                if user_input.lower() == 'clear':
                    self.conversation_history.clear()
                    console.print("[green]✅ Conversation history cleared![/green]")
                    continue
                
                if user_input.lower() == 'history':
                    self._show_history()
                    continue
                
                # Get AI response
                console.print("[yellow]🤖 AI is thinking...[/yellow]")
                response = self.ai_helper.chat(user_input)
                
                # Display response
                console.print(Panel(
                    Markdown(response),
                    title="[bold green]Chain Rice AI[/bold green]",
                    border_style="green"
                ))
                
                # Save to history
                self.conversation_history.append({
                    "user": user_input,
                    "ai": response
                })
                
            except KeyboardInterrupt:
                console.print("\n[yellow]👋 Goodbye! Thanks for chatting![/yellow]")
                break
            except Exception as e:
                console.print(f"[red]❌ Error: {e}[/red]")
                logger.error(f"Chat error: {e}")
    
    def _show_help(self):
        """Show available commands"""
        help_text = """
        **Available Commands:**
        - `help`: Show this help message
        - `clear`: Clear conversation history
        - `history`: Show conversation history
        - `quit`/`exit`: Exit the chat
        
        **Example Questions:**
        - "What is blockchain?"
        - "How do I use Chain Rice?"
        - "Explain Python for blockchain"
        - "What are smart contracts?"
        """
        console.print(Panel(
            Markdown(help_text),
            title="Help",
            border_style="blue"
        ))
    
    def _show_history(self):
        """Show conversation history"""
        if not self.conversation_history:
            console.print("[dim]No conversation history yet.[/dim]")
            return
        
        console.print("[bold]📜 Conversation History:[/bold]")
        for i, conv in enumerate(self.conversation_history, 1):
            console.print(f"\n[bold cyan]{i}. You:[/bold cyan] {conv['user']}")
            console.print(f"[bold green]   AI:[/bold green] {conv['ai'][:100]}...")

def main():
    """
    Main entry point for AI chat.
    This is where the AI magic begins! ✨
    """
    try:
        ai_chat = ChainRiceAI()
        ai_chat.start_chat()
    except Exception as e:
        console.print(f"[red]❌ AI Chat error: {e}[/red]")
        logger.error(f"AI Chat main error: {e}")

if __name__ == "__main__":
    main()
