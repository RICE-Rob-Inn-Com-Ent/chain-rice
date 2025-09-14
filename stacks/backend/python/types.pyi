from typing import TypedDict

class HelloResponse(TypedDict):
    message: str

def greet(name: str = ...) -> str: ...

def main() -> None: ...

def run() -> None: ...


