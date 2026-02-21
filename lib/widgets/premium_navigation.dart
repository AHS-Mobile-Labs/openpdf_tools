import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/animation_utils.dart';

/// Premium animated bottom navigation bar
class PremiumBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  
  const PremiumBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);
  
  @override
  State<PremiumBottomNavigation> createState() =>
      _PremiumBottomNavigationState();
}

class _PremiumBottomNavigationState extends State<PremiumBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  
  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: AnimationUtils.standard,
        vsync: this,
      ),
    );
    _animationControllers[widget.currentIndex].forward();
  }
  
  @override
  void didUpdateWidget(PremiumBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationControllers[oldWidget.currentIndex].reverse();
      _animationControllers[widget.currentIndex].forward();
    }
  }
  
  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfacePrimary
            : PremiumColors.lightSurfacePrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PremiumSpacing.md,
            vertical: PremiumSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              widget.items.length,
              (index) => _AnimatedNavItem(
                item: widget.items[index],
                isActive: widget.currentIndex == index,
                animationController: _animationControllers[index],
                onTap: () => widget.onTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual animated navigation item
class _AnimatedNavItem extends StatefulWidget {
  final BottomNavItem item;
  final bool isActive;
  final AnimationController animationController;
  final VoidCallback onTap;
  
  const _AnimatedNavItem({
    required this.item,
    required this.isActive,
    required this.animationController,
    required this.onTap,
  });
  
  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem> {
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeOut,
      ),
    );
  }
  
  @override
  void didUpdateWidget(_AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationController != widget.animationController) {
      _setupAnimations();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: widget.animationController,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(PremiumSpacing.md),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? PremiumColors.luxuryRed.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(PremiumSpacing.radiusMd),
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: PremiumSpacing.iconMedium,
                    color: Color.lerp(
                      isDark
                          ? PremiumColors.darkTextTertiary
                          : PremiumColors.lightTextTertiary,
                      PremiumColors.luxuryRed,
                      _opacityAnimation.value - 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: PremiumSpacing.xs),
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  widget.item.label,
                  style: PremiumTypography.labelSmall.copyWith(
                    color: widget.isActive
                        ? PremiumColors.luxuryRed
                        : (isDark
                            ? PremiumColors.darkTextTertiary
                            : PremiumColors.lightTextTertiary),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bottom navigation item model
class BottomNavItem {
  final IconData icon;
  final String label;
  
  BottomNavItem({
    required this.icon,
    required this.label,
  });
}

/// Premium top app bar with elevation and blur effects
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final bool showElevation;
  
  const PremiumAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
    this.showElevation = true,
  }) : super(key: key);
  
  @override
  Size get preferredSize => const Size.fromHeight(56);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfacePrimary
            : PremiumColors.lightSurfacePrimary,
        boxShadow: showElevation
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PremiumSpacing.lg,
            vertical: PremiumSpacing.md,
          ),
          child: Row(
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(PremiumSpacing.sm),
                    decoration: BoxDecoration(
                      color: isDark
                          ? PremiumColors.darkSurfaceSecondary
                          : PremiumColors.lightSurfaceSecondary,
                      borderRadius:
                          BorderRadius.circular(PremiumSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: PremiumSpacing.iconMedium,
                      color: isDark
                          ? PremiumColors.darkText
                          : PremiumColors.lightText,
                    ),
                  ),
                ),
              if (showBackButton) const SizedBox(width: PremiumSpacing.lg),
              Expanded(
                child: Text(
                  title,
                  style: PremiumTypography.headlineSmall.copyWith(
                    color: isDark
                        ? PremiumColors.darkText
                        : PremiumColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: PremiumSpacing.md),
                Row(children: actions!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium icon button
class PremiumIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final bool showBackground;
  
  const PremiumIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = PremiumSpacing.iconMedium,
    this.showBackground = true,
  }) : super(key: key);
  
  @override
  State<PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<PremiumIconButton> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ButtonAnimations.scaleOnPress(
      onPressed: widget.onPressed,
      child: Container(
        padding: const EdgeInsets.all(PremiumSpacing.md),
        decoration: BoxDecoration(
          color: widget.showBackground
              ? (isDark
                  ? PremiumColors.darkSurfaceSecondary
                  : PremiumColors.lightSurfaceSecondary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        ),
        child: Icon(
          widget.icon,
          size: widget.size,
          color: widget.color ?? PremiumColors.luxuryRed,
        ),
      ),
    );
  }
}
