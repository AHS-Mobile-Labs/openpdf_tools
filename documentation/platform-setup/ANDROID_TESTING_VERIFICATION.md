# Android Optimization Testing & Verification Guide

## Pre-Testing Setup

### Build Configuration
```bash
# Build APK for testing
flutter build apk --release

# Build with verbose output for debugging
flutter build apk --release -v

# Clean build if needed
flutter clean
flutter pub get
flutter build apk --release
```

### Device/Emulator Setup
- Use Android emulator with API 24-34
- Test on multiple physical devices if available
- Enable Developer Options and USB Debugging
- Install app using: `adb install -r build/app/outputs/flutter-apk/app-release.apk`

## Permission Testing

### 1. First-Time Permission Requests
**Test Scenario**: Fresh app install
1. Launch app
2. Verify permission request dialogs appear
3. Grant all permissions
4. Verify app initializes properly
5. ✅ Expected: All features work without issues

**Test Commands**:
```bash
adb logcat | grep -i permission
adb logcat | grep -i "main.*permission"
```

### 2. Permission Denial Handling
**Test Scenario**: Deny permissions
1. Launch app
2. Deny storage permission
3. Try PDF viewer - should show permission message
4. ✅ Expected: Shows toast/snackbar, attempts to proceed
5. Try file picker - should still attempt operation
6. ✅ Expected: Graceful error handling

**Test**: 
- Click "Allow" to retry after denial
- Click "Don't allow" to see fallback behavior

### 3. Permanent Permission Denial
**Test Scenario**: Toggle permission in settings
1. Open Settings → Apps → OpenPDF Tools → Permissions
2. Deny Storage permission
3. Check "Don't ask again"
4. Return to app and try file picker
5. ✅ Expected: Shows appropriate message, app doesn't crash

**Verify in Logcat**:
```bash
adb logcat | grep -i "Permission.*denied"
```

### 4. Permission Revocation
**Test Scenario**: Revoke permissions mid-app usage
1. Start PDF processing operation
2. While processing, open Settings and revoke permission
3. Resume app
4. ✅ Expected: App handles gracefully (may not complete current operation)

## File Operation Testing

### 1. PDF File Selection
**Test Scenario**: Pick PDF from file picker
1. Navigate to PDF Viewer screen
2. Click "Select PDF"
3. Choose a PDF file
4. ✅ Expected: PDF opens without issues
5. Verify permissions requested
6. ✅ Check logcat for permission logs

**Verify**:
- Storage permission requested before picker opens
- File accessible after permission granted

### 2. Multiple File Operations
**Test Scenario**: Merge/Combine PDFs
1. Go to Merge PDF screen
2. Add multiple PDFs
3. Merge operation starts
4. ✅ Expected: All files accessible, merge completes
5. Check saved file location

**Test Different File Sizes**:
- Small PDFs (< 1MB)
- Medium PDFs (1-10MB)
- Large PDFs (> 10MB)

### 3. Image to PDF Conversion
**Test Scenario**: Convert image to PDF
1. Go to "Convert to PDF"
2. Select "Images to PDF"
3. Request camera permission
4. ✅ Expected: Camera permission requested
5. Select image from gallery
6. ✅ Expected: Conversion completes and file accessible

**Verify Permissions**:
```bash
adb logcat | grep -i "camera\|photos\|gallery"
```

### 4. File Compression
**Test Scenario**: Compress PDF
1. Go to Compress PDF screen
2. Select PDF file
3. ✅ Expected: Storage permission requested
4. Adjust quality slider
5. Compress file
6. ✅ Expected: File saved to accessible location

## Android Version-Specific Testing

### Android 5-9 (API 21-28)
**Focus**: Legacy permission handling
- Test Runtime Permissions
- Verify READ/WRITE_EXTERNAL_STORAGE works
- Check deprecated APIs handling

**Commands**:
```bash
adb shell getprop ro.build.version.release
```

### Android 10 (API 29)
**Focus**: Scoped Storage introduction
- Test app-specific directory access
- Verify requestLegacyExternalStorage works
- Check file picker behavior

### Android 11+ (API 30+)
**Focus**: Full Scoped Storage enforcement
- Test MANAGE_EXTERNAL_STORAGE
- Verify app-specific directory access
- Test access to Downloads folder
- Check new permissions (READ_MEDIA_IMAGES, etc.)

**Test Commands**:
```bash
adb shell dumpsys package com.ahsmobilelabs.openpdf_tools
```

## Memory & Performance Testing

### 1. Memory Usage
**Test Scenario**: Large PDF operations
```bash
# Monitor memory
adb shell dumpsys meminfo com.ahsmobilelabs.openpdf_tools

# Real-time monitoring
adb shell top | grep openpdf
```

**Test Cases**:
1. Open large PDF (50+ MB)
2. Edit multiple pages
3. Merge 10+ PDFs
4. ✅ Expected: Memory usage stays reasonable (< 500MB)

### 2. Battery Impact
- Monitor battery drain during long operations
- Check CPU usage during processing

### 3. Storage Cleanup
**Test Scenario**: Verify temp files cleanup
1. Perform multiple conversion operations
2. Check app cache directory
3. Restart app
4. ✅ Expected: Old temp files removed automatically

**Check Cache**:
```bash
adb shell ls -la /data/data/com.ahsmobilelabs.openpdf_tools/cache/
```

## Feature-Specific Testing

### 1. PDF Viewer
- [ ] Open local PDF
- [ ] Open PDF from intent/share
- [ ] View PDF with password
- [ ] Navigate pages
- [ ] Zoom/rotate PDF
- [ ] Add to favorites
- [ ] Share PDF

### 2. PDF Editor
- [ ] Edit PDF metadata
- [ ] Rotate pages
- [ ] Delete pages
- [ ] Reorder pages
- [ ] Save changes

### 3. PDF Compressor
- [ ] Compress different quality levels
- [ ] Verify file size reduction
- [ ] Test with different PDFs

### 4. PDF Merger
- [ ] Select multiple PDFs
- [ ] Merge in correct order
- [ ] Save merged PDF
- [ ] Open result to verify

### 5. PDF Splitter
- [ ] Extract all pages
- [ ] Extract specific page range
- [ ] Extract single page

### 6. Image to PDF
- [ ] Capture image from camera
- [ ] Select from gallery
- [ ] Convert single/multiple images
- [ ] Create PDF successfully

### 7. PDF to Image
- [ ] Convert to JPEG
- [ ] Convert to PNG
- [ ] Verify output quality
- [ ] Save to accessible location

## UI/UX Testing

### 1. Permission Dialogs
- [ ] Dialog appears when permission needed
- [ ] Dialog messages are clear
- [ ] Accept/Deny buttons work properly
- [ ] Dialog doesn't freeze app

### 2. Error Messages
- [ ] Permission denied message is clear
- [ ] File not found message is helpful
- [ ] Operation failure messages are informative

### 3. Loading States
- [ ] Loading indicators appear for long operations
- [ ] Can cancel long operations if applicable
- [ ] Progress updates are smooth

### 4. Navigation
- [ ] All screens accessible
- [ ] Back navigation works properly
- [ ] No crashes during navigation

## Edge Cases

### 1. Out of Storage Space
**Test Scenario**: Simulate low storage
```bash
adb shell "df" | grep data
# Create large dummy files to consume space
```
- ✅ Expected: Graceful error message

### 2. Corrupted Files
**Test Scenario**: Try opening corrupted PDF
- ✅ Expected: Shows error, doesn't crash

### 3. Very Large Files
**Test Scenario**: Open 100+ MB PDF
- ✅ Expected: Handles gracefully or shows appropriate message

### 4. Rapidly Changing Permissions
**Test Scenario**: Toggle permissions while app running
- ✅ Expected: App adapts gracefully

### 5. App in Background
**Test Scenario**: Put app in background during operation
```bash
adb shell am send-trim-memory com.ahsmobilelabs.openpdf_tools COMPLETE
```
- ✅ Expected: App recovers properly when returned to foreground

## Crash Testing

### 1. Monitor Crashes
```bash
adb logcat | grep -i "crashed\|exception\|error"
adb logcat *:E | grep openpdf
```

### 2. Crash Scenarios
- [ ] Force stop app: `adb shell am force-stop com.ahsmobilelabs.openpdf_tools`
- [ ] Kill app during operation
- [ ] Rapid permission changes
- [ ] Rapid screen transitions

### 3. Regression Testing
- [ ] Previous features still work
- [ ] No new crashes introduced
- [ ] Performance acceptable

## Logcat Analysis

### Permission-Related Logs
```bash
# All logs
adb logcat

# Filter for app only
adb logcat com.ahsmobilelabs.openpdf_tools:* *:S

# Filter for errors
adb logcat *:E

# Filter for specific strings
adb logcat | grep -i "permission\|storage\|camera"
adb logcat | grep -i "flutter\|dart"
```

### Key Log Patterns to Watch For
- ✅ "File permissions requested" - Permission request initiated
- ✅ "File permissions granted" - Permission granted
- ✅ "File permissions denied" - Permission denied
- ❌ "Permission exception" - Permission error
- ❌ "SecurityException" - Security issue
- ❌ "FileNotFoundException" - File access error

## Performance Benchmarks

### Expected Performance Targets
- App startup time: < 2 seconds
- PDF open time (10MB): < 3 seconds
- PDF compression: < 5 seconds per MB
- PDF merge: < 10 seconds for 5 files
- File picker open: < 1 second

## Sign-Off Checklist

### Before Release
- [ ] All permissions requested properly
- [ ] All features tested on API 21, 29, 34
- [ ] No permission-related crashes
- [ ] Logcat clean (no concerning errors)
- [ ] Memory usage acceptable
- [ ] All features working
- [ ] Error messages user-friendly
- [ ] App responds to back button
- [ ] Temp files cleaned up
- [ ] Performance acceptable

### Device Testing Checklist
- [ ] Android 5.0 (API 21)
- [ ] Android 9 (API 28)
- [ ] Android 10 (API 29)
- [ ] Android 11 (API 30)
- [ ] Android 12 (API 31)
- [ ] Android 13 (API 33)
- [ ] Android 14 (API 34)

### Permission Testing Checklist
- [ ] Storage permission granted
- [ ] Storage permission denied
- [ ] Camera permission granted
- [ ] Camera permission denied
- [ ] Multiple permission combinations tested

## Issues Found & Resolution

Document any issues found during testing:

### Issue Template
```
## Issue: [Title]
- Device: [Model, API Level]
- Reproducible: [Yes/No]
- Steps to Reproduce:
  1. [Step 1]
  2. [Step 2]
- Expected Behavior: [Description]
- Actual Behavior: [Description]
- Logcat Output: [Relevant logs]
- Resolution: [Fix applied]
```

## Conclusion

Upon successful completion of all tests:
1. App is optimized for Android
2. All permissions properly implemented
3. No critical bugs remaining
4. Ready for production release
