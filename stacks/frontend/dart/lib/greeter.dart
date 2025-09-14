class Greeter {
  final String name;
  const Greeter(this.name);

  String greet({String prefix = 'Hello'}) => '$prefix, $name!';
}


