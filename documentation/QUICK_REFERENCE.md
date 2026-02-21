# Quick Reference Guide - Platform Optimization

## 🎯 Quick Start

### For Mobile Development
```bash
flutter run                    # Run on Android/iOS
flutter run -d <device-id>    # Specific device
```

### For Desktop Development
```bash
flutter run -d windows         # Windows desktop
flutter run -d macos          # macOS desktop
flutter run -d linux          # Linux desktop
```

### For Web Development
```bash
flutter run -d chrome          # Chrome development
flutter build web --release    # Production build
```

## 📱 Responsive Breakpoints

Quick reference for responsive design:
```
Mobile:    < 600px   → 2 columns, bottom nav
Tablet:    600-1200px → 3 columns, side nav
Desktop:   ≥ 1200px   → 4 columns, full sidebar
```

## 🔧 Common Tasks

### Check Current Platform
```dart
import 'package:openpdf_tools/utils/platform_helper.dart';

if (PlatformHelper.isMobile) {
  print('Running on mobile');
} else if (PlatformHelper.isDesktop) {
  print('Running on desktop');
} else if (PlatformHelper.isWeb) {
  print('Running on web');
}

// Get platform name
print('Platform: ${PlatformHelper.platformName}');
```

### Use Responsive Design
```dart
import 'package:openpdf_tools/utils/responsive_helper.dart';

// Direct check
if (context.isMobile) {
  // Build mobile layout
}

// Get responsive value
final padding = context.responsive.responsivePadding(
  mobile: 12,
  tablet: 20,
  desktop: 24,
);

// Grid columns
final cols = context.responsive.gridColumns;
```

### Handle File Operations
```dart
import 'package:openpdf_tools/utils/platform_file_handler.dart';

// Request permissions if mobile
if (PlatformHelper.isMobile) {
  await PlatformFileHandler.requestFilePermissions();
}

// Pick a file
final file = await PlatformFileHandler.pickFile();

// Handle different platforms
String savePath = await PlatformFileHandler.getDefaultSaveLocation();
```

### Theme & Configuration
```dart
import 'package:openpdf_tools/config/app_config.dart';

// Access app theme
ThemeData theme = AppConfig.getThemeData();

// Get colors
Color primary = AppConfig.primaryColor;

// Get spacing
double padding = AppConfig.paddingLarge;
```

## 📂 File Structure

### New Directories
```
lib/
├── config/              # App configuration
│   ├── app_config.dart
│   └── platform_optimizations.dart
└── utils/               # Utility functions
    ├── platform_helper.dart
    ├── responsive_helper.dart
    └── platform_file_handler.dart
```

### Key Files Modified
- `lib/main.dart` - Platform-aware initialization
- `pubspec.yaml` - New dependencies added

## 🚀 Deployment

### Mobile Deployment
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ipa --release
```

### Desktop Deployment
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Web Deployment
```bash
flutter build web --release
# Deploy to hosting service (Firebase, Netlify, etc.)
```

## 🎨 Customization

### Change Theme Colors
Edit `lib/config/app_config.dart`:
```dart
static const Color primaryColor = Color(0xFFC6302C);
static const Color accentColor = Color(0xFFFFB81C);
```

### Adjust Breakpoints
Edit `lib/utils/responsive_helper.dart`:
```dart
static const double mobileMaxWidth = 600;
static const double tabletMaxWidth = 1200;
```

### Performance Settings
Edit `lib/config/platform_optimizations.dart`:
```dart
static const int imageMemorySizeLimit = 50 * 1024 * 1024;
static const int maxPDFCacheSizeMB = 200;
```

## 🐛 Debugging

### Enable Debug Information
```dart
// In main.dart, uncomment for debugging
// debugPrintBeginFrameBanner = true;
// debugPrintEndFrameBanner = true;
```

### Test Responsive Behavior
```bash
flutter run -d chrome  # Web - use browser DevTools
flutter run --profile  # Profile mode for performance
```

### Check Platform Detection
```dart
print('Platform: ${PlatformHelper.platformName}');
print('Is Mobile: ${PlatformHelper.isMobile}');
print('Is Desktop: ${PlatformHelper.isDesktop}');
print('Is Web: ${PlatformHelper.isWeb}');
```

## 📊 Performance Tips

### For Mobile
- Use caching for images
- Minimize animations on low-end devices
- Request permissions at appropriate times
- Use platform-specific file paths

### For Desktop
- Implement multi-threading for heavy operations
- Support keyboard shortcuts
- Use native file dialogs
- Implement drag-and-drop

### For Web
- Minimize JavaScript
- Use service workers
- Compress assets
- Test in multiple browsers

## 🔐 Permissions

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (Info.plist)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Access photos for PDF creation</string>
```

## 📚 Resources

- [OPTIMIZATIONS_SUMMARY.md](./OPTIMIZATIONS_SUMMARY.md) - Full summary
- [PLATFORM_OPTIMIZATION_GUIDE.md](./PLATFORM_OPTIMIZATION_GUIDE.md) - Detailed guide
- [MULTI_PLATFORM_SETUP.md](./MULTI_PLATFORM_SETUP.md) - Setup guide
- [Flutter Official Docs](https://flutter.dev/docs)
- [Responsive Design Guide](https://flutter.dev/docs/development/ui/look-and-feel/adaptive)

## 🆘 Common Issues

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Platform-Specific Problems

**Permissions on mobile:**
- Check AndroidManifest.xml / Info.plist
- Request permissions at runtime
- Test on physical device

**Window sizing on desktop:**
- Check window_manager configuration
- Verify minimum window size
- Test on actual OS

**Blank web page:**
- Clear cache
- Check browser console
- Try different web renderer

## 💡 Pro Tips

1. Always test on actual devices, not just emulators
2. Use `context.isMobile` instead of `Platform.isAndroid` for consistent behavior
3. Cache remote data when possible
4. Profile your app regularly with DevTools
5. Test with slow networks for web
6. Implement proper error handling for file operations

## 🎓 Learning Path

1. Start with [Quick Reference Guide](./QUICK_REFERENCE.md) (this file)
2. Read [OPTIMIZATIONS_SUMMARY.md](./OPTIMIZATIONS_SUMMARY.md)
3. Deep dive into [PLATFORM_OPTIMIZATION_GUIDE.md](./PLATFORM_OPTIMIZATION_GUIDE.md)
4. Follow [MULTI_PLATFORM_SETUP.md](./MULTI_PLATFORM_SETUP.md) for deployment
5. Review source code in `lib/utils/` and `lib/config/`

---

**Need more help?** Check the main documentation files or review the optimized source code!
