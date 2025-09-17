package examples.java.src.com.example;

public class App {
    public static void main(String[] args) {
        String name = (args != null && args.length > 0) ? args[0] : "World";
        System.out.println(new Greeter(name).greet());
    }
}
