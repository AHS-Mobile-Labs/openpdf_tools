import 'package:flutter/material.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:openpdf_tools/utils/responsive_helper.dart';
class AdaptiveNavigation extends StatefulWidget {
  final Widget child;
  final Function(int index) onNavigationChanged;
  final int selectedIndex;
  final List<NavigationItem> items;
  const AdaptiveNavigation({
    super.key,
    required this.child,
    required this.onNavigationChanged,
    this.selectedIndex = 0,
    required this.items,
  });
  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}
class _AdaptiveNavigationState extends State<AdaptiveNavigation> {
  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isDesktop = context.isDesktop;
    if (isMobile) {
      return _buildMobileLayout();
    } else if (isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildTabletLayout();
    }
  }
  Widget _buildMobileLayout() {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.selectedIndex,
        onTap: widget.onNavigationChanged,
        type: BottomNavigationBarType.fixed,
        items: widget.items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
                tooltip: item.tooltip,
              ),
            )
            .toList(),
      ),
    );
  }
  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSideBar(width: 250, showLabels: true),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSideBar(width: 280, showLabels: true),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
  Widget _buildSideBar({required double width, required bool showLabels}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'OpenPDF Tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(color: Colors.white30),
          Expanded(
            child: ListView(
              children: List.generate(
                widget.items.length,
                (index) => _buildNavItem(
                  item: widget.items[index],
                  index: index,
                  isSelected: widget.selectedIndex == index,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNavItem({
    required NavigationItem item,
    required int index,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNavigationChanged(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class NavigationItem {
  final IconData icon;
  final String label;
  final String tooltip;
  final Widget screen;
  NavigationItem({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.screen,
  });
}
class AdaptiveDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<AdaptiveDialogAction> actions;
  final bool barrierDismissible;
  const AdaptiveDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.barrierDismissible = true,
  });
  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.isIOS) {
      return _buildCupertinoDialog(context);
    }
    return _buildMaterialDialog(context);
  }
  Widget _buildMaterialDialog(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: actions
          .map(
            (action) => TextButton(
              onPressed: () {
                Navigator.of(context).pop(action.value);
                action.onPressed?.call();
              },
              child: Text(action.label),
            ),
          )
          .toList(),
    );
  }
  Widget _buildCupertinoDialog(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions
                    .map(
                      (action) => TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(action.value);
                          action.onPressed?.call();
                        },
                        child: Text(action.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class AdaptiveDialogAction {
  final String label;
  final dynamic value;
  final VoidCallback? onPressed;
  final bool isDestructive;
  AdaptiveDialogAction({
    required this.label,
    this.value,
    this.onPressed,
    this.isDestructive = false,
  });
}
class AdaptiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isDestructive;
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isDestructive = false,
  });
  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive
            ? Colors.red
            : Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.screenWidth * 0.15,
          vertical: 12,
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
    return context.responsive.isMobile
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}