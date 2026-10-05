import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PlayerPhotoFile {
  final Uint8List bytes;
  final String name;

  const PlayerPhotoFile({
    required this.bytes,
    required this.name,
  });
}

class PlayerPhotoPicker {
  static Future<PlayerPhotoFile?> pickPhoto() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.image,
    );

    if (pickedFile == null) {
      return null;
    }

    final bytes = await pickedFile.readAsBytes();

    return PlayerPhotoFile(
      bytes: bytes,
      name: pickedFile.name,
    );
  }
}