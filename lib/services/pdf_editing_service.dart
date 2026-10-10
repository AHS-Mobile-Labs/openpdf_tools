import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

  /// Adds text to a PDF page using pure-Dart Syncfusion PDF.
  static Future<String> addTextToPdf({
    required String inputPath,
    required String text,
    required double fontSize,
    double x = 50.0,
    double y = 50.0,
    int pageIndex = 0,
  }) async {
    _checkWebSupport('PDF text editing');
    try {
      final outputPath = await _ensureOutputPath('text');
      debugPrint('[PdfEditingService] Adding text to PDF: $inputPath');

      final bytes = await File(inputPath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      try {
        if (document.pages.count == 0) {
          throw Exception('PDF has no pages');
        }
        final targetIndex = pageIndex.clamp(0, document.pages.count - 1);
        final page = document.pages[targetIndex];

        final font = PdfStandardFont(
          PdfFontFamily.helvetica,
          fontSize > 0 ? fontSize : 14.0,
        );
        final brush = PdfSolidBrush(PdfColor(0, 0, 0));

        page.graphics.drawString(
          text,
          font,
          brush: brush,
          bounds: ui.Rect.fromLTWH(
            x,
            y,
            page.size.width - x > 50 ? page.size.width - x : page.size.width,
            page.size.height - y > 50 ? page.size.height - y : page.size.height,
          ),
        );

        final savedBytes = await document.save();
        await File(outputPath).writeAsBytes(savedBytes, flush: true);
        return outputPath;
      } finally {
        document.dispose();
      }
    } catch (e) {
      throw Exception('Failed to add text: $e');
    }
  }

  /// Rotates all pages in a PDF by the specified angle (90, 180, 270) in pure Dart.
  static Future<String> rotatePdf({
    required String inputPath,
    required int angle,
  }) async {
    _checkWebSupport('PDF rotation');
    try {
      final outputPath = await _ensureOutputPath('rotated');
      final bytes = await File(inputPath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      try {
        final normalizedAngle = ((angle % 360) + 360) % 360;
        for (var i = 0; i < document.pages.count; i++) {
          final page = document.pages[i];
          int currentDeg = 0;
          switch (page.rotation) {
            case PdfPageRotateAngle.rotateAngle90:
              currentDeg = 90;
              break;
            case PdfPageRotateAngle.rotateAngle180:
              currentDeg = 180;
              break;
            case PdfPageRotateAngle.rotateAngle270:
              currentDeg = 270;
              break;
            case PdfPageRotateAngle.rotateAngle0:
              currentDeg = 0;
              break;
          }
          final newDeg = (currentDeg + normalizedAngle) % 360;
          switch (newDeg) {
            case 90:
              page.rotation = PdfPageRotateAngle.rotateAngle90;
              break;
            case 180:
              page.rotation = PdfPageRotateAngle.rotateAngle180;
              break;
            case 270:
              page.rotation = PdfPageRotateAngle.rotateAngle270;
              break;
            case 0:
            default:
              page.rotation = PdfPageRotateAngle.rotateAngle0;
              break;
          }
        }
        final savedBytes = await document.save();
        await File(outputPath).writeAsBytes(savedBytes, flush: true);
        return outputPath;
      } finally {
        document.dispose();
      }
    } catch (e) {
      throw Exception('Failed to rotate PDF: $e');
    }
  }

  /// Crops PDF pages to a given bounding box [left, bottom, right, top].
  static Future<String> cropPdf({
    required String inputPath,
    required List<double> cropBox,
  }) async {
    _checkWebSupport('PDF cropping');
    try {
      final outputPath = await _ensureOutputPath('cropped');
      final bytes = await File(inputPath).readAsBytes();
      final srcDoc = PdfDocument(inputBytes: bytes);
      final destDoc = PdfDocument();
      try {
        final left = cropBox.isNotEmpty ? cropBox[0] : 0.0;
        final bottom = cropBox.length > 1 ? cropBox[1] : 0.0;
        final right = cropBox.length > 2 ? cropBox[2] : 612.0;
        final top = cropBox.length > 3 ? cropBox[3] : 792.0;

        final cropW = (right - left).abs().clamp(50.0, 5000.0);
        final cropH = (top - bottom).abs().clamp(50.0, 5000.0);

        for (var i = 0; i < srcDoc.pages.count; i++) {
          final srcPage = srcDoc.pages[i];
          final template = srcPage.createTemplate();
          final section = destDoc.sections!.add();
          section.pageSettings.setMargins(0);
          section.pageSettings.orientation = cropW > cropH
              ? PdfPageOrientation.landscape
              : PdfPageOrientation.portrait;
          section.pageSettings.size = ui.Size(cropW, cropH);
          final newPage = section.pages.add();
          newPage.graphics.drawPdfTemplate(
            template,
            ui.Offset(-left, -bottom),
            srcPage.size,
          );
        }

        final savedBytes = await destDoc.save();
        await File(outputPath).writeAsBytes(savedBytes, flush: true);
        return outputPath;
      } finally {
        srcDoc.dispose();
        destDoc.dispose();
      }
    } catch (e) {
      throw Exception('Failed to crop PDF: $e');
    }
  }

  /// Adds a watermark to all pages with custom placement, opacity, and font size in pure Dart.
  static Future<String> addWatermarkWithPlacement({
    required String inputPath,
    required String text,
    required String placement,
    required double opacity,
    required double fontSize,
    ui.Color color = const ui.Color(0xFFE53935),
  }) async {
    _checkWebSupport('PDF watermark');
    try {
      final outputPath = await _ensureOutputPath('watermarked');
      final bytes = await File(inputPath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      try {
        final font = PdfStandardFont(
          PdfFontFamily.helvetica,
          fontSize > 0 ? fontSize : 40.0,
          style: PdfFontStyle.bold,
        );
        final brush = PdfSolidBrush(
          PdfColor(
            (color.r * 255.0).round().clamp(0, 255),
            (color.g * 255.0).round().clamp(0, 255),
            (color.b * 255.0).round().clamp(0, 255),
          ),
        );
        final clampedOpacity = opacity.clamp(0.05, 1.0);

        for (var i = 0; i < document.pages.count; i++) {
          final page = document.pages[i];
          final state = page.graphics.save();
          page.graphics.setTransparency(clampedOpacity);

          final textSize = font.measureString(text);
          final pw = page.size.width;
          final ph = page.size.height;

          if (placement == 'diagonal' || placement == 'center') {
            page.graphics.translateTransform(pw / 2, ph / 2);
            page.graphics.rotateTransform(placement == 'diagonal' ? -45.0 : 0.0);
            page.graphics.drawString(
              text,
              font,
              brush: brush,
              bounds: ui.Rect.fromLTWH(
                -textSize.width / 2,
                -textSize.height / 2,
                textSize.width,
                textSize.height,
              ),
              format: PdfStringFormat(alignment: PdfTextAlignment.center),
            );
          } else if (placement == 'top') {
            page.graphics.drawString(
              text,
              font,
              brush: brush,
              bounds: ui.Rect.fromLTWH(
                (pw - textSize.width) / 2,
                40.0,
                textSize.width,
                textSize.height,
              ),
              format: PdfStringFormat(alignment: PdfTextAlignment.center),
            );
          } else if (placement == 'bottom') {
            page.graphics.drawString(
              text,
              font,
              brush: brush,
              bounds: ui.Rect.fromLTWH(
                (pw - textSize.width) / 2,
                ph - 60.0,
                textSize.width,
                textSize.height,
              ),
              format: PdfStringFormat(alignment: PdfTextAlignment.center),
            );
          }
          page.graphics.restore(state);
        }

        final savedBytes = await document.save();
        await File(outputPath).writeAsBytes(savedBytes, flush: true);
        return outputPath;
      } finally {
        document.dispose();
      }
    } catch (e) {
      throw Exception('Failed to add watermark: $e');
    }
  }

  /// Sets or draws a background color behind/on PDF pages in pure Dart.
  static Future<String> changeBackgroundColor({
    required String inputPath,
    required String hexColor,
  }) async {
    _checkWebSupport('PDF background color');
    try {
      final outputPath = await _ensureOutputPath('colored');
      final cleanHex = hexColor.replaceAll('#', '');
      final intVal = int.tryParse(cleanHex, radix: 16) ?? 0xFFFFFF;
      final r = (intVal >> 16) & 0xFF;
      final g = (intVal >> 8) & 0xFF;
      final b = intVal & 0xFF;

      final bytes = await File(inputPath).readAsBytes();
      final srcDoc = PdfDocument(inputBytes: bytes);
      final destDoc = PdfDocument();
      try {
        for (var i = 0; i < srcDoc.pages.count; i++) {
          final srcPage = srcDoc.pages[i];
          final section = destDoc.sections!.add();
          section.pageSettings.setMargins(0);
          section.pageSettings.orientation =
              srcPage.size.width > srcPage.size.height
                  ? PdfPageOrientation.landscape
                  : PdfPageOrientation.portrait;
          section.pageSettings.size = srcPage.size;
          try {
            section.pageSettings.rotate = srcPage.rotation;
          } catch (_) {}
          final newPage = section.pages.add();
          try {
            newPage.rotation = srcPage.rotation;
          } catch (_) {}

          // Draw solid background color
          newPage.graphics.drawRectangle(
            brush: PdfSolidBrush(PdfColor(r, g, b)),
            bounds: ui.Rect.fromLTWH(0, 0, srcPage.size.width, srcPage.size.height),
          );

          // Overlay original page template
          final template = srcPage.createTemplate();
          newPage.graphics.drawPdfTemplate(
            template,
            ui.Offset.zero,
            srcPage.size,
          );
        }

        final savedBytes = await destDoc.save();
        await File(outputPath).writeAsBytes(savedBytes, flush: true);
        return outputPath;
      } finally {
        srcDoc.dispose();
        destDoc.dispose();
      }
    } catch (e) {
      throw Exception('Failed to change background color: $e');
    }
  }

  /// Compresses PDF using platform renderer on Android or pure-Dart document rebuild.
  static Future<String> compressPdf({required String inputPath}) async {
    _checkWebSupport('PDF compression');
    try {
      final outputPath = await _ensureOutputPath('compressed');
      if (PlatformHelper.isAndroid) {
        try {
          final result = await _platform.invokeMethod<String>('compressPdf', {
            'inputPath': inputPath,
            'outputPath': outputPath,
            'quality': 60,
          });
          if (result != null && result.isNotEmpty) return result;
        } catch (_) {}
      }

      // Pure Dart fallback: load and resave with optimization
      final bytes = await File(inputPath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      try {
        document.compressionLevel = PdfCompressionLevel.best;
        document.fileStructure.crossReferenceType =
            PdfCrossReferenceType.crossReferenceStream;
        document.fileStructure.incrementalUpdate = false;
        final savedBytes = await document.save();
        await File(outputPath).writeAsBytes(savedBytes, flush: true);
        return outputPath;
      } finally {
        document.dispose();
      }
    } catch (e) {
      throw Exception('Failed to compress PDF: $e');
    }
  }

  /// Retrieves page count using pure Dart Syncfusion PDF.
  static Future<int> getPageCount({required String inputPath}) async {
    if (kIsWeb) return 1;
    try {
      final bytes = await File(inputPath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (e) {
      return 0;
    }
  }
}
