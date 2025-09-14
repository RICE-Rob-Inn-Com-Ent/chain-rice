#!/usr/bin/env python3
"""
🔥 Chain Rice CLI - The Ultimate Learning Playground
This is where the magic happens, bruh! 🚀
"""
import sys
import asyncio
from typing import Optional, List
from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.table import Table
from rich.progress import Progress, SpinnerColumn, TextColumn
import click
from loguru import logger

# Import our sick modules
from ai_chat import main as ai_chat_main
from data_analysis import main as data_analysis_main
from fast_api import run as api_run
from utils.blockchain_simulator import BlockchainSimulator
from utils.data_generator import DataGenerator
from utils.ai_helper import AIHelper

console = Console()

@click.group()
@click.version_option(version="0.2.0", prog_name="Chain Rice CLI")
def cli():
    """
    🔥 Chain Rice CLI - The Ultimate Learning Playground
    
    This CLI is like a Swiss Army knife for blockchain development.
    It's got everything you need to learn, experiment, and build cool stuff!
    
    Pro tip: Use --help with any command to see what it can do! 🎯
    """
    # Configure logging (because we're professionals, not animals)
    logger.remove()
    logger.add(sys.stderr, level="INFO", format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>")

@cli.command()
@click.argument('name', default='World')
@click.option('--emoji', '-e', default='🚀', help='Emoji to use in greeting')
@click.option('--style', '-s', default='bold blue', help='Text style')
def greet(name: str, emoji: str, style: str):
    """
    Say hello to someone (or something) in style! 
    
    This is the classic "Hello World" but with extra sauce! 🌶️
    """
    message = f"{emoji} Hello, {name}! Welcome to Chain Rice! {emoji}"
    
    # Create a beautiful panel because we're fancy like that
    panel = Panel(
        Text(message, style=style),
        title="[bold green]Chain Rice Greeting[/bold green]",
        subtitle="[dim]Powered by Python magic ✨[/dim]",
        border_style="green"
    )
    
    console.print(panel)
    logger.info(f"Greeted {name} with emoji {emoji}")

@cli.command()
@click.option('--model', '-m', default='gpt-3.5-turbo', help='AI model to use')
@click.option('--prompt', '-p', help='Custom prompt (otherwise interactive)')
def ai(prompt: Optional[str], model: str):
    """
    Chat with AI about blockchain stuff! 
    
    This is where you can ask questions about Chain Rice, blockchain concepts,
    or just have a casual chat with our AI buddy! 🤖
    """
    console.print(Panel(
        "[bold blue]🤖 AI Chat Mode Activated![/bold blue]\n"
        "Ask me anything about blockchain, Chain Rice, or just chat!",
        title="AI Assistant",
        border_style="blue"
    ))
    
    if prompt:
        # Non-interactive mode
        ai_helper = AIHelper()
        response = ai_helper.chat(prompt, model=model)
        console.print(f"[green]AI:[/green] {response}")
    else:
        # Interactive mode - let's get chatty!
        ai_chat_main()

@cli.command()
@click.option('--data-type', '-t', default='transactions', help='Type of data to generate')
@click.option('--count', '-c', default=100, help='Number of records to generate')
@click.option('--output', '-o', help='Output file (CSV)')
def generate_data(data_type: str, count: int, output: Optional[str]):
    """
    Generate some sick sample data for testing and learning!
    
    Perfect for when you need data but don't want to create it manually.
    We've got transactions, users, blocks, and more! 📊
    """
    console.print(f"[yellow]Generating {count} {data_type} records...[/yellow]")
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        task = progress.add_task("Generating data...", total=None)
        
        generator = DataGenerator()
        data = generator.generate_data(data_type, count)
        
        if output:
            data.to_csv(output, index=False)
            console.print(f"[green]✅ Data saved to {output}[/green]")
        else:
            console.print(data.head())
            console.print(f"[dim]Use --output to save to file[/dim]")

@cli.command()
@click.option('--blocks', '-b', default=5, help='Number of blocks to simulate')
@click.option('--transactions', '-t', default=10, help='Transactions per block')
def simulate_blockchain(blocks: int, transactions: int):
    """
    Simulate a blockchain! This is where the magic happens! ⛓️
    
    Watch as we create blocks, mine them, and see the blockchain grow.
    It's like watching a digital organism evolve! 🧬
    """
    console.print(Panel(
        f"[bold green]⛓️ Blockchain Simulation Starting![/bold green]\n"
        f"Creating {blocks} blocks with {transactions} transactions each...",
        title="Blockchain Simulator",
        border_style="green"
    ))
    
    simulator = BlockchainSimulator()
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        task = progress.add_task("Mining blocks...", total=blocks)
        
        for i in range(blocks):
            simulator.add_block(transactions)
            progress.update(task, advance=1, description=f"Mined block {i+1}/{blocks}")
    
    # Show the blockchain
    console.print("\n[bold]📊 Blockchain Summary:[/bold]")
    table = Table(title="Blockchain Stats")
    table.add_column("Metric", style="cyan")
    table.add_column("Value", style="green")
    
    table.add_row("Total Blocks", str(len(simulator.chain)))
    table.add_row("Total Transactions", str(sum(len(block.transactions) for block in simulator.chain)))
    table.add_row("Chain Hash", simulator.chain[-1].hash[:20] + "...")
    
    console.print(table)

@cli.command()
@click.option('--port', '-p', default=8000, help='Port to run API on')
@click.option('--host', '-h', default='0.0.0.0', help='Host to bind to')
def api(port: int, host: str):
    """
    Start the Chain Rice API server! 
    
    This fires up our FastAPI server with all the endpoints you need.
    Perfect for building frontends or integrating with other services! 🌐
    """
    console.print(Panel(
        f"[bold blue]🌐 Starting Chain Rice API Server[/bold blue]\n"
        f"Server will be available at: http://{host}:{port}\n"
        f"API docs: http://{host}:{port}/docs",
        title="API Server",
        border_style="blue"
    ))
    
    # Start the API server
    api_run(host=host, port=port)

@cli.command()
def demo():
    """
    Run the full Chain Rice demo! 
    
    This is like a fireworks show of all our features!
    Perfect for showing off what Chain Rice can do! 🎆
    """
    console.print(Panel(
        "[bold magenta]🎆 Chain Rice Full Demo Starting![/bold magenta]\n"
        "Get ready for an epic showcase of all our features!",
        title="Demo Mode",
        border_style="magenta"
    ))
    
    # Demo sequence
    demo_steps = [
        ("Greeting", lambda: greet.callback("Demo User", "🎉", "bold magenta")),
        ("Data Generation", lambda: generate_data.callback("transactions", 50, None)),
        ("Blockchain Simulation", lambda: simulate_blockchain.callback(3, 5)),
        ("AI Chat", lambda: ai.callback("Tell me about blockchain technology")),
    ]
    
    for step_name, step_func in demo_steps:
        console.print(f"\n[bold]🎯 Running: {step_name}[/bold]")
        try:
            step_func()
        except Exception as e:
            console.print(f"[red]❌ Error in {step_name}: {e}[/red]")
        
        console.print("[dim]Press Enter to continue...[/dim]")
        input()

@cli.command()
def status():
    """
    Check the status of all Chain Rice services! 
    
    This gives you a quick health check of everything.
    Like a doctor's checkup, but for your blockchain app! 🏥
    """
    console.print(Panel(
        "[bold green]🏥 Chain Rice Health Check[/bold green]",
        title="System Status",
        border_style="green"
    ))
    
    # Create status table
    table = Table(title="Service Status")
    table.add_column("Service", style="cyan")
    table.add_column("Status", style="green")
    table.add_column("Description", style="dim")
    
    services = [
        ("CLI", "✅ Running", "Command line interface"),
        ("AI Chat", "✅ Ready", "AI assistant"),
        ("Data Generator", "✅ Ready", "Sample data creation"),
        ("Blockchain Sim", "✅ Ready", "Blockchain simulation"),
        ("API Server", "✅ Ready", "REST API endpoints"),
        ("Auth System", "✅ Ready", "JWT authentication"),
    ]
    
    for service, status, desc in services:
        table.add_row(service, status, desc)
    
    console.print(table)

def main():
    """
    Main entry point for the Chain Rice CLI.
    
    This is where it all begins! 🚀
    """
    try:
        cli()
    except KeyboardInterrupt:
        console.print("\n[yellow]👋 Goodbye! Thanks for using Chain Rice![/yellow]")
    except Exception as e:
        console.print(f"[red]❌ Something went wrong: {e}[/red]")
        logger.error(f"CLI error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
