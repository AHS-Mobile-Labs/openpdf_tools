import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_file_saver_stub.dart'
    if (dart.library.html) 'web_file_saver_web.dart' as saver;

class WebFileSaver {
  static Future<void> saveFile({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/pdf',
  }) async {
    if (kIsWeb) {
      await saver.downloadFile(bytes, fileName, mimeType: mimeType);
    }
  }
}
