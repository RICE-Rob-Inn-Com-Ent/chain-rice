{ pkgs }:

{
  packages = with pkgs; [
    # Compilers and toolchains
    gcc
    gdb
    clang_18
    clang-tools_18  # clangd, clang-tidy, clang-format, scan-build
    lldb_18
    llvmPackages_18.lld
    ccache
    mold

    # Build systems and helpers
    cmake
    ninja
    meson
    pkg-config
    autoconf
    automake
    libtool
    bear  # compile_commands.json generator

    # Language servers and analysis
    ccls
    cppcheck
    include-what-you-use

    # Package/dependency managers
    conan
    vcpkg

    # Documentation
    doxygen
    graphviz

    # Testing frameworks (headers/libs available in Nix)
    googletest
    catch2
    doctest

    # Common C++ libraries
    boost
    fmt
    spdlog
    range-v3
    eigen
    openssl
    zlib
    curl
    sqlite
    protobuf
    grpc
    abseil-cpp
    re2
    tbb
    nlohmann_json

    # Coverage and profiling
    lcov
    gcovr
    valgrind
    heaptrack
    gperftools
    linuxPackages.perf
    flamegraph

    # CMake developer tooling
    python3Packages.cmake-language-server
    python3Packages.cmake-format

    # Linting/formatting extras
    python3Packages.cpplint
  ];
  
  envVars = {
    # Preferred toolchain (override per-project if needed)
    CC = "clang";
    CXX = "clang++";

    # Build configuration defaults
    CMAKE_GENERATOR = "Ninja";
    CMAKE_EXPORT_COMPILE_COMMANDS = "1";
    BUILD_TYPE = "Debug";

    # Compiler flags
    CFLAGS = "-O0 -g3 -fPIC -Wall -Wextra -Wpedantic";
    CXXFLAGS = "-O0 -g3 -fPIC -Wall -Wextra -Wpedantic";

    # Linker (prefer mold, fallback to lld)
    LDFLAGS = "-fuse-ld=mold";

    # Sanitizers (enable by exporting SANITIZERS or ASAN/UBSAN separately)
    SANITIZERS = "";  # e.g. "address,undefined"

    # ccache configuration
    CCACHE_BASEDIR = "$PWD";
    CCACHE_DIR = "$HOME/.ccache";
    CCACHE_COMPRESS = "1";
    CCACHE_MAXSIZE = "10G";

    # Project root hint for examples
    CHAINRICE_CPP_ROOT = "$PWD/stacks/langs/c++";
  };
  
  shellHook = ''
    echo "🔶 C++ Toolchain ready: GCC $(gcc --version | head -n1 | awk '{print $3}') | Clang $(${CXX:-clang++} --version | head -n1 | awk '{print $3}')"
    echo "   • clangd/clang-tidy/clang-format | ccls | cppcheck | iwyu"
    echo "   • CMake/Ninja/Meson | Conan/Vcpkg | Boost/fmt/spdlog/Protobuf/gRPC"
    echo "   • Valgrind/heaptrack/perf | lcov/gcovr | ccache | mold/LLD"

    # Ensure ccache in use if available
    if command -v ccache >/dev/null 2>&1; then
      export CC="ccache ${CC:-clang}"
      export CXX="ccache ${CXX:-clang++}"
      mkdir -p "$CCACHE_DIR"
      ccache -z >/dev/null 2>&1 || true
    fi

    # Prefer mold; fallback to lld if mold isn't found
    if ! ${CXX:-clang++} -fuse-ld=mold -Wl,--version >/dev/null 2>&1; then
      export LDFLAGS="-fuse-ld=lld"
    fi

    # Enable sanitizers if requested
    if [ -n "$SANITIZERS" ]; then
      export CFLAGS="$CFLAGS -fsanitize=$SANITIZERS -fno-omit-frame-pointer"
      export CXXFLAGS="$CXXFLAGS -fsanitize=$SANITIZERS -fno-omit-frame-pointer"
      export LDFLAGS="$LDFLAGS -fsanitize=$SANITIZERS"
    fi

    # Generate compile_commands.json on first entry if a CMake project exists
    if [ -f "CMakeLists.txt" ]; then
      if [ ! -d "build" ]; then
        echo "🏗️  Configuring CMake (generator: $CMAKE_GENERATOR, type: ${BUILD_TYPE})"
        cmake -S . -B build \
          -G "${CMAKE_GENERATOR}" \
          -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DCMAKE_C_COMPILER_LAUNCHER=ccache \
          -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
          -DCMAKE_C_COMPILER=$(echo "$CC" | awk '{print $NF}') \
          -DCMAKE_CXX_COMPILER=$(echo "$CXX" | awk '{print $NF}') || true
      fi
      # Symlink compile_commands.json to project root for LSPs
      if [ -f "build/compile_commands.json" ] && [ ! -f "compile_commands.json" ]; then
        ln -s build/compile_commands.json compile_commands.json 2>/dev/null || true
      fi
    fi

    # Helpful aliases
    alias cmk='cmake -S . -B build -G "${CMAKE_GENERATOR}" -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache'
    alias cb='cmake --build build -j $(nproc)'
    alias ct='ctest --test-dir build --output-on-failure'
    alias tidy='clang-tidy -p build'
    alias fmt-cpp='clang-format -i $(git ls-files "**/*.[ch]pp" "**/*.[ch]xx" "**/*.[ch]++" "**/*.[ch]")'
    alias iwyu='include-what-you-use'
    alias scan='scan-build cmake -S . -B build && scan-build cmake --build build'
    alias memcheck='valgrind --leak-check=full --show-leak-kinds=all'

    # Conan/vcpkg quick init in project if files exist
    if [ -f "conanfile.txt" ] || [ -f "conanfile.py" ]; then
      echo "📦 Conan: installing dependencies"
      conan profile detect --force >/dev/null 2>&1 || true
      conan install . --output-folder=build --build=missing || true
    fi
    if [ -f "vcpkg.json" ] && command -v vcpkg >/dev/null 2>&1; then
      echo "📦 vcpkg: installing dependencies"
      vcpkg install || true
    fi

    # If sample project exists in CHAINRICE_CPP_ROOT, hint how to run
    if [ -f "${CHAINRICE_CPP_ROOT}/CMakeLists.txt" ]; then
      echo "📘 Sample available at ${CHAINRICE_CPP_ROOT}"
      echo "   cd ${CHAINRICE_CPP_ROOT} && cmk && cb && ./build/cpp_hello"
    fi
  '';
}
