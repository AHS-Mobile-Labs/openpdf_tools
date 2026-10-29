import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openpdf_tools/services/format_conversion_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('FormatConversionService - To PDF Tests', () {
    test('textToPdf generates a valid non-empty PDF document', () async {
      const sampleText = 'Hello OpenPDF Tools!\nThis is a sample document for testing pure-Dart conversion.';
      final pdfBytes = await FormatConversionService.textToPdf(sampleText, title: 'Test Document');

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));

      // Verify it is a valid PDF readable by Syncfusion
      final doc = PdfDocument(inputBytes: pdfBytes);
      expect(doc.pages.count, greaterThanOrEqualTo(1));
      doc.dispose();
    });

    test('markdownToPdf creates a valid PDF with headings and content', () async {
      const markdown = '''# Sample Title
## Subheading
This is a paragraph with **bold** text and *italic* text.

- Item 1
- Item 2
- Item 3
''';
      final pdfBytes = await FormatConversionService.markdownToPdf(markdown, title: 'Markdown Test');

      expect(pdfBytes, isNotNull);
      final doc = PdfDocument(inputBytes: pdfBytes);
      expect(doc.pages.count, greaterThanOrEqualTo(1));
      doc.dispose();
    });

    test('csvToPdf generates a valid PDF with tabular layout', () async {
      const csv = '''Name,Role,Status
Alice,Developer,Active
Bob,Designer,Active
Charlie,Manager,Pending
''';
      final pdfBytes = await FormatConversionService.csvToPdf(csv, title: 'Team Roster');

      expect(pdfBytes, isNotNull);
      final doc = PdfDocument(inputBytes: pdfBytes);
      expect(doc.pages.count, greaterThanOrEqualTo(1));
      doc.dispose();
    });

    test('htmlToPdf generates a valid PDF from basic HTML elements', () async {
      const html = '''
<!DOCTYPE html>
<html>
<head><title>Test HTML</title></head>
<body>
  <h1>Heading 1</h1>
  <p>This is a test paragraph converted to PDF.</p>
</body>
</html>
''';
      final pdfBytes = await FormatConversionService.htmlToPdf(html, title: 'HTML Test');

      expect(pdfBytes, isNotNull);
      final doc = PdfDocument(inputBytes: pdfBytes);
      expect(doc.pages.count, greaterThanOrEqualTo(1));
      doc.dispose();
    });
  });

  group('FormatConversionService - From PDF Tests', () {
    late Uint8List testPdfBytes;

    setUpAll(() async {
      // Create a valid PDF with text
      testPdfBytes = await FormatConversionService.textToPdf(
        'Invoice #1001\nCustomer: Acme Corp\nTotal: \$500.00',
        title: 'Invoice',
      );
    });

    test('pdfToDocx creates a valid DOCX ZIP archive', () {
      final docxBytes = FormatConversionService.pdfToDocx(testPdfBytes);
      expect(docxBytes, isNotNull);
      expect(docxBytes.length, greaterThan(0));

      // Verify it is a valid ZIP archive containing Word document structure
      final archive = ZipDecoder().decodeBytes(docxBytes);
      expect(archive.findFile('word/document.xml'), isNotNull);
      expect(archive.findFile('[Content_Types].xml'), isNotNull);
      expect(archive.findFile('_rels/.rels'), isNotNull);
    });

    test('pdfToOdt creates a valid ODT ZIP archive', () {
      final odtBytes = FormatConversionService.pdfToOdt(testPdfBytes);
      expect(odtBytes, isNotNull);

      final archive = ZipDecoder().decodeBytes(odtBytes);
      expect(archive.findFile('mimetype'), isNotNull);
      expect(archive.findFile('content.xml'), isNotNull);
      expect(archive.findFile('META-INF/manifest.xml'), isNotNull);

      final mimetypeFile = archive.findFile('mimetype')!;
      final mimetype = String.fromCharCodes(mimetypeFile.content as List<int>);
      expect(mimetype, contains('application/vnd.oasis.opendocument.text'));
    });

    test('pdfToOdp creates a valid ODP presentation archive with presentation mimetype', () {
      final odpBytes = FormatConversionService.pdfToOdp(testPdfBytes);
      expect(odpBytes, isNotNull);

      final archive = ZipDecoder().decodeBytes(odpBytes);
      expect(archive.findFile('mimetype'), isNotNull);
      expect(archive.findFile('content.xml'), isNotNull);
      expect(archive.findFile('META-INF/manifest.xml'), isNotNull);

      final mimetypeFile = archive.findFile('mimetype')!;
      final mimetype = String.fromCharCodes(mimetypeFile.content as List<int>);
      expect(mimetype, contains('application/vnd.oasis.opendocument.presentation'));
    });

    test('pdfToOds creates a valid ODS spreadsheet archive', () {
      final odsBytes = FormatConversionService.pdfToOds(testPdfBytes);
      expect(odsBytes, isNotNull);

      final archive = ZipDecoder().decodeBytes(odsBytes);
      expect(archive.findFile('mimetype'), isNotNull);
      expect(archive.findFile('content.xml'), isNotNull);

      final mimetypeFile = archive.findFile('mimetype')!;
      final mimetype = String.fromCharCodes(mimetypeFile.content as List<int>);
      expect(mimetype, contains('application/vnd.oasis.opendocument.spreadsheet'));
    });
  });
}
