fun greet(name: String = "World") = "Hello, $name!"

fun main(args: Array<String>) {
    val name = args.firstOrNull() ?: "World"
    println(greet(name))
}

fun main() {
    println("Hello, World!")
}


