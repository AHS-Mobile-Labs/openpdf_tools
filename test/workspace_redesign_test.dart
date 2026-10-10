import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openpdf_tools/widgets/workspace_components.dart';
import 'package:openpdf_tools/screens/all_tools_screen.dart';
import 'package:openpdf_tools/config/premium_theme.dart';

void main() {
  group('Workspace Modern Redesign Tests', () {
    test('ToolItem registry contains all core and workflow tools', () {
      final tools = ToolItem.allTools;
      expect(tools.length, greaterThanOrEqualTo(10));

      final toolIds = tools.map((t) => t.id).toSet();
      expect(toolIds.contains('viewer'), isTrue);
      expect(toolIds.contains('edit'), isTrue);
      expect(toolIds.contains('merge'), isTrue);
      expect(toolIds.contains('split'), isTrue);
      expect(toolIds.contains('compress'), isTrue);
      expect(toolIds.contains('sign'), isTrue);
      expect(toolIds.contains('repair'), isTrue);
      expect(toolIds.contains('convert_to'), isTrue);
      expect(toolIds.contains('convert_from'), isTrue);
      expect(toolIds.contains('images_to_pdf'), isTrue);
      expect(toolIds.contains('history'), isTrue);
    });

    test('Spotlight tools contain the top 6 user workflows', () {
      final spotlight = ToolItem.spotlightTools;
      expect(spotlight.length, equals(6));
      final ids = spotlight.map((t) => t.id).toList();
      expect(ids.contains('viewer'), isTrue);
      expect(ids.contains('edit'), isTrue);
      expect(ids.contains('merge'), isTrue);
      expect(ids.contains('compress'), isTrue);
      expect(ids.contains('sign'), isTrue);
      expect(ids.contains('convert_from'), isTrue);
    });

    test('Brand Red color is set accurately', () {
      expect(PremiumColors.brandRed, const Color(0xFFE1251B));
      expect(PremiumColors.luxuryRed, const Color(0xFFE1251B));
    });

    testWidgets('AppBrandLogo renders with brand text in light and dark mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBrandLogo(size: 32, showText: true),
          ),
        ),
      );

      expect(find.text('OpenPDF'), findsOneWidget);
      expect(find.text(' Tools'), findsOneWidget);
    });

    testWidgets('ToolCard renders title, description, and handles tap', (
      tester,
    ) async {
      bool tapped = false;
      final tool = ToolItem.allTools.firstWhere((t) => t.id == 'merge');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 180,
              child: ToolCard(
                tool: tool,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text(tool.title), findsOneWidget);
      expect(find.text('Launch'), findsOneWidget);

      await tester.tap(find.byType(ToolCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('HeroDropZone renders and fires onFileSelected', (
      tester,
    ) async {
      bool selected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroDropZone(
              onFileSelected: () => selected = true,
            ),
          ),
        ),
      );

      expect(find.text('Open a PDF Document'), findsOneWidget);
      expect(find.text('Select PDF'), findsOneWidget);
      expect(find.text('100% Offline & Private'), findsOneWidget);

      await tester.tap(find.text('Select PDF'));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
    });

    testWidgets('AllToolsScreen renders category filter chips and filters tools', (
      tester,
    ) async {
      ToolItem? selectedTool;

      await tester.pumpWidget(
        MaterialApp(
          home: AllToolsScreen(
            onSelectTool: (t) => selectedTool = t,
          ),
        ),
      );

      expect(find.text('All Tools'), findsWidgets);
      expect(find.text('View & Annotate'), findsWidgets);
      expect(find.text('Combine & Organize'), findsWidgets);

      // Tap "Combine & Organize" chip
      await tester.tap(find.text('Combine & Organize'));
      await tester.pumpAndSettle();

      expect(find.text('Merge PDFs'), findsOneWidget);
      expect(find.text('Split PDF'), findsOneWidget);

      await tester.tap(find.text('Merge PDFs'));
      await tester.pumpAndSettle();
      expect(selectedTool?.id, 'merge');
    });
  });
}
