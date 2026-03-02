# Android Optimization Guide - OpenPDF Tools

## Overview
This document outlines all Android optimizations, permissions handling, and bug fixes implemented for the OpenPDF Tools app.

## Permissions Implementation

### ✅ AndroidManifest.xml Updates
- Added proper Android 11+ (API 30+) permission declarations
- Separated READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE with max SDK version 32
- Added READ_MEDIA_IMAGES and READ_MEDIA_VIDEO for Android 13+
- Added MANAGE_EXTERNAL_STORAGE for comprehensive file access
- Added CAMERA permission for image capture
- Added INTERNET and ACCESS_NETWORK_STATE for connectivity
- Added `android:requestLegacyExternalStorage="true"` for backward compatibility
- Configured proper intent filters for PDF file handling
- Added package visibility queries for Android 11+ compliance

### ✅ Runtime Permission Requests
All permissions are now requested at runtime:
- **Storage Permissions**: Using `Permission.manageExternalStorage` with fallback to `Permission.storage`
- **Media Permissions**: Android 13+ specific media permissions for photos/videos
- **Camera Permission**: Requested before accessing camera features
- **Fallback Logic**: Graceful degradation if permissions are denied

### ✅ Permission Handler Improvements (`platform_file_handler.dart`)
```dart
// Comprehensive permission request methods:
- requestStoragePermission()        // Main storage access
- requestMediaPermissions()         // Android 13+ media permissions
- requestCameraPermission()         // Camera access
- requestMediaLibraryAccess()       // iOS photo library
- requestFilePermissions()          // All required permissions
- arePermissionsPermanentlyDenied() // Check permanent denial
```

## Feature-Specific Optimizations

### 1. PDF Viewer & File Picker
- ✅ Request storage permissions before file picking
- ✅ Graceful error handling with user notifications
- ✅ Improved file path handling for scoped storage
- ✅ Timeout protection (30 seconds) for file picker

### 2. Image Handling
- ✅ Request CAMERA and PHOTOS permissions for image selection
- ✅ Intelligent permission requests in `in_app_file_picker.dart`
- ✅ Camera permission before image capture
- ✅ Gallery permission fallback options

### 3. PDF Digital Signing (NEW)
- ✅ Certificate file access with validation
- ✅ Proper file permission requests for signing operations
- ✅ Scoped storage compatibility (Android 11+)
- ✅ Secure temporary file handling for certificate processing
- ✅ Safe output directory selection (app-specific or Downloads)
- ✅ Memory cleanup after signing operations
- ✅ No sensitive data in logs or error messages
- ✅ File size limits enforced for security

### 3. PDF Processing
Updated permission requests in all screens:
- ✅ `compress_pdf_screen.dart`
- ✅ `merge_pdf_screen.dart`
- ✅ `split_pdf_screen.dart`
- ✅ `edit_pdf_screen.dart`
- ✅ `convert_to_pdf_screen.dart` (with camera permission)
- ✅ `convert_from_pdf_screen.dart`
- ✅ `repair_pdf_screen.dart`

## Android Build Optimization

### ✅ Gradle Configuration (`build.gradle.kts`)
- Set `minSdk = 21` (Android 5.0+ support)
- Enabled `multiDexEnabled = true` for large app
- Configured ProGuard/R8 code shrinking
- Set proper `jvmTarget = "17"` for Kotlin
- Added release build optimizations
- Proper package options configuration

### ✅ ProGuard Rules (`proguard-rules.pro`)
- Preserved Flutter and Dart classes
- Protected native method signatures
- Preserved app-specific classes
- Configured proper optimization passes
- Added library-specific rules for:
  - PDF libraries (pdfview, pdfbox, bouncycastle)
  - Image compression libraries
  - Permission handler
  - File picker
  - Image picker
  - Cryptography libraries

## Scoped Storage Compatibility

### ✅ New `ScopedStorageHelper` Class
Provides Android 11+ compatibility layer:
```dart
- getSafeTempDirectory()              // App cache directory
- getSafeDownloadsDirectory()         // App-specific downloads
- getSafeCacheDirectory()             // PDF processing cache
- getSafeSupportDirectory()           // App support files
- savePdfToSafeLocation()             // Save with proper handling
- isFileAccessible()                  // Verify access
- cleanupTempFiles()                  // Automatic cleanup
```

## Bug Fixes

### 1. Permission-Related Bugs
- ✅ Fixed missing permission requests before file operations
- ✅ Fixed permission denial handling with fallback options
- ✅ Added proper error messages for denied permissions

### 2. File Path Handling
- ✅ Improved file existence checks
- ✅ Better error handling for inaccessible paths
- ✅ Proper temporary file cleanup
- ✅ Fixed platform-specific path separators

### 3. Android 11+ (Scoped Storage)
- ✅ Proper use of app-specific directories
- ✅ Fallback to getExternalFilesDirectory()
- ✅ No dangerous permissions for basic file access
- ✅ Proper cache directory management

### 4. Memory and Performance
- ✅ Enabled code shrinking in release builds
- ✅ ProGuard R8 optimization
- ✅ Proper resource cleanup
- ✅ Timeout protection on file operations

## Main App Initialization

### ✅ Improved `main.dart`
```dart
// Enhanced permission request flow:
1. Ensure Flutter binding initialized
2. Request file permissions (with platform detection)
3. Request camera permission (Android only)
4. Initialize theme service
5. Log all steps for debugging
6. Graceful error handling
```

## User Experience Improvements

### 1. Permission Prompts
- Clear permission request explanations
- User-friendly error messages
- Option to proceed even if permission denied
- Toast notifications for permission denial

### 2. File Operations
- ✅ Safe file picker with timeout
- ✅ Better error dialogs
- ✅ Fallback UI options
- ✅ Progress indicators during operations

### 3. Android-Specific Features
- ✅ Hardware acceleration enabled
- ✅ Back gesture support (API 31+)
- ✅ Proper keyboard handling
- ✅ Deep link support for PDF files

## Testing Checklist

- [ ] Test file picker on different Android versions (API 21-34)
- [ ] Test permission requests (first time, denial, permanent denial)
- [ ] Test PDF navigation and viewing
- [ ] Test PDF editing features
- [ ] Test image to PDF conversion
- [ ] Test PDF merging and splitting
- [ ] Test PDF compression
- [ ] Test PDF signing and repair
- [ ] Test sharing functionality
- [ ] Test app restart after permission changes
- [ ] Test with Developer Options enabled
- [ ] Monitor memory usage during large file operations
- [ ] Test on devices with limited storage
- [ ] Test with Android's scoped storage enforcement

## Configuration Summary

### Supported Android Versions
- **Minimum**: Android 5.0 (API 21)
- **Target**: Android 14+ (API 34+)
- **Recommended**: Android 12+ (API 31+)

### Key Permissions
- `READ_EXTERNAL_STORAGE` (deprecated on 33+)
- `WRITE_EXTERNAL_STORAGE` (max SDK 32)
- `MANAGE_EXTERNAL_STORAGE` (Android 11+)
- `READ_MEDIA_IMAGES` (Android 13+)
- `READ_MEDIA_VIDEO` (Android 13+)
- `CAMERA` (for image capture)
- `INTERNET` (for connectivity)

### App-Specific Directories (No Special Permissions)
- Application cache directory
- Application documents directory
- Application external files directory (scoped storage safe)
- Application support directory

## Notes for Developers

1. Always check `PlatformHelper.isAndroid` before Android-specific code
2. Use `PlatformFileHandler` for all file operations
3. Request permissions before any file access
4. Handle permission denials gracefully
5. Use `ScopedStorageHelper` for file saving on Android 11+
6. Test on both emulator and real devices
7. Monitor logcat for permission-related warnings
8. Clean up temporary files regularly

## Future Improvements

- [ ] Implement SAF (Storage Access Framework) for better file access
- [ ] Add granular permission requests (only when needed)
- [ ] Implement backup/restore functionality
- [ ] Add file management UI for app-specific directory
- [ ] Implement cloud storage integration
