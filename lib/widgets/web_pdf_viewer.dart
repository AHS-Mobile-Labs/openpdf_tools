import 'dart:typed_data';
import 'package:flutter/material.dart';
class WebPdfViewer extends StatefulWidget {
  final Uint8List pdfBytes;
  final String? fileName;
  const WebPdfViewer({super.key, required this.pdfBytes, this.fileName});
  @override
  State<WebPdfViewer> createState() => _WebPdfViewerState();
}
class _WebPdfViewerState extends State<WebPdfViewer> {
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('PDF viewer not available on this platform'),
    );
  }
}