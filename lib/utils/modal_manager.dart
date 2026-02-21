import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/animation_utils.dart';

/// Premium modal dialog manager with smooth animations
class PremiumModalManager {
  /// Show a premium dialog with fade and scale animation
  static Future<T?> showPremiumDialog<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      builder: (context) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutBack),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
  
  /// Show premium bottom sheet with slide animation
  static Future<T?> showPremiumBottomSheet<T>(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
    Duration duration = const Duration(milliseconds: 500),
    double minHeight = 0.3,
    double maxHeight = 0.9,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionAnimationController: AnimationController(
        duration: duration,
        vsync: Navigator.of(context) as TickerProvider,
      ),
    );
  }
  
  /// Show a premium snackbar
  static void showPremiumSnackBar(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = PremiumColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = PremiumColors.error;
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor = PremiumColors.warning;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = PremiumColors.info;
        icon = Icons.info_rounded;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: PremiumSpacing.md),
            Expanded(
              child: Text(
                message,
                style: PremiumTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        ),
        elevation: 2,
        margin: const EdgeInsets.all(PremiumSpacing.lg),
      ),
    );
    
    onDismiss?.call();
  }
}

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

/// Premium alert dialog with smooth animations
class PremiumAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;
  
  const PremiumAlertDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.confirmButtonColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? PremiumColors.darkSurfacePrimary
              : PremiumColors.lightSurfacePrimary,
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(PremiumSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: PremiumTypography.headlineSmall.copyWith(
                  color: isDark
                      ? PremiumColors.darkText
                      : PremiumColors.lightText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: PremiumSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: PremiumTypography.bodyMedium.copyWith(
                  color: isDark
                      ? PremiumColors.darkTextSecondary
                      : PremiumColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: PremiumSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: PremiumOutlinedButton(
                      label: cancelLabel ?? 'Cancel',
                      onPressed: () {
                        onCancel?.call();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: PremiumSpacing.md),
                  Expanded(
                    child: PremiumButton(
                      label: confirmLabel ?? 'Confirm',
                      onPressed: () {
                        onConfirm?.call();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Imports for button components
import 'package:openpdf_tools/widgets/premium_components.dart';

/// Premium bottom sheet wrapper
class PremiumBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback? onClose;
  
  const PremiumBottomSheet({
    Key? key,
    this.title,
    required this.child,
    this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: ModalRoute.of(context)?.animation ??
          AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)?.animation ??
                  AlwaysStoppedAnimation(1.0),
              curve: Curves.easeOut,
            ),
          ),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? PremiumColors.darkSurfacePrimary
              : PremiumColors.lightSurfacePrimary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(PremiumSpacing.radiusXl),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: PremiumSpacing.lg),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? PremiumColors.darkDivider
                      : PremiumColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: PremiumSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PremiumSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: PremiumTypography.headlineSmall.copyWith(
                          color: isDark
                              ? PremiumColors.darkText
                              : PremiumColors.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        onClose?.call();
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? PremiumColors.darkTextTertiary
                            : PremiumColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PremiumSpacing.lg),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PremiumSpacing.lg,
                  ),
                  child: child,
                ),
              ),
            ),
            const SizedBox(height: PremiumSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Premium loading dialog
class PremiumLoadingDialog extends StatelessWidget {
  final String? message;
  
  const PremiumLoadingDialog({
    Key? key,
    this.message,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? PremiumColors.darkSurfacePrimary
              : PremiumColors.lightSurfacePrimary,
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
        ),
        padding: const EdgeInsets.all(PremiumSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(PremiumColors.luxuryRed),
                strokeWidth: 3,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: PremiumSpacing.lg),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: PremiumTypography.bodyMedium.copyWith(
                  color: isDark
                      ? PremiumColors.darkTextSecondary
                      : PremiumColors.lightTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
