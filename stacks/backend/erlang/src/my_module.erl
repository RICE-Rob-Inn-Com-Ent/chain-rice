-module(my_module).
-export([greet/0, greet/1]).

greet() -> greet("World").

greet(Name) when is_list(Name) ->
    io:format("Hello, ~s!~n", [Name]).


