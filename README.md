<div align="center">
  <img src="asset/app_img/OpenPDF Tools.png" alt="OpenPDF Tools Logo" width="200" height="200">
</div>

# OpenPDF Tools

A professional, feature-rich Flutter application for comprehensive PDF management and manipulation. Seamlessly view, convert, compress, and edit PDF files across **desktop and mobile platforms** with an intuitive and modern interface.

**Version**: 1.0.0 | **Language**: Dart | **Framework**: Flutter 3.10.7+

> Open-source PDF toolkit with support for 50+ file formats and 6 platforms

---

## � Table of Contents

- [Download](#️-download-openpdf-tools)
- [Features](#-features)
- [Platform Support](#-platform-support)
- [Optimization Information](#️-optimization-information)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Dependencies](#-dependencies)
- [Customization](#-customization)
- [Security & Permissions](#-security--permissions)
- [UI Design](#-ui-design)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---
## ⬇️ Download OpenPDF Tools

OpenPDF Tools will soon be available on the following platforms:

- **Google Play Store (Android)** – 🚧 Initial stage, coming soon  
- **SourceForge (Linux & Windows)** – 🚧 Coming soon  
- **Web Version** – 🚧 Coming soon  
- **Apple App Store (iOS)** – 🚧 Coming soon  
- **macOS Direct Download** – 🚧 Coming soon  
- **Indus App Store** – 🚧 Coming soon  
- **Samsung Galaxy Store** – 🚧 Coming soon  

Stay tuned for official release announcements.
---

## ✨ Features

### 📋 Core Tools
- **PDF Viewer** - Professional PDF viewing with password-protected document support
- **PDF Compression** - Intelligent file size reduction while preserving quality
- **Image to PDF** - Convert images (JPG, PNG, WEBP, HEIC, TIFF, GIF, BMP) into PDF documents
- **PDF Conversion** - Export PDFs to 13+ popular formats
- **PDF Editor** - Add text, annotations, and make modifications
- **Merge PDF** - Combine PDFs in the order you want with the easiest PDF merger available
- **Split PDF** - Separate one page or a whole set for easy conversion into independent PDF files
- **Sign PDF** - 🆕 Production-grade digital signatures with enterprise security
- **Smart History** - Auto-manage 50 recent files with quick access favorites

### 🚀 Advanced Capabilities
- **Digital Signatures** - Secure PDF signing with certificate validation and expiry detection
- **Cross-Platform Sharing** - Seamless file sharing with Android Intent integration
- **Smart File Browser** - Fast directory navigation with permission handling
- **Persistent Storage** - Local history management using SharedPreferences
- **Real-Time Validation** - Comprehensive error handling and file verification
- **Responsive UI** - Adaptive layouts for mobile, tablet, and desktop

---

## 🌍 Platform Support

| Platform | Support | Min Version |
|----------|---------|-------------|
| 🤖 Android | ✅ Full | API 21+ |
| 🍎 iOS | ✅ Full | 13.0+ |
| 💻 macOS | ✅ Full | 10.15+ |
| 🐧 Linux | ✅ Full | GTK 3.0+ |
| 🪟 Windows | ✅ Full | 10+ |
| 🌐 Web | ✅ Full | Modern browsers |

---

## ⚡ Optimization Information

This project has been **fully optimized for cross-platform development** with comprehensive responsive design and platform-specific features:

### Responsive Design
- **Mobile** (< 600px): 2-column grid + bottom navigation
- **Tablet** (600-1200px): 3-column grid + side navigation  
- **Desktop** (≥ 1200px): 4-column grid + full sidebar

### Platform-Specific Optimizations
- **Mobile**: Native navigation patterns, permission handling, share intents
- **Desktop**: Keyboard shortcuts, window management, native file dialogs
- **Web**: PWA support, service workers, offline capabilities

### Key Utilities Added
- `PlatformHelper` - Platform detection and recommendations
- `ResponsiveHelper` - Responsive layout system
- `PlatformFileHandler` - Cross-platform file operations
- `AdaptiveNavigation` - Responsive navigation widget

### Documentation
For detailed information, see:
- [OPTIMIZATIONS_SUMMARY.md](./documentation/production/OPTIMIZATIONS_SUMMARY.md) - Overview of all optimizations
- [PLATFORM_OPTIMIZATION_GUIDE.md](./documentation/platform-setup/PLATFORM_OPTIMIZATION_GUIDE.md) - Detailed platform guide
- [MULTI_PLATFORM_SETUP.md](./documentation/platform-setup/MULTI_PLATFORM_SETUP.md) - Setup and deployment guide

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- **Flutter**: 3.10.7 or higher
- **Dart**: 3.10.7 or higher
- **Git**: For version control

```bash
# Verify Flutter installation
flutter --version
```

### Installation

**Step 1: Clone the Repository**
```bash
git clone https://github.com/AHS-Mobile-Labs/openpdf_tools.git
cd openpdf_tools
```

**Step 2: Install Dependencies**
```bash
flutter pub get
```

**Step 3: Run the Application**

```bash
# Development mode (hot reload enabled)
flutter run

# Select your target device/emulator when prompted
```

### Building for Production

**Android**
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk

flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS**
```bash
flutter build ios --release
# Open the generated build in Xcode for App Store submission
```

**Desktop Platforms**
```bash
# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

**Web**
```bash
flutter build web --release
```

---

## 📦 Dependencies

OpenPDF Tools uses carefully curated packages for optimal performance and reliability:

### PDF & Printing
| Package | Version | Purpose |
|---------|---------|---------|
| `pdf` | 3.10.7 | PDF generation and creation |
| `printing` | 5.12.0 | Cross-platform print support |
| `syncfusion_flutter_pdfviewer` | 32.2.4 | Advanced PDF viewing capabilities |
| `pdfrx_engine` | 0.3.9 | Desktop-optimized PDF rendering |

### File & Media Management
| Package | Version | Purpose |
|---------|---------|---------|
| `file_picker` | 10.3.10 | Cross-platform file selection |
| `image_picker` | 1.0.7 | Image capture and selection |
| `image` | 4.0.17 | Image processing and manipulation |
| `flutter_image_compress` | 2.2.0 | Efficient image compression |
| `receive_sharing_intent` | 1.8.1 | Android share intent handling |

### System & Storage
| Package | Version | Purpose |
|---------|---------|---------|
| `path_provider` | 2.1.2 | Platform-specific directory access |
| `path` | 1.8.3 | Path manipulation utilities |
| `shared_preferences` | 2.2.0 | Local persistent storage |
| `permission_handler` | 12.0.1 | Unified permission management |
| `share_plus` | 12.0.1 | Cross-platform file sharing |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `intl` | 0.19.0 | Internationalization & date formatting |
| `cupertino_icons` | 1.0.8 | iOS-style icons |

See [pubspec.yaml](pubspec.yaml) for the complete dependency list with exact versions.

---

## 🏗️ Project Structure

```
lib/
├── main.dart                              # 🎯 App entry point and theme setup
├── screens/                               # 🎨 Feature screens
│   ├── home_screen.dart                  # Navigation hub with tool cards
│   ├── pdf_viewer_screen.dart            # PDF viewing and review
│   ├── compress_pdf_screen.dart          # PDF compression utility
│   ├── convert_to_pdf_screen.dart        # Convert images & files to PDF
│   ├── pdf_from_images_screen.dart       # Multi-image to PDF converter
│   ├── convert_from_pdf_screen.dart      # Export PDF to other formats
│   ├── edit_pdf_screen.dart              # PDF annotation and editing
│   └── history_screen.dart               # Recent files and favorites
├── services/                              # ⚙️ Core business logic
│   └── file_history_service.dart         # History and favorites management
└── widgets/                               # 🧩 Reusable UI components
    └── in_app_file_picker.dart           # Custom file browser dialog
```

### Architecture Highlights

**Service Layer (`file_history_service.dart`)**
- Manages up to 50 recent files with timestamps
- Bookmark system for frequently used documents
- Automatic path tracking for renamed files
- Persistent storage using SharedPreferences

**UI Layer**
- Material Design 2 compliance
- Responsive grid layouts (adaptive columns)
- Touch-optimized interactions
- Smooth animations and transitions

**File Picker System**
- Directory navigation with breadcrumbs
- Extension-based filtering
- Permission management
- Mobile gallery integration

---

## 🎨 Customization

### Theme Configuration

Modify the app theme by editing [main.dart](lib/main.dart):

```dart
const Color _primaryColor = Color(0xFFC6302C);      // Main brand color
const Color _darkRedColor = Color(0xFF9A0000);      // Accent color
const String _appTitle = 'OpenPDF Tools';           // App display name
const String _appVersion = '1.0.0';                 // Version string
```

### Adding New Tools

To add a new PDF tool to the application:

1. **Create Screen**: Add a new file in `lib/screens/` (e.g., `my_tool_screen.dart`)
2. **Implement Logic**: Build your tool's functionality using Flutter widgets
3. **Add Route**: Register the route in `HomeScreen`
4. **Add Card**: Create a `_ToolCard` widget in the home grid
5. **Test**: Build and test the new feature

Example:
```dart
// In home_screen.dart
_ToolCard(
  title: 'My New Tool',
  icon: Icons.build,
  onTap: () => Navigator.push(...),
)
```

---

## 🔒 Security & Permissions

### Android Permissions

The app requests the following permissions:

```xml
<!-- Reading files -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_ALL" />

<!-- Writing converted/compressed files -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**Why these permissions?**
- Files must be read from device storage to process PDFs
- Conversion and compression results must be saved to accessible locations
- Android prompts users to grant these at runtime (Scoped Storage)

### iOS Permissions

The app requires:
- **Photo Library Access** - For image selection during PDF creation
- **File System Access** - For document handling (requested via `Info.plist`)

### Security Best Practices

✅ Implemented in OpenPDF Tools:
- All file I/O operations wrapped in try-catch blocks
- Proper resource cleanup on app lifecycle events
- Secure temporary file handling with automatic deletion
- Input validation on all file paths
- Error logging for debugging (without exposing sensitive data)

---

## 📱 UI Design

### Responsive Layouts
- **Mobile**: 2-column grid optimized for touch
- **Tablet**: 3+ columns with flexible spacing
- **Desktop**: Full-width responsive adaptation

### Design System
- **Framework**: Material Design 2
- **Primary Color**: #C6302C (Professional Red)
- **Accent**: #9A0000 (Deep Red)
- **Font**: System default for platform
- **Animations**: Smooth transitions and micro-interactions

### Accessibility
- Semantic HTML/Material components
- Touch target size: 48x48 dp minimum
- High contrast mode support
- Screen reader compatible

---

## 🐛 Troubleshooting

### Common Issues & Solutions

#### ❌ File Picker Not Working (Android)
```bash
# Solution: Ensure dependencies and permissions are properly set up
flutter pub get
flutter clean
flutter pub get
flutter run
```
**Fix**: Also check that `AndroidManifest.xml` includes storage permissions.

#### ❌ PDF Viewer Crashes
```bash
# Solution: Update the Syncfusion package
flutter pub upgrade syncfusion_flutter_pdfviewer
flutter clean
flutter run
```
**Note**: Syncfusion PdfViewer requires specific permissions on newer Android versions.

#### ❌ Image Compression Failing
```bash
# Solution: Verify system resources
- Check available disk space: At least 500MB free
- Check RAM usage: Close background apps
- Check file permissions: Ensure write access to temp directory
```
**Debug**: Check `flutter logs` for detailed error messages.

#### ❌ "Path not found" on File Operations
- **Android 10+**: Ensure you're using `getExternalFilesDir()` instead of direct paths
- **iOS**: Check `Info.plist` for required document access permissions

#### ❌ Sharing Not Working (Android)
```bash
# Solution: Verify FileProvider is configured
# Check android/app/src/main/AndroidManifest.xml for:
<provider android:name="androidx.core.content.FileProvider" ... />
```

### Debug Mode

Enable verbose logging:
```bash
flutter run -v
# or
flutter logs
```

---

## 🤝 Contributing

We welcome contributions! Here's how to get involved:

### Development Workflow

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/AHS-Mobile-Labs/openpdf_tools.git
   cd openpdf_tools
   ```
3. **Create** a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. **Commit** your changes:
   ```bash
   git commit -m 'Add amazing feature'
   ```
5. **Push** to your branch:
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open** a Pull Request with a clear description

### Code Guidelines

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) conventions:

- ✅ Use meaningful names: `getUserFiles()` not `getUF()`
- ✅ Document public APIs: Add dartdoc comments
- ✅ Format code: `dart format lib/`
- ✅ Analyze code: `flutter analyze` (must pass)
- ✅ Write tests: Add tests for new features

Example:
```dart
/// Compresses a PDF file and returns the compressed file path.
/// 
/// [inputPath] must be a valid PDF file path.
/// [quality] should be between 0.0 and 1.0.
Future<String> compressPdf(String inputPath, {double quality = 0.8}) async {
  // Implementation...
}
```

### Testing

Before submitting, run the test suite:
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

---

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for full details.

**Summary**: Feel free to use, modify, and distribute this software, with proper attribution.

---

## 💬 Support & Community

### Getting Help

- 📋 **Report Issues**: [GitHub Issues](https://github.com/AHS-Mobile-Labs/openpdf_tools/issues)
- 💬 **Discuss Ideas**: [GitHub Discussions](https://github.com/AHS-Mobile-Labs/openpdf_tools/discussions)
- 📚 **Learn Flutter**: [Official Flutter Docs](https://flutter.dev/docs)
- 🎓 **Dart Guide**: [Effective Dart](https://dart.dev/guides/language/effective-dart)

### Resources

- [Flutter Documentation](https://flutter.dev)
- [Syncfusion PDF Viewer](https://www.syncfusion.com/flutter-widgets/flutter-pdf-viewer)
- [Dart Language](https://dart.dev)
- [Material Design](https://m2.material.io)

---

## 🙏 Acknowledgments

This project wouldn't be possible without:

- **[Flutter Team](https://flutter.dev/)** - Amazing framework for cross-platform development
- **[Syncfusion](https://www.syncfusion.com/)** - Professional PDF viewer component
- **[Dart Community](https://dart.dev/community)** - Continuously improving the language
- **Contributors** - Everyone who reports issues and submits improvements
- **Users** - Your feedback drives development priorities

---

## 📊 Project Stats

| Metric | Value |
|--------|-------|
| **Language** | Dart |
| **Framework** | Flutter 3.10.7+ |
| **Supported Platforms** | 6 (Android, iOS, macOS, Linux, Windows, Web) |
| **Total Dependencies** | 15+ |
| **Code Organization** | Modular & maintainable |
| **Code Quality** | Lint-free with clean architecture |
| **License** | MIT |
| **Open Source** | ✅ Yes |

---

## 🔄 Release History

### v1.0.0 (Current) - Released
- ✨ Initial public release
- 🎯 Full PDF viewing and manipulation
- 🔄 Multi-format conversion support
- 📱 Cross-platform mobile and desktop
- 🎨 Modern Material Design interface
- 🔒 Secure file handling

---

## 🚀 Future Roadmap

### Planned Features (Upcoming Releases)
- [ ] **Dark Mode** - System-wide dark theme support
- [ ] **Cloud Sync** - Google Drive & Dropbox integration
- [ ] **Advanced Editing** - Enhanced PDF annotation tools
- [ ] **Batch Operations** - Convert/compress multiple files
- [ ] **OCR Support** - Extract text from images and PDFs
- [ ] **Watermarking** - Add watermarks to PDFs
- [ ] **Digital Signatures** - Sign documents digitally
- [ ] **Localization** - Multi-language support (10+ languages)
- [ ] **Performance** - Further optimization for large files

---

## 📧 Get in Touch

**Author**: [Ameer Hamza Saifi](https://github.com/ameerhamzasaifi)

Found a bug? Have a suggestion? Open an issue or start a discussion!

---

**Made with ❤️ for the open-source community**

**Happy PDF Processing! 📄✨**

© 2026 AHS Mobile Labs
