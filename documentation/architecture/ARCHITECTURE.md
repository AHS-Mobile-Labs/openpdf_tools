# Architecture Overview - Optimized for Multiple Platforms

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     OpenPDF Tools Application                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    main.dart                             │  │
│  │  • Platform Detection & Initialization                  │  │
│  │  • Responsive Home Screen Setup                         │  │
│  │  • Permission Handling                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│          ↓                          ↓                         ↓  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │   Android      │  │      iOS       │  │      Web       │  │
│  │                │  │                │  │                │  │
│  │ • Bottom Nav   │  │ • Bottom Nav   │  │ • Responsive   │  │
│  │ • Permissions  │  │ • Permissions  │  │   Layout       │  │
│  │ • Share Intent │  │ • Photos Lib   │  │ • PWA Support  │  │
│  └────────────────┘  └────────────────┘  └────────────────┘  │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐  │
│  │   Windows      │  │     macOS      │  │     Linux      │  │
│  │                │  │                │  │                │  │
│  │ • Sidebar Nav  │  │ • Sidebar Nav  │  │ • Sidebar Nav  │  │
│  │ • File Dialog  │  │ • File Dialog  │  │ • File Dialog  │  │
│  │ • Keyboard     │  │ • Trackpad     │  │ • Keyboard     │  │
│  └────────────────┘  └────────────────┘  └────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI Layer (Screens)                        │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┬───┐  │
│  │  Home    │  Viewer  │ Compress │ Convert  │  Edit    │..│  │
│  │ Screen   │ Screen   │ Screen   │ Screen   │ Screen   │  │  │
│  └──────────┴──────────┴──────────┴──────────┴──────────┴───┘  │
├─────────────────────────────────────────────────────────────────┤
│                    Responsive Widget Layer                      │
│  ┌──────────────────┬──────────────────┬──────────────────┐  │
│  │    Mobile UI     │    Tablet UI     │   Desktop UI     │  │
│  │  (2 columns)     │  (3 columns)     │  (4 columns)     │  │
│  │  Bottom Nav      │  Side Nav        │  Full Sidebar    │  │
│  └──────────────────┴──────────────────┴──────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                      Utility & Service Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Platform   │  │  Responsive  │  │    File      │         │
│  │   Helper     │  │   Helper     │  │  Handler     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
├─────────────────────────────────────────────────────────────────┤
│                       Configuration Layer                       │
│  ┌──────────────┐  ┌──────────────────┐                        │
│  │  App Config  │  │  Platform Config  │                        │
│  │  • Theme     │  │  • Performance    │                        │
│  │  • Colors    │  │  • Features       │                        │
│  │  • Spacing   │  │  • Optimizations  │                        │
│  └──────────────┘  └──────────────────┘                        │
├─────────────────────────────────────────────────────────────────┤
│                    Platform-Specific Layer                      │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┬───┐  │
│  │ Android  │   iOS    │   Web    │ Windows  │  macOS   │..│  │
│  │ Runtime  │ Runtime  │ Runtime  │ Runtime  │ Runtime  │  │  │
│  └──────────┴──────────┴──────────┴──────────┴──────────┴───┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
User Input
    ↓
┌─────────────────────────────────────────┐
│  Platform Detection (PlatformHelper)    │
│  - Check current platform                │
│  - Get platform-specific settings        │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│  Responsive Helper (ResponsiveHelper)   │
│  - Detect screen size                   │
│  - Calculate layout parameters           │
│  - Apply responsive styling              │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│  Widget Layer                           │
│  - Build appropriate UI                  │
│  - Apply platform theme                  │
│  - Render content                        │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│  Platform Specific Rendering            │
│  - Native components                     │
│  - Platform features                     │
│  - Device-specific optimizations         │
└─────────────────────────────────────────┘
    ↓
Display on User Device
```

## File Handling Flow

```
User Action (Pick File)
    ↓
┌──────────────────────────────┐
│ PlatformFileHandler.pickFile()│
└──────────────────────────────┘
    ↓
    ├─→ Android: Intent-based picker
    │
    ├─→ iOS: Photo library picker
    │
    ├─→ Web: HTML5 file input
    │
    ├─→ Windows: Native dialog
    │
    ├─→ macOS: Native dialog
    │
    └─→ Linux: GTK/file dialog
    ↓
┌──────────────────────────────┐
│ Process & Store File          │
│ - Validate format             │
│ - Save to appropriate path    │
│ - Update history              │
└──────────────────────────────┘
    ↓
Display Results
```

## Responsive Layout Decision Tree

```
                    Screen Detected
                          ↓
                Load Context Size
                          ↓
                ┌─────────┴─────────┐
                ↓                   ↓
           < 600px?            ≥ 600px?
             │                      │
        YES  │  NO              YES │  NO
             ↓                      ↓
         MOBILE              ┌──────┴──────┐
      (2 columns)            ↓             ↓
      Bottom Nav        < 1200px?     ≥ 1200px?
                             │             │
                        YES  │  NO    YES  │  NO
                             ↓             ↓
                         TABLET      DESKTOP
                      (3 columns)   (4 columns)
                      Side Nav      Full Sidebar
```

## Platform Feature Matrix

```
┌─────────────┬─────────┬─────────┬─────────┬──────────┬──────────┬──────────┐
│   Feature   │ Android │   iOS   │   Web   │ Windows  │  macOS   │  Linux   │
├─────────────┼─────────┼─────────┼─────────┼──────────┼──────────┼──────────┤
│ Navigation  │ Bottom  │ Bottom  │ Adaptive│ Sidebar  │ Sidebar  │ Sidebar  │
│ File Access │ Scoped  │ Photo   │ HTML5   │ Native   │ Native   │ Native   │
│ Permissions │ Runtime │ Runtime │ None    │ OS       │ OS       │ OS       │
│ Window Mgmt │ App Mgr │ App Mgr │ Browser │ Custom   │ Custom   │ Custom   │
│ Clipboard   │ Yes     │ Yes     │ Yes     │ Yes      │ Yes      │ Yes      │
│ Keyboard    │ Virtual │ Virtual │ Yes     │ Yes      │ Yes      │ Yes      │
│ Touch       │ Yes     │ Yes     │ Partial │ No       │ Trackpad │ No       │
│ Drag-Drop   │ Limited │ Limited │ Yes     │ Yes      │ Yes      │ Yes      │
└─────────────┴─────────┴─────────┴─────────┴──────────┴──────────┴──────────┘
```

## State Management Flow

```
┌─────────────────────────┐
│  App State (main.dart)  │
│  - Selected Navigation  │
│  - Current Screen       │
└─────────────────────────┘
         ↓
┌─────────────────────────┐         ┌─────────────────────┐
│  Screen State           │ ←------|  Local Storage      │
│  - File Selection       │         │  (SharedPreferences)│
│  - UI State             │         └─────────────────────┘
│  - Operation Progress   │
└─────────────────────────┘
         ↓
┌─────────────────────────┐
│  Widget Rendering       │
└─────────────────────────┘
```

## PDF Digital Signing Architecture (NEW)

```
┌─────────────────────────────────────────────────────────────┐
│              PDF Signing Feature Architecture                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│                    UI Layer                                  │
│            SignPdfScreenRefactored                           │
│  (5-step workflow with real-time validation)                │
│                          ↓                                   │
├─────────────────────────────────────────────────────────────┤
│              Domain Models Layer                             │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────┐        │
│  │ CertificateI │  │ SigningRequ  │  │ SigningResult│        │
│  │ nfo          │  │ est          │  │              │        │
│  └──────────────┘  └─────────────┘  └──────────────┘        │
│                          ↓                                   │
├─────────────────────────────────────────────────────────────┤
│              Service Layer (Business Logic)                  │
│  ┌──────────────────────────────────────────────────┐      │
│  │ CertificateService                              │      │
│  │ • Validation (format, expiry, integrity)        │      │
│  │ • Parsing & metadata extraction                 │      │
│  │ • Password verification (no logging)            │      │
│  └──────────────────────────────────────────────────┘      │
│  ┌──────────────────────────────────────────────────┐      │
│  │ SecureFilePickerService                         │      │
│  │ • Cross-platform file selection                 │      │
│  │ • Magic bytes verification                      │      │
│  │ • Size limit enforcement (5MB cert, 500MB PDF) │      │
│  └──────────────────────────────────────────────────┘      │
│  ┌──────────────────────────────────────────────────┐      │
│  │ ProductionPdfSigningService                     │      │
│  │ • SHA-256 signature generation                  │      │
│  │ • HMAC authentication                           │      │
│  │ • Signature verification                        │      │
│  │ • Secure memory clearing                        │      │
│  └──────────────────────────────────────────────────┘      │
│                          ↓                                   │
├─────────────────────────────────────────────────────────────┤
│            Platform-Specific File Operations                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │ Android  │  │   iOS    │  │   Web    │                 │
│  │ Scoped   │  │ App      │  │ Browser  │                 │
│  │ Storage  │  │ Sandbox  │  │ Download │                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │ Windows  │  │  macOS   │  │  Linux   │                 │
│  │ Desktop  │  │ Desktop  │  │ Desktop  │                 │
│  │ Files    │  │ Files    │  │ Files    │                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
│                          ↓                                   │
│                Signed PDF Output                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Performance Optimization Strategy

```
┌─────────────────────────────────────────────────────┐
│           Performance Monitoring                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Memory Management                                  │
│  ├─ Image Cache Limits (50MB)                      │
│  ├─ PDF Cache (200MB)                              │
│  └─ Cleanup on navigation                          │
│                                                     │
│  Network Optimization                               │
│  ├─ Compression enabled                            │
│  ├─ Timeout settings                               │
│  └─ Retry logic                                     │
│                                                     │
│  UI Performance                                     │
│  ├─ Lazy loading screens                           │
│  ├─ Efficient re-renders                           │
│  └─ Animation frame rate limiting                  │
│                                                     │
│  File Processing                                    │
│  ├─ Async operations                               │
│  ├─ Chunk-based processing (1MB chunks)           │
│  └─ Progress tracking                              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Dependency Injection Pattern

```
pubspec.yaml
    ↓
┌─────────────────────────────────────┐
│   Flutter Framework                  │
│  • Material Design ← App Theme       │
│  • Core Widgets                      │
│  • Platform Channels                 │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│   Cross-Platform Libraries           │
│  • file_picker                       │
│  • path_provider                     │
│  • permission_handler                │
│  • share_plus                        │
│  • syncfusion_flutter_pdfviewer      │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│   Platform-Specific Implementations  │
│  • Android SDK (API 21+)             │
│  • iOS SDK (13.0+)                   │
│  • Web APIs (Modern Browsers)        │
│  • Desktop (Win/Mac/Linux)           │
└─────────────────────────────────────┘
```

## Key Principles

### Single Responsibility
- Each utility handles one concern
- Utilities separated by purpose
- Constants in dedicated config

### Open/Closed Principle
- Easy to extend for new platforms
- Configuration-driven features
- Extensible widget system

### Dependency Inversion
- Depend on abstractions (helpers)
- Utilities injected via context
- Configuration passed as constants

### DRY (Don't Repeat Yourself)
- Responsive logic centralized
- Platform checks in helper
- Reusable widgets and utilities

## Integration Points

```
┌────────────────────────────────────────┐
│       Platform Native APIs             │
├────────────────────────────────────────┤
│                                        │
│  Android         iOS          Desktop  │
│  ├─ Intents     ├─ Schemes   ├─ Win32 │
│  ├─ Storage     ├─ Photos    ├─ Cocoa │
│  └─ Sensors     └─ Keychain  └─ X11   │
│                                        │
│  ↓                                     │
│  Platform Channels (Future Ready)      │
│                                        │
│  ↓                                     │
│  Flutter Apps can extend functionality│
│                                        │
└────────────────────────────────────────┘
```

---

**Architecture is optimized for:**
- ✅ Maintainability
- ✅ Scalability
- ✅ Cross-platform compatibility
- ✅ Performance
- ✅ Extensibility
