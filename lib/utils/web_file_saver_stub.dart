import 'dart:typed_data';

Future<void> downloadFile(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/pdf',
}) async {
  // No-op on non-web platforms (native file system used instead)
}
