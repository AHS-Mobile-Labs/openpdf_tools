# PDF Opener Registration Implementation Guide

This document describes the implementation of registering OpenPDF Tools as the default PDF opener across all supported platforms (Android, iOS, macOS, Windows, and Linux).

## Overview

The application has been enhanced to register itself as a system-level PDF opener. When users interact with PDF files in their file manager or other applications, OpenPDF Tools will appear in the "Open with" menu and can be set as the default PDF handler.

## Architecture

### Components

1. **PDFOpenerService** (`lib/services/pdf_opener_service.dart`)
   - Central Dart service that manages PDF file opening across all platforms
   - Handles platform-specific method channels
   - Manages deep linking for the `openpdf://` URI scheme
   - Provides unified interface for registering as PDF opener

2. **Platform-Specific Configurations**
   - Android: `AndroidManifest.xml` with intent filters
   - iOS/macOS: `Info.plist` entries for document type associations
   - Windows: Native C++ registry handling with method channel
   - Linux: `.desktop` file and MIME type definitions

3. **Integration Point** (`lib/main.dart`)
   - Initializes `PDFOpenerService` in the app's main state
   - Receives callbacks when PDF files are opened via system intent

## Platform-Specific Implementation Details

### Android

**Files Modified:**
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/ahsmobilelabs/openpdf_tools/MainActivity.kt`

**How It Works:**
1. Intent filters in `AndroidManifest.xml` register the app for:
   - `android.intent.action.VIEW` with MIME type `application/pdf`
   - File URI schemes with `.pdf` extension
   - Content URI access for PDF files
   - Deep links with `openpdf://file/path` scheme

2. The `MainActivity.kt` intercepts these intents and:
   - Extracts the file path from the intent
   - Handles various URI schemes (file://, content://, openpdf://)
   - Communicates the file path to the Flutter layer via method channel

**Launch from System:**
When a user opens a PDF file from the file manager or another app, the system shows a chooser dialog including OpenPDF Tools.

**Registration:**
The app automatically registers through the manifest configuration. No runtime registration is needed for basic functionality.

### iOS

**Files Modified:**
- `ios/Runner/Info.plist`

**Configuration Added:**
- `CFBundleDocumentTypes`: Declares the app can handle PDF documents
  - Defines `com.adobe.pdf` as the MIME type (UTType)
  - Sets handler rank as "Alternate" (not default, allowing user choice)

- `CFBundleURLTypes`: Registers the `openpdf://` URL scheme for deep linking

**How It Works:**
1. iOS reads the `Info.plist` configuration at app installation
2. The system registers OpenPDF Tools as a capable PDF handler
3. Users can set it as default in Settings > Default Apps

**Limitations:**
- iOS users may need to set the app as default through system settings
- Apps cannot programmatically change the default handler in modern iOS versions

### macOS

**Files Modified:**
- `macos/Runner/Info.plist`

**Configuration Added:**
- `CFBundleDocumentTypes`: Similar to iOS but includes both:
  - `CFBundleTypeOSTypes`: Legacy type codes for backward compatibility
  - `LSItemContentTypes`: Modern UTType encoding

- `CFBundleURLTypes`: Registers the `openpdf://` URL scheme

**How It Works:**
1. macOS reads the `Info.plist` at app launch
2. The Finder and other apps can open PDFs with this app
3. Users can set as default via Right-click > "Open With" > "Always Open With"

### Windows

**Files Modified:**
- `windows/runner/main.cpp`
- `windows/runner/flutter_window.cpp`
- `windows/runner/pdf_opener_handler.h` (new)
- `windows/runner/pdf_opener_handler.cpp` (new)
- `windows/runner/CMakeLists.txt`

**How It Works:**
1. The `PDFOpenerHandler` class provides Windows registry operations:
   - Registers file extension associations (`.pdf`)
   - Creates ProgID entries for the application
   - Sets up context menu handlers
   - Registers the URI scheme (`openpdf://`)

2. Registry entries are created in `HKEY_CURRENT_USER\Software\Classes\`:
   ```
   .pdf -> OpenPDFDocument
   OpenPDFDocument\shell\open\command -> "path\to\openpdf_tools.exe %1"
   openpdf -> "URL Protocol handler"
   ```

3. The method channel receives `registerPdfOpener` calls from Dart and executes registry operations

**Elevation:**
- User registry (HKCU) modifications don't require elevation
- For system-wide registration (HKLM), administrator rights are needed

**Function:**
Call `PDFOpenerService().registerAsPdfOpener()` to register at runtime

### Linux

**Files Modified:**
- `linux/openpdf_tools.desktop` (new)
- `linux/mimetypes.xml` (new)
- `linux/register_pdf_opener.sh` (new)

**How It Works:**
1. **Desktop Entry** (`openpdf_tools.desktop`):
   - Provides metadata about the application
   - Lists MIME types it can handle (`application/pdf`)
   - Registers the URI scheme handler

2. **MIME Type Definition** (`mimetypes.xml`):
   - Defines custom MIME type handlers
   - Associates `x-scheme-handler/openpdf` for deep links

3. **Registration Script** (`register_pdf_opener.sh`):
   - Copies `.desktop` file to `~/.local/share/applications/`
   - Installs MIME type definitions
   - Updates system databases (MIME, desktop, icon caches)
   - Sets as default using `xdg-mime`

**Installation Steps:**
```bash
# Make the script executable
chmod +x linux/register_pdf_opener.sh

# Run the registration script
./linux/register_pdf_opener.sh
```

**Manual Registration:**
If the script doesn't work, manually register using:
```bash
xdg-mime default openpdf_tools.desktop application/pdf
xdg-mime default openpdf_tools.desktop x-scheme-handler/openpdf
```

## Dart Implementation

### PDFOpenerService Class

**Key Methods:**

```dart
// Initialize with callback
await _pdfOpenerService.initialize(
  onPdfFileReceived: (filePath) {
    // Handle the PDF file
  },
);

// Register as PDF opener (platform-specific)
bool success = await _pdfOpenerService.registerAsPdfOpener();

// Check if a file is PDF
bool isPdf = PDFOpenerService.isPdfFile(filePath);
```

**Event Flow:**
1. Service initializes app links listener in `initialize()`
2. When system opens PDF with this app:
   - Platform channel receives intent/deep link
   - File path is extracted
   - Callback is invoked with file path
3. App navigates to PDF viewer with the file

### Deep Linking Support

The app supports the custom URI scheme `openpdf://`:

```
openpdf://file/path/to/document.pdf
```

This allows:
- Direct PDF file opening via hyperlinks
- Custom protocol handlers
- Testing and automation

## Usage Instructions

### For End Users

**Android:**
1. Open a PDF file in your file manager
2. Choose "Open with" → Select "OpenPDF Tools"
3. Optionally set as default by checking "Always open with"

**iOS/macOS:**
1. Right-click a PDF file → "Open With" → OpenPDF Tools
2. Set as default in system Settings (macOS: Right-click → "Always Open With")

**Windows:**
1. Right-click a PDF file → "Open with" → "Choose another app"
2. Select "OpenPDF Tools"
3. Check "Always use this app to open PDF files"

**Linux:**
1. Run `./linux/register_pdf_opener.sh` after installation
2. Or manually use: `xdg-mime default openpdf_tools.desktop application/pdf`
3. Right-click PDF → "Open With" → Select OpenPDF Tools

### For Developers

**Testing PDF Opening:**

```dart
// In your test or development code:
final pdfService = PDFOpenerService();
await pdfService.initialize(
  onPdfFileReceived: (path) {
    print('Received PDF: $path');
  },
);

// Simulate opening via system
await pdfService.openPdfFile('/path/to/test.pdf');
```

**Registering Programmatically:**

```dart
// Register as PDF opener (Windows/Android)
bool success = await PDFOpenerService().registerAsPdfOpener();
if (success) {
  print('Successfully registered as PDF opener');
}
```

## Technical Specifications

### Method Channel Communication

**Channel Name:** `com.openpdf.tools/pdfOpener`

**Available Methods:**

| Method | Platform | Arguments | Returns | Purpose |
|--------|----------|-----------|---------|---------|
| `registerPdfOpener` | Android, Windows | None | bool | Register as PDF opener |
| `getReceivedPdfPath` | Android | None | String? | Get path from intent |
| `openPdf` | All | String (path) | None | Invoke from platform to notify Dart |

### Registry Entries (Windows)

```
HKEY_CURRENT_USER
├─ Software
│  └─ Classes
│     ├─ .pdf
│     │  └─ (Default) = "OpenPDFDocument"
│     ├─ OpenPDFDocument
│     │  ├─ (Default) = "PDF Document - OpenPDF Tools"
│     │  ├─ DefaultIcon
│     │  │  └─ (Default) = "C:\path\to\openpdf_tools.exe,0"
│     │  └─ shell
│     │     └─ open
│     │        └─ command
│     │           └─ (Default) = "C:\path\to\openpdf_tools.exe \"%1\""
│     └─ openpdf
│        ├─ (Default) = "URL:OpenPDF Handler"
│        ├─ URL Protocol = ""
│        ├─ DefaultIcon
│        │  └─ (Default) = "C:\path\to\openpdf_tools.exe,0"
│        └─ shell
│           └─ open
│              └─ command
│                 └─ (Default) = "C:\path\to\openpdf_tools.exe \"%1\""
```

### Plist Entries (iOS/macOS)

**Document Types:**
```xml
<dict>
  <key>CFBundleTypeName</key>
  <string>PDF Document</string>
  <key>LSItemContentTypes</key>
  <array>
    <string>com.adobe.pdf</string>
  </array>
  <key>LSHandlerRank</key>
  <string>Alternate</string>
</dict>
```

**URL Schemes:**
```xml
<dict>
  <key>CFBundleTypeRole</key>
  <string>Editor</string>
  <key>CFBundleURLName</key>
  <string>com.openpdf.tools</string>
  <key>CFBundleURLSchemes</key>
  <array>
    <string>openpdf</string>
  </array>
</dict>
```

### Android Intent Filters

```xml
<!-- MIME type handler -->
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:mimeType="application/pdf"/>
</intent-filter>

<!-- File extension handler -->
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <data android:scheme="file" android:pathPattern=".*\\.pdf" android:mimeType="application/pdf"/>
</intent-filter>

<!-- Content URI handler -->
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <data android:scheme="content" android:mimeType="application/pdf"/>
</intent-filter>

<!-- Deep link handler -->
<intent-filter android:autoVerify="false">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="openpdf" android:host="file"/>
</intent-filter>
```

## Troubleshooting

### Android

**Problem:** App doesn't appear in "Open with" menu
- Ensure `android:exported="true"` in AndroidManifest.xml
- Check that intent filters are properly nested in the MainActivity activity
- Clear app cache: `adb shell pm clear com.ahsmobilelabs.openpdf_tools`

**Problem:** File path not received
- Verify Android permissions: READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
- Check logcat for method channel errors

### iOS/macOS

**Problem:** App not listed in "Open With" menu
- Rebuild the application after modifying Info.plist
- Check that `CFBundleDocumentTypes` is properly formatted in plist
- Verify the UTType `com.adobe.pdf` is correctly spelled

### Windows

**Problem:** Registry entries not created
- Run with administrator privileges for system-wide registration
- Check Windows Defender doesn't block registry access
- Verify C++ compilation succeeds

**Problem:** App doesn't open when double-clicking PDF
- Ensure registry entries exist in HKCU\Software\Classes\
- Use `assoc` and `ftype` commands to verify associations:
  ```cmd
  assoc .pdf
  ftype.pdf
  ```

### Linux

**Problem:** `register_pdf_opener.sh` permission denied
- Ensure script is executable: `chmod +x register_pdf_opener.sh`
- Run from the correct directory

**Problem:** MIME database not updated
- Install required package: `sudo apt install shared-mime-info`
- Manually update: `update-mime-database ~/.local/share/mime`

**Problem:** xdg-mime command not found
- Install xdg-utils package (usually pre-installed)
- Alternative: Edit `~/.config/mimeapps.list` manually

## Security Considerations

1. **File Access Verification:**
   - Service verifies file exists before attempting to open
   - Checks file extension for security

2. **URI Scheme Validation:**
   - Deep links are validated before processing
   - Malformed URIs are safely ignored

3. **Platform-Specific Permissions:**
   - Android: Respects system file permissions
   - Windows: Uses user-level registry (no system-wide access needed for basic functionality)
   - Linux: Follows XDG Desktop standards

## Future Enhancements

1. **iOS App Shortcuts Integration:**
   - Add support for iOS App Shortcuts for enhanced automation

2. **Advanced Context Menu Options:**
   - Windows: Add "Open as PDF" context menu for other formats
   - macOS: Implement services menu for document conversion

3. **Cloud Integration:**
   - Support opening PDFs from cloud storage
   - Add recent files sync

4. **Default Handler Management UI:**
   - Create in-app settings to manage file associations
   - Show current default handler status

## References

- [Android Intent Filters Documentation](https://developer.android.com/guide/components/intents-filters)
- [iOS Document Types](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html)
- [macOS Bundle Programming Guide](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html)
- [Windows Registry for File Associations](https://docs.microsoft.com/en-us/windows/win32/shell/fa-file-types)
- [Linux Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html)
- [XDG MIME Applications Specification](https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-latest.html)

## Support

For issues or questions regarding PDF opener functionality:
1. Check the troubleshooting section above
2. Review platform-specific logs (logcat for Android, Console for macOS, Event Viewer for Windows)
3. Verify all files mentioned in this guide have been properly created/modified
