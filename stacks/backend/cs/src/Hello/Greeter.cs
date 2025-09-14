namespace Hello;

public class Greeter
{
    private readonly string _name;

    public Greeter(string name)
    {
        _name = name;
    }

    public string Greet() => $"Hello, {_name}!";
}


