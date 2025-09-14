import 'greeter.dart';
import 'models.dart';

String libraryGreeting() {
  final greeter = Greeter('Library');
  return greeter.greet();
}

Map<String, dynamic> samplePersonJson() {
  final person = Person(name: 'Ala', age: 30);
  return person.toJson();
}


