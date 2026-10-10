import 'package:flutter/material.dart';
import '../config/premium_theme.dart';

class ModernNavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;
  final String? badge;
  final String? section;

  ModernNavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.badge,
    this.section,
  });
}

class ModernNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final List<ModernNavigationItem> items;
  final Widget? header;
  final Widget? footer;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const ModernNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.items,
    this.header,
    this.footer,
    this.isExpanded = true,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = isExpanded ? 240.0 : 68.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfacePrimary
            : PremiumColors.lightSurfacePrimary,
        border: Border(
          right: BorderSide(
            color: isDark
                ? PremiumColors.darkDivider
                : PremiumColors.lightDivider,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          if (header != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? 16 : 8,
                vertical: 14,
              ),
              child: header!,
            ),
            Divider(
              color: isDark
                  ? PremiumColors.darkDivider
                  : PremiumColors.lightDivider,
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

                final showSectionHeader = isExpanded &&
                    item.section != null &&
                    (index == 0 || items[index - 1].section != item.section);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSectionHeader)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 18,
                          top: 14,
                          bottom: 6,
                        ),
                        child: Text(
                          item.section!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isExpanded ? 8 : 6,
                        vertical: 2,
                      ),
                      child: Tooltip(
                        message: isExpanded ? '' : item.label,
                        preferBelow: false,
                        waitDuration: const Duration(milliseconds: 300),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onIndexChanged(index),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected
                                    ? PremiumColors.brandRed.withValues(alpha: 0.12)
                                    : Colors.transparent,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isExpanded ? 12 : 0,
                                vertical: 9,
                              ),
                              child: Row(
                                mainAxisAlignment: isExpanded
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? PremiumColors.brandRed
                                        : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600),
                                  ),
                                  if (isExpanded) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? PremiumColors.brandRed
                                              : (isDark
                                                  ? Colors.grey.shade300
                                                  : const Color(0xFF1E1E1E)),
                                        ),
                                      ),
                                    ),
                                    if (item.badge != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? PremiumColors.brandRed
                                              : (isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade200),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.badge!,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade700),
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (footer != null || onToggleExpanded != null) ...[
            Divider(
              color: isDark
                  ? PremiumColors.darkDivider
                  : PremiumColors.lightDivider,
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  ?footer,
                  if (onToggleExpanded != null)
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      tooltip: isExpanded ? 'Collapse Sidebar' : 'Expand Sidebar',
                      onPressed: onToggleExpanded,
                    ),
                ],
              ),
            ),
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
    final displayItems = items.length > 5 ? items.take(5).toList() : items;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfacePrimary
            : PremiumColors.lightSurfacePrimary,
        border: Border(
          top: BorderSide(
            color: isDark
                ? PremiumColors.darkDivider
                : PremiumColors.lightDivider,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(displayItems.length, (index) {
              final isSelected = selectedIndex == index;
              final item = displayItems[index];

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onIndexChanged(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? PremiumColors.brandRed.withValues(alpha: 0.12)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? PremiumColors.brandRed
                                  : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? PremiumColors.brandRed
                                  : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                            ),
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
      ),
    );
  }
}
