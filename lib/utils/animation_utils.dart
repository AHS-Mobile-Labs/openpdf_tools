import 'package:flutter/material.dart';

/// Collection of smooth, modern animation utilities
class AnimationUtils {
  // Animation durations
  static const Duration fastest = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
  static const Duration slowest = Duration(milliseconds: 1000);
  
  // Animation curves
  static const Curve smoothCurve = Cubic(0.4, 0.0, 0.2, 1.0);      // Fluent curve
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutBounce = Curves.bounceOut;
  static const Curve easeOutBack = Curves.easeOutBack;
}

/// Page transition animations
class PageTransitions {
  /// Fade transition
  static PageRoute<T> fadeTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
  
  /// Slide transition (right to left)
  static PageRoute<T> slideTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    AxisDirection direction = AxisDirection.left,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case AxisDirection.left:
            begin = const Offset(1.0, 0.0);
            break;
          case AxisDirection.right:
            begin = const Offset(-1.0, 0.0);
            break;
          case AxisDirection.up:
            begin = const Offset(0.0, 1.0);
            break;
          case AxisDirection.down:
            begin = const Offset(0.0, -1.0);
            break;
        }
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  /// Scale transition
  static PageRoute<T> scaleTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: AnimationUtils.easeOutBack),
            ),
          ),
          child: child,
        );
      },
    );
  }
  
  /// Combined slide and fade transition
  static PageRoute<T> slideAndFadeTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: AnimationUtils.smoothCurve)),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
  
  /// Rotate and fade transition
  static PageRoute<T> rotateAndFadeTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: RotationTransition(
            turns: animation.drive(
              Tween(begin: -0.1, end: 0.0)
                  .chain(CurveTween(curve: AnimationUtils.easeOutBack)),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
    );
  }
}

/// Button interaction animations
class ButtonAnimations {
  /// Press animation with scale effect
  static Widget scaleOnPress({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _PressScaleButton(
      onPressed: onPressed,
      duration: duration,
      child: child,
    );
  }
  
  /// Ripple effect on tap
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback onPressed,
    Color rippleColor = const Color(0xFFD4465F),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: rippleColor.withOpacity(0.3),
        highlightColor: rippleColor.withOpacity(0.1),
        child: child,
      ),
    );
  }
  
  /// Elevation change on hover/press
  static Widget elevatedOnPress({
    required Widget child,
    required VoidCallback onPressed,
    double baseElevation = 1,
    double pressedElevation = 4,
  }) {
    return _PressElevatedButton(
      onPressed: onPressed,
      baseElevation: baseElevation,
      pressedElevation: pressedElevation,
      child: child,
    );
  }
}

/// Card animation widgets
class CardAnimations {
  /// Elevation on tap effect
  static Widget elevationOnTap({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return _TapElevationCard(
      onTap: onTap,
      child: child,
    );
  }
  
  /// Floating animation effect
  static Widget floatingEffect({
    required Widget child,
    double offsetY = 4,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return _FloatingCard(
      offsetY: offsetY,
      duration: duration,
      child: child,
    );
  }
  
  /// Slide-in animation
  static Widget slideInAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Offset offset = const Offset(0.0, 0.5),
  }) {
    return _SlideInCard(
      duration: duration,
      offset: offset,
      child: child,
    );
  }
}

/// Loading animations
class LoadingAnimations {
  /// Shimmer effect for skeleton loaders
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return _ShimmerEffect(
      duration: duration,
      child: child,
    );
  }
  
  /// Pulsing animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return _PulseAnimation(
      duration: duration,
      child: child,
    );
  }
}

/// Scroll animations
class ScrollAnimations {
  /// Fade and slide as you scroll
  static Widget fadeAndSlideOnScroll({
    required Widget child,
    required ScrollController scrollController,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return _ScrollFadeSlideAnimation(
      scrollController: scrollController,
      duration: duration,
      child: child,
    );
  }
}

// ============= INTERNAL ANIMATION WIDGETS =============

class _PressScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;
  
  const _PressScaleButton({
    required this.child,
    required this.onPressed,
    required this.duration,
  });
  
  @override
  State<_PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<_PressScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }
  
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class _PressElevatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double baseElevation;
  final double pressedElevation;
  
  const _PressElevatedButton({
    required this.child,
    required this.onPressed,
    required this.baseElevation,
    required this.pressedElevation,
  });
  
  @override
  State<_PressElevatedButton> createState() => _PressElevatedButtonState();
}

class _PressElevatedButtonState extends State<_PressElevatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: widget.baseElevation,
      end: widget.pressedElevation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }
  
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1 * _elevationAnimation.value),
                  blurRadius: 6 * _elevationAnimation.value,
                  offset: Offset(0, 2 * _elevationAnimation.value),
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _TapElevationCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  
  const _TapElevationCard({
    required this.child,
    required this.onTap,
  });
  
  @override
  State<_TapElevationCard> createState() => _TapElevationCardState();
}

class _TapElevationCardState extends State<_TapElevationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _FloatingCard extends StatefulWidget {
  final Widget child;
  final double offsetY;
  final Duration duration;
  
  const _FloatingCard({
    required this.child,
    required this.offsetY,
    required this.duration,
  });
  
  @override
  State<_FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<_FloatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _offsetAnimation = Tween<double>(begin: 0, end: widget.offsetY).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_offsetAnimation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideInCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset offset;
  
  const _SlideInCard({
    required this.child,
    required this.duration,
    required this.offset,
  });
  
  @override
  State<_SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<_SlideInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _slideAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  
  const _ShimmerEffect({
    required this.child,
    required this.duration,
  });
  
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(begin: -1, end: 2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ],
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  
  const _PulseAnimation({
    required this.child,
    required this.duration,
  });
  
  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacityAnimation, child: widget.child);
  }
}

class _ScrollFadeSlideAnimation extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final Duration duration;
  
  const _ScrollFadeSlideAnimation({
    required this.child,
    required this.scrollController,
    required this.duration,
  });
  
  @override
  State<_ScrollFadeSlideAnimation> createState() =>
      _ScrollFadeSlideAnimationState();
}

class _ScrollFadeSlideAnimationState extends State<_ScrollFadeSlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    widget.scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (widget.scrollController.offset > 0) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }
  
  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_controller),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_controller),
        child: widget.child,
      ),
    );
  }
}
