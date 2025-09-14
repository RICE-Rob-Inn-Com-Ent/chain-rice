import Pkg
Pkg.activate(@__DIR__)

push!(LOAD_PATH, joinpath(@__DIR__, "src"))
using MyApp

name = length(ARGS) > 0 ? ARGS[1] : "World"
println(greet(name))


