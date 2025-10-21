#!/usr/bin/env python3
"""
Code Generator using Ollama with DeepSeek Coder or Code Llama
"""

import ollama
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

console = Console()


def generate_code(prompt: str, language: str = "python", model: str = "deepseek-coder:6.7b"):
    """
    Generate code using Ollama

    Args:
        prompt: Code generation prompt
        language: Programming language
        model: Ollama model (deepseek-coder, codellama, etc.)
    """

    console.print(Panel(f"[bold cyan]Generating {language} code...[/bold cyan]", title="Code Generator"))

    # Create a more specific prompt for code generation
    full_prompt = f"""You are an expert programmer. Generate {language} code for the following task.
Only return the code, no explanations unless asked.

Task: {prompt}

Code:
"""

    response = ollama.generate(
        model=model,
        prompt=full_prompt,
        options={"temperature": 0.2, "top_p": 0.9, "num_predict": 1000},  # Lower for more deterministic code
    )

    code = response["response"].strip()

    # Remove markdown code blocks if present
    if code.startswith("```"):
        lines = code.split("\n")
        code = "\n".join(lines[1:-1]) if len(lines) > 2 else code

    # Display with syntax highlighting
    syntax = Syntax(code, language, theme="monokai", line_numbers=True)
    console.print(syntax)

    return code


def explain_code(code: str, model: str = "llama3.3"):
    """Explain what the code does"""

    console.print("\n[bold green]Explaining code...[/bold green]\n")

    prompt = f"""Explain what this code does in simple terms:

```
{code}
```

Explanation:"""

    response = ollama.generate(model=model, prompt=prompt)
    console.print(response["response"])


def review_code(code: str, model: str = "llama3.3"):
    """Review code for potential issues"""

    console.print("\n[bold yellow]Reviewing code...[/bold yellow]\n")

    prompt = f"""Review this code and suggest improvements, potential bugs, or optimizations:

```
{code}
```

Code Review:"""

    response = ollama.generate(model=model, prompt=prompt)
    console.print(response["response"])


if __name__ == "__main__":
    # Example 1: Generate a function
    console.print("[bold]Example 1: Generate a function[/bold]\n")
    code1 = generate_code(
        "Create a function to calculate Fibonacci numbers with memoization",
        language="python",
        model="deepseek-coder:6.7b",
    )

    # Example 2: Generate a class
    console.print("\n\n[bold]Example 2: Generate a class[/bold]\n")
    code2 = generate_code(
        "Create a binary search tree class with insert, search, and delete methods",
        language="python",
        model="deepseek-coder:6.7b",
    )

    # Example 3: Explain code
    console.print("\n\n[bold]Example 3: Explain code[/bold]")
    explain_code(code1)

    # Example 4: Review code
    console.print("\n\n[bold]Example 4: Review code[/bold]")
    review_code(code2)

    # Interactive mode
    console.print("\n\n[bold cyan]Interactive Code Generator[/bold cyan]")
    console.print("[dim]Type 'exit' to quit[/dim]\n")

    while True:
        task = console.input("[bold blue]What code do you need?[/bold blue] ")

        if task.lower() in ["exit", "quit"]:
            break

        lang = console.input("[bold blue]Language (default: python):[/bold blue] ") or "python"

        generate_code(task, lang)

        action = console.input("\n[bold]Explain (e), Review (r), or Continue (c)?[/bold] ").lower()

        if action == "e":
            explain_code(code1)
        elif action == "r":
            review_code(code1)
