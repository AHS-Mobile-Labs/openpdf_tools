import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PdfManipulationService {
  static const platform = MethodChannel('com.openpdf.tools/pdfManipulation');
  static Future<String> mergePdfs(List<String> pdfPaths) async {
    if (pdfPaths.isEmpty) {
      throw Exception('No PDF files provided for merging');
    }
    if (pdfPaths.length == 1) {
      throw Exception('Please select at least 2 PDF files to merge');
    }
    try {
      if (kIsWeb) {
        throw Exception(
          'PDF merging is not available on web. Please use the desktop or mobile app.',
        );
      }
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
      debugPrint(
        '[PdfManipulation] Merging ${pdfPaths.length} PDFs to: $outputPath',
      );
      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        if (!await file.exists()) {
          throw Exception('File not found: $pdfPath');
        }
      }
      if (Platform.isAndroid) {
        try {
          final result = await platform.invokeMethod<String>('mergePdfs', {
            'inputPaths': pdfPaths,
            'outputPath': outputPath,
          });
          if (result != null && result.isNotEmpty) {
            return result;
          }
        } catch (e) {
          debugPrint('[PdfManipulation] Native merge failed: $e');
          throw Exception('Failed to merge PDFs: $e');
        }
      } else {
        final qpdfResult = await _tryMergeWithQpdf(pdfPaths, outputPath);
        if (qpdfResult != null) {
          return qpdfResult;
        }
        final pdfttkResult = await _tryMergeWithPdftk(pdfPaths, outputPath);
        if (pdfttkResult != null) {
          return pdfttkResult;
        }
        final gsResult = await _tryMergeWithGhostscript(pdfPaths, outputPath);
        if (gsResult != null) {
          return gsResult;
        }
        throw Exception(
          'No PDF manipulation tools found. '
          'Please install qpdf, pdftk, or ghostscript.',
        );
      }
      throw Exception('Failed to merge PDFs: Unknown error');
    } catch (e) {
      throw Exception('Failed to merge PDFs: $e');
    }
  }

  static Future<String?> _tryMergeWithQpdf(
    List<String> pdfPaths,
    String outputPath,
  ) async {
    try {
      final args = ['--empty'];
      for (final pdfPath in pdfPaths) {
        args.addAll(['--pages', pdfPath, '1-z']);
      }
      args.addAll(['--', outputPath]);
      final result = await Process.run('qpdf', args);
      if (result.exitCode == 0) {
        return outputPath;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _tryMergeWithPdftk(
    List<String> pdfPaths,
    String outputPath,
  ) async {
    try {
      final args = [...pdfPaths, 'cat', 'output', outputPath];
      final result = await Process.run('pdftk', args);
      if (result.exitCode == 0) {
        return outputPath;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _tryMergeWithGhostscript(
    List<String> pdfPaths,
    String outputPath,
  ) async {
    try {
      final outDir = File(outputPath).parent;
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }
      final args = [
        '-sDEVICE=pdfwrite',
        '-dNOPAUSE',
        '-dBATCH',
        '-dSAFER',
        '-dCompatibilityLevel=1.4',
        '-dPDFSETTINGS=/ebook',
        '-dEmbedAllFonts=true',
        '-dSubsetFonts=true',
        '-dAutoRotatePages=/None',
        '-dMonoImageResolution=300',
        '-dMonoImageDownsampleType=/Subsample',
        '-dGrayImageResolution=300',
        '-dGrayImageDownsampleType=/Subsample',
        '-dColorImageResolution=300',
        '-dColorImageDownsampleType=/Subsample',
        '-sOutputFile=$outputPath',
        ...pdfPaths,
      ];
      final result = await Process.run('gs', args);
      if (result.exitCode == 0) {
        return outputPath;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<String>> splitPdf(
    String pdfPath, {
    List<int>? pages,
  }) async {
    try {
      if (kIsWeb) {
        throw Exception(
          'PDF splitting is not available on web. Please use the desktop or mobile app.',
        );
      }
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('File not found: $pdfPath');
      }
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      if (Platform.isAndroid) {
        try {
          final result = await platform.invokeMethod<List<dynamic>>(
            'splitPdf',
            {'inputPath': pdfPath, 'outputDir': tempDir.path},
          );
          if (result != null && result.isNotEmpty) {
            return result.cast<String>();
          }
        } catch (e) {
          debugPrint('[PdfManipulation] Native split failed: $e');
          throw Exception('Failed to split PDF: $e');
        }
      } else {
        if (pages != null && pages.isNotEmpty) {
          final outputPaths = <String>[];
          for (final pageNum in pages) {
            final outputPath =
                '${tempDir.path}/page_${pageNum}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final success = await _extractPagesTool(pdfPath, outputPath, [
              pageNum,
            ]);
            if (success) {
              outputPaths.add(outputPath);
            }
          }
          if (outputPaths.isEmpty) {
            throw Exception('Failed to extract pages');
          }
          return outputPaths;
        } else {
          final pageCount = await _getPageCount(pdfPath);
          if (pageCount <= 0) {
            throw Exception('Could not determine PDF page count');
          }
          final outputPaths = <String>[];
          for (int i = 1; i <= pageCount; i++) {
            final outputPath =
                '${tempDir.path}/page_${i}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final success = await _extractPagesTool(pdfPath, outputPath, [i]);
            if (success) {
              outputPaths.add(outputPath);
            }
          }
          if (outputPaths.isEmpty) {
            throw Exception('Failed to extract pages');
          }
          return outputPaths;
        }
      }
      throw Exception('Failed to split PDF: Unknown error');
    } catch (e) {
      throw Exception('Failed to split PDF: $e');
    }
  }

  static Future<String> splitPdfRange(
    String pdfPath, {
    required int startPage,
    required int endPage,
  }) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('File not found: $pdfPath');
      }
      if (startPage < 1 || endPage < 1 || startPage > endPage) {
        throw Exception('Invalid page range: $startPage to $endPage');
      }
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/extracted_${DateTime.now().millisecondsSinceEpoch}.pdf';
      if (Platform.isAndroid) {
        try {
          final result = await platform.invokeMethod<String>('splitPdfRange', {
            'inputPath': pdfPath,
            'startPage': startPage,
            'endPage': endPage,
            'outputPath': outputPath,
          });
          if (result != null && result.isNotEmpty) {
            return result;
          }
        } catch (e) {
          debugPrint('[PdfManipulation] Native split range failed: $e');
          throw Exception('Failed to split PDF range: $e');
        }
      } else {
        final pages = List.generate(
          endPage - startPage + 1,
          (i) => startPage + i,
        );
        final success = await _extractPagesTool(pdfPath, outputPath, pages);
        if (!success) {
          throw Exception('Failed to extract page range');
        }
        return outputPath;
      }
      throw Exception('Failed to split PDF range: Unknown error');
    } catch (e) {
      throw Exception('Failed to split PDF range: $e');
    }
  }

  static Future<bool> _extractPagesTool(
    String inputPath,
    String outputPath,
    List<int> pages,
  ) async {
    try {
      if (await _tryQpdfExtract(inputPath, outputPath, pages)) {
        return true;
      }
      if (await _tryPdfttkExtract(inputPath, outputPath, pages)) {
        return true;
      }
      if (await _tryGhostscriptExtract(inputPath, outputPath, pages)) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _tryQpdfExtract(
    String inputPath,
    String outputPath,
    List<int> pages,
  ) async {
    try {
      final pageSpec = pages.join(',');
      final args = ['--pages', inputPath, pageSpec, '--', outputPath];
      final result = await Process.run('qpdf', args);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _tryPdfttkExtract(
    String inputPath,
    String outputPath,
    List<int> pages,
  ) async {
    try {
      final pageSpec = pages.join(' ');
      final args = [inputPath, 'cat', pageSpec, 'output', outputPath];
      final result = await Process.run('pdftk', args);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _tryGhostscriptExtract(
    String inputPath,
    String outputPath,
    List<int> pages,
  ) async {
    try {
      final outDir = File(outputPath).parent;
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }
      final args = [
        '-sDEVICE=pdfwrite',
        '-dNOPAUSE',
        '-dBATCH',
        '-dSAFER',
        '-dFirstPage=${pages.first}',
        '-dLastPage=${pages.last}',
        '-sOutputFile=$outputPath',
        inputPath,
      ];
      final result = await Process.run('gs', args);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<int> _getPageCount(String pdfPath) async {
    try {
      if (Platform.isAndroid) {
        try {
          final result = await platform.invokeMethod<int>('getPageCount', {
            'inputPath': pdfPath,
          });
          if (result != null && result > 0) {
            return result;
          }
        } catch (e) {
          debugPrint('[PdfManipulation] Native page count failed: $e');
        }
      } else {
        final result = await Process.run('pdfinfo', [pdfPath]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.contains('Pages:')) {
              final pages = line.replaceAll(RegExp(r'[^\d]'), '');
              return int.tryParse(pages) ?? 0;
            }
          }
        }
        final qpdfResult = await Process.run('qpdf', [
          '--show-npages',
          pdfPath,
        ]);
        if (qpdfResult.exitCode == 0) {
          final count = int.tryParse(qpdfResult.stdout.toString().trim());
          return count ?? 0;
        }
        final identifyResult = await Process.run('identify', [pdfPath]);
        if (identifyResult.exitCode == 0) {
          final output = identifyResult.stdout.toString();
          final matches = RegExp(r'(\d+)\]').allMatches(output);
          if (matches.isNotEmpty) {
            final lastMatch = matches.last.group(1);
            return int.tryParse(lastMatch ?? '1') ?? 1;
          }
        }
      }
      return 1;
    } catch (e) {
      return 1;
    }
  }
}
