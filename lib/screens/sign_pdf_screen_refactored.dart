import 'dart:io';
import 'package:flutter/material.dart';
import '../models/signing_models.dart';
import '../services/certificate_service.dart';
import '../services/secure_file_picker_service.dart';
import '../services/production_pdf_signing_service.dart';
import 'pdf_viewer_screen.dart';

/// Production-grade Sign PDF screen with enterprise-ready UI/UX
/// Implements step-by-step signing workflow with comprehensive validation
class SignPdfScreenRefactored extends StatefulWidget {
  const SignPdfScreenRefactored({super.key});

  @override
  State<SignPdfScreenRefactored> createState() =>
      _SignPdfScreenRefactoredState();
}

class _SignPdfScreenRefactoredState extends State<SignPdfScreenRefactored> {
  // Signing workflow steps
  static const int totalSteps = 5;
  int _currentStep = 0;

  // File selections
  File? _selectedPdfFile;
  File? _selectedCertificateFile;
  PdfMetadata? _pdfMetadata;
  CertificateInfo? _certificateInfo;

  // Form state
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // UI state
  bool _isProcessing = false;
  final double _signingProgress = 0.0;
  String? _errorMessage;
  String? _successMessage;
  bool _showPassword = false;
  bool _useVisibleSignature = true;
  SignatureLocation _selectedLocation = SignatureLocation.bottomLeft;

  // Validation state
  bool _pdfValidated = false;
  bool _certificateValidated = false;
  bool _passwordVerified = false;
  bool _nameEntered = false;

  CertificateValidationResult? _certificateValidation;

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Sign PDF'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: _isProcessing
          ? _buildProcessingState()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Step indicator
                  _buildStepIndicator(isDark),
                  const SizedBox(height: 20),

                  // Error / Success messages
                  if (_errorMessage != null) _buildErrorBanner(isDark),
                  if (_successMessage != null) _buildSuccessBanner(isDark),

                  // Step content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentStep == 0) _buildStep1SelectPdf(isDark),
                        if (_currentStep == 1)
                          _buildStep2SelectCertificate(isDark),
                        if (_currentStep == 2) _buildStep3EnterPassword(isDark),
                        if (_currentStep == 3)
                          _buildStep4EnterSignerInfo(isDark),
                        if (_currentStep == 4) _buildStep5Review(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildNavigationButtons(isDark),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? Colors.green
                                : (isActive
                                      ? Colors.blue
                                      : (isDark
                                            ? Colors.grey.shade600
                                            : Colors.grey.shade300)),
                          ),
                        ),
                        if (index < totalSteps - 1) const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : (isActive
                                  ? Colors.blue
                                  : (isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200)),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive || isCompleted
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _getStepTitle(_currentStep),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    const titles = [
      'Select PDF File',
      'Select Certificate',
      'Enter Password',
      'Signer Information',
      'Review & Sign',
    ];
    return titles[step];
  }

  Widget _buildStep1SelectPdf(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildCard(
          isDark,
          child: Column(
            children: [
              Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Select PDF to Sign',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedPdfFile == null
                    ? 'No PDF file selected'
                    : _selectedPdfFile!.path.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (_pdfMetadata != null) ...[
                const SizedBox(height: 12),
                _buildMetadataRow('Pages:', _pdfMetadata!.pageCount.toString()),
                _buildMetadataRow('Size:', _pdfMetadata!.fileSizeDisplay),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _selectPdfFile,
          icon: const Icon(Icons.folder_open),
          label: const Text('Choose PDF File'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2SelectCertificate(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildCard(
          isDark,
          child: Column(
            children: [
              Icon(Icons.security, size: 48, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                'Select Certificate',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCertificateFile == null
                    ? 'No certificate selected'
                    : _selectedCertificateFile!.path.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (_certificateInfo != null) ...[
                const SizedBox(height: 12),
                _buildCertificateDetails(isDark),
              ],
              if (_certificateValidation != null &&
                  _certificateValidation!.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _certificateValidation!.warnings.join('\n'),
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _selectCertificate,
          icon: const Icon(Icons.folder_open),
          label: const Text('Choose Certificate (.p12/.pfx)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3EnterPassword(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildCard(
          isDark,
          child: Column(
            children: [
              Icon(Icons.lock, size: 48, color: Colors.purple),
              const SizedBox(height: 12),
              Text(
                'Certificate Password',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Enter certificate password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _passwordController.text = value);
                },
              ),
              const SizedBox(height: 12),
              if (_passwordVerified)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Password verified',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4EnterSignerInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildCard(
          isDark,
          child: Column(
            children: [
              Icon(Icons.person, size: 48, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                'Signer Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Your full name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _nameEntered = value.isNotEmpty);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for Signing',
                  hintText: 'e.g., Approved, Agreement',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'your@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep5Review(bool isDark) {
    final canSign =
        _pdfValidated &&
        _certificateValidated &&
        _passwordVerified &&
        _nameEntered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildCard(
          isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review Signing Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildReviewRow(
                'PDF File:',
                _selectedPdfFile?.path.split('/').last,
              ),
              _buildReviewRow('Signer Name:', _nameController.text),
              _buildReviewRow(
                'Reason:',
                _reasonController.text.isEmpty ? 'N/A' : _reasonController.text,
              ),
              _buildReviewRow(
                'Certificate:',
                _selectedCertificateFile?.path.split('/').last,
              ),
              if (_certificateInfo != null)
                _buildReviewRow(
                  'Valid Until:',
                  _certificateInfo!.validityPeriod,
                ),
              const SizedBox(height: 16),
              Text(
                'Signature Settings:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _useVisibleSignature,
                onChanged: (value) {
                  setState(() => _useVisibleSignature = value ?? true);
                },
                title: const Text('Visible Signature'),
                dense: true,
              ),
              if (_useVisibleSignature) ...[
                const SizedBox(height: 8),
                DropdownButton<SignatureLocation>(
                  value: _selectedLocation,
                  isExpanded: true,
                  items: SignatureLocation.values.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLocation = value);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: canSign ? _performSigning : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
          ),
          child: const Text(
            'Sign PDF',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (!canSign)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Complete all previous steps to enable signing',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.orange),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildCertificateDetails(bool isDark) {
    if (_certificateInfo == null) return const SizedBox.shrink();

    final isExpiring = CertificateService.shouldWarnAboutExpiry(
      _certificateInfo!,
    );

    return Column(
      children: [
        _buildMetadataRow('Subject:', _certificateInfo!.subject),
        _buildMetadataRow('Issuer:', _certificateInfo!.issuer),
        _buildMetadataRow('Valid Until:', _certificateInfo!.validityPeriod),
        if (isExpiring)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                CertificateService.getExpiryWarningMessage(_certificateInfo!),
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() => _currentStep--);
                _clearErrorMessages();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        if (_currentStep < totalSteps - 1)
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceedToNextStep() ? _proceedToNextStep : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Next'),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: child,
    );
  }

  Widget _buildMetadataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value ?? 'N/A', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _clearErrorMessages,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage ?? 'Success',
              style: const TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Signing PDF...'),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _signingProgress,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_signingProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPdfFile() async {
    try {
      final file = await SecureFilePickerService.pickPdfFile();
      if (file != null) {
        final metadata = await SecureFilePickerService.getPdfMetadata(file);
        setState(() {
          _selectedPdfFile = file;
          _pdfMetadata = metadata;
          _pdfValidated = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('Failed to select PDF: $e');
    }
  }

  Future<void> _selectCertificate() async {
    try {
      final file = await SecureFilePickerService.pickCertificateFile();
      if (file != null) {
        setState(() => _isProcessing = true);

        // Validate certificate
        _certificateValidation =
            await CertificateService.validateCertificateFile(file);

        if (_certificateValidation!.isValid) {
          setState(() {
            _selectedCertificateFile = file;
            _certificateValidated = true;
            _errorMessage = null;
            _isProcessing = false;
          });
        } else {
          setState(() => _isProcessing = false);
          _showError(_certificateValidation!.errors.join('\n'));
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Failed to select certificate: $e');
    }
  }

  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty || _selectedCertificateFile == null) {
      _showError('Please enter password and select certificate');
      return;
    }

    try {
      setState(() => _isProcessing = true);

      final isValid = await CertificateService.verifyCertificatePassword(
        _selectedCertificateFile!,
        _passwordController.text,
      );

      setState(() => _isProcessing = false);

      if (isValid) {
        setState(() {
          _passwordVerified = true;
          _errorMessage = null;
        });
      } else {
        _showError('Invalid certificate password');
      }

      // Parse certificate
      _certificateInfo = await CertificateService.parseCertificate(
        _selectedCertificateFile!,
        _passwordController.text,
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Password verification failed: $e');
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _pdfValidated;
      case 1:
        return _certificateValidated;
      case 2:
        return _passwordVerified;
      case 3:
        return _nameEntered;
      default:
        return true;
    }
  }

  void _proceedToNextStep() async {
    if (_currentStep == 2 && !_passwordVerified) {
      await _verifyPassword();
      if (_passwordVerified && mounted) {
        setState(() => _currentStep++);
      }
    } else if (_canProceedToNextStep()) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _performSigning() async {
    try {
      setState(() => _isProcessing = true);

      // Get output directory
      final outputDir = await SecureFilePickerService.getOutputDirectory();
      final outputFileName = SecureFilePickerService.generateOutputFilename(
        _selectedPdfFile!.path.split('/').last,
      );
      final outputPath = '$outputDir/$outputFileName';

      // Validate output path
      if (!await SecureFilePickerService.validateOutputPath(outputPath)) {
        _showError('Cannot write to output directory');
        setState(() => _isProcessing = false);
        return;
      }

      // Create signing request
      final signingRequest = SigningRequest(
        pdfFilePath: _selectedPdfFile!.path,
        nameOnSignature: _nameController.text,
        reason: _reasonController.text.isEmpty
            ? 'Approved'
            : _reasonController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        certificate: _certificateInfo!,
        certificatePassword: _passwordController.text,
        outputPath: outputPath,
        visibleSignature: _useVisibleSignature,
        location: _selectedLocation,
      );

      // Perform signing
      final result = await ProductionPdfSigningService.signPdf(signingRequest);

      // Clear sensitive data
      ProductionPdfSigningService.clearSensitiveData(
        password: _passwordController.text,
      );
      CertificateService.clearSensitiveData(_passwordController.text);

      setState(() => _isProcessing = false);

      if (result.success && mounted) {
        _showSuccess('PDF signed successfully!');

        // Show success dialog
        if (mounted) {
          _showSigningSuccessDialog(result);
        }
      } else {
        _showError(result.errorMessage ?? 'Signing failed');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Signing error: $e');
    }
  }

  void _showSigningSuccessDialog(SigningResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('PDF Signed Successfully'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signer: ${_nameController.text}'),
            const SizedBox(height: 8),
            Text('Reason: ${_reasonController.text}'),
            const SizedBox(height: 8),
            Text('File Size: ${result.fileSize ?? 0} bytes'),
            const SizedBox(height: 8),
            Text(
              'Saved to:\n${result.signedFilePath}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openSignedPdf(result.signedFilePath);
            },
            child: const Text('View PDF'),
          ),
        ],
      ),
    );
  }

  void _openSignedPdf(String? filePath) {
    if (filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => PdfViewerScreen(externalFile: File(filePath)),
        ),
      );
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 5), _clearErrorMessages);
  }

  void _showSuccess(String message) {
    setState(() => _successMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _successMessage = null);
      }
    });
  }

  void _clearErrorMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }
}
