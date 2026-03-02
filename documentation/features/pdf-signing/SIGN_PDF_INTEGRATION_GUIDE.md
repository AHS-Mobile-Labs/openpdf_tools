# Sign PDF Feature - Integration & Migration Guide

## Quick Start: 5 Minutes to Integration

### Step 1: Add to Home Screen

Update your home screen navigation to include the new signing feature:

```dart
// In main.dart or dashboard_home_screen.dart

ToolCardData(
  icon: Icons.edit_document,
  title: 'Sign PDF',
  subtitle: 'Digital Signatures',
  color: const Color(0xFF7C3AED), // Purple
  screen: const SignPdfScreenRefactored(),
),
```

### Step 2: Update Pubspec (if needed)

The implementation uses only existing dependencies:

```yaml
dependencies:
  crypto: ^3.0.0  # For SHA-256 hashing (usually already present)
```

### Step 3: Import the Screen

```dart
import 'lib/screens/sign_pdf_screen_refactored.dart';
```

Done! The feature is automatically available on all platforms.

## Migration from Old Implementation

If you have an old `SignPdfScreen` implementation, follow this migration path:

### Before (Old Implementation)
```dart
// Old - not recommended for production
class _SignPdfScreenState extends State<SignPdfScreen> {
  // All business logic in UI
  // Direct file access
  // Minimal validation
  // Mixed concerns
}
```

### After (Production Implementation)
```dart
// New - clean, secure, testable
class _SignPdfScreenRefactoredState extends State<SignPdfScreenRefactored> {
  // UI logic only
  // Delegates to services
  // Comprehensive validation
  // Separated concerns
}
```

### Migration Steps

#### 1. Keep Old Screen as Legacy (Optional)
```dart
// In navigation, provide both:
// 'Sign PDF' (new) → SignPdfScreenRefactored
// 'Sign PDF (Legacy)' (old) → SignPdfScreen
```

#### 2. Update Navigation Target
```dart
// Before:
// screen: SignPdfScreen(),

// After:
screen: SignPdfScreenRefactored(),
```

#### 3. No Breaking Changes
The new implementation is completely separate, so:
- ✅ Old code continues to work
- ✅ Gradual migration possible
- ✅ Both can coexist during transition
- ✅ Eventually deprecate old version

## Services Integration

### CertificateService Usage

```dart
// Validate certificate
final validation = await CertificateService.validateCertificateFile(file);
if (!validation.isValid) {
  print(validation.errors);
}

// Parse certificate with password
final certInfo = await CertificateService.parseCertificate(file, password);

// Check expiry
if (CertificateService.shouldWarnAboutExpiry(certInfo)) {
  print('Certificate expiring soon');
}

// Verify password
final isCorrect = await CertificateService.verifyCertificatePassword(file, pwd);
```

### SecureFilePickerService Usage

```dart
// Pick PDF
final pdfFile = await SecureFilePickerService.pickPdfFile();

// Pick certificate
final certFile = await SecureFilePickerService.pickCertificateFile();

// Get metadata
final metadata = await SecureFilePickerService.getPdfMetadata(pdfFile);

// Generate safe filename
final filename = SecureFilePickerService.generateOutputFilename('document.pdf');
```

### ProductionPdfSigningService Usage

```dart
// Create request
final request = SigningRequest(
  pdfFilePath: pdfFile.path,
  nameOnSignature: 'John Doe',
  reason: 'Approved',
  certificate: certInfo,
  certificatePassword: password,
  outputPath: outputPath,
);

// Sign PDF
final result = await ProductionPdfSigningService.signPdf(request);

if (result.success) {
  print('Signed: ${result.signedFilePath}');
} else {
  print('Error: ${result.errorMessage}');
}

// Clean up
ProductionPdfSigningService.clearSensitiveData(password: password);
```

## Advanced Usage Examples

### Complete Signing Workflow in Custom Code

```dart
Future<void> demonstrateCompleteWorkflow() async {
  try {
    // 1. Select files
    final pdfFile = await SecureFilePickerService.pickPdfFile();
    final certFile = await SecureFilePickerService.pickCertificateFile();
    
    if (pdfFile == null || certFile == null) return;

    // 2. Validate certificate
    final validation = await CertificateService.validateCertificateFile(certFile);
    if (!validation.isValid) {
      print('Certificate invalid: ${validation.errors}');
      return;
    }

    // 3. Get password from user
    final password = await getUserPassword(); // Your implementation

    // 4. Verify password
    final isPasswordCorrect = await CertificateService.verifyCertificatePassword(
      certFile,
      password,
    );
    
    if (!isPasswordCorrect) {
      print('Invalid password');
      return;
    }

    // 5. Parse certificate
    final certInfo = await CertificateService.parseCertificate(certFile, password);
    if (certInfo == null) {
      print('Failed to parse certificate');
      return;
    }

    // 6. Check expiry
    if (!certInfo.isCurrentlyValid) {
      print('Certificate not valid');
      return;
    }

    // 7. Create signing request
    final outputDir = await SecureFilePickerService.getOutputDirectory();
    final outputFilename = SecureFilePickerService.generateOutputFilename(
      pdfFile.path.split('/').last,
    );
    
    final request = SigningRequest(
      pdfFilePath: pdfFile.path,
      nameOnSignature: 'Jane Smith',
      reason: 'Approved for Processing',
      email: 'jane@example.com',
      certificate: certInfo,
      certificatePassword: password,
      outputPath: '$outputDir/$outputFilename',
      visibleSignature: true,
      location: SignatureLocation.bottomRight,
      includeTimestamp: true,
    );

    // 8. Validate request
    final requestValidation = request.validate();
    if (!requestValidation.isValid) {
      print('Request invalid: ${requestValidation.errors}');
      return;
    }

    // 9. Perform signing
    final result = await ProductionPdfSigningService.signPdf(request);

    // 10. Clean up sensitive data
    ProductionPdfSigningService.clearSensitiveData(password: password);
    CertificateService.clearSensitiveData(password);

    // 11. Handle result
    if (result.success) {
      print('PDF signed: ${result.signedFilePath}');
      print('File size: ${result.fileSize} bytes');
      print('Signature hash: ${result.signatureHash}');
      
      // Optionally verify
      final signatureValid = await ProductionPdfSigningService.verifySignature(
        File(result.signedFilePath!),
      );
      print('Signature verified: $signatureValid');
    } else {
      print('Signing failed: ${result.errorMessage}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Batch Signing (Multiple PDFs)

```dart
Future<void> batchSignPdfs(List<String> pdfPaths) async {
  final certFile = await SecureFilePickerService.pickCertificateFile();
  final password = await getUserPassword();

  if (certFile == null) return;

  for (final pdfPath in pdfPaths) {
    try {
      final result = await ProductionPdfSigningService.signPdf(
        SigningRequest(
          pdfFilePath: pdfPath,
          nameOnSignature: 'Batch Signer',
          reason: 'Batch Processing',
          certificate: (await CertificateService.parseCertificate(
            certFile,
            password,
          ))!,
          certificatePassword: password,
          outputPath: '$pdfPath.signed.pdf',
        ),
      );
      
      print('${pdfPath}: ${result.success ? 'Success' : 'Failed'}');
    } catch (e) {
      print('${pdfPath}: Error - $e');
    }
  }

  // Final cleanup
  ProductionPdfSigningService.clearSensitiveData(password: password);
}
```

### Custom Validation Wrapper

```dart
class SigningValidator {
  static Future<ValidationResult> comprehensiveValidation(
    SigningRequest request,
  ) async {
    final errors = <String>[];

    // Check PDF file exists and is accessible
    if (!File(request.pdfFilePath).existsSync()) {
      errors.add('PDF file cannot be accessed');
    }

    // Check output directory is writable
    if (!await SecureFilePickerService.validateOutputPath(request.outputPath)) {
      errors.add('Output directory is not writable');
    }

    // Validate certificate security
    if (!request.certificate.isCurrentlyValid) {
      errors.add('Certificate is not valid');
    }

    // Add any other custom validation...

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
```

## Error Handling Best Practices

### Category-Based Error Handling

```dart
try {
  final result = await ProductionPdfSigningService.signPdf(request);
  if (!result.success) {
    final error = result.errorMessage ?? 'Unknown error';
    
    if (error.contains('Certificate')) {
      handleCertificateError(error);
    } else if (error.contains('PDF')) {
      handlePdfError(error);
    } else if (error.contains('password')) {
      handlePasswordError(error);
    } else {
      handleGenericError(error);
    }
  }
} on FileSystemException catch (e) {
  handleFileSystemError(e);
} on Exception catch (e) {
  handleUnexpectedError(e);
}
```

### User-Friendly Error Messages

```dart
String getUserFriendlyMessage(String technicalError) {
  if (technicalError.contains('expired')) {
    return 'Your certificate has expired. Please get a new one.';
  }
  if (technicalError.contains('password')) {
    return 'The certificate password is incorrect.';
  }
  if (technicalError.contains('file not found')) {
    return 'The file you selected could not be found.';
  }
  if (technicalError.contains('writable')) {
    return 'Cannot save the signed PDF. Check storage permissions.';
  }
  return 'Something went wrong. Please try again.';
}
```

## Platform-Specific Considerations

### Android/iOS

#### Permissions
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### Storage Access
```dart
// Files go to app's document directory
// Users must grant permission via file picker
// Downloads folder selected automatically if available
```

### Windows/macOS

#### File Access
```dart
// Full filesystem access granted
// Desktop native dialogs used
// Large file support (>500MB possible)
```

### Web

#### Browser Limitations
```dart
// File picker through browser dialog
// Downloaded directly to Downloads folder
// No filesystem persistence between sessions
// Memory-based temporary storage only
```

## Testing the Integration

### Manual Testing Checklist

- [ ] Select PDF file successfully
- [ ] Select certificate file successfully
- [ ] Certificate validation shows expiry info
- [ ] Password verification works
- [ ] Password field masks input
- [ ] All required fields enforced
- [ ] Sign button disabled until ready
- [ ] Signing completes successfully
- [ ] Signed PDF created with correct name
- [ ] No sensitive data in logs
- [ ] Error messages are clear
- [ ] Success dialog shows file location
- [ ] View PDF button opens viewer
- [ ] Works on Android
- [ ] Works on iOS
- [ ] Works on Windows
- [ ] Works on macOS
- [ ] Works on Linux
- [ ] Works on Web

### Automated Testing

```dart
// Run tests
flutter test

// Integration tests
flutter drive --target=test_driver/app.dart
```

## Performance Characteristics

### Typical Operation Times (Estimated)

| Operation | Time |
|-----------|------|
| PDF validation | < 100ms |
| Certificate validation | < 50ms |
| Password verification | < 200ms |
| Certificate parsing | < 300ms |
| PDF signing | 1-5s (depends on PDF size) |
| Signature verification | < 100ms |

### Memory Usage

| Phase | Approx Memory |
|-------|--------------|
| File selection | ~2 MB |
| Certificate loading | ~5 MB |
| PDF loading (for signing) | +PDF size |
| Signing operation | Peak before release |
| After cleanup | < 1 MB |

## Troubleshooting Common Issues

### Certificate Issues

**Problem**: "Invalid certificate format"
- **Cause**: File is not .p12/.pfx/.pem
- **Solution**: Convert to .p12 format using `openssl`

**Problem**: "Certificate password incorrect"
- **Cause**: Wrong password entered
- **Solution**: Verify password with certificate provider

**Problem**: "Certificate has expired"
- **Cause**: Certificate validity period ended
- **Solution**: Renew certificate with provider

### File Issues

**Problem**: "PDF file does not exist"
- **Cause**: File was moved or deleted after selection
- **Solution**: Re-select file

**Problem**: "Cannot write to output directory"
- **Cause**: Permission denied
- **Solution**: Try different directory (Downloads preferred)

### Signing Issues

**Problem**: "PDF signing failed"
- **Cause**: Corrupted PDF or certificate
- **Solution**: Try with different PDF or certificate

**Problem**: "Operation timeout"
- **Cause**: Very large PDF (500MB+)
- **Solution**: Split PDF or use backend service

## Monitoring & Analytics

### Safe Logging

```dart
// ✅ Safe to log
debugPrint('Signing operation started');
debugPrint('PDF size: ${pdfBytes.length}');
debugPrint('Certificate: ${cert.fileName}');
debugPrint('Signing completed successfully');

// ❌ Never log
// debugPrint('Password: $password');
// debugPrint('Certificate path: $certPath');
// debugPrint('Signature hash: $hash');
```

### Analytics Events

```dart
// Track (without sensitive data)
analytics.logEvent('pdf_signing_started');
analytics.logEvent('pdf_signing_completed', {
  'pdf_size_mb': pdfBytes.length ~/ (1024 * 1024),
  'success': true,
});
analytics.logEvent('pdf_signing_failed', {
  'reason': 'password_invalid',
});
```

## Support & Help

### For Issues
- Check error message first
- Review troubleshooting section
- Check certificate format
- Verify file permissions
- Try on different device/platform

### For Enhancement Requests
- Backend-based signing
- Multiple signatures per PDF
- Timestamp authority integration
- Hardware security module support
- Biometric authentication

## Next Steps

1. **Integrate into App**: Add to your home screen navigation
2. **Test on All Platforms**: Verify on Android, iOS, Windows, macOS, Linux, Web
3. **User Training**: Teach users about certificate preparation
4. **Monitor Usage**: Track signing operations (safely)
5. **Gather Feedback**: Collect user feedback for improvements
6. **Plan Upgrades**: Consider future features mentioned above
