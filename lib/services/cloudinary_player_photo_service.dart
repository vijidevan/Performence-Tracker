import 'dart:convert';

import 'package:http/http.dart' as http;

class CloudinaryPlayerPhotoService {
  static const String _cloudName = 'ugr6tgqt';
  static const String _uploadPreset = 'team_performance_players';

  static Uri get _uploadUri => Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  static Future<String> uploadPlayerPhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    if (bytes.length > _maxFileSizeBytes) {
      throw Exception('Player photo must be smaller than 5 MB.');
    }

    final request = http.MultipartRequest(
      'POST',
      _uploadUri,
    );

    request.fields['upload_preset'] = _uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Player photo upload failed.';

      try {
        final errorData =
            jsonDecode(response.body) as Map<String, dynamic>;

        final error = errorData['error'];

        if (error is Map<String, dynamic>) {
          final messageValue = error['message'];

          if (messageValue is String && messageValue.isNotEmpty) {
            message = messageValue;
          }
        }
      } catch (_) {
        // Keep the default error message.
      }

      throw Exception(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final secureUrl = data['secure_url'];

    if (secureUrl is! String || secureUrl.isEmpty) {
      throw Exception(
        'Cloudinary upload succeeded, but no image URL was returned.',
      );
    }

    return secureUrl;
  }
}