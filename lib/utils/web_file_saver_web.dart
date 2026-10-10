// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
// ignore: deprecated_member_use
import 'dart:html' as html;

Future<void> downloadFile(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/pdf',
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
