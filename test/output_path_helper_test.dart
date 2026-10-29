import 'package:flutter_test/flutter_test.dart';
import 'package:openpdf_tools/utils/output_path_helper.dart';

void main() {
  group('OutputPathHelper Tests', () {
    test('sanitizeFileName removes illegal filesystem characters', () {
      expect(OutputPathHelper.sanitizeFileName('clean_file.pdf'), equals('clean_file.pdf'));
      expect(OutputPathHelper.sanitizeFileName('file:with*bad?chars|.pdf'), equals('file_with_bad_chars_.pdf'));
      expect(OutputPathHelper.sanitizeFileName('../../../path/traversal.pdf'), isNot(contains('/')));
      expect(OutputPathHelper.sanitizeFileName(''), startsWith('openpdf_'));
    });

    test('outputFileName creates valid output file names with suffix and extension', () {
      final name = OutputPathHelper.outputFileName(
        sourcePath: '/docs/my_contract.pdf',
        suffix: 'signed',
        extension: 'pdf',
      );
      expect(name, startsWith('my_contract_signed'));
      expect(name, endsWith('.pdf'));
    });

    test('mimeTypeForFileName returns correct MIME types', () {
      expect(OutputPathHelper.mimeTypeForFileName('document.pdf'), equals('application/pdf'));
      expect(OutputPathHelper.mimeTypeForFileName('photo.png'), equals('image/png'));
      expect(OutputPathHelper.mimeTypeForFileName('photo.jpg'), equals('image/jpeg'));
      expect(OutputPathHelper.mimeTypeForFileName('archive.zip'), equals('application/zip'));
      expect(OutputPathHelper.mimeTypeForFileName('document.docx'), equals('application/vnd.openxmlformats-officedocument.wordprocessingml.document'));
    });
  });
}
