part of 'lib/models.dart';

Person _$PersonFromJson(Map<String, dynamic> json) =>
    Person(name: json['name'] as String, age: json['age'] as int);

Map<String, dynamic> _$PersonToJson(Person instance) =>
    <String, dynamic>{'name': instance.name, 'age': instance.age};


