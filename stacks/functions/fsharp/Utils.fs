module Utils

let greet (?prefix: string) (name: string) =
    let p = defaultArg prefix "Hello"
    sprintf "%s, %s!" p name


