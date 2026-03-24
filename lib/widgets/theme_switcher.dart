import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openpdf_tools/services/theme_service.dart' as theme_service;
class ThemeSwitcher extends StatelessWidget {
  final bool compact;
  final VoidCallback? onChanged;
  const ThemeSwitcher({super.key, this.compact = false, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Consumer<theme_service.ThemeService>(
      builder: (context, themeService, _) {
        if (!themeService.isInitialized) {
          return const SizedBox.shrink();
        }
        if (compact) {
          return _buildCompactButton(context, themeService);
        }
        return _buildFullButton(context, themeService);
      },
    );
  }
  Widget _buildCompactButton(
    BuildContext context,
    theme_service.ThemeService themeService,
  ) {
    return IconButton(
      icon: Icon(
        themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        size: 24,
      ),
      tooltip: 'Toggle ${themeService.isDarkMode ? 'Light' : 'Dark'} Mode',
      onPressed: () {
        themeService.toggleTheme();
        onChanged?.call();
      },
    );
  }
  Widget _buildFullButton(
    BuildContext context,
    theme_service.ThemeService themeService,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            themeService.isDarkMode ? 'Light Mode' : 'Dark Mode',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(width: 8),
          Switch(
            value: themeService.isDarkMode,
            onChanged: (value) {
              themeService.toggleTheme();
              onChanged?.call();
            },
          ),
        ],
      ),
    );
  }
}
class ThemeModeSelector extends StatelessWidget {
  final Function(theme_service.ThemeMode)? onChanged;
  const ThemeModeSelector({super.key, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Consumer<theme_service.ThemeService>(
      builder: (context, themeService, _) {
        if (!themeService.isInitialized) {
          return const SizedBox.shrink();
        }
        return DropdownButton<theme_service.ThemeMode>(
          value: themeService.themeMode,
          items: theme_service.ThemeMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getThemeModeIcon(mode)),
                      const SizedBox(width: 12),
                      Text(_getThemeModeName(mode)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (theme_service.ThemeMode? newMode) {
            if (newMode != null) {
              themeService.setThemeMode(newMode);
              onChanged?.call(newMode);
            }
          },
        );
      },
    );
  }
  IconData _getThemeModeIcon(theme_service.ThemeMode mode) {
    switch (mode) {
      case theme_service.ThemeMode.light:
        return Icons.light_mode;
      case theme_service.ThemeMode.dark:
        return Icons.dark_mode;
      case theme_service.ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
  String _getThemeModeName(theme_service.ThemeMode mode) {
    switch (mode) {
      case theme_service.ThemeMode.light:
        return 'Light';
      case theme_service.ThemeMode.dark:
        return 'Dark';
      case theme_service.ThemeMode.system:
        return 'System';
    }
  }
}
class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<theme_service.ThemeService>(
      builder: (context, themeService, _) {
        if (!themeService.isInitialized) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_4),
              title: const Text('Theme'),
              trailing: ThemeModeSelector(
                onChanged: (mode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Theme changed to ${_getThemeModeName(mode)}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
          ],
        );
      },
    );
  }
  String _getThemeModeName(theme_service.ThemeMode mode) {
    switch (mode) {
      case theme_service.ThemeMode.light:
        return 'Light';
      case theme_service.ThemeMode.dark:
        return 'Dark';
      case theme_service.ThemeMode.system:
        return 'System';
    }
  }
}