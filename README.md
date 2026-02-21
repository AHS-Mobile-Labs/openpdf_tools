# OpenPDF Tools

A professional, cross-platform Flutter application for comprehensive PDF management and manipulation. OpenPDF Tools provides an intuitive interface for viewing, converting, compressing, and editing PDF files with support for multiple file formats.

**Version**: 1.0.0

---

## 🚀 Features

### Core Functionality
- **PDF Viewer** - View and review PDF documents with full support for password-protected files
- **Compress PDF** - Reduce file size while maintaining quality for easy sharing and storage
- **Convert to PDF** - Convert multiple file formats into PDF:
  - Images (JPG, PNG, WEBP, HEIC, TIFF, GIF, BMP)
  - Documents via LibreOffice support
- **Convert from PDF** - Export PDF content to 13+ formats
- **Edit PDF** - Add text, annotations, and other modifications
- **History & Favorites** - Track recently accessed files and save favorites for quick access

### Advanced Features
- Platform-specific file sharing (Android integration)
- Fast file browser with directory navigation
- Permission handling for platform-specific storage access
- Local storage with SharedPreferences for history retention
- Support for 50 recent files with automatic cleanup
- Real-time file validation and error handling

---

## 📋 System Requirements

### Minimum Versions
- **Flutter**: 3.10.7 or higher
- **Dart**: 3.10.7 or higher
- **Android**: API 21+ (for Android devices)
- **iOS**: 13.0+ (for iOS devices)

### Platform Support
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Linux
- ✅ Windows
- ✅ Web

---

## 🛠️ Installation & Setup

### Prerequisites
Ensure you have Flutter installed and properly configured:

```bash
flutter --version
```

### Clone the Repository
```bash
git clone https://github.com/yourusername/openpdf_tools.git
cd openpdf_tools
```

### Install Dependencies
```bash
flutter pub get
```

### Running the Application

#### Development Mode
```bash
flutter run
```

#### Release Build
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Web
flutter build web --release
```

---

## 📦 Dependencies

The application uses carefully selected dependencies for optimal performance:

### PDF Management
- **pdf** (3.10.7) - PDF creation
- **printing** (5.12.0) - PDF printing support
- **syncfusion_flutter_pdfviewer** (32.2.4) - Feature-rich PDF viewer
- **pdfrx_engine** (0.3.9) - Desktop PDF rendering

### File Management
- **file_picker** (10.3.10) - Cross-platform file selection
- **image_picker** (1.0.7) - Image capture and selection
- **path_provider** (2.1.2) - System directory access
- **path** (1.8.3) - Path manipulation utilities

### Media & Sharing
- **image** (4.0.17) - Image processing
- **flutter_image_compress** (2.2.0) - Image compression
- **share_plus** (12.0.1) - Cross-platform file sharing
- **receive_sharing_intent** (1.8.1) - Android share intent handling

### Storage & Utilities
- **shared_preferences** (2.2.0) - Local persistent storage
- **permission_handler** (12.0.1) - Platform permission management
- **intl** (0.19.0) - Internationalization and date formatting

See [pubspec.yaml](pubspec.yaml) for complete dependency list.

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                          # App entry point and theme configuration
├── screens/                           # Feature screens
│   ├── home_screen.dart              # Main navigation hub
│   ├── compress_pdf_screen.dart      # PDF compression
│   ├── convert_to_pdf_screen.dart    # Convert files to PDF
│   ├── convert_from_pdf_screen.dart  # Export PDF to other formats
│   ├── edit_pdf_screen.dart          # PDF editing
│   ├── history_screen.dart           # Recent files and favorites
│   ├── pdf_viewer_screen.dart        # PDF viewing and review
│   └── pdf_from_images_screen.dart   # Image to PDF conversion
├── services/
│   └── file_history_service.dart     # Local history and favorites management
└── widgets/
    └── in_app_file_picker.dart       # Custom file browser dialog
```

### Key Components

#### FileHistoryService
Manages user file history and favorites using local storage:
- **History Management**: Stores up to 50 recent files with timestamps
- **Favorites**: Bookmark frequently used files
- **Path Tracking**: Update paths when files are renamed
- **Persistent Storage**: Uses SharedPreferences for data retention

#### In-App File Picker
Custom file selection dialog with:
- Directory navigation
- Multi-select capability
- Extension filtering
- Mobile gallery integration
- Permission handling

#### Theme System
Centralized theme configuration with:
- Material Design 2 compatibility
- Consistent color scheme (primary: #C6302C)
- Responsive elevation and shadows
- Accessibility-first design

---

## 🎨 Customization

### Theme Configuration
Edit the theme in `main.dart`:

```dart
const Color _primaryColor = Color(0xFFC6302C);
const Color _darkRedColor = Color(0xFF9A0000);
const String _appTitle = 'OpenPDF Tools';
const String _appVersion = '1.0.0';
```

### Adding New Tools
1. Create a new screen in `lib/screens/`
2. Add a navigation route in `HomeScreen`
3. Create a `_ToolCard` for the home screen grid

---

## 🔒 Security & Permissions

### Android Permissions
The app requests:
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_VISUAL_ALL` - File access
- `WRITE_EXTERNAL_STORAGE` - Save converted files

### iOS Permissions
- Photo library access for image selection
- File system access for document handling

### Best Practices
- All file operations include error handling
- Sensitive operations use try-catch blocks
- Proper resource cleanup on app lifecycle events
- Secure temporary file handling

---

## 📱 Mobile-First Design

The UI is optimized for all screen sizes:
- Responsive grid layout (2 columns on mobile, adaptive on tablets)
- Flexible AppBar with collapsing header
- Touch-friendly buttons and interactive elements
- Performance-optimized animations and transitions

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: File picker not working on Android
```bash
# Solution: Ensure permissions are granted
flutter pub get
flutter clean
flutter run
```

**Issue**: PDF viewer crashes
```bash
# Solution: Update Syncfusion package
flutter pub upgrade syncfusion_flutter_pdfviewer
```

**Issue**: Image compression failing
```bash
# Solution: Check available disk space and file permissions
# Ensure sufficient RAM for large images
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Run `flutter analyze` before submitting PR

### Testing
```bash
flutter test
```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📞 Support & Contact

- **Issues**: Report bugs and request features via [GitHub Issues](https://github.com/yourusername/openpdf_tools/issues)
- **Discussions**: Join our [GitHub Discussions](https://github.com/yourusername/openpdf_tools/discussions)
- **Documentation**: Visit [Flutter Documentation](https://flutter.dev/docs)

---

## 🙏 Acknowledgments

- [Flutter Community](https://flutter.dev/) for the amazing framework
- [Syncfusion](https://www.syncfusion.com/) for the excellent PDF viewer
- All contributors and users who help improve this project

---

## 📊 Project Stats

- **Language**: Dart
- **Framework**: Flutter
- **Packages**: 15+ dependencies
- **Supported Platforms**: 6+ platforms
- **Code Quality**: Lint-free with clean architecture

---

## 🔄 Version History

### v1.0.0 (Current)
- ✨ Initial release
- 🎯 Core PDF management features
- 🔄 Multi-format conversion support
- 📱 Cross-platform support
- 🎨 Modern Material Design UI

---

## 🚀 Roadmap

- [ ] Dark mode support
- [ ] Cloud storage integration (Google Drive, Dropbox)
- [ ] Advanced PDF editing tools
- [ ] Batch conversion
- [ ] OCR support
- [ ] Watermarking
- [ ] Digital signatures
- [ ] Localization (multi-language support)

---

**Happy PDF Processing! 📄✨**

For more information and updates, visit the [GitHub repository](https://github.com/yourusername/openpdf_tools).
