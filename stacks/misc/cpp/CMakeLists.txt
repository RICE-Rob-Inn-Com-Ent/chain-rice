cmake_minimum_required(VERSION 3.16)
project(cpp_hello LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(cpp_hello src/main.cpp)

target_compile_features(cpp_hello PRIVATE cxx_std_17)

target_sources(cpp_hello PRIVATE src/greeter.cpp)
target_include_directories(cpp_hello PRIVATE include)


