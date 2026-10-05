import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class PlayerPhotoStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadPlayerPhoto({
    required String playerId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = _extensionFromFileName(fileName);

    final storageRef = _storage.ref().child(
          'player_photos/$playerId.$extension',
        );

    final metadata = SettableMetadata(
      contentType: _contentType(extension),
      cacheControl: 'public,max-age=3600',
    );

    await storageRef.putData(
      bytes,
      metadata,
    );

    return await storageRef.getDownloadURL();
  }

  static String _extensionFromFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }

    final extension = fileName.substring(dotIndex + 1).toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return extension;
      default:
        return 'jpg';
    }
  }

  static String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}