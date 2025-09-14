using Test
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using MyApp

@test greet() == "Hello, World!"
@test greet("Ala") == "Hello, Ala!"


