package examples.java.src.com.example;

public class Greeter {
    private final String name;

    public Greeter(String name) {
        this.name = (name == null || name.isEmpty()) ? "World" : name;
    }

    public String greet() {
        return "Hello, " + name + "!";
    }
}
