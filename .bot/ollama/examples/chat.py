#!/usr/bin/env python3
"""
Ollama Chat Example - Interactive chat with local LLM
"""

import ollama
from rich.console import Console
from rich.markdown import Markdown

console = Console()


def chat_with_ollama(model: str = "llama3.3"):
    """Interactive chat session with Ollama"""

    console.print(f"[bold green]Starting chat with {model}...[/bold green]")
    console.print("[dim]Type 'exit' or 'quit' to end the conversation[/dim]\n")

    messages = []

    while True:
        # Get user input
        user_input = console.input("[bold blue]You:[/bold blue] ")

        if user_input.lower() in ["exit", "quit"]:
            console.print("[yellow]Goodbye![/yellow]")
            break

        # Add user message
        messages.append({"role": "user", "content": user_input})

        # Get AI response
        console.print("\n[bold green]AI:[/bold green]", end=" ")

        full_response = ""
        stream = ollama.chat(model=model, messages=messages, stream=True)

        for chunk in stream:
            content = chunk["message"]["content"]
            console.print(content, end="", markup=False)
            full_response += content

        console.print("\n")

        # Add AI response to history
        messages.append({"role": "assistant", "content": full_response})


if __name__ == "__main__":
    import sys

    model = sys.argv[1] if len(sys.argv) > 1 else "llama3.3"

    try:
        chat_with_ollama(model)
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted. Goodbye![/yellow]")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")
