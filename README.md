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
- [Getting Started](#-getting-started)
- [Contributing](#-contributing)

---
## ⬇️ Download OpenPDF Tools

OpenPDF Tools will soon be available on the following platforms:

- **Google Play Store (Android)** – 🚧 Initial stage, coming soon  
- **SourceForge (Linux & Windows)** – 🚧 Coming soon  
- **Web Version** – 🚧 Coming soon  
- **Apple App Store (iOS)** – 🚧 Coming soon  
- **macOS Direct Download** – 🚧 Coming soon  
- **Indus App Store** – 🚧 Coming soon  
- **Samsung Galaxy AppsStore** – 🚧 Coming soon  

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

---

## 📧 Get in Touch

**Author**: [Ameer Hamza Saifi](https://github.com/ameerhamzasaifi)

Found a bug? Have a suggestion? Open an issue or start a discussion!

---

**Made with ❤️ for the open-source community**

**Happy PDF Processing! 📄✨**

© 2026 AHS Mobile Labs
