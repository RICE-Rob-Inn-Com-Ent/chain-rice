part 'models.g.dart';

class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);
}


