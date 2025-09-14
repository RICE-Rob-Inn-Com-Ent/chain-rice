package main

import (
	"fmt"
	"os"

	"examples/go/internal/greeter"
)

func main() {
	name := "World"
	if len(os.Args) > 1 {
		name = os.Args[1]
	}
	fmt.Println(greeter.Greet(name))
}
