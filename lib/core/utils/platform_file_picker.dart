import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Picks an image file from the device (Android, iOS, Web) and returns it
/// as a Base64 Data URL (data:image/...;base64,...), or null if cancelled.
Future<String?> pickImageFromDevice() async {
  try {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? 'image/jpeg';
    final base64 = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64';
  } catch (e, stack) {
    debugPrint('[SaveBite] pickImageFromDevice error: $e\n$stack');
    rethrow;
  }
}
