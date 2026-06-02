import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openpdf_tools/main.dart';
import 'package:openpdf_tools/services/theme_service.dart' as theme_service;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('OpenPDF Tools app launches', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final themeService = theme_service.ThemeService();
    await themeService.initialize();
    await tester.pumpWidget(
      ChangeNotifierProvider<theme_service.ThemeService>.value(
        value: themeService,
        child: const OpenPDFToolsApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
