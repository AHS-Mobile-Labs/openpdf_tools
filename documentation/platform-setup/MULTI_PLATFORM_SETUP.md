# Multi-Platform Setup Guide

## Quick Start for Each Platform

### Prerequisites
- Flutter 3.10.7+ installed
- Platform SDKs installed (Android SDK, Xcode for iOS/macOS, etc.)

## Mobile Setup

### Android
```bash
# Enable Android support
flutter config --enable-android

# Build
flutter pub get
flutter build apk

# Run on device/emulator
flutter run
```

### iOS
```bash
# Enable iOS support
flutter config --enable-ios

# Build
flutter pub get
cd ios && pod install && cd ..
flutter build ipa

# Run on device/simulator
flutter run
```

## Web Setup

```bash
# Enable web support
flutter config --enable-web

# Build
flutter pub get
flutter build web

# Run development server
flutter run -d chrome

# Production build
flutter build web --release --web-renderer html
```

### Web Deployment Tips
- Use `--web-renderer html` for better compatibility
- Set `<base href="/path/">` if deploying to subdirectory
- Configure service worker caching strategy
- Test in multiple browsers

## Desktop Setup

### Windows
```bash
# Enable Windows support
flutter config --enable-windows

# Build
flutter pub get
flutter build windows

# Run
flutter run -d windows
```

### macOS
```bash
# Enable macOS support
flutter config --enable-macos

# Build
flutter pub get
flutter build macos

# Run
flutter run -d macos
```

### Linux
```bash
# Enable Linux support
flutter config --enable-linux

# Build
flutter pub get
flutter build linux

# Run
flutter run -d linux
```

## Configuration Files

### Key Configuration Files
- `pubspec.yaml` - Dependencies and platform configuration
- `lib/config/app_config.dart` - App theme and constants
- `lib/config/platform_optimizations.dart` - Performance settings
- `lib/utils/platform_helper.dart` - Platform detection
- `lib/utils/responsive_helper.dart` - Responsive layout
- `lib/utils/platform_file_handler.dart` - File operations

### Platform-Specific Files

#### Android
- `android/app/build.gradle` - Android build configuration
- `android/app/src/main/AndroidManifest.xml` - Permissions

#### iOS
- `ios/Runner/Info.plist` - iOS configuration
- `ios/Podfile` - iOS dependencies

#### Web
- `web/index.html` - Web entry point
- `web/manifest.json` - PWA configuration

#### Desktop (all)
- `<platform>/CMakeLists.txt` - Build configuration
- `windows/runner/CMakeLists.txt` - Windows specific
- `macos/Runner.xcodeproj/` - macOS specific
- `linux/CMakeLists.txt` - Linux specific

## Responsive UI Testing

### Test on Different Screen Sizes
```bash
# Mobile (portrait)
flutter run -d chrome --web-renderer html

# Tablet/iPad
flutter run --device-id=device-id

# Desktop
flutter run -d windows/macos/linux
```

### Use DevTools for Responsive Testing
```bash
flutter run
# Then open DevTools and select Device Preview
```

## Performance Optimization

### Enable Performance Monitoring
```dart
// In main.dart, set PlatformOptimizations:
debugPrintBeginFrameBanner = true;
debugPrintEndFrameBanner = true;
```

### Profile Your App
```bash
flutter run --profile
# Or with release mode
flutter run --release
```

## Platform-Specific Permissions

### Android
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Already configured for file access -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS
Edit `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library</string>
<key>NSDocumentsFolderUsageDescription</key>
<string>This app needs access to your documents</string>
```

### Web
PWA support is configured in `web/manifest.json`:
- App name and icons
- Display mode and orientation
- Theme colors

## Building for Production

### Mobile (Android)
```bash
# Create signed APK
flutter build apk --release --split-per-abi

# Or create AAB for Play Store
flutter build appbundle --release
```

### Mobile (iOS)
```bash
# Create IPA for App Store
flutter build ipa --release
```

### Web
```bash
# Production build with minification
flutter build web --release --web-renderer html

# Deploy to Firebase Hosting
firebase deploy
```

### Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Troubleshooting

### Common Issues

**Mobile: Permissions not working**
- Ensure correct permissions in manifest/Info.plist
- Test on actual device (emulator may have limitations)
- Request permissions explicitly at runtime

**Desktop: Window not appearing**
- Check window manager configuration
- Verify minimum window sizes
- Try running with `--verbose` flag

**Web: Blank page**
- Clear browser cache
- Check browser console for errors
- Try different web renderer: `--web-renderer html`
- Verify service worker is registered

**Cross-platform: Build failures**
- Run `flutter clean`
- Run `flutter pub get`
- Check Flutter version matches requirements
- Verify all platform SDKs are up to date

## Platform-Specific Running

### Run on specific device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Debug on specific platform
```bash
flutter run -d chrome           # Web in Chrome
flutter run -d windows          # Windows
flutter run -d macos            # macOS
flutter run -d linux            # Linux
```

## Next Steps

1. Read [PLATFORM_OPTIMIZATION_GUIDE.md](./PLATFORM_OPTIMIZATION_GUIDE.md) for detailed optimization strategies
2. Review platform-specific code in `lib/utils/platform_helper.dart`
3. Test responsive layouts across different screen sizes
4. Run performance profiling with DevTools
5. Deploy to app stores and web hosting

## Resources

- [Flutter Multi-platform Guide](https://flutter.dev/multi-platform)
- [Responsive Design](https://flutter.dev/docs/development/ui/look-and-feel/adaptive)
- [Platform Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)
- [DevTools](https://flutter.dev/docs/development/tools/devtools)
