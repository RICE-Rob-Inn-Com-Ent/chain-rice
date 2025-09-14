module MyApp

export greet

greet(name::AbstractString="World") = "Hello, $(name)!"

end # module


