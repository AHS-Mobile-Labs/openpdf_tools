import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfManipulationService {
  /// Merge multiple PDF files into a single PDF
  ///
  /// Takes a list of PDF file paths and combines them in order
  /// Returns the path to the output merged PDF file
  static Future<String> mergePdfs(List<String> pdfPaths) async {
    if (pdfPaths.isEmpty) {
      throw Exception('No PDF files provided for merging');
    }

    if (pdfPaths.length == 1) {
      throw Exception('Please select at least 2 PDF files to merge');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Verify all files exist
      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        if (!await file.exists()) {
          throw Exception('File not found: $pdfPath');
        }
      }

      // Try using qpdf if available (preferred for PDF manipulation)
      final qpdfResult = await _tryMergeWithQpdf(pdfPaths, outputPath);
      if (qpdfResult != null) {
        return qpdfResult;
      }

      // Fallback: try pdftk
      final pdfttkResult = await _tryMergeWithPdftk(pdfPaths, outputPath);
      if (pdfttkResult != null) {
        return pdfttkResult;
      }

      // If no command-line tools available, use pdfbox or gs
      final gsResult = await _tryMergeWithGhostscript(pdfPaths, outputPath);
      if (gsResult != null) {
        return gsResult;
      }

      throw Exception(
        'No PDF manipulation tools found. '
        'Please install qpdf, pdftk, or ghostscript.',
      );
    } catch (e) {
      throw Exception('Failed to merge PDFs: $e');
    }
  }

  /// Try merging PDFs using qpdf (preferred method)
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
    } catch (e) {
      // qpdf not found or error, try next method
    }
    return null;
  }

  /// Try merging PDFs using pdftk
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
    } catch (e) {
      // pdftk not found or error, try next method
    }
    return null;
  }

  /// Fallback: merge using Ghostscript
  static Future<String?> _tryMergeWithGhostscript(
    List<String> pdfPaths,
    String outputPath,
  ) async {
    try {
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
    } catch (e) {
      // gs not found or error
    }
    return null;
  }

  /// Split a PDF file into individual pages or a range of pages
  ///
  /// [pdfPath] - Path to the PDF file to split
  /// [pages] - List of page numbers to extract (1-indexed)
  /// If pages is empty, all pages are extracted separately
  ///
  /// Returns a list of paths to the split PDF files
  static Future<List<String>> splitPdf(
    String pdfPath, {
    List<int>? pages,
  }) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('File not found: $pdfPath');
      }

      final tempDir = await getTemporaryDirectory();

      if (pages != null && pages.isNotEmpty) {
        // Extract specific pages as individual PDFs
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
        // Extract all pages individually by getting page count first
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
    } catch (e) {
      throw Exception('Failed to split PDF: $e');
    }
  }

  /// Split a PDF file and save range/pages as a single PDF
  ///
  /// [pdfPath] - Path to the PDF file to split
  /// [startPage] - Starting page number (1-indexed)
  /// [endPage] - Ending page number (1-indexed, inclusive)
  ///
  /// Returns the path to the output PDF containing the specified pages
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
      final outputPath =
          '${tempDir.path}/extracted_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Create a list of pages to extract
      final pages = List.generate(
        endPage - startPage + 1,
        (i) => startPage + i,
      );

      final success = await _extractPagesTool(pdfPath, outputPath, pages);
      if (!success) {
        throw Exception('Failed to extract page range');
      }

      return outputPath;
    } catch (e) {
      throw Exception('Failed to split PDF range: $e');
    }
  }

  /// Extract specific pages from a PDF using available tools
  static Future<bool> _extractPagesTool(
    String inputPath,
    String outputPath,
    List<int> pages,
  ) async {
    try {
      // Try qpdf first (preferred)
      if (await _tryQpdfExtract(inputPath, outputPath, pages)) {
        return true;
      }

      // Try pdftk
      if (await _tryPdfttkExtract(inputPath, outputPath, pages)) {
        return true;
      }

      // Fallback to Ghostscript
      if (await _tryGhostscriptExtract(inputPath, outputPath, pages)) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Extract pages using qpdf
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

  /// Extract pages using pdftk
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

  /// Extract pages using Ghostscript (less efficient but widely available)
  static Future<bool> _tryGhostscriptExtract(
    String inputPath,
    String outputPath,
    List<int> pages,
  ) async {
    try {
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

  /// Get the page count of a PDF
  static Future<int> _getPageCount(String pdfPath) async {
    try {
      // Try using pdfinfo (from poppler-utils)
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

      // Fallback: try using qpdf to get page count
      final qpdfResult = await Process.run('qpdf', ['--show-npages', pdfPath]);
      if (qpdfResult.exitCode == 0) {
        final count = int.tryParse(qpdfResult.stdout.toString().trim());
        return count ?? 0;
      }

      // Fallback: try identify from ImageMagick
      final identifyResult = await Process.run('identify', [pdfPath]);
      if (identifyResult.exitCode == 0) {
        final output = identifyResult.stdout.toString();
        final matches = RegExp(r'(\d+)\]').allMatches(output);
        if (matches.isNotEmpty) {
          final lastMatch = matches.last.group(1);
          return int.tryParse(lastMatch ?? '1') ?? 1;
        }
      }

      return 1; // Default to 1 page if we can't determine
    } catch (e) {
      return 1;
    }
  }
}
