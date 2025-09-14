import 'dart:convert';
import 'package:examples_dart_hello/greeter.dart';
import 'package:examples_dart_hello/main.dart' as lib;

void main(List<String> args) {
  final greeter = Greeter('World');
  print(greeter.greet());
  print(lib.libraryGreeting());
  print(jsonEncode(lib.samplePersonJson()));
}


