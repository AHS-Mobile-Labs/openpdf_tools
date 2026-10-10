import 'dart:io' show Process;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformOpenerInfo {
  final String platformName;
  final String status;
  final String instructions;
  final bool canDirectRegister;

  const PlatformOpenerInfo({
    required this.platformName,
    required this.status,
    required this.instructions,
    required this.canDirectRegister,
  });
}

class PDFOpenerService {
  static const platform = MethodChannel('com.openpdf.tools/pdfOpener');
  static const String _pdfScheme = 'openpdf';
  static final PDFOpenerService _instance = PDFOpenerService._internal();
  late AppLinks _appLinks;
  Function(String pdfPath)? _onPdfFileReceived;
  PDFOpenerService._internal();
  factory PDFOpenerService() {
    return _instance;
  }

  Future<void> initialize({
    required Function(String pdfPath) onPdfFileReceived,
  }) async {
    try {
      _onPdfFileReceived = onPdfFileReceived;
      debugLog('[PDFOpenerService] Initializing service');
      try {
        _appLinks = AppLinks();
        debugLog('[PDFOpenerService] AppLinks initialized');
        _appLinks.uriLinkStream.listen(
          (uri) {
            _handleDeepLink(uri);
          },
          onError: (err) {
            debugLog('[PDFOpenerService] Error listening to app links: $err');
          },
        );
        debugLog('[PDFOpenerService] App links stream listener attached');
      } catch (e) {
        debugLog('[PDFOpenerService] Error with AppLinks: $e');
      }
      try {
        platform.setMethodCallHandler((call) async {
          debugLog('[PDFOpenerService] Platform method called: ${call.method}');
          if (call.method == 'openPdf') {
            final filePath = call.arguments as String?;
            if (filePath != null && filePath.isNotEmpty) {
              debugLog('[PDFOpenerService] Opening PDF: $filePath');
              _onPdfFileReceived?.call(filePath);
            }
          } else if (call.method == 'getPdfPath') {
            return await _getReceivedPdfPath();
          }
          return null;
        });
        debugLog('[PDFOpenerService] Platform method handler set');
      } catch (e) {
        debugLog('[PDFOpenerService] Error setting platform handler: $e');
      }
      debugLog('[PDFOpenerService] Initialization complete');
    } catch (e) {
      debugLog('[PDFOpenerService] Fatal error during initialization: $e');
      rethrow;
    }
  }

  void _handleDeepLink(Uri uri) {
    try {
      if (uri.scheme == _pdfScheme) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.contains('file') && pathSegments.length > 1) {
          final fileIndex = pathSegments.indexOf('file');
          final filePath = '/${pathSegments.sublist(fileIndex + 1).join('/')}';
          if (filePath.isNotEmpty) {
            _onPdfFileReceived?.call(filePath);
          }
        }
      }
    } catch (e) {
      debugLog('Error handling deep link: $e');
    }
  }

  Future<String?> _getReceivedPdfPath() async {
    try {
      final result = await platform.invokeMethod<String>('getReceivedPdfPath');
      return result;
    } catch (e) {
      debugLog('Error getting received PDF path: $e');
      return null;
    }
  }

  PlatformOpenerInfo getPlatformOpenerDetails() {
    if (PlatformHelper.isAndroid) {
      return const PlatformOpenerInfo(
        platformName: 'Android',
        status: 'Intent filters registered for PDF MIME & files',
        instructions:
            'When opening any PDF in Files, Downloads, or WhatsApp, tap "Open with" and select OpenPDF Tools. Choose "Always" to make it your default viewer.',
        canDirectRegister: true,
      );
    } else if (PlatformHelper.isIOS) {
      return const PlatformOpenerInfo(
        platformName: 'iOS',
        status: 'Document Interaction registered in Info.plist',
        instructions:
            'In iOS Files, Mail, or Safari, tap the Share icon on any PDF document and choose "OpenPDF Tools" to view or edit immediately.',
        canDirectRegister: false,
      );
    } else if (PlatformHelper.isWindows) {
      return const PlatformOpenerInfo(
        platformName: 'Windows',
        status: 'Windows file associations supported',
        instructions:
            'Right-click any .pdf file in File Explorer -> "Open with" -> "Choose another app" -> select OpenPDF Tools and check "Always use this app to open .pdf files".',
        canDirectRegister: true,
      );
    } else if (PlatformHelper.isMacOS) {
      return const PlatformOpenerInfo(
        platformName: 'macOS',
        status: 'macOS CFBundleDocumentTypes configured',
        instructions:
            'In Finder, right-click any .pdf file -> "Get Info" -> expand "Open with" -> select OpenPDF Tools -> click "Change All...".',
        canDirectRegister: false,
      );
    } else if (PlatformHelper.isLinux) {
      return const PlatformOpenerInfo(
        platformName: 'Linux',
        status: 'XDG MIME desktop associations supported',
        instructions:
            'Click below to set OpenPDF Tools as the default application/pdf handler via xdg-mime, or right-click any PDF in file manager -> Properties -> Open With.',
        canDirectRegister: true,
      );
    } else {
      return const PlatformOpenerInfo(
        platformName: 'Web',
        status: 'Web PWA drag-and-drop & file picker',
        instructions:
            'You can drag and drop any PDF file into the OpenPDF Tools browser tab or install the app via your browser\'s PWA Install button.',
        canDirectRegister: false,
      );
    }
  }

  Future<bool> registerAsPdfOpener() async {
    try {
      if (kIsWeb) {
        return false;
      }
      if (PlatformHelper.isAndroid) {
        return await _registerAndroidPdfOpener();
      } else if (PlatformHelper.isIOS) {
        return await _registerIOSPdfOpener();
      } else if (PlatformHelper.isMacOS) {
        return await _registerMacOSPdfOpener();
      } else if (PlatformHelper.isWindows) {
        return await _registerWindowsPdfOpener();
      } else if (PlatformHelper.isLinux) {
        return await _registerLinuxPdfOpener();
      }
      return false;
    } catch (e) {
      debugLog('Error registering PDF opener: $e');
      return false;
    }
  }

  Future<bool> _registerAndroidPdfOpener() async {
    try {
      final result = await platform.invokeMethod<bool>('registerPdfOpener');
      if (result == true) return true;
    } catch (e) {
      debugLog('Android native register error: $e');
    }
    return true;
  }

  Future<bool> _registerIOSPdfOpener() async {
    debugLog('iOS PDF opener registration is configured in Info.plist');
    return true;
  }

  Future<bool> _registerMacOSPdfOpener() async {
    debugLog('macOS PDF opener registration is configured in Info.plist');
    return true;
  }

  Future<bool> _registerWindowsPdfOpener() async {
    try {
      final result = await platform.invokeMethod<bool>('registerPdfOpener');
      if (result == true) return true;
    } catch (_) {}
    try {
      final uri = Uri.parse('ms-settings:defaultapps');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _registerLinuxPdfOpener() async {
    try {
      final res = await Process.run('xdg-mime', [
        'default',
        'openpdf_tools.desktop',
        'application/pdf',
      ]);
      return res.exitCode == 0;
    } catch (e) {
      debugLog('Linux xdg-mime error: $e');
      return true;
    }
  }

  static bool isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  static void debugLog(String message) {
    debugPrint('[PDFOpenerService] $message');
  }

  void dispose() {
    _onPdfFileReceived = null;
  }
}
