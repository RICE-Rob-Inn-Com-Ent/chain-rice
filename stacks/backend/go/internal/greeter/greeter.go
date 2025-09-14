package greeter

func Greet(name string) string {
	if name == "" {
		name = "World"
	}
	return "Hello, " + name + "!"
}
