import 'package:flutter/material.dart';
class ModernNavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;
  final String? badge;
  ModernNavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.badge,
  });
}
class ModernNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final List<ModernNavigationItem> items;
  final Widget? header;
  final Widget? footer;
  const ModernNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.items,
    this.header,
    this.footer,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF404040) : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          if (header != null) ...[
            Padding(padding: const EdgeInsets.all(20), child: header),
            Divider(
              color: isDark ? const Color(0xFF404040) : Colors.grey.shade200,
              height: 1,
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Menu',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Divider(
              color: isDark ? const Color(0xFF404040) : Colors.grey.shade200,
              height: 1,
            ),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onIndexChanged(index),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected
                              ? const Color(0xFFC6302C).withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 22,
                              color: isSelected
                                  ? const Color(0xFFC6302C)
                                  : (isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFFC6302C)
                                      : (isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade700),
                                ),
                              ),
                            ),
                            if (item.badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC6302C),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item.badge!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (footer != null) ...[
            Divider(
              color: isDark ? const Color(0xFF404040) : Colors.grey.shade200,
              height: 1,
            ),
            Padding(padding: const EdgeInsets.all(16), child: footer),
          ],
        ],
      ),
    );
  }
}
class ModernBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final List<ModernNavigationItem> items;
  const ModernBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.items,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      bottom: true,
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF404040) : Colors.grey.shade200,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length > 5 ? 5 : items.length, (index) {
            final isSelected = selectedIndex == index;
            final item = items[index];
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onIndexChanged(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFFC6302C).withValues(alpha: 0.1)
                                : Colors.transparent,
                          ),
                          child: Icon(
                            item.icon,
                            size: 24,
                            color: isSelected
                                ? const Color(0xFFC6302C)
                                : (isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFC6302C)
                                : (isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}