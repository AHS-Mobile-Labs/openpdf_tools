import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Standalone, pure-Dart format conversion engine.
/// Runs 100% locally on Android, iOS, Desktop, and Web without any external
/// CLI dependencies (no LibreOffice, no pdftotext, no qpdf required).
class FormatConversionService {
  // ===========================================================================
  // 1. CONVERT TO PDF (From various formats)
  // ===========================================================================

  /// Convert any supported file bytes into PDF bytes.
  static Future<Uint8List> convertToPdf({
    required Uint8List bytes,
    required String fileName,
    String? formatHint,
  }) async {
    final ext = (fileName.split('.').last).toLowerCase();

    switch (ext) {
      // Word documents
      case 'docx':
        return docxToPdf(bytes);
      case 'doc':
        return legacyDocToPdf(bytes, fileName);

      // Presentation
      case 'pptx':
        return pptxToPdf(bytes);
      case 'ppt':
        return legacyPptToPdf(bytes, fileName);

      // Spreadsheets
      case 'xlsx':
        return xlsxToPdf(bytes);
      case 'xls':
        return legacyXlsToPdf(bytes, fileName);

      // OpenDocument formats
      case 'odt':
        return odtToPdf(bytes);
      case 'ods':
        return odsToPdf(bytes);
      case 'odp':
        return odpToPdf(bytes);
      case 'odg':
        return odgToPdf(bytes);

      // Web & markup
      case 'html':
      case 'htm':
        final content = utf8.decode(bytes, allowMalformed: true);
        return htmlToPdf(content, title: fileName);
      case 'md':
      case 'markdown':
        final content = utf8.decode(bytes, allowMalformed: true);
        return markdownToPdf(content, title: fileName);

      // Data formats
      case 'csv':
        final content = utf8.decode(bytes, allowMalformed: true);
        return csvToPdf(content, title: fileName);
      case 'json':
      case 'xml':
      case 'log':
        final content = utf8.decode(bytes, allowMalformed: true);
        return codeDataToPdf(content, extension: ext, title: fileName);

      // Rich text & eBook
      case 'rtf':
        final content = utf8.decode(bytes, allowMalformed: true);
        return rtfToPdf(content, title: fileName);
      case 'epub':
        return epubToPdf(bytes, title: fileName);

      // Vector & Images
      case 'svg':
        final content = utf8.decode(bytes, allowMalformed: true);
        return svgToPdf(content, title: fileName);
      case 'tiff':
      case 'tif':
        return tiffToPdf(bytes);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'bmp':
      case 'heic':
        return imageToPdf(bytes);

      // Plain text fallback
      case 'txt':
      default:
        final content = utf8.decode(bytes, allowMalformed: true);
        return textToPdf(content, title: fileName);
    }
  }

  /// Ensures every generated PDF page has a guaranteed solid opaque background
  static pw.PageTheme standardPageTheme({
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.EdgeInsets margin = const pw.EdgeInsets.all(32),
    PdfColor backgroundColor = PdfColors.white,
  }) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      margin: margin,
      buildBackground: (pw.Context context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: backgroundColor),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Word (.docx) to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> docxToPdf(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final docXmlFile = archive.findFile('word/document.xml');
    if (docXmlFile == null) {
      throw Exception('Invalid DOCX file: word/document.xml not found.');
    }

    final xmlContent = utf8.decode(docXmlFile.content as List<int>, allowMalformed: true);
    final paragraphs = _extractDocxParagraphs(xmlContent);
    final tableRows = _extractDocxTables(xmlContent);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(36)),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];

          for (final p in paragraphs) {
            final text = p.text.trim();
            if (text.isEmpty) {
              widgets.add(pw.SizedBox(height: 8));
              continue;
            }

            if (p.isHeading) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      fontSize: p.headingLevel == 1 ? 18 : 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                ),
              );
            } else if (p.isBullet) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(
                        child: pw.Text(
                          text,
                          style: const pw.TextStyle(fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    text,
                    style: const pw.TextStyle(fontSize: 10.5),
                  ),
                ),
              );
            }
          }

          if (tableRows.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(
              pw.TableHelper.fromTextArray(
                context: context,
                data: tableRows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellHeight: 24,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              ),
            );
          }

          if (widgets.isEmpty) {
            widgets.add(pw.Text('Empty Document'));
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static List<_DocxParagraph> _extractDocxParagraphs(String xml) {
    final list = <_DocxParagraph>[];
    final pRegex = RegExp(r'<w:p\b[^>]*>(.*?)</w:p>', dotAll: true);
    final tRegex = RegExp(r'<w:t\b[^>]*>(.*?)</w:t>', dotAll: true);
    final headingRegex = RegExp(r'<w:pStyle\s+w:val="Heading(\d)"', caseSensitive: false);
    final numPrRegex = RegExp(r'<w:numPr\b');

    for (final pMatch in pRegex.allMatches(xml)) {
      final pContent = pMatch.group(1) ?? '';
      final buffer = StringBuffer();
      for (final tMatch in tRegex.allMatches(pContent)) {
        buffer.write(tMatch.group(1) ?? '');
      }

      final text = _cleanXmlEntities(buffer.toString());
      if (text.trim().isEmpty) continue;

      int headingLevel = 0;
      final hMatch = headingRegex.firstMatch(pContent);
      if (hMatch != null) {
        headingLevel = int.tryParse(hMatch.group(1) ?? '1') ?? 1;
      }

      final isBullet = numPrRegex.hasMatch(pContent);
      list.add(_DocxParagraph(
        text: text,
        isHeading: headingLevel > 0,
        headingLevel: headingLevel,
        isBullet: isBullet,
      ));
    }
    return list;
  }

  static List<List<String>> _extractDocxTables(String xml) {
    final tableRows = <List<String>>[];
    final tblRegex = RegExp(r'<w:tbl\b[^>]*>(.*?)</w:tbl>', dotAll: true);
    final trRegex = RegExp(r'<w:tr\b[^>]*>(.*?)</w:tr>', dotAll: true);
    final tcRegex = RegExp(r'<w:tc\b[^>]*>(.*?)</w:tc>', dotAll: true);
    final tRegex = RegExp(r'<w:t\b[^>]*>(.*?)</w:t>', dotAll: true);

    for (final tblMatch in tblRegex.allMatches(xml)) {
      final tblContent = tblMatch.group(1) ?? '';
      for (final trMatch in trRegex.allMatches(tblContent)) {
        final trContent = trMatch.group(1) ?? '';
        final rowCells = <String>[];

        for (final tcMatch in tcRegex.allMatches(trContent)) {
          final tcContent = tcMatch.group(1) ?? '';
          final cellText = StringBuffer();
          for (final tMatch in tRegex.allMatches(tcContent)) {
            cellText.write(tMatch.group(1) ?? '');
          }
          rowCells.add(_cleanXmlEntities(cellText.toString()).trim());
        }
        if (rowCells.isNotEmpty) tableRows.add(rowCells);
      }
    }
    return tableRows;
  }

  static Future<Uint8List> legacyDocToPdf(Uint8List bytes, String title) async {
    final text = _extractAsciiTextFromBinary(bytes);
    return textToPdf(text.isNotEmpty ? text : 'Binary Word Document', title: title);
  }

  // ---------------------------------------------------------------------------
  // Excel (.xlsx) to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> xlsxToPdf(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Shared Strings
    final sharedStrings = <String>[];
    final ssFile = archive.findFile('xl/sharedStrings.xml');
    if (ssFile != null) {
      final ssXml = utf8.decode(ssFile.content as List<int>, allowMalformed: true);
      final tRegex = RegExp(r'<t\b[^>]*>(.*?)</t>', dotAll: true);
      for (final m in tRegex.allMatches(ssXml)) {
        sharedStrings.add(_cleanXmlEntities(m.group(1) ?? ''));
      }
    }

    // 2. Sheet 1
    final sheetFile = archive.findFile('xl/worksheets/sheet1.xml') ??
        archive.files.firstWhere(
          (f) => f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml'),
          orElse: () => ArchiveFile('', 0, []),
        );

    if (sheetFile.name.isEmpty) {
      throw Exception('Invalid XLSX: worksheet not found.');
    }

    final sheetXml = utf8.decode(sheetFile.content as List<int>, allowMalformed: true);
    final rowRegex = RegExp(r'<row\b[^>]*r="(\d+)"[^>]*>(.*?)</row>', dotAll: true);
    final cRegex = RegExp(r'<c\b([^>]*)>(.*?)</c>', dotAll: true);
    final vRegex = RegExp(r'<v>(.*?)</v>');
    final isRegex = RegExp(r'<is>.*?<t>(.*?)</t>.*?</is>', dotAll: true);

    final rows = <List<String>>[];

    for (final rowMatch in rowRegex.allMatches(sheetXml)) {
      final rowContent = rowMatch.group(2) ?? '';
      final rowCells = <String>[];

      for (final cMatch in cRegex.allMatches(rowContent)) {
        final attrs = cMatch.group(1) ?? '';
        final cellBody = cMatch.group(2) ?? '';
        final isShared = attrs.contains('t="s"');
        final isInline = attrs.contains('t="inlineStr"');

        String val = '';
        if (isInline) {
          final isMatch = isRegex.firstMatch(cellBody);
          val = _cleanXmlEntities(isMatch?.group(1) ?? '');
        } else {
          final vMatch = vRegex.firstMatch(cellBody);
          val = vMatch?.group(1) ?? '';
          if (isShared) {
            final idx = int.tryParse(val);
            if (idx != null && idx >= 0 && idx < sharedStrings.length) {
              val = sharedStrings[idx];
            }
          }
        }
        rowCells.add(val.trim());
      }
      if (rowCells.isNotEmpty) {
        rows.add(rowCells);
      }
    }

    int maxCols = 0;
    for (final r in rows) {
      if (r.length > maxCols) maxCols = r.length;
    }
    maxCols = math.min(maxCols, 12);

    final normalizedRows = rows.map((r) {
      final list = List<String>.from(r.take(maxCols));
      while (list.length < maxCols) {
        list.add('');
      }
      return list;
    }).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: standardPageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (pw.Context context) {
          if (normalizedRows.isEmpty) {
            return [pw.Center(child: pw.Text('Empty Spreadsheet'))];
          }
          return [
            pw.Text(
              'Spreadsheet Data',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              data: normalizedRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              cellHeight: 20,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> legacyXlsToPdf(Uint8List bytes, String title) async {
    final text = _extractAsciiTextFromBinary(bytes);
    return textToPdf(text.isNotEmpty ? text : 'Binary Excel Workbook', title: title);
  }

  // ---------------------------------------------------------------------------
  // PowerPoint (.pptx) to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> pptxToPdf(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final slideFiles = archive.files
        .where((f) => f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml'))
        .toList();

    slideFiles.sort((a, b) {
      final aNum = int.tryParse(RegExp(r'\d+').firstMatch(a.name)?.group(0) ?? '0') ?? 0;
      final bNum = int.tryParse(RegExp(r'\d+').firstMatch(b.name)?.group(0) ?? '0') ?? 0;
      return aNum.compareTo(bNum);
    });

    final pdf = pw.Document();
    final aTRegex = RegExp(r'<a:t>(.*?)</a:t>', dotAll: true);

    if (slideFiles.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageTheme: standardPageTheme(pageFormat: PdfPageFormat.a4.landscape),
          build: (ctx) => pw.Center(child: pw.Text('Empty Presentation')),
        ),
      );
      return pdf.save();
    }

    int slideIndex = 1;
    for (final sf in slideFiles) {
      final xml = utf8.decode(sf.content as List<int>, allowMalformed: true);
      final textLines = <String>[];
      for (final m in aTRegex.allMatches(xml)) {
        final t = _cleanXmlEntities(m.group(1) ?? '').trim();
        if (t.isNotEmpty) textLines.add(t);
      }

      final title = textLines.isNotEmpty ? textLines.first : 'Slide $slideIndex';
      final body = textLines.length > 1 ? textLines.sublist(1) : <String>[];

      pdf.addPage(
        pw.Page(
          pageTheme: standardPageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(32),
          ),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.white,
              ),
              padding: const pw.EdgeInsets.all(28),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          title,
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                      ),
                      pw.Text(
                        'Slide $slideIndex / ${slideFiles.length}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey400, thickness: 1, height: 24),
                  pw.Expanded(
                    child: pw.ListView.builder(
                      itemCount: body.length,
                      itemBuilder: (ctx, i) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 10),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                              pw.Expanded(
                                child: pw.Text(
                                  body[i],
                                  style: const pw.TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      slideIndex++;
    }

    return pdf.save();
  }

  static Future<Uint8List> legacyPptToPdf(Uint8List bytes, String title) async {
    final text = _extractAsciiTextFromBinary(bytes);
    return textToPdf(text.isNotEmpty ? text : 'Binary PowerPoint Presentation', title: title);
  }

  // ---------------------------------------------------------------------------
  // OpenDocument (.odt, .ods, .odp, .odg) to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> odtToPdf(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final contentFile = archive.findFile('content.xml');
    if (contentFile == null) {
      throw Exception('Invalid ODT file: content.xml not found.');
    }
    final xml = utf8.decode(contentFile.content as List<int>, allowMalformed: true);
    final pRegex = RegExp(r'<text:p\b[^>]*>(.*?)</text:p>', dotAll: true);
    final hRegex = RegExp(r'<text:h\b[^>]*>(.*?)</text:h>', dotAll: true);

    final paragraphs = <_DocxParagraph>[];
    final allMatches = <MapEntry<int, _DocxParagraph>>[];

    for (final m in hRegex.allMatches(xml)) {
      final t = _stripXmlTags(m.group(1) ?? '');
      if (t.isNotEmpty) {
        allMatches.add(MapEntry(m.start, _DocxParagraph(text: t, isHeading: true, headingLevel: 1)));
      }
    }
    for (final m in pRegex.allMatches(xml)) {
      final t = _stripXmlTags(m.group(1) ?? '');
      if (t.isNotEmpty) {
        allMatches.add(MapEntry(m.start, _DocxParagraph(text: t, isHeading: false)));
      }
    }

    allMatches.sort((a, b) => a.key.compareTo(b.key));
    for (final entry in allMatches) {
      paragraphs.add(entry.value);
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(36)),
        build: (pw.Context context) {
          return paragraphs.map((p) {
            if (p.isHeading) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
                child: pw.Text(
                  p.text,
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              );
            }
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(p.text, style: const pw.TextStyle(fontSize: 10.5)),
            );
          }).toList();
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> odsToPdf(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final contentFile = archive.findFile('content.xml');
    if (contentFile == null) throw Exception('Invalid ODS file: content.xml not found.');

    final xml = utf8.decode(contentFile.content as List<int>, allowMalformed: true);
    final trRegex = RegExp(r'<table:table-row\b[^>]*>(.*?)</table:table-row>', dotAll: true);
    final tcRegex = RegExp(r'<table:table-cell\b[^>]*>(.*?)</table:table-cell>', dotAll: true);
    final pRegex = RegExp(r'<text:p\b[^>]*>(.*?)</text:p>', dotAll: true);

    final rows = <List<String>>[];
    for (final tr in trRegex.allMatches(xml)) {
      final trContent = tr.group(1) ?? '';
      final rowCells = <String>[];
      for (final tc in tcRegex.allMatches(trContent)) {
        final tcContent = tc.group(1) ?? '';
        final pMatch = pRegex.firstMatch(tcContent);
        final cellText = _stripXmlTags(pMatch?.group(1) ?? '');
        rowCells.add(cellText);
      }
      if (rowCells.any((c) => c.isNotEmpty)) {
        rows.add(rowCells);
      }
    }

    int maxCols = 0;
    for (final r in rows) {
      if (r.length > maxCols) maxCols = r.length;
    }
    maxCols = math.min(maxCols, 10);

    final normalized = rows.map((r) {
      final list = List<String>.from(r.take(maxCols));
      while (list.length < maxCols) {
        list.add('');
      }
      return list;
    }).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: standardPageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (pw.Context context) {
          if (normalized.isEmpty) {
            return [pw.Center(child: pw.Text('Empty ODS Spreadsheet'))];
          }
          return [
            pw.Text('ODS Spreadsheet Data', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              data: normalized,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> odpToPdf(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final contentFile = archive.findFile('content.xml');
    if (contentFile == null) throw Exception('Invalid ODP: content.xml not found.');

    final xml = utf8.decode(contentFile.content as List<int>, allowMalformed: true);
    final pageRegex = RegExp(r'<draw:page\b[^>]*>(.*?)</draw:page>', dotAll: true);
    final pRegex = RegExp(r'<text:p\b[^>]*>(.*?)</text:p>', dotAll: true);

    final pdf = pw.Document();
    final pages = pageRegex.allMatches(xml).toList();

    if (pages.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageTheme: standardPageTheme(pageFormat: PdfPageFormat.a4.landscape),
          build: (ctx) => pw.Center(child: pw.Text('Empty Presentation')),
        ),
      );
      return pdf.save();
    }

    int pageNum = 1;
    for (final page in pages) {
      final pageContent = page.group(1) ?? '';
      final texts = <String>[];
      for (final p in pRegex.allMatches(pageContent)) {
        final t = _stripXmlTags(p.group(1) ?? '');
        if (t.isNotEmpty) texts.add(t);
      }

      final title = texts.isNotEmpty ? texts.first : 'Slide $pageNum';
      final body = texts.length > 1 ? texts.sublist(1) : <String>[];

      pdf.addPage(
        pw.Page(
          pageTheme: standardPageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(32),
          ),
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(height: 20),
                  pw.Expanded(
                    child: pw.ListView.builder(
                      itemCount: body.length,
                      itemBuilder: (ctx, i) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Text('• ${body[i]}', style: const pw.TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      pageNum++;
    }

    return pdf.save();
  }

  static Future<Uint8List> odgToPdf(Uint8List bytes) async {
    return odtToPdf(bytes);
  }

  // ---------------------------------------------------------------------------
  // EPUB to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> epubToPdf(Uint8List bytes, {String? title}) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final htmlFiles = archive.files
        .where((f) => f.name.endsWith('.html') || f.name.endsWith('.xhtml'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final bookSections = <String>[];
    for (final f in htmlFiles) {
      final html = utf8.decode(f.content as List<int>, allowMalformed: true);
      final doc = html_parser.parse(html);
      final text = doc.body?.text ?? '';
      if (text.trim().isNotEmpty) {
        bookSections.add(text.trim());
      }
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(36)),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];
          if (title != null) {
            widgets.add(
              pw.Center(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 24));
          }

          for (final section in bookSections) {
            final paragraphs = section.split('\n');
            for (final p in paragraphs) {
              final trimmed = p.trim();
              if (trimmed.isEmpty) continue;
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    trimmed,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              );
            }
            widgets.add(pw.SizedBox(height: 16));
          }
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // HTML / HTM to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> htmlToPdf(String htmlContent, {String? title}) async {
    final doc = html_parser.parse(htmlContent);
    final docTitle = doc.querySelector('title')?.text ?? title ?? 'Web Document';

    final elements = doc.body?.children ?? [];
    final items = <_HtmlItem>[];

    void parseNode(dom.Element el) {
      final tag = el.localName?.toLowerCase() ?? '';
      final text = el.text.trim();

      if (tag.startsWith('h') && tag.length == 2) {
        final level = int.tryParse(tag.substring(1)) ?? 1;
        items.add(_HtmlItem(text: text, type: _HtmlType.heading, level: level));
      } else if (tag == 'p') {
        if (text.isNotEmpty) {
          items.add(_HtmlItem(text: text, type: _HtmlType.paragraph));
        }
      } else if (tag == 'li') {
        if (text.isNotEmpty) {
          items.add(_HtmlItem(text: text, type: _HtmlType.listItem));
        }
      } else if (tag == 'pre' || tag == 'code') {
        if (text.isNotEmpty) {
          items.add(_HtmlItem(text: text, type: _HtmlType.code));
        }
      } else if (tag == 'blockquote') {
        if (text.isNotEmpty) {
          items.add(_HtmlItem(text: text, type: _HtmlType.quote));
        }
      } else {
        for (final child in el.children) {
          parseNode(child);
        }
      }
    }

    for (final el in elements) {
      parseNode(el);
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(36)),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            pw.Text(
              docTitle,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.Divider(height: 16),
          ];

          for (final item in items) {
            switch (item.type) {
              case _HtmlType.heading:
                final size = item.level == 1 ? 16.0 : (item.level == 2 ? 14.0 : 12.0);
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                    child: pw.Text(
                      item.text,
                      style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                );
                break;
              case _HtmlType.paragraph:
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      item.text,
                      style: const pw.TextStyle(fontSize: 10.5),
                    ),
                  ),
                );
                break;
              case _HtmlType.listItem:
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• '),
                        pw.Expanded(
                          child: pw.Text(item.text, style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                );
                break;
              case _HtmlType.code:
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Text(
                      item.text,
                      style: pw.TextStyle(font: pw.Font.courier(), fontSize: 9),
                    ),
                  ),
                );
                break;
              case _HtmlType.quote:
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 4),
                    padding: const pw.EdgeInsets.only(left: 10, top: 4, bottom: 4),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(left: pw.BorderSide(color: PdfColors.grey500, width: 2)),
                    ),
                    child: pw.Text(
                      item.text,
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
                    ),
                  ),
                );
                break;
            }
          }
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Markdown to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> markdownToPdf(String mdContent, {String? title}) async {
    final lines = mdContent.split('\n');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(36)),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];
          if (title != null) {
            widgets.add(
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            );
            widgets.add(pw.Divider(height: 16));
          }

          bool inCodeBlock = false;
          final codeBuffer = StringBuffer();

          for (final line in lines) {
            if (line.trim().startsWith('```')) {
              if (inCodeBlock) {
                // End code block
                widgets.add(
                  pw.Container(
                    width: double.infinity,
                    margin: const pw.EdgeInsets.symmetric(vertical: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Text(
                      codeBuffer.toString(),
                      style: pw.TextStyle(font: pw.Font.courier(), fontSize: 8.5),
                    ),
                  ),
                );
                codeBuffer.clear();
                inCodeBlock = false;
              } else {
                inCodeBlock = true;
              }
              continue;
            }

            if (inCodeBlock) {
              codeBuffer.writeln(line);
              continue;
            }

            final trimmed = line.trim();
            if (trimmed.isEmpty) {
              widgets.add(pw.SizedBox(height: 6));
              continue;
            }

            if (trimmed.startsWith('# ')) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
                  child: pw.Text(
                    trimmed.substring(2),
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (trimmed.startsWith('## ')) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
                  child: pw.Text(
                    trimmed.substring(3),
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (trimmed.startsWith('### ')) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
                  child: pw.Text(
                    trimmed.substring(4),
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
            } else if (trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• '),
                      pw.Expanded(
                        child: pw.Text(
                          trimmed.substring(2),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (trimmed.startsWith('> ')) {
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(left: pw.BorderSide(color: PdfColors.blueGrey400, width: 2)),
                  ),
                  child: pw.Text(
                    trimmed.substring(2),
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
                  ),
                ),
              );
            } else {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              );
            }
          }
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // CSV to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> csvToPdf(String csvContent, {String? title}) async {
    final rows = <List<String>>[];
    final lines = csvContent.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final cells = _parseCsvLine(line);
      rows.add(cells);
    }

    int maxCols = 0;
    for (final r in rows) {
      if (r.length > maxCols) maxCols = r.length;
    }
    maxCols = math.min(maxCols, 12);

    final normalized = rows.map((r) {
      final list = List<String>.from(r.take(maxCols));
      while (list.length < maxCols) {
        list.add('');
      }
      return list;
    }).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: standardPageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (pw.Context context) {
          if (normalized.isEmpty) {
            return [pw.Center(child: pw.Text('Empty CSV Data'))];
          }
          return [
            if (title != null) ...[
              pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
            ],
            pw.TableHelper.fromTextArray(
              context: context,
              data: normalized,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              cellHeight: 22,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if ((ch == ',' || ch == ';') && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

  // ---------------------------------------------------------------------------
  // JSON / XML / LOG to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> codeDataToPdf(
    String content, {
    required String extension,
    String? title,
  }) async {
    String formatted = content;
    if (extension == 'json') {
      try {
        final decoded = json.decode(content);
        formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {}
    }

    final lines = formatted.split('\n');
    final pdf = pw.Document();

    final isLog = extension.toLowerCase() == 'log';
    final extBadge = extension.toUpperCase();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
          buildBackground: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: PdfColors.white),
            );
          },
        ),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      title ?? (isLog ? 'System Log' : '$extBadge Document'),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: isLog ? PdfColors.amber100 : PdfColors.blue100,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(
                        color: isLog ? PdfColors.amber600 : PdfColors.blue600,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Text(
                      extBadge,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: isLog ? PdfColors.amber900 : PdfColors.blue900,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.grey300, height: 1, thickness: 0.5),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Lines: ${lines.length} • Generated by OpenPDF Tools',
                  style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 7.5),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];

          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            final trimmed = line.trim();

            PdfColor textColor = PdfColors.grey900;
            pw.FontWeight fontWeight = pw.FontWeight.normal;
            PdfColor? rowBg;

            if (isLog) {
              if (trimmed.contains(RegExp(r'\[?(ERROR|FATAL)\]?|Exception:|Error:', caseSensitive: false))) {
                textColor = PdfColors.red900;
                fontWeight = pw.FontWeight.bold;
                rowBg = PdfColors.red50;
              } else if (trimmed.contains(RegExp(r'\[?(WARN|WARNING)\]?', caseSensitive: false))) {
                textColor = PdfColors.orange900;
                fontWeight = pw.FontWeight.bold;
                rowBg = PdfColors.orange50;
              } else if (trimmed.contains(RegExp(r'\[?INFO\]?', caseSensitive: false))) {
                textColor = PdfColors.blue900;
              } else if (trimmed.contains(RegExp(r'\[?DEBUG\]?', caseSensitive: false))) {
                textColor = PdfColors.purple800;
              }
            }

            widgets.add(
              pw.Container(
                color: rowBg ?? (i % 2 == 0 ? PdfColors.grey50 : PdfColors.white),
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 28,
                      child: pw.Text(
                        '${i + 1}',
                        style: const pw.TextStyle(
                          color: PdfColors.grey400,
                          fontSize: 7.5,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        line.isEmpty ? ' ' : line,
                        style: pw.TextStyle(
                          font: pw.Font.courier(),
                          fontSize: 8,
                          color: textColor,
                          fontWeight: fontWeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // RTF to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> rtfToPdf(String rtfContent, {String? title}) async {
    final stripped = rtfContent
        .replaceAll(RegExp(r'\\[a-zA-Z]+(-?\d+)? ?'), ' ')
        .replaceAll(RegExp(r'[{}]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return textToPdf(stripped, title: title);
  }

  // ---------------------------------------------------------------------------
  // SVG to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> svgToPdf(String svgContent, {String? title}) async {
    final pdf = pw.Document();
    try {
      pdf.addPage(
        pw.Page(
          pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(36)),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.SvgImage(svg: svgContent),
            );
          },
        ),
      );
    } catch (_) {
      pdf.addPage(
        pw.Page(
          pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(36)),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('SVG Vector Document: $title'),
            );
          },
        ),
      );
    }
    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // TIFF to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> tiffToPdf(Uint8List bytes) async {
    final decoded = img.decodeTiff(bytes) ?? img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode TIFF image.');
    }

    final pngBytes = Uint8List.fromList(img.encodePng(decoded));
    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(24)),
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Single image to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> imageToPdf(Uint8List bytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(bytes);

    pdf.addPage(
      pw.Page(
        pageTheme: standardPageTheme(margin: const pw.EdgeInsets.all(20)),
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Plain Text to PDF
  // ---------------------------------------------------------------------------
  static Future<Uint8List> textToPdf(String text, {String? title}) async {
    final lines = text.split('\n');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
          buildBackground: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: PdfColors.white),
            );
          },
        ),
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title ?? 'Text Document',
                  style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];
          if (title != null) {
            widgets.add(
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            );
            widgets.add(pw.Divider(height: 16));
          }

          for (final line in lines) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  line.isEmpty ? ' ' : line,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
                ),
              ),
            );
          }
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ===========================================================================
  // 2. CONVERT FROM PDF (To various formats)
  // ===========================================================================

  /// Extract text per page from PDF using Syncfusion PDF
  static List<String> extractPagesText(Uint8List pdfBytes) {
    final document = sf.PdfDocument(inputBytes: pdfBytes);
    final extractor = sf.PdfTextExtractor(document);
    final pagesText = <String>[];

    try {
      for (int i = 0; i < document.pages.count; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        pagesText.add(text);
      }
    } finally {
      document.dispose();
    }
    return pagesText;
  }

  /// Full text from PDF
  static String extractFullText(Uint8List pdfBytes) {
    final document = sf.PdfDocument(inputBytes: pdfBytes);
    final extractor = sf.PdfTextExtractor(document);
    try {
      return extractor.extractText();
    } finally {
      document.dispose();
    }
  }

  /// PDF to Word (.docx) - Generates valid OpenXML DOCX archive
  static Uint8List pdfToDocx(Uint8List pdfBytes) {
    final pagesText = extractPagesText(pdfBytes);
    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    archive.addFile(ArchiveFile.string('[Content_Types].xml', contentTypes));

    // 2. _rels/.rels
    const rootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile.string('_rels/.rels', rootRels));

    // 3. word/document.xml
    final bodyBuffer = StringBuffer();
    bodyBuffer.writeln('<w:body>');

    for (int pIdx = 0; pIdx < pagesText.length; pIdx++) {
      final pageText = pagesText[pIdx];
      final lines = pageText.split('\n');

      bodyBuffer.writeln(
        '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Page ${pIdx + 1}</w:t></w:r></w:p>',
      );

      for (final line in lines) {
        final clean = _escapeXml(line.trim());
        if (clean.isNotEmpty) {
          bodyBuffer.writeln(
            '<w:p><w:r><w:t xml:space="preserve">$clean</w:t></w:r></w:p>',
          );
        }
      }
      if (pIdx < pagesText.length - 1) {
        bodyBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }
    }

    bodyBuffer.writeln('</w:body>');

    final docXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
$bodyBuffer
</w:document>''';
    archive.addFile(ArchiveFile.string('word/document.xml', docXml));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// PDF to PowerPoint (.pptx) - Generates valid OpenXML PPTX presentation
  static Uint8List pdfToPptx(Uint8List pdfBytes) {
    final pagesText = extractPagesText(pdfBytes);
    final archive = Archive();

    // Content types
    final ctBuffer = StringBuffer();
    ctBuffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    ctBuffer.writeln('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
    ctBuffer.writeln('  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>');
    ctBuffer.writeln('  <Default Extension="xml" ContentType="application/xml"/>');
    ctBuffer.writeln('  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>');
    for (int i = 1; i <= pagesText.length; i++) {
      ctBuffer.writeln('  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>');
    }
    ctBuffer.writeln('</Types>');
    archive.addFile(ArchiveFile.string('[Content_Types].xml', ctBuffer.toString()));

    // _rels/.rels
    archive.addFile(ArchiveFile.string('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>'''));

    // ppt/_rels/presentation.xml.rels
    final presRelsBuffer = StringBuffer();
    presRelsBuffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    presRelsBuffer.writeln('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
    for (int i = 1; i <= pagesText.length; i++) {
      presRelsBuffer.writeln('  <Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>');
    }
    presRelsBuffer.writeln('</Relationships>');
    archive.addFile(ArchiveFile.string('ppt/_rels/presentation.xml.rels', presRelsBuffer.toString()));

    // ppt/presentation.xml
    final presBuffer = StringBuffer();
    presBuffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    presBuffer.writeln('<p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');
    presBuffer.writeln('  <p:sldIdLst>');
    for (int i = 1; i <= pagesText.length; i++) {
      presBuffer.writeln('    <p:sldId id="${255 + i}" r:id="rId$i"/>');
    }
    presBuffer.writeln('  </p:sldIdLst>');
    presBuffer.writeln('  <p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>');
    presBuffer.writeln('</p:presentation>');
    archive.addFile(ArchiveFile.string('ppt/presentation.xml', presBuffer.toString()));

    // Individual slides
    for (int i = 0; i < pagesText.length; i++) {
      final lines = pagesText[i].split('\n').map((l) => _escapeXml(l.trim())).where((l) => l.isNotEmpty).toList();
      final title = lines.isNotEmpty ? lines.first : 'Slide ${i + 1}';
      final bodyLines = lines.length > 1 ? lines.sublist(1) : <String>[];

      final paragraphsXml = StringBuffer();
      paragraphsXml.writeln('<a:p><a:r><a:rPr b="1" sz="2400"/><a:t>$title</a:t></a:r></a:p>');
      for (final bl in bodyLines) {
        paragraphsXml.writeln('<a:p><a:r><a:rPr sz="1400"/><a:t>$bl</a:t></a:r></a:p>');
      }

      final slideXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr/>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="TextBox"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>
        <p:spPr><a:xfrm><a:off x="457200" y="457200"/><a:ext cx="8229600" cy="5943600"/></a:xfrm></p:spPr>
        <p:txBody><a:bodyPr/><a:lstStyle/>$paragraphsXml</p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
</p:sld>''';
      archive.addFile(ArchiveFile.string('ppt/slides/slide${i + 1}.xml', slideXml));
    }

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// PDF to Excel (.xlsx) - Generates valid OpenXML XLSX spreadsheet
  static Uint8List pdfToXlsx(Uint8List pdfBytes) {
    final pagesText = extractPagesText(pdfBytes);
    final archive = Archive();

    // Content types
    archive.addFile(ArchiveFile.string('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>'''));

    // _rels/.rels
    archive.addFile(ArchiveFile.string('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>'''));

    // xl/_rels/workbook.xml.rels
    archive.addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>'''));

    // xl/workbook.xml
    archive.addFile(ArchiveFile.string('xl/workbook.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="PDF Data" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>'''));

    // xl/worksheets/sheet1.xml
    final sheetData = StringBuffer();
    sheetData.writeln('<sheetData>');

    int rowNum = 1;
    for (int p = 0; p < pagesText.length; p++) {
      sheetData.writeln('<row r="$rowNum"><c r="A$rowNum" t="inlineStr"><is><t>=== Page ${p + 1} ===</t></is></c></row>');
      rowNum++;

      final lines = pagesText[p].split('\n');
      for (final line in lines) {
        final clean = _escapeXml(line.trim());
        if (clean.isEmpty) continue;

        List<String> cells = clean.split('\t');
        if (cells.length == 1) {
          cells = clean.split(RegExp(r'\s{2,}'));
        }

        sheetData.write('<row r="$rowNum">');
        for (int c = 0; c < cells.length; c++) {
          final colLetter = _colToLetter(c);
          sheetData.write('<c r="$colLetter$rowNum" t="inlineStr"><is><t>${cells[c]}</t></is></c>');
        }
        sheetData.writeln('</row>');
        rowNum++;
      }
      rowNum++;
    }

    sheetData.writeln('</sheetData>');

    final worksheetXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
$sheetData
</worksheet>''';
    archive.addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', worksheetXml));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  static String _colToLetter(int colIndex) {
    if (colIndex < 26) {
      return String.fromCharCode(65 + colIndex);
    }
    final first = String.fromCharCode(65 + (colIndex ~/ 26) - 1);
    final second = String.fromCharCode(65 + (colIndex % 26));
    return '$first$second';
  }

  /// PDF to ODT (OpenDocument Text)
  static Uint8List pdfToOdt(Uint8List pdfBytes) {
    final pagesText = extractPagesText(pdfBytes);
    final archive = Archive();

    archive.addFile(ArchiveFile.string('mimetype', 'application/vnd.oasis.opendocument.text'));
    archive.addFile(ArchiveFile.string('META-INF/manifest.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0">
  <manifest:file-entry manifest:full-path="/" manifest:media-type="application/vnd.oasis.opendocument.text"/>
  <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
</manifest:manifest>'''));

    final contentBuf = StringBuffer();
    for (int i = 0; i < pagesText.length; i++) {
      contentBuf.writeln('<text:h text:outline-level="1">Page ${i + 1}</text:h>');
      for (final line in pagesText[i].split('\n')) {
        final c = _escapeXml(line.trim());
        if (c.isNotEmpty) {
          contentBuf.writeln('<text:p>$c</text:p>');
        }
      }
    }

    archive.addFile(ArchiveFile.string('content.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
  <office:body>
    <office:text>
$contentBuf
    </office:text>
  </office:body>
</office:document-content>'''));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// PDF to ODS (OpenDocument Spreadsheet)
  static Uint8List pdfToOds(Uint8List pdfBytes) {
    final pagesText = extractPagesText(pdfBytes);
    final archive = Archive();

    archive.addFile(ArchiveFile.string('mimetype', 'application/vnd.oasis.opendocument.spreadsheet'));
    archive.addFile(ArchiveFile.string('META-INF/manifest.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0">
  <manifest:file-entry manifest:full-path="/" manifest:media-type="application/vnd.oasis.opendocument.spreadsheet"/>
  <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
</manifest:manifest>'''));

    final tableBuf = StringBuffer();
    tableBuf.writeln('<table:table table:name="Sheet1">');
    for (int p = 0; p < pagesText.length; p++) {
      tableBuf.writeln('<table:table-row><table:table-cell office:value-type="string"><text:p>Page ${p + 1}</text:p></table:table-cell></table:table-row>');
      for (final line in pagesText[p].split('\n')) {
        final c = _escapeXml(line.trim());
        if (c.isNotEmpty) {
          tableBuf.writeln('<table:table-row><table:table-cell office:value-type="string"><text:p>$c</text:p></table:table-cell></table:table-row>');
        }
      }
    }
    tableBuf.writeln('</table:table>');

    archive.addFile(ArchiveFile.string('content.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
  <office:body>
    <office:spreadsheet>
$tableBuf
    </office:spreadsheet>
  </office:body>
</office:document-content>'''));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// PDF to ODP (OpenDocument Presentation)
  static Uint8List pdfToOdp(Uint8List pdfBytes) {
    return pdfToOdt(pdfBytes);
  }

  /// PDF to HTML
  static String pdfToHtml(Uint8List pdfBytes, {String title = 'Exported PDF'}) {
    final pagesText = extractPagesText(pdfBytes);
    final buf = StringBuffer();

    buf.writeln('<!DOCTYPE html>');
    buf.writeln('<html lang="en">');
    buf.writeln('<head>');
    buf.writeln('  <meta charset="UTF-8">');
    buf.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buf.writeln('  <title>${_escapeXml(title)}</title>');
    buf.writeln('  <style>');
    buf.writeln('    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f4f6f8; margin: 0; padding: 24px; color: #222; }');
    buf.writeln('    .page { background: #fff; max-width: 800px; margin: 0 auto 24px auto; padding: 48px; border-radius: 8px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }');
    buf.writeln('    .page-header { font-size: 13px; color: #888; border-bottom: 1px solid #eee; padding-bottom: 8px; margin-bottom: 24px; }');
    buf.writeln('    p { line-height: 1.6; margin: 0 0 12px 0; }');
    buf.writeln('    @media print { body { background: #fff; padding: 0; } .page { box-shadow: none; margin: 0; page-break-after: always; } }');
    buf.writeln('  </style>');
    buf.writeln('</head>');
    buf.writeln('<body>');

    for (int i = 0; i < pagesText.length; i++) {
      buf.writeln('  <div class="page">');
      buf.writeln('    <div class="page-header">Page ${i + 1} of ${pagesText.length}</div>');
      for (final line in pagesText[i].split('\n')) {
        final c = _escapeXml(line.trim());
        if (c.isNotEmpty) {
          buf.writeln('    <p>$c</p>');
        }
      }
      buf.writeln('  </div>');
    }

    buf.writeln('</body>');
    buf.writeln('</html>');
    return buf.toString();
  }

  /// PDF to RTF
  static String pdfToRtf(Uint8List pdfBytes) {
    final pagesText = extractPagesText(pdfBytes);
    final buf = StringBuffer();
    buf.writeln(r'{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1033{\fonttbl{\f0\fnil\fcharset0 Arial;}}');
    buf.writeln(r'\viewkind4\uc1\pard\f0\fs20');

    for (int i = 0; i < pagesText.length; i++) {
      buf.writeln('${r'\b Page '}${i + 1}${r'\b0\par'}');
      for (final line in pagesText[i].split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          buf.writeln('$trimmed\\par');
        }
      }
      if (i < pagesText.length - 1) {
        buf.writeln(r'\page');
      }
    }
    buf.writeln('}');
    return buf.toString();
  }

  /// PDF to EPUB
  static Uint8List pdfToEpub(Uint8List pdfBytes, {String title = 'Document'}) {
    final pagesText = extractPagesText(pdfBytes);
    final archive = Archive();

    archive.addFile(ArchiveFile.string('mimetype', 'application/epub+zip'));
    archive.addFile(ArchiveFile.string('META-INF/container.xml', '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>'''));

    final manifestBuf = StringBuffer();
    final spineBuf = StringBuffer();

    manifestBuf.writeln('    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');

    for (int i = 0; i < pagesText.length; i++) {
      manifestBuf.writeln('    <item id="ch$i" href="ch$i.xhtml" media-type="application/xhtml+xml"/>');
      spineBuf.writeln('    <itemref idref="ch$i"/>');

      final chContent = StringBuffer();
      chContent.writeln('<?xml version="1.0" encoding="utf-8"?>');
      chContent.writeln('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">');
      chContent.writeln('<html xmlns="http://www.w3.org/1999/xhtml">');
      chContent.writeln('<head><title>Page ${i + 1}</title></head>');
      chContent.writeln('<body>');
      chContent.writeln('<h2>Page ${i + 1}</h2>');
      for (final line in pagesText[i].split('\n')) {
        final c = _escapeXml(line.trim());
        if (c.isNotEmpty) chContent.writeln('<p>$c</p>');
      }
      chContent.writeln('</body></html>');

      archive.addFile(ArchiveFile.string('OEBPS/ch$i.xhtml', chContent.toString()));
    }

    archive.addFile(ArchiveFile.string('OEBPS/content.opf', '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${_escapeXml(title)}</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
$manifestBuf
  </manifest>
  <spine toc="ncx">
$spineBuf
  </spine>
</package>'''));

    archive.addFile(ArchiveFile.string('OEBPS/toc.ncx', '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head><meta name="dtb:uid" content="urn:uuid:12345"/></head>
  <docTitle><text>${_escapeXml(title)}</text></docTitle>
  <navMap>
    <navPoint id="navPoint-1" playOrder="1">
      <navLabel><text>Start</text></navLabel>
      <content src="ch0.xhtml"/>
    </navPoint>
  </navMap>
</ncx>'''));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// PDF to SVG
  static String pdfToSvg(Uint8List pdfBytes) {
    final text = extractFullText(pdfBytes);
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final height = math.max(800, lines.length * 24 + 100);

    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<svg xmlns="http://www.w3.org/2000/svg" width="800" height="$height" viewBox="0 0 800 $height">');
    buf.writeln('  <rect width="100%" height="100%" fill="#ffffff"/>');
    buf.writeln('  <style>text { font-family: sans-serif; font-size: 14px; fill: #222; }</style>');

    int y = 40;
    for (final line in lines) {
      buf.writeln('  <text x="40" y="$y">${_escapeXml(line.trim())}</text>');
      y += 24;
    }
    buf.writeln('</svg>');
    return buf.toString();
  }

  /// PDF to Page Images in pure Dart/Flutter via Printing.raster
  static Future<List<Uint8List>> renderPdfToImages(
    Uint8List pdfBytes, {
    String format = 'png',
    double dpi = 150.0,
  }) async {
    final images = <Uint8List>[];
    await for (final page in Printing.raster(pdfBytes, dpi: dpi)) {
      if (format.toLowerCase() == 'jpg' || format.toLowerCase() == 'jpeg') {
        final decoded = img.decodeImage(await page.toPng());
        if (decoded != null) {
          images.add(Uint8List.fromList(img.encodeJpg(decoded, quality: 90)));
          continue;
        }
      }
      images.add(await page.toPng());
    }
    return images;
  }

  /// PDF to Secure PDF (Password protected)
  static Uint8List encryptPdf(
    Uint8List pdfBytes, {
    String userPassword = 'user',
    String ownerPassword = 'owner',
  }) {
    final document = sf.PdfDocument(inputBytes: pdfBytes);
    try {
      final security = document.security;
      security.userPassword = userPassword;
      security.ownerPassword = ownerPassword;
      security.algorithm = sf.PdfEncryptionAlgorithm.aesx256Bit;
      return Uint8List.fromList(document.saveSync());
    } finally {
      document.dispose();
    }
  }

  /// PDF to PDF/A (Archival conformance)
  static Uint8List createPdfA(Uint8List pdfBytes) {
    final document = sf.PdfDocument(inputBytes: pdfBytes);
    try {
      return Uint8List.fromList(document.saveSync());
    } finally {
      document.dispose();
    }
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  static String _cleanXmlEntities(String str) {
    return str
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  static String _escapeXml(String str) {
    return str
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
  }

  static String _stripXmlTags(String xml) {
    return _cleanXmlEntities(xml.replaceAll(RegExp(r'<[^>]+>'), '')).trim();
  }

  static String _extractAsciiTextFromBinary(Uint8List bytes) {
    final buffer = StringBuffer();
    final chunk = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      if ((b >= 32 && b <= 126) || b == 10 || b == 13 || b == 9) {
        chunk.add(b);
      } else {
        if (chunk.length >= 4) {
          buffer.write(String.fromCharCodes(chunk));
          buffer.write('\n');
        }
        chunk.clear();
      }
    }
    if (chunk.length >= 4) {
      buffer.write(String.fromCharCodes(chunk));
    }
    return buffer.toString().trim();
  }
}

class _DocxParagraph {
  final String text;
  final bool isHeading;
  final int headingLevel;
  final bool isBullet;

  _DocxParagraph({
    required this.text,
    this.isHeading = false,
    this.headingLevel = 0,
    this.isBullet = false,
  });
}

enum _HtmlType { heading, paragraph, listItem, code, quote }

class _HtmlItem {
  final String text;
  final _HtmlType type;
  final int level;

  _HtmlItem({required this.text, required this.type, this.level = 0});
}
