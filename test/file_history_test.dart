import 'package:flutter_test/flutter_test.dart';
import 'package:openpdf_tools/services/file_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileHistoryService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('HistoryItem extracts filename correctly on both Unix and Windows paths', () {
      final unixItem = HistoryItem(
        filePath: '/home/user/documents/report.pdf',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      expect(unixItem.fileName, equals('report.pdf'));

      final windowsItem = HistoryItem(
        filePath: r'C:\Users\User\Documents\report.pdf',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      expect(windowsItem.fileName, equals('report.pdf'));
    });

    test('addToHistory saves and retrieves history in LIFO order', () async {
      await FileHistoryService.addToHistory('/path/to/doc1.pdf');
      await FileHistoryService.addToHistory('/path/to/doc2.pdf');

      final history = await FileHistoryService.getHistory();
      expect(history.length, equals(2));
      expect(history[0].filePath, equals('/path/to/doc2.pdf'));
      expect(history[1].filePath, equals('/path/to/doc1.pdf'));
    });

    test('addToHistory deduplicates existing entries and moves to front', () async {
      await FileHistoryService.addToHistory('/path/to/doc1.pdf');
      await FileHistoryService.addToHistory('/path/to/doc2.pdf');
      await FileHistoryService.addToHistory('/path/to/doc1.pdf');

      final history = await FileHistoryService.getHistory();
      expect(history.length, equals(2));
      expect(history[0].filePath, equals('/path/to/doc1.pdf'));
      expect(history[1].filePath, equals('/path/to/doc2.pdf'));
    });

    test('toggleFavorite adds and removes favorites', () async {
      const path = '/path/to/favorite.pdf';

      expect(await FileHistoryService.isFavorite(path), isFalse);

      final added = await FileHistoryService.toggleFavorite(path);
      expect(added, isTrue);
      expect(await FileHistoryService.isFavorite(path), isTrue);

      final removed = await FileHistoryService.toggleFavorite(path);
      expect(removed, isFalse);
      expect(await FileHistoryService.isFavorite(path), isFalse);
    });

    test('clearHistory removes all entries', () async {
      await FileHistoryService.addToHistory('/path/to/doc1.pdf');
      await FileHistoryService.clearHistory();

      final history = await FileHistoryService.getHistory();
      expect(history, isEmpty);
    });
  });
}
