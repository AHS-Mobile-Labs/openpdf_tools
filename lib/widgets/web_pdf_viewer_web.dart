// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
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
  String? _blobUrl;

  @override
  void initState() {
    super.initState();
    _viewId = 'web_pdf_viewer_${DateTime.now().millisecondsSinceEpoch}';
    _loadPdf();
  }

  @override
  void dispose() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
    }
    super.dispose();
  }

  void _loadPdf() {
    // Convert bytes to base64
    final base64String = base64Encode(widget.pdfBytes);

    // Create HTML content with PDF.js viewer
    final htmlContent =
        '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        body {
          font-family: Arial, sans-serif;
          background: #f0f0f0;
        }
        
        #pdf-container {
          display: flex;
          flex-direction: column;
          height: 100vh;
          width: 100%;
        }
        
        #toolbar {
          background: #333;
          color: white;
          padding: 10px 15px;
          display: flex;
          align-items: center;
          gap: 10px;
          box-shadow: 0 2px 5px rgba(0,0,0,0.1);
          flex-wrap: wrap;
        }
        
        .toolbar-btn {
          background: #555;
          border: none;
          color: white;
          padding: 8px 12px;
          border-radius: 4px;
          cursor: pointer;
          font-size: 14px;
          transition: background 0.3s;
        }
        
        .toolbar-btn:hover {
          background: #777;
        }
        
        .toolbar-btn:disabled {
          background: #888;
          cursor: not-allowed;
          opacity: 0.6;
        }
        
        .separator {
          width: 1px;
          height: 24px;
          background: #555;
        }
        
        #page-info {
          color: white;
          font-size: 14px;
          margin-left: 10px;
        }
        
        #zoom-input {
          width: 70px;
          padding: 6px 8px;
          border: none;
          border-radius: 4px;
          font-size: 14px;
        }
        
        #canvas-container {
          flex: 1;
          overflow: auto;
          display: flex;
          justify-content: center;
          align-items: flex-start;
          padding: 20px;
          background: #f0f0f0;
        }
        
        #pdf-canvas {
          box-shadow: 0 0 10px rgba(0,0,0,0.2);
          max-width: 100%;
          height: auto;
        }
        
        #file-name {
          color: white;
          font-size: 14px;
          margin-left: auto;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          max-width: 200px;
        }
      </style>
    </head>
    <body>
      <div id="pdf-container">
        <div id="toolbar">
          <button id="prev-btn" class="toolbar-btn" title="Previous page">← Prev</button>
          <button id="next-btn" class="toolbar-btn" title="Next page">Next →</button>
          <div class="separator"></div>
          <span id="page-info">Page <span id="page-num">1</span> of <span id="page-count">-</span></span>
          <div class="separator"></div>
          <button id="zoom-out-btn" class="toolbar-btn" title="Zoom out">−</button>
          <input type="text" id="zoom-input" value="100" title="Zoom level">
          <span style="color: white; font-size: 14px;">%</span>
          <button id="zoom-in-btn" class="toolbar-btn" title="Zoom in">+</button>
          <button id="fit-width-btn" class="toolbar-btn" title="Fit to width">Fit Width</button>
          <button id="fit-page-btn" class="toolbar-btn" title="Fit page">Fit Page</button>
          <div id="file-name" title="${widget.fileName ?? 'PDF Document'}">📄 ${widget.fileName ?? 'PDF Document'}</div>
        </div>
        <div id="canvas-container">
          <canvas id="pdf-canvas"></canvas>
        </div>
      </div>

      <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
      <script>
        pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
        const base64Pdf = '$base64String';
        let pdfDoc = null;
        let currentPage = 1;
        let pageCount = 0;
        let scale = 1;
        let fitMode = 'custom'; // 'custom', 'width', 'page'

        const canvas = document.getElementById('pdf-canvas');
        const ctx = canvas.getContext('2d');
        const pageNumSpan = document.getElementById('page-num');
        const pageCountSpan = document.getElementById('page-count');
        const zoomInput = document.getElementById('zoom-input');
        const prevBtn = document.getElementById('prev-btn');
        const nextBtn = document.getElementById('next-btn');
        const zoomOutBtn = document.getElementById('zoom-out-btn');
        const zoomInBtn = document.getElementById('zoom-in-btn');
        const fitWidthBtn = document.getElementById('fit-width-btn');
        const fitPageBtn = document.getElementById('fit-page-btn');
        const canvasContainer = document.getElementById('canvas-container');

        // Load PDF from base64
        async function loadPdf() {
          try {
            const binaryString = atob(base64Pdf);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
              bytes[i] = binaryString.charCodeAt(i);
            }
            
            pdfDoc = await pdfjsLib.getDocument({ data: bytes }).promise;
            pageCount = pdfDoc.numPages;
            pageCountSpan.textContent = pageCount;
            
            await renderPage(1);
          } catch (error) {
            console.error('Error loading PDF:', error);
            canvas.parentElement.innerHTML = '<p style="color: red;">Error loading PDF: ' + error.message + '</p>';
          }
        }

        // Render specific page
        async function renderPage(pageNum) {
          try {
            if (pageNum < 1 || pageNum > pageCount) return;
            
            const page = await pdfDoc.getPage(pageNum);
            const viewport = page.getViewport({ scale: scale });
            
            canvas.width = viewport.width;
            canvas.height = viewport.height;
            
            await page.render({
              canvasContext: ctx,
              viewport: viewport
            }).promise;
            
            currentPage = pageNum;
            pageNumSpan.textContent = currentPage;
            updateButtonStates();
          } catch (error) {
            console.error('Error rendering page:', error);
          }
        }

        function updateButtonStates() {
          prevBtn.disabled = currentPage <= 1;
          nextBtn.disabled = currentPage >= pageCount;
        }

        function updateZoomInput() {
          zoomInput.value = Math.round(scale * 100);
        }

        // Event listeners
        prevBtn.addEventListener('click', () => {
          if (currentPage > 1) {
            fitMode = 'custom';
            renderPage(currentPage - 1);
          }
        });

        nextBtn.addEventListener('click', () => {
          if (currentPage < pageCount) {
            fitMode = 'custom';
            renderPage(currentPage + 1);
          }
        });

        zoomOutBtn.addEventListener('click', () => {
          fitMode = 'custom';
          scale = Math.max(0.5, scale - 0.1);
          updateZoomInput();
          renderPage(currentPage);
        });

        zoomInBtn.addEventListener('click', () => {
          fitMode = 'custom';
          scale = Math.min(3, scale + 0.1);
          updateZoomInput();
          renderPage(currentPage);
        });

        zoomInput.addEventListener('change', () => {
          fitMode = 'custom';
          const newScale = Math.max(0.5, Math.min(3, parseInt(zoomInput.value) / 100));
          if (!isNaN(newScale)) {
            scale = newScale;
            renderPage(currentPage);
          }
        });

        fitWidthBtn.addEventListener('click', async () => {
          fitMode = 'width';
          const page = await pdfDoc.getPage(currentPage);
          const viewport = page.getViewport({ scale: 1 });
          const containerWidth = canvasContainer.clientWidth - 40;
          scale = containerWidth / viewport.width;
          updateZoomInput();
          await renderPage(currentPage);
        });

        fitPageBtn.addEventListener('click', async () => {
          fitMode = 'page';
          const page = await pdfDoc.getPage(currentPage);
          const viewport = page.getViewport({ scale: 1 });
          const containerWidth = canvasContainer.clientWidth - 40;
          const containerHeight = canvasContainer.clientHeight - 40;
          const scaleX = containerWidth / viewport.width;
          const scaleY = containerHeight / viewport.height;
          scale = Math.min(scaleX, scaleY);
          updateZoomInput();
          await renderPage(currentPage);
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
          if (e.key === 'ArrowLeft' && currentPage > 1) {
            prevBtn.click();
          } else if (e.key === 'ArrowRight' && currentPage < pageCount) {
            nextBtn.click();
          } else if (e.key === '+' || e.key === '=') {
            zoomInBtn.click();
          } else if (e.key === '-') {
            zoomOutBtn.click();
          }
        });

        // Initialize
        loadPdf();
      </script>
    </body>
    </html>
    ''';

    // Create blob URL
    final blob = html.Blob([htmlContent], 'text/html');
    _blobUrl = html.Url.createObjectUrlFromBlob(blob);

    // Create iframe element
    final iframeElement = html.IFrameElement()
      ..src = _blobUrl
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
