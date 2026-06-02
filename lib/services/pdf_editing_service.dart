import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:openpdf_tools/utils/output_path_helper.dart';

class PdfEditingService {
  static const _platform = MethodChannel('com.openpdf.tools/pdfManipulation');
  static void _checkWebSupport(String operation) {
    if (kIsWeb) {
      throw Exception(
        '$operation is not available on web. Please use the desktop or mobile app.',
      );
    }
  }

  static Future<String> _ensureOutputPath(String prefix) async {
    return OutputPathHelper.createWorkingOutputPath(
      fileName: '${prefix}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      category: OutputCategory.exports,
    );
  }

  static Future<String> addTextToPdf({
    required String inputPath,
    required String text,
    required double fontSize,
  }) async {
    _checkWebSupport('PDF text editing');
    try {
      final outputPath = await _ensureOutputPath('text');
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
      }
      throw Exception(_desktopUnsupportedMessage('add text to PDFs'));
    } catch (e) {
      throw Exception('Failed to add text: $e');
    }
  }

  static Future<String> rotatePdf({
    required String inputPath,
    required int angle,
  }) async {
    _checkWebSupport('PDF rotation');
    try {
      final outputPath = await _ensureOutputPath('rotated');
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<String>('rotatePdf', {
          'inputPath': inputPath,
          'outputPath': outputPath,
          'angle': angle,
        });
        if (result != null && result.isNotEmpty) return result;
        throw Exception('Native rotatePdf returned null');
      } else {
        try {
          final rotArg = angle == 90
              ? '+90'
              : angle == 180
              ? '+180'
              : '+270';
          final result = await Process.run('qpdf', [
            inputPath,
            '--rotate=$rotArg:1-z',
            '--',
            outputPath,
          ]);
          if (result.exitCode == 0) return outputPath;
        } catch (_) {}
        throw Exception(
          'Rotation requires qpdf on desktop. Install qpdf and try again.',
        );
      }
    } catch (e) {
      throw Exception('Failed to rotate PDF: $e');
    }
  }

  static Future<String> cropPdf({
    required String inputPath,
    required List<double> cropBox,
  }) async {
    _checkWebSupport('PDF cropping');
    try {
      final outputPath = await _ensureOutputPath('cropped');
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
      }
      throw Exception(_desktopUnsupportedMessage('crop PDFs'));
    } catch (e) {
      throw Exception('Failed to crop PDF: $e');
    }
  }

  static Future<String> addWatermarkWithPlacement({
    required String inputPath,
    required String text,
    required String placement,
    required double opacity,
    required double fontSize,
  }) async {
    _checkWebSupport('PDF watermark');
    try {
      final outputPath = await _ensureOutputPath('watermarked');
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
      }
      throw Exception(_desktopUnsupportedMessage('add watermarks'));
    } catch (e) {
      throw Exception('Failed to add watermark: $e');
    }
  }

  static Future<String> changeBackgroundColor({
    required String inputPath,
    required String hexColor,
  }) async {
    _checkWebSupport('PDF background color');
    try {
      final outputPath = await _ensureOutputPath('colored');
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
      }
      throw Exception(_desktopUnsupportedMessage('change PDF backgrounds'));
    } catch (e) {
      throw Exception('Failed to change background color: $e');
    }
  }

  static Future<String> compressPdf({required String inputPath}) async {
    _checkWebSupport('PDF compression');
    try {
      final outputPath = await _ensureOutputPath('compressed');
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<String>('compressPdf', {
          'inputPath': inputPath,
          'outputPath': outputPath,
        });
        if (result != null && result.isNotEmpty) return result;
        throw Exception('Native compressPdf returned null');
      } else {
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
        throw Exception(
          'Compression requires Ghostscript on desktop. Install ghostscript and try again.',
        );
      }
    } catch (e) {
      throw Exception('Failed to compress PDF: $e');
    }
  }

  static Future<int> getPageCount({required String inputPath}) async {
    if (kIsWeb) return 1;
    try {
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod<int>('getPageCount', {
          'inputPath': inputPath,
        });
        return result ?? 0;
      }
      final pdfInfo = await Process.run('pdfinfo', [inputPath]);
      if (pdfInfo.exitCode == 0) {
        for (final line in pdfInfo.stdout.toString().split('\n')) {
          if (line.startsWith('Pages:')) {
            return int.tryParse(line.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          }
        }
      }
      final qpdf = await Process.run('qpdf', ['--show-npages', inputPath]);
      if (qpdf.exitCode == 0) {
        return int.tryParse(qpdf.stdout.toString().trim()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static String _desktopUnsupportedMessage(String operation) {
    return 'This platform cannot currently $operation without a native PDF '
        'editing backend. No unchanged copy was saved.';
  }
}
