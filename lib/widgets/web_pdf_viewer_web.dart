import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class WebPdfViewer extends StatefulWidget {
  final Uint8List pdfBytes;
  final String? fileName;

  const WebPdfViewer({super.key, required this.pdfBytes, this.fileName});

  @override
  State<WebPdfViewer> createState() => _WebPdfViewerState();
}

class _WebPdfViewerState extends State<WebPdfViewer> {
  late String _viewId;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'web_pdf_viewer_${DateTime.now().millisecondsSinceEpoch}';
    _loadPdf();
  }

  void _loadPdf() {
    // Convert bytes to base64
    final base64String = base64Encode(widget.pdfBytes);
    final dataUrl = 'data:application/pdf;base64,$base64String';

    // Create iframe element
    final iframeElement = html.IFrameElement()
      ..src = dataUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // Register view factory
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => iframeElement,
    );

    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return HtmlElementView(viewType: _viewId);
  }
}
