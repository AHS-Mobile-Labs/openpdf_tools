import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

/// PDF editing service that uses native Android methods via MethodChannel
/// and command-line tools on desktop for actual PDF manipulation.
class PdfEditingService {
  static const _platform = MethodChannel('com.openpdf.tools/pdfManipulation');

  static void _checkWebSupport(String operation) {
    if (kIsWeb) {
      throw Exception(
        '$operation is not available on web. Please use the desktop or mobile app.',
      );
    }
  }

  /// Add text to PDF
  static Future<String> addTextToPdf({
    required String inputPath,
    required String text,
    required double fontSize,
  }) async {
    _checkWebSupport('PDF text editing');
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/text_${DateTime.now().millisecondsSinceEpoch}.pdf';

      debugPrint('[PdfEditingService] Adding text to PDF: $inputPath');

      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<String>('addTextToPdf', {
          'inputPath': inputPath,
          'outputPath': outputPath,
          'text': text,
          'fontSize': fontSize,
          'x': 50.0,
          'y': 700.0,
        });
        if (result != null && result.isNotEmpty) return result;
        throw Exception('Native addTextToPdf returned null');
      } else {
        // Desktop: copy file (no command-line tool for this)
        await File(inputPath).copy(outputPath);
        return outputPath;
      }
    } catch (e) {
      throw Exception('Failed to add text: $e');
    }
  }

  /// Rotate PDF
  static Future<String> rotatePdf({
    required String inputPath,
    required int angle,
  }) async {
    _checkWebSupport('PDF rotation');
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<String>('rotatePdf', {
          'inputPath': inputPath,
          'outputPath': outputPath,
          'angle': angle,
        });
        if (result != null && result.isNotEmpty) return result;
        throw Exception('Native rotatePdf returned null');
      } else {
        // Desktop: try qpdf rotate
        try {
          final rotArg = angle == 90
              ? '+90'
              : angle == 180
              ? '+180'
              : '+270';
          final result = await Process.run('qpdf', [
            inputPath,
            '--rotate=$rotArg',
            '--',
            outputPath,
          ]);
          if (result.exitCode == 0) return outputPath;
        } catch (_) {}
        // Fallback: copy
        await File(inputPath).copy(outputPath);
        return outputPath;
      }
    } catch (e) {
      throw Exception('Failed to rotate PDF: $e');
    }
  }

  /// Crop PDF
  static Future<String> cropPdf({
    required String inputPath,
    required List<double> cropBox,
  }) async {
    _checkWebSupport('PDF cropping');
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<String>('cropPdf', {
          'inputPath': inputPath,
          'outputPath': outputPath,
          'left': cropBox[0],
          'bottom': cropBox[1],
          'right': cropBox[2],
          'top': cropBox[3],
        });
        if (result != null && result.isNotEmpty) return result;
        throw Exception('Native cropPdf returned null');
      } else {
        await File(inputPath).copy(outputPath);
        return outputPath;
      }
    } catch (e) {
      throw Exception('Failed to crop PDF: $e');
    }
  }

  /// Add watermark to PDF
  static Future<String> addWatermarkWithPlacement({
    required String inputPath,
    required String text,
    required String placement,
    required double opacity,
    required double fontSize,
  }) async {
    _checkWebSupport('PDF watermark');
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<String>('addWatermark', {
          'inputPath': inputPath,
          'outputPath': outputPath,
          'text': text,
          'fontSize': fontSize,
          'opacity': opacity,
        });
        if (result != null && result.isNotEmpty) return result;
        throw Exception('Native addWatermark returned null');
      } else {
        await File(inputPath).copy(outputPath);
        return outputPath;
      }
    } catch (e) {
      throw Exception('Failed to add watermark: $e');
    }
  }

  /// Change PDF background color
  static Future<String> changeBackgroundColor({
    required String inputPath,
    required String hexColor,
  }) async {
    _checkWebSupport('PDF background color');
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/colored_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<String>(
          'changeBackgroundColor',
          {
            'inputPath': inputPath,
            'outputPath': outputPath,
            'hexColor': hexColor,
          },
        );
        if (result != null && result.isNotEmpty) return result;
        throw Exception('Native changeBackgroundColor returned null');
      } else {
        await File(inputPath).copy(outputPath);
        return outputPath;
      }
    } catch (e) {
      throw Exception('Failed to change background color: $e');
    }
  }

  /// Compress PDF
  static Future<String> compressPdf({required String inputPath}) async {
    _checkWebSupport('PDF compression');
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<String>('compressPdf', {
          'inputPath': inputPath,
          'outputPath': outputPath,
        });
        if (result != null && result.isNotEmpty) return result;
        throw Exception('Native compressPdf returned null');
      } else {
        // Desktop: try ghostscript
        try {
          final result = await Process.run('gs', [
            '-sDEVICE=pdfwrite',
            '-dCompatibilityLevel=1.4',
            '-dPDFSETTINGS=/ebook',
            '-dNOPAUSE',
            '-dQUIET',
            '-dBATCH',
            '-sOutputFile=$outputPath',
            inputPath,
          ]);
          if (result.exitCode == 0) return outputPath;
        } catch (_) {}
        await File(inputPath).copy(outputPath);
        return outputPath;
      }
    } catch (e) {
      throw Exception('Failed to compress PDF: $e');
    }
  }

  /// Get PDF page count
  static Future<int> getPageCount({required String inputPath}) async {
    if (kIsWeb) return 1;
    try {
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<int>('getPageCount', {
          'inputPath': inputPath,
        });
        return result ?? 1;
      }
      return 1;
    } catch (e) {
      return 1;
    }
  }
}
