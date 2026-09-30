import 'platform_file_picker_stub.dart'
    if (dart.library.html) 'platform_file_picker_web.dart' as platform_picker;

/// Picks an image file from the device and returns it as a Base64 Data URL (data:image/...;base64,...),
/// or null if cancelled or unsupported on this platform.
Future<String?> pickImageFromDevice() => platform_picker.pickImageAsDataUrl();
