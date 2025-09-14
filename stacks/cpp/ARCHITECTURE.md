## Architecture

- `CMakeLists.txt`: Definicja projektu i targetu wykonywalnego.
- `include/greeter.hpp`: Prosty interfejs klasy `Greeter` (API publiczne).
- `src/greeter.cpp`: Implementacja klasy `Greeter` (szczegóły ukryte).
- `src/main.cpp`: Punkt wejścia używający `Greeter`.

### Build flow

1. Konfiguracja: `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release`
2. Kompilacja: `cmake --build build --config Release`
3. Uruchomienie: `./build/cpp_hello`

### Jak to działa (mini przykład)

- `Greeter` przechowuje nazwę i generuje wiadomość typu "Hello, <name>!".
- `main.cpp` tworzy obiekt `Greeter("World")` i wypisuje wynik `greet()` na stdout.

### Rozszerzanie

- Dodaj katalog `include/` dla nagłówków i uporządkuj API.
- Dodaj testy (np. GoogleTest/Catch2) i integrację CI.
- Wydziel bibliotekę (`add_library`) i linkuj do niej w `add_executable`.


