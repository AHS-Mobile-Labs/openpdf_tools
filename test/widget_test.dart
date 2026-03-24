import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openpdf_tools/main.dart';
void main() {
  testWidgets('OpenPDF Tools app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenPDFToolsApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}