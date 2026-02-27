import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/pdf_signature_service.dart';
import '../config/app_config.dart';

class SignPdfScreen extends StatefulWidget {
  const SignPdfScreen({super.key});

  @override
  State<SignPdfScreen> createState() => _SignPdfScreenState();
}

class _SignPdfScreenState extends State<SignPdfScreen> {
  String? _selectedFilePath;
  String? _fileName;
  bool _isProcessing = false;
  final double _progress = 0.0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _signatureImagePath;
  String? _certificatePath;
  String? _privateKeyPath;
  bool _useElectronicSignature = false;

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Pick a PDF file
  Future<void> _pickPDFFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.first.path;
          _fileName = result.files.first.name;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  // Pick a signature image
  Future<void> _pickSignatureImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _signatureImagePath = result.files.first.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  // Sign the PDF
  Future<void> _signPDF() async {
    if (_selectedFilePath == null) {
      _showErrorSnackBar('Please select a PDF file');
      return;
    }

    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final outputDir = await getApplicationDocumentsDirectory();
      final fileName = _fileName!.replaceAll('.pdf', '_signed.pdf');
      final outputPath = '${outputDir.path}/$fileName';

      if (_useElectronicSignature && _emailController.text.isNotEmpty) {
        // Request electronic signature
        final success = await PDFSignatureService.requestElectronicSignature(
          pdfPath: _selectedFilePath!,
          recipientEmail: _emailController.text,
          message:
              'Please sign this document: $_reasonController (requested by ${_nameController.text})',
        );

        setState(() => _isProcessing = false);

        if (success) {
          _showSuccessSnackBar('E-signature request sent');
          _showSignatureRequestDialog(_emailController.text);
        } else {
          _showErrorSnackBar('Failed to send e-signature request');
        }
      } else {
        // Local cryptographic signature
        final success = await PDFSignatureService.addSignatureToDocument(
          inputPath: _selectedFilePath!,
          outputPath: outputPath,
          signatureName: _nameController.text,
          signatureImagePath: _signatureImagePath,
          reason: _reasonController.text.isNotEmpty
              ? _reasonController.text
              : 'Document Signed',
          certificatePath: _certificatePath,
          privateKeyPath: _privateKeyPath,
        );

        setState(() => _isProcessing = false);

        if (success) {
          _showSuccessSnackBar(
            'PDF signed successfully with cryptographic signature',
          );
          _showSignedFileDialog(outputPath, fileName);
        } else {
          _showErrorSnackBar('Failed to sign PDF');
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSignedFileDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Signed Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your PDF has been signed successfully with cryptographic signature.',
            ),
            const SizedBox(height: 16),
            Text(
              'File: $fileName',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Path: $filePath',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.green.shade50,
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Document verified with RSA-SHA256',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _handleShareFile(filePath, fileName, 'Signed PDF');
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showSignatureRequestDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-Signature Request Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The signature request has been sent to:'),
            const SizedBox(height: 12),
            Text(
              email,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
              ),
              child: const Text(
                '📧 The recipient will receive an email with a link to sign the document. '
                'You will be notified when they complete the signature.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign PDF'),
        elevation: 0,
        backgroundColor: AppConfig.primaryColor,
      ),
      body: _isProcessing
          ? _buildProcessingScreen()
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          AppConfig.primaryColor.withValues(alpha: 0.1),
                          AppConfig.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: AppConfig.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 48,
                          color: AppConfig.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sign Your PDF',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your digital signature to PDF documents. Sign yourself or request signatures from others.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // File Selection Section
                  const Text(
                    'Step 1: Select PDF File',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickPDFFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppConfig.primaryColor.withValues(alpha: 0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppConfig.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFilePath == null
                                ? 'Tap to select PDF'
                                : 'PDF Selected: $_fileName',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _selectedFilePath == null
                                  ? Colors.grey
                                  : Colors.green,
                            ),
                          ),
                          if (_selectedFilePath != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap to change file',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Signer Information Section
                  const Text(
                    'Step 2: Enter Your Information',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _reasonController,
                    label: 'Reason for Signing (Optional)',
                    hint: 'e.g., Approved, Agreed',
                    icon: Icons.description,
                  ),
                  const SizedBox(height: 24),

                  // Signature Type Option
                  const Text(
                    'Step 3: Signature Method',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Local Signature'),
                          subtitle: const Text(
                            'Sign with cryptographic signature (RSA-256) saved locally',
                          ),
                          leading: Radio(
                            value: false,
                            groupValue: _useElectronicSignature,
                            onChanged: (value) => setState(
                              () => _useElectronicSignature = value!,
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('Request E-Signature'),
                          subtitle: const Text(
                            'Send signature request to another person via email',
                          ),
                          leading: Radio(
                            value: true,
                            groupValue: _useElectronicSignature,
                            onChanged: (value) => setState(
                              () => _useElectronicSignature = value!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_useElectronicSignature)
                    _buildTextField(
                      controller: _emailController,
                      label: 'Recipient Email',
                      hint: 'recipient@example.com',
                      icon: Icons.email,
                    ),
                  const SizedBox(height: 24),

                  // Signature Image Section
                  const Text(
                    'Step 4: Add Signature Image (Optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickSignatureImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppConfig.primaryColor.withValues(alpha: 0.3),
                        ),
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _signatureImagePath == null
                                ? 'Tap to add signature image'
                                : 'Image added',
                            style: TextStyle(
                              fontSize: 13,
                              color: _signatureImagePath == null
                                  ? Colors.grey.shade600
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Advanced Options
                  ExpansionTile(
                    title: const Text(
                      'Advanced Options',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Certificate Management',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null) {
                            setState(
                              () => _certificatePath = result.files.first.path,
                            );
                          }
                        },
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: Text(
                          _certificatePath == null
                              ? 'Upload Certificate'
                              : 'Certificate loaded',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final success =
                              await PDFSignatureService.exportCertificate(
                                outputPath:
                                    '${(await getApplicationDocumentsDirectory()).path}/my_certificate.pem',
                              );
                          if (success && mounted) {
                            _showSuccessSnackBar(
                              'Certificate exported successfully',
                            );
                          }
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Export Certificate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed:
                        _selectedFilePath == null ||
                            _nameController.text.isEmpty ||
                            (_useElectronicSignature &&
                                _emailController.text.isEmpty)
                        ? null
                        : _signPDF,
                    icon: const Icon(Icons.check_circle),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Sign PDF'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                  ),
                  if (_selectedFilePath != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedFilePath = null;
                          _fileName = null;
                          _nameController.clear();
                          _reasonController.clear();
                          _emailController.clear();
                          _signatureImagePath = null;
                          _certificatePath = null;
                          _privateKeyPath = null;
                          _useElectronicSignature = false;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Reset'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark
                          ? Colors.blue.shade900.withValues(alpha: 0.3)
                          : Colors.blue.shade50,
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      '📌 Features:\n'
                      '• Cryptographic signing with RSA-SHA256 algorithm\n'
                      '• Certificate management support\n'
                      '• E-signature request integration\n'
                      '• Batch document signing\n'
                      '• Document integrity verification',
                      style: TextStyle(fontSize: 11, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _handleShareFile(
    String filePath,
    String fileName,
    String fileType,
  ) async {
    try {
      if (Platform.isLinux) {
        // File sharing not supported on Linux - show file location instead
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('File saved successfully'),
                const SizedBox(height: 8),
                SelectableText(filePath, style: const TextStyle(fontSize: 10)),
              ],
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // You can implement copy to clipboard using flutter/services
              },
            ),
          ),
        );
      } else {
        // Use native sharing on other platforms
        await Share.shareXFiles([
          XFile(filePath),
        ], text: '$fileType: $fileName');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Share failed: $e');
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildProcessingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _progress,
            strokeWidth: 4,
            color: AppConfig.primaryColor,
          ),
          const SizedBox(height: 24),
          const Text(
            'Signing your PDF...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
