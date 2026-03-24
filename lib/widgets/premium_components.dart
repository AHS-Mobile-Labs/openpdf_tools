import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/animation_utils.dart';
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final EdgeInsets padding;
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PremiumSpacing.lg,
      vertical: PremiumSpacing.md,
    ),
  });
  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}
class _PremiumButtonState extends State<PremiumButton> {
  @override
  Widget build(BuildContext context) {
    return ButtonAnimations.scaleOnPress(
      onPressed: widget.isLoading ? () {} : widget.onPressed,
      child: Container(
        width: widget.fullWidth ? double.infinity : null,
        height: PremiumSpacing.buttonHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PremiumColors.luxuryRed,
              PremiumColors.luxuryRed.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: PremiumColors.luxuryRed.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
            child: Padding(
              padding: widget.padding,
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: PremiumSpacing.iconMedium,
                          ),
                          const SizedBox(width: PremiumSpacing.sm),
                        ],
                        Text(
                          widget.label,
                          style: PremiumTypography.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
class PremiumOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool fullWidth;
  const PremiumOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ButtonAnimations.scaleOnPress(
      onPressed: onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: PremiumSpacing.buttonHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? PremiumColors.darkDivider
                : PremiumColors.lightDivider,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
            splashColor: PremiumColors.luxuryRed.withValues(alpha: 0.1),
            highlightColor: PremiumColors.luxuryRed.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PremiumSpacing.lg,
                vertical: PremiumSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: PremiumColors.luxuryRed,
                      size: PremiumSpacing.iconMedium,
                    ),
                    const SizedBox(width: PremiumSpacing.sm),
                  ],
                  Text(
                    label,
                    style: PremiumTypography.labelLarge.copyWith(
                      color: PremiumColors.luxuryRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final bool enableGlassmorphism;
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PremiumSpacing.lg),
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.enableGlassmorphism = false,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfacePrimary);
    final cardContent = Container(
      decoration: BoxDecoration(
        color: enableGlassmorphism ? bgColor.withValues(alpha: 0.8) : bgColor,
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
        border: enableGlassmorphism
            ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: enableGlassmorphism ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      return CardAnimations.elevationOnTap(onTap: onTap!, child: cardContent);
    }
    return cardContent;
  }
}
class PremiumGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final List<Color> colors;
  final VoidCallback? onTap;
  const PremiumGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PremiumSpacing.lg),
    this.colors = const [PremiumColors.luxuryRed, Color(0xFFE94B3C)],
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      return CardAnimations.elevationOnTap(onTap: onTap!, child: cardContent);
    }
    return cardContent;
  }
}
class PremiumTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int? maxLines;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final bool obscureText;
  const PremiumTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.obscureText = false,
  });
  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}
class _PremiumTextFieldState extends State<PremiumTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      duration: AnimationUtils.fast,
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 0, end: 1).animate(_focusController);
  }
  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: PremiumTypography.labelMedium.copyWith(
                color: Color.lerp(
                  isDark
                      ? PremiumColors.darkTextSecondary
                      : PremiumColors.lightTextSecondary,
                  PremiumColors.luxuryRed,
                  _focusAnimation.value,
                ),
              ),
            ),
            const SizedBox(height: PremiumSpacing.sm),
            Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  _focusController.forward();
                } else {
                  _focusController.reverse();
                }
              },
              child: TextField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                obscureText: widget.obscureText,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: Color.lerp(
                            isDark
                                ? PremiumColors.darkTextTertiary
                                : PremiumColors.lightTextTertiary,
                            PremiumColors.luxuryRed,
                            _focusAnimation.value,
                          ),
                        )
                      : null,
                  suffixIcon: widget.suffixIcon != null
                      ? GestureDetector(
                          onTap: widget.onSuffixTap,
                          child: Icon(
                            widget.suffixIcon,
                            color: PremiumColors.luxuryRed,
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      PremiumSpacing.radiusMd,
                    ),
                    borderSide: BorderSide(
                      color: Color.lerp(
                        isDark
                            ? PremiumColors.darkDivider
                            : PremiumColors.lightDivider,
                        PremiumColors.luxuryRed,
                        _focusAnimation.value,
                      )!,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      PremiumSpacing.radiusMd,
                    ),
                    borderSide: const BorderSide(
                      color: PremiumColors.lightDivider,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
class PremiumChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;
  final Color? backgroundColor;
  const PremiumChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.backgroundColor,
  });
  @override
  State<PremiumChip> createState() => _PremiumChipState();
}
class _PremiumChipState extends State<PremiumChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationUtils.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void didUpdateWidget(PremiumChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward();
    } else if (!widget.selected && oldWidget.selected) {
      _controller.reverse();
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: widget.selected
              ? PremiumColors.luxuryRed
              : (widget.backgroundColor ??
                    (isDark
                        ? PremiumColors.darkSurfaceSecondary
                        : PremiumColors.lightSurfaceSecondary)),
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusCircle),
          border: !widget.selected
              ? Border.all(
                  color: isDark
                      ? PremiumColors.darkDivider
                      : PremiumColors.lightDivider,
                  width: 1,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSelected,
            borderRadius: BorderRadius.circular(PremiumSpacing.radiusCircle),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PremiumSpacing.lg,
                vertical: PremiumSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.selected
                          ? Colors.white
                          : (isDark
                                ? PremiumColors.darkTextSecondary
                                : PremiumColors.lightTextSecondary),
                      size: PremiumSpacing.iconSmall,
                    ),
                    const SizedBox(width: PremiumSpacing.sm),
                  ],
                  Text(
                    widget.label,
                    style: PremiumTypography.labelMedium.copyWith(
                      color: widget.selected
                          ? Colors.white
                          : (isDark
                                ? PremiumColors.darkText
                                : PremiumColors.lightText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = PremiumSpacing.radiusMd,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LoadingAnimations.shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? PremiumColors.darkSurfaceSecondary
              : PremiumColors.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
class SkeletonCardLoader extends StatelessWidget {
  final int lines;
  const SkeletonCardLoader({super.key, this.lines = 3});
  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: double.infinity, height: 20),
          const SizedBox(height: PremiumSpacing.md),
          ...List.generate(
            lines,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: PremiumSpacing.sm),
              child: SkeletonLoader(width: double.infinity, height: 12),
            ),
          ),
        ],
      ),
    );
  }
}
class PremiumBadge extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final Color? textColor;
  final IconData? icon;
  const PremiumBadge({
    super.key,
    required this.label,
    this.bgColor,
    this.textColor,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor ?? PremiumColors.luxuryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: PremiumSpacing.md,
        vertical: PremiumSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: PremiumSpacing.iconSmall,
              color: textColor ?? PremiumColors.luxuryRed,
            ),
            const SizedBox(width: PremiumSpacing.xs),
          ],
          Text(
            label,
            style: PremiumTypography.labelSmall.copyWith(
              color: textColor ?? PremiumColors.luxuryRed,
            ),
          ),
        ],
      ),
    );
  }
}
class PremiumDivider extends StatelessWidget {
  final String? label;
  final EdgeInsets padding;
  const PremiumDivider({
    super.key,
    this.label,
    this.padding = const EdgeInsets.symmetric(vertical: PremiumSpacing.lg),
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (label == null) {
      return Padding(
        padding: padding,
        child: Divider(
          color: isDark
              ? PremiumColors.darkDivider
              : PremiumColors.lightDivider,
        ),
      );
    }
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark
                  ? PremiumColors.darkDivider
                  : PremiumColors.lightDivider,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
            child: Text(
              label!,
              style: PremiumTypography.bodySmall.copyWith(
                color: isDark
                    ? PremiumColors.darkTextTertiary
                    : PremiumColors.lightTextTertiary,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark
                  ? PremiumColors.darkDivider
                  : PremiumColors.lightDivider,
            ),
          ),
        ],
      ),
    );
  }
}
class PremiumListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsets padding;
  const PremiumListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailingIcon,
    this.onTap,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(PremiumSpacing.lg),
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark
                ? PremiumColors.darkSurfaceSecondary
                : PremiumColors.lightSurfaceSecondary),
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: PremiumColors.luxuryRed),
                  const SizedBox(width: PremiumSpacing.lg),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PremiumTypography.bodyLarge.copyWith(
                          color: isDark
                              ? PremiumColors.darkText
                              : PremiumColors.lightText,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: PremiumSpacing.xs),
                        Text(
                          subtitle!,
                          style: PremiumTypography.bodySmall.copyWith(
                            color: isDark
                                ? PremiumColors.darkTextTertiary
                                : PremiumColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: PremiumSpacing.md),
                  Icon(
                    trailingIcon,
                    color: isDark
                        ? PremiumColors.darkTextTertiary
                        : PremiumColors.lightTextTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (onTap != null) {
      return CardAnimations.elevationOnTap(onTap: onTap!, child: content);
    }
    return content;
  }
}