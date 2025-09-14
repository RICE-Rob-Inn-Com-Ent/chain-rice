module Program

open Utils

[<EntryPoint>]
let main _argv =
    printfn "%s" (greet "World")
    0


