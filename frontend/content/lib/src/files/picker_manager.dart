import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Cross-surface file and gallery access for firmware blobs, libraries, and media.
final class PickerManager {
  PickerManager._();

  static final PickerManager instance = PickerManager._();

  final ImagePicker _images = ImagePicker();

  Future<List<String>?> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: allowedExtensions == null || allowedExtensions.isEmpty
          ? FileType.any
          : FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final paths = <String>[];
    for (final f in result.files) {
      final p = f.path;
      if (p != null) {
        paths.add(p);
      }
    }
    return paths.isEmpty ? null : paths;
  }

  Future<String?> pickImageFromGallery() async {
    final x = await _images.pickImage(source: ImageSource.gallery);
    return x?.path;
  }

  Future<String?> pickImageFromCamera() async {
    final x = await _images.pickImage(source: ImageSource.camera);
    return x?.path;
  }

  Future<Uint8List?> pickImageBytesFromGallery() async {
    final x = await _images.pickImage(source: ImageSource.gallery);
    if (x == null) {
      return null;
    }
    return x.readAsBytes();
  }
}
