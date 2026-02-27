import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openpdf_tools/config/app_config.dart';
import 'package:openpdf_tools/services/file_history_service.dart';
import 'pdf_viewer_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryItem>> _historyFuture;
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _historyFuture = FileHistoryService.getHistory();
    _loadData();
  }

  void _loadData() async {
    final favorites = await FileHistoryService.getFavorites();
    setState(() {
      _favorites = Set.from(favorites);
      _historyFuture = FileHistoryService.getHistory();
    });
  }

  void _toggleFavorite(String filePath) async {
    final isFav = await FileHistoryService.toggleFavorite(filePath);
    setState(() {
      if (isFav) {
        _favorites.add(filePath);
      } else {
        _favorites.remove(filePath);
      }
    });
  }

  void _removeFromHistory(String filePath) async {
    await FileHistoryService.removeFromHistory(filePath);
    _loadData();
  }

  void _openFile(String filePath) {
    final file = File(filePath);
    if (file.existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerScreen(externalFile: file)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File no longer exists')));
      _removeFromHistory(filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F0F0F)
            : const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: const Text('History & Favorites'),
          backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          bottom: TabBar(
            labelColor: isDark ? Colors.white : Colors.black87,
            unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
            indicatorColor: const Color(0xFFC6302C),
            tabs: const [
              Tab(icon: Icon(Icons.history), text: 'Recent'),
              Tab(icon: Icon(Icons.star), text: 'Favorites'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildHistoryTab(), _buildFavoritesTab()]),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<HistoryItem>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No history yet', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final exists = item.fileExists;

            return ListTile(
              leading: Icon(
                Icons.description,
                color: exists ? AppConfig.primaryColor : Colors.grey,
              ),
              title: Text(
                item.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                DateFormat('MMM dd, yyyy • HH:mm').format(item.date),
                style: TextStyle(
                  fontSize: 12,
                  color: exists ? Colors.grey : AppConfig.primaryColor,
                ),
              ),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _favorites.contains(item.filePath)
                            ? Icons.star
                            : Icons.star_outline,
                        color: _favorites.contains(item.filePath)
                            ? Colors.amber
                            : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(item.filePath),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeFromHistory(item.filePath),
                    ),
                  ],
                ),
              ),
              onTap: exists ? () => _openFile(item.filePath) : null,
              enabled: exists,
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder<List<String>>(
      future: FileHistoryService.getFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = snapshot.data ?? [];
        if (favorites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No favorites yet', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final filePath = favorites[index];
            final file = File(filePath);
            final exists = file.existsSync();
            final fileName = filePath.split('/').last;

            return ListTile(
              leading: Icon(
                Icons.description,
                color: exists ? AppConfig.primaryColor : Colors.grey,
              ),
              title: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                exists ? 'Available' : 'File not found',
                style: TextStyle(
                  fontSize: 12,
                  color: exists ? Colors.grey : AppConfig.primaryColor,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.star, color: Colors.amber),
                onPressed: () => _toggleFavorite(filePath),
              ),
              onTap: exists ? () => _openFile(filePath) : null,
              enabled: exists,
            );
          },
        );
      },
    );
  }
}
