import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:openpdf_tools/services/pdf_manipulation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return Directory.systemTemp.path;
  });

  test('PdfManipulationService preserves landscape page size when merging', () async {
    // Create a landscape document (A4 landscape: 842 x 595)
    final doc1 = PdfDocument();
    final section1 = doc1.sections!.add();
    section1.pageSettings.orientation = PdfPageOrientation.landscape;
    section1.pageSettings.size = const Size(842, 595);
    section1.pageSettings.setMargins(0);
    final page1 = section1.pages.add();
    expect(page1.size.width, 842);
    expect(page1.size.height, 595);

    // Save to temp file
    final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
    final file1 = File('${tempDir.path}/landscape1.pdf');
    file1.writeAsBytesSync(await doc1.save());
    doc1.dispose();

    // Create another document
    final doc2 = PdfDocument();
    final section2 = doc2.sections!.add();
    section2.pageSettings.orientation = PdfPageOrientation.portrait;
    section2.pageSettings.size = const Size(595, 842);
    section2.pageSettings.setMargins(0);
    final page2 = section2.pages.add();
    expect(page2.size.width, 595);
    final file2 = File('${tempDir.path}/portrait1.pdf');
    file2.writeAsBytesSync(await doc2.save());
    doc2.dispose();

    // Merge them
    final mergedPath = await PdfManipulationService.mergePdfs([file1.path, file2.path]);
    final mergedDoc = PdfDocument(inputBytes: File(mergedPath).readAsBytesSync());

    expect(mergedDoc.pages.count, 2);
    expect(mergedDoc.pages[0].size.width, 842);
    expect(mergedDoc.pages[0].size.height, 595);
    expect(mergedDoc.pages[1].size.width, 595);
    expect(mergedDoc.pages[1].size.height, 842);

    mergedDoc.dispose();

    // Test splitting landscape PDF
    final splitPaths = await PdfManipulationService.splitPdf(file1.path);
    expect(splitPaths.length, 1);
    final splitDoc = PdfDocument(inputBytes: File(splitPaths.first).readAsBytesSync());
    expect(splitDoc.pages[0].size.width, 842);
    expect(splitDoc.pages[0].size.height, 595);
    splitDoc.dispose();

    // Test splitting page range
    final splitRangePath = await PdfManipulationService.splitPdfRange(
      file1.path,
      startPage: 1,
      endPage: 1,
    );
    final splitRangeDoc = PdfDocument(inputBytes: File(splitRangePath).readAsBytesSync());
    expect(splitRangeDoc.pages[0].size.width, 842);
    expect(splitRangeDoc.pages[0].size.height, 595);
    splitRangeDoc.dispose();

    tempDir.deleteSync(recursive: true);
  });
}
