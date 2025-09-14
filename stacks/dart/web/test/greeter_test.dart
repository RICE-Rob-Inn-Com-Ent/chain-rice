import 'package:test/test.dart';
import 'package:examples_dart_hello/greeter.dart';

void main() {
  test('default greeting', () {
    expect(const Greeter('World').greet(), 'Hello, World!');
  });

  test('custom prefix', () {
    expect(const Greeter('Ala').greet(prefix: 'Cześć'), 'Cześć, Ala!');
  });
}


