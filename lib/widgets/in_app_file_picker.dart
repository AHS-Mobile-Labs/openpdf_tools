import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Get a sensible default directory for file picking on Linux/macOS/Windows
Future<String> _getDefaultPickDirectory() async {
  try {
    // Try Downloads directory first
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null && await downloadsDir.exists()) {
      return downloadsDir.path;
    }
  } catch (e) {
    developer.log('Error getting downloads directory', error: e);
  }

  try {
    // Fallback to home directory
    final homeDir = Platform.environment['HOME'];
    if (homeDir != null && await Directory(homeDir).exists()) {
      return homeDir;
    }
  } catch (e) {
    developer.log('Error accessing home directory', error: e);
  }

  // Final fallback to root or current directory
  return Platform.isWindows ? 'C:\\' : '/home';
}

/// Simple in-app file picker dialog that supports single and multi-selection,
/// Android runtime permission checks, and a mobile-optimized layout.
///
/// Use `showInAppFilePicker` for single-file selection, or
/// `showInAppFilePickerMultiple` for multi-select.
Future<String?> showInAppFilePicker(
  BuildContext context, {
  String? initialDirectory,
  List<String>? allowedExtensions,
}) async {
  final dir = initialDirectory ?? await _getDefaultPickDirectory();
  final res = await showDialog<List<String>>(
    // ignore: use_build_context_synchronously
    context: context,
    builder: (ctx) => _InAppFilePickerDialog(
      initialDir: dir,
      allowedExtensions: allowedExtensions ?? const [],
      allowMultiple: false,
    ),
  );
  return (res == null || res.isEmpty) ? null : res.first;
}

Future<List<String>?> showInAppFilePickerMultiple(
  BuildContext context, {
  String? initialDirectory,
  List<String>? allowedExtensions,
}) async {
  final dir = initialDirectory ?? await _getDefaultPickDirectory();
  return showDialog<List<String>>(
    // ignore: use_build_context_synchronously
    context: context,
    builder: (ctx) => _InAppFilePickerDialog(
      initialDir: dir,
      allowedExtensions: allowedExtensions ?? const [],
      allowMultiple: true,
    ),
  );
}

class _InAppFilePickerDialog extends StatefulWidget {
  final String initialDir;
  final List<String> allowedExtensions;
  final bool allowMultiple;
  const _InAppFilePickerDialog({required this.initialDir, required this.allowedExtensions, required this.allowMultiple});

  @override
  State<_InAppFilePickerDialog> createState() => _InAppFilePickerDialogState();
}

class _InAppFilePickerDialogState extends State<_InAppFilePickerDialog> {
  late String currentDir;
  List<FileSystemEntity> entries = [];
  bool loading = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    currentDir = widget.initialDir;
    _ensurePermissionsAndRead();
  }

  Future<void> _ensurePermissionsAndRead() async {
    // On Android we need to request storage permission for direct file access
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // If not granted, still allow entering a path or using the gallery alternative
      }
    }
    _readDir();
  }

  void _readDir() async {
    setState(() => loading = true);
    try {
      final dir = Directory(currentDir);
      final list = dir.existsSync() ? dir.listSync() : <FileSystemEntity>[];
      list.sort((a, b) {
        final aIsDir = a is Directory ? 0 : 1;
        final bIsDir = b is Directory ? 0 : 1;
        if (aIsDir != bIsDir) return aIsDir - bIsDir;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      setState(() {
        entries = list;
      });
    } catch (e) {
      developer.log('Error reading directory', error: e);
      setState(() => entries = []);
    } finally {
      setState(() => loading = false);
    }
  }

  void _goUp() {
    final parent = p.dirname(currentDir);
    if (parent != currentDir) {
      setState(() => currentDir = parent);
      _readDir();
    }
  }

  bool _fileAllowed(String path) {
    if (widget.allowedExtensions.isEmpty) return true;
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return widget.allowedExtensions.map((e) => e.toLowerCase()).contains(ext);
  }

  Future<void> _enterPath() async {
    final controller = TextEditingController(text: currentDir);
      // ignore: use_build_context_synchronously
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter path'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '/path/to/file.pdf')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
        ],
      ),
    );

    if (ok == true) {
      final pth = controller.text.trim();
      if (pth.isEmpty) return;
      final f = File(pth);
      if (await f.exists()) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop([f.path]);
      } else {
      // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found')));
      }
    }
  }

  Future<void> _useGallery() async {
    try {
      final picker = ImagePicker();
      if (widget.allowMultiple) {
        final picked = await picker.pickMultiImage();
        if (picked.isNotEmpty) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(picked.map((e) => e.path).toList());
        }
      } else {
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (!mounted) return;
        if (picked != null) Navigator.of(context).pop([picked.path]);
      }
    } catch (e) {
      developer.log('Gallery pick failed', error: e);
      if (mounted) {
      // ignore: use_build_context_synchronously
        // ignore: use_build_context_synchronously

        // ignore: use_build_context_synchronously


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery pick failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final width = isMobile ? MediaQuery.of(context).size.width * 0.95 : 700.0;
    final height = isMobile ? MediaQuery.of(context).size.height * 0.7 : 420.0;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.allowMultiple ? 'Select files' : 'Select file')),
          IconButton(icon: const Icon(Icons.arrow_upward), onPressed: _goUp),
          IconButton(icon: const Icon(Icons.edit), onPressed: _enterPath),
        ],
      ),
      content: SizedBox(
        width: width,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                children: [
                  Expanded(child: Text(currentDir, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  if (Platform.isAndroid || Platform.isIOS) TextButton.icon(onPressed: _useGallery, icon: const Icon(Icons.photo), label: const Text('Gallery')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : entries.isEmpty
                      ? Center(child: Text('No files or permission denied in $currentDir'))
                      : ListView.builder(
                          itemCount: entries.length,
                          itemBuilder: (ctx, i) {
                            final e = entries[i];
                            final name = p.basename(e.path);
                            if (e is Directory) {
                              return ListTile(
                                leading: const Icon(Icons.folder),
                                title: Text(name),
                                onTap: () {
                                  setState(() => currentDir = e.path);
                                  // ignore: use_build_context_synchronously

                                  _readDir();
                                },
                              );
                            } else {
                              if (!_fileAllowed(e.path)) return const SizedBox.shrink();
                              final stat = e.statSync();
                              final selected = _selected.contains(e.path);
                              return ListTile(
                                leading: widget.allowMultiple
                                    ? Checkbox(value: selected, onChanged: (v) => setState(() => v == true ? _selected.add(e.path) : _selected.remove(e.path)))
                                    // ignore: use_build_context_synchronously

                                    : const Icon(Icons.insert_drive_file),
                                title: Text(name),
                                subtitle: Text('${(stat.size / 1024).toStringAsFixed(1)} KB'),
                                onTap: () {
                                  if (widget.allowMultiple) {
                                    setState(() {
                                      if (selected) {
                                          _selected.remove(e.path);
                                        } else {
                                          _selected.add(e.path);
                                        }
                                    });
                                  } else {
                                    Navigator.of(context).pop([e.path]);
                                  }
                                },
                              );
                            }
                          },
                        ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
                if (widget.allowMultiple)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
                      child: Text('Select ${_selected.length}'),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
