import 'dart:convert';

// TODO:
// [ ] decode/encode GeneratedMessage — https://pub.dev/documentation/protobuf/latest/
// [ ] toMap for Riverpod state
//
/// JSON helpers for protobuf JSON wire — pair with generated `*.pb.dart` messages in `gen/`.
Map<String, dynamic> protoToJson(Map<String, dynamic> message) => Map<String, dynamic>.from(message);

Map<String, dynamic> protoFromJson(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

Map<String, dynamic> protoClone(Map<String, dynamic> message) =>
    protoFromJson(jsonEncode(message));
