# PDF Opener Quick Start Guide

This guide helps you quickly test and deploy the PDF opener functionality in OpenPDF Tools.

## Quick Overview

OpenPDF Tools is now registered as a system PDF handler across all platforms. Users can:
- Open PDFs directly from their file manager
- Use "Open with" context menus
- Set OpenPDF Tools as the default PDF viewer
- Use the `openpdf://` URI scheme for deep linking

## Platform Setup Checklist

### Android ✓
- [x] Intent filters configured in `AndroidManifest.xml`
- [x] Method channel handler implemented in `MainActivity.kt`
- [x] Automatically registered (no manual setup needed)

**Test:**
```bash
# From a PDF file in Android file manager:
# 1. Tap the PDF file
# 2. Select "Open with" → "OpenPDF Tools"
```

### iOS ✓
- [x] Document types registered in `Info.plist`
- [x] URL scheme configured for deep links
- [x] Automatically registered at app installation

**Test:**
```bash
# In iOS Files app:
# 1. Locate a PDF file
# 2. Tap file → "Open" → Select "OpenPDF Tools"
# 3. To set as default: Settings → [App name] → Default PDF Viewer
```

### macOS ✓
- [x] Document types registered in `Info.plist`
- [x] URL scheme configured
- [x] Automatically registered on app launch

**Test:**
```bash
# In Finder:
# 1. Right-click a PDF file
# 2. "Open With" → "OpenPDF Tools"
# 3. To set as default: Right-click → "Always Open With" → "OpenPDF Tools"
```

### Windows ✓
- [x] C++ registry handler implemented (`pdf_opener_handler.cpp`)
- [x] Method channel integration in `flutter_window.cpp`
- [x] CMakeLists.txt updated for compilation
- [x] Ready to register at runtime

**Test:**
```cmd
REM After building, register:
cd windows\runner

REM Check if registration method is available:
REM The app can call PDFOpenerService().registerAsPdfOpener()

REM Or manually test:
REM 1. Right-click PDF file
REM 2. "Open with" → "Choose another app" → "OpenPDF Tools"
REM 3. Check "Always use this app to open PDF files"
```

### Linux ✓
- [x] .desktop file created with MIME types
- [x] MIME type XML definitions added
- [x] Registration script provided
- [x] Ready for deployment

**Test - Automatic:**
```bash
# Run the registration script:
chmod +x linux/register_pdf_opener.sh
./linux/register_pdf_opener.sh
```

**Test - Manual:**
```bash
# Register MIME types:
xdg-mime default openpdf_tools.desktop application/pdf
xdg-mime default openpdf_tools.desktop x-scheme-handler/openpdf

# Verify:
xdg-mime query default application/pdf
```

## Integration Steps

### 1. For Flutter App Dev/Testing

The PDF opener service is already initialized in main.dart:

```dart
// In _OpenPDFToolsAppState.initState()
_pdfOpenerService = PDFOpenerService();
_pdfOpenerService.initialize(
  onPdfFileReceived: _handlePdfFileFromSystem,
);
```

No additional code changes needed. The service automatically:
- Listens for system PDF opening events
- Extracts file paths from various sources
- Routes PDF files to the viewer screen

### 2. For Packaging/Distribution

#### Android
```bash
# Build APK/AAB - no special steps needed
flutter build apk
flutter build appbundle
```

#### iOS
```bash
# Build iOS app - Info.plist already configured
flutter build ios
```

#### macOS
```bash
# Build macOS app
flutter build macos
```

#### Windows
```bash
# Build Windows app - registry setup happens at runtime
flutter build windows
# After first launch, registry entries are created
```

#### Linux
```bash
# Build Linux app
flutter build linux

# For snap:
# Add register script to snap hooks
# Post-install: run register_pdf_opener.sh

# For AppImage/deb:
# Include the .desktop and .xml files
# Run register script in post-install
```

## Testing the Functionality

### Test 1: System File Opening

**Android:**
```
1. Copy a PDF to Downloads
2. Open Files app → Download
3. Tap PDF → "Open with" → "OpenPDF Tools"
```

**iOS/macOS:**
```
1. Open Files app with a PDF
2. Right-click → "Open With" → "OpenPDF Tools"
```

**Windows:**
```
1. Right-click PDF file
2. Select "Open with" → "OpenPDF Tools"
```

**Linux:**
```
1. After running register_pdf_opener.sh:
2. Right-click PDF → Properties → Open With
3. Select "OpenPDF Tools"
```

### Test 2: Deep Linking

**Test with openpdf:// scheme:**

Android/iOS (from browser):
```html
<a href="openpdf://file/sdcard/Documents/test.pdf">Open PDF</a>
```

Windows/Linux (from terminal):
```bash
# Windows
start openpdf://file/C:/Users/Documents/test.pdf

# Linux
xdg-open openpdf://file/home/user/Documents/test.pdf
```

### Test 3: Multiple PDF Formats

The app should handle:
- Regular PDF files (.pdf)
- Content URIs (Android)
- File URIs (file://)
- Custom URIs (openpdf://)

## Common Issues & Solutions

### Issue: "Can't find app" when opening PDF

**Android:**
- Clear app cache: `adb shell pm clear com.ahsmobilelabs.openpdf_tools`
- Reinstall the app
- Check Android 11+ permissions

**Windows:**
- Run registry check: `assoc .pdf` - verify it points to OpenPDFDocument
- May need administrator rights for system-wide registration

**Linux:**
- Run: `xdg-mime query default application/pdf`
- Ensure `openpdf_tools.desktop` exists in `~/.local/share/applications/`

### Issue: File path not recognized

**Check:**
```dart
// Add debug logging in _handlePdfFileFromSystem()
debugPrint('Received path: $filePath');
debugPrint('File exists: ${File(filePath).existsSync()}');
debugPrint('Is PDF: ${filePath.toLowerCase().endsWith('.pdf')}');
```

### Issue: Registration script fails on Linux

```bash
# Check permissions
ls -la linux/register_pdf_opener.sh

# Make executable
chmod +x linux/register_pdf_opener.sh

# Run with verbose output
bash -x linux/register_pdf_opener.sh
```

## File Checklist

Verify these files are present and properly configured:

- [x] `lib/services/pdf_opener_service.dart` - Main service
- [x] `lib/main.dart` - Updated with service initialization
- [x] `android/app/src/main/AndroidManifest.xml` - Intent filters added
- [x] `android/app/src/main/kotlin/.../MainActivity.kt` - Method channel handler
- [x] `ios/Runner/Info.plist` - Document types configured
- [x] `macos/Runner/Info.plist` - Document types configured
- [x] `windows/runner/pdf_opener_handler.h` - Registry handler header
- [x] `windows/runner/pdf_opener_handler.cpp` - Registry handler implementation
- [x] `windows/runner/flutter_window.cpp` - Method channel integration
- [x] `windows/runner/CMakeLists.txt` - Build configuration updated
- [x] `linux/openpdf_tools.desktop` - Desktop entry file
- [x] `linux/mimetypes.xml` - MIME type definitions
- [x] `linux/register_pdf_opener.sh` - Registration script

## Next Steps

1. **Build and Test:**
   - Build for each target platform
   - Test PDF opening from file manager
   - Verify file path is correctly extracted

2. **Set as Default (Optional):**
   - Android: User selects "Always" in chooser
   - iOS/macOS: User sets in system settings
   - Windows: User checks "Always use this app"
   - Linux: Use `xdg-mime default`

3. **Packaging:**
   - Include all modified files in release
   - For Linux: Run registration script in post-install
   - Test with sample PDF files

4. **Documentation for Users:**
   - Create user guide for setting OpenPDF Tools as default
   - Include platform-specific screenshots
   - Provide troubleshooting links

## Version History

- **v1.0** - Initial PDF opener implementation
  - Android intent filters
  - iOS/macOS document type registration
  - Windows registry handler
  - Linux MIME type associations
  - Cross-platform service layer
  - Deep link support (openpdf://)

## Support Resources

- Full documentation: [PDF_OPENER_IMPLEMENTATION.md](PDF_OPENER_IMPLEMENTATION.md)
- Platform-specific guides:
  - [Android Intent Filters](https://developer.android.com/guide/components/intents-filters)
  - [iOS Document Types](https://developer.apple.com/documentation/macos/uniform_type_identifiers)
  - [Windows File Associations](https://docs.microsoft.com/en-us/windows/win32/shell/fa-file-types)
  - [Linux Desktop Standards](https://specifications.freedesktop.org/desktop-entry-spec/)
