import 'dart:io';

import 'package:flutter/services.dart';

/// Resolves Android content/file URIs into app-readable filesystem paths.
///
/// FilePicker can return content:// values on Android. Native PDF operations
/// and Flutter's File APIs need a real path, so content URIs are copied into
/// the app cache through the PDF manipulation channel.
Future<String> resolveToRealPath(String pickedPath) async {
  if (!Platform.isAndroid) return pickedPath;

  if (pickedPath.startsWith('file://')) {
    try {
      final filePath = Uri.parse(pickedPath).toFilePath();
      if (File(filePath).existsSync()) return filePath;
    } catch (_) {}
  }

  if (!pickedPath.startsWith('content://') && File(pickedPath).existsSync()) {
    return pickedPath;
  }

  const channel = MethodChannel('com.openpdf.tools/pdfManipulation');
  try {
    final result = await channel.invokeMethod<String>('copyUriToCache', {
      'uri': pickedPath,
    });
    if (result != null && result.isNotEmpty) return result;
  } catch (_) {}

  return pickedPath;
}
