## C++ Hello World (CMake)

**Build & Run**

- Create build dir: `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release`
- Build: `cmake --build build --config Release`
- Run: `./build/cpp_hello`

See `ARCHITECTURE.md` for structure and extension ideas.

## Do czego najlepiej pasuje C++?

- Systemy niskopoziomowe: systemy operacyjne, sterowniki, firmware, embedded/RTOS.
- Aplikacje o krytycznej wydajności: silniki gier, renderowanie 3D, multimedia.
- Systemy czasu rzeczywistego i o niskich opóźnieniach: HFT, telekom, IoT.
- Biblioteki i narzędzia wieloplatformowe: silniki baz danych, serwery, runtime'y.
- HPC i obliczenia równoległe: SIMD, CUDA/OpenCL, OpenMP/MPI, numeryka.
- Aplikacje desktopowe natywne: Qt/wxWidgets, narzędzia developerskie.

## Kiedy rozważyć inne języki?

- Szybkie skrypty/prototypy i data wrangling: Python, JavaScript/TypeScript.
- Proste narzędzia CLI i serwisy z krótkim cyklem build/run: Go, Rust.
- Aplikacje web o wysokim poziomie abstrakcji: TypeScript (Node/Next), Python.

## Oceny (1–5 gwiazdek)

Skala: 1 = niskie/małe, 5 = wysokie/duże.

- Poziom trudności nauki: ★★★★☆
- Bogactwo bibliotek/ekosystemu: ★★★★☆
- Bogactwo zastosowań w praktyce: ★★★★★
- Potencjał wydajności: ★★★★★
- Złożoność narzędzi/buildów (im więcej, tym trudniej): ★★★★☆

## Przykładowe biblioteki i narzędzia

- Standard: STL, `<thread>`, `<filesystem>`, `<chrono>`.
- GUI: Qt, wxWidgets, ImGui.
- Gry/multimedia: Unreal Engine (C++), SDL2, SFML.
- Grafika: OpenGL/Vulkan/DirectX (przez API/warstwy), BGFX.
- Sieć i RPC: Boost.Asio, gRPC, cpp-httplib.
- ML/inferencja: ONNX Runtime, TensorRT, OpenVINO (C++ API).
- Testy: GoogleTest, Catch2, doctest.
- Build: CMake, Meson, Conan/vcpkg (zarządzanie zależnościami).

## Jak zacząć z tym przykładem?

- Zbuduj i uruchom wg kroków powyżej.
- Zajrzyj do `ARCHITECTURE.md`, aby zobaczyć, jak rozbudować projekt (np. dodać `include/`, testy, biblioteki).