import 'package:flutter/material.dart';

/// Wraps [child] with a playful scale-down/spring-back animation on tap.
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BouncyTap({super.key, required this.child, this.onTap});

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  double _scale = 1.0;

  void _setScale(double s) => setState(() => _scale = s);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.88),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Wraps [child] and plays a quick rotation wiggle whenever [trigger] changes.
class WiggleOnChange extends StatefulWidget {
  final Widget child;
  final Object trigger;

  const WiggleOnChange({super.key, required this.child, required this.trigger});

  @override
  State<WiggleOnChange> createState() => _WiggleOnChangeState();
}

class _WiggleOnChangeState extends State<WiggleOnChange>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wiggle;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _wiggle = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(WiggleOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wiggle,
      builder: (context, child) =>
          Transform.rotate(angle: _wiggle.value, child: child),
      child: widget.child,
    );
  }
}

/// A checkmark that pops in with an elastic scale + slight rotation settle —
/// shown briefly for "success" moments (goal reached, commitment paid).
class CelebrationPop extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onDone;

  const CelebrationPop({
    super.key,
    required this.color,
    this.size = 64,
    this.onDone,
  });

  @override
  State<CelebrationPop> createState() => _CelebrationPopState();
}

class _CelebrationPopState extends State<CelebrationPop> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      widget.onDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.4),
          child: Transform.rotate(
            angle: (1 - value.clamp(0.0, 1.0)) * 0.3,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: Colors.white, size: widget.size * 0.55),
      ),
    );
  }
}

/// Shows a brief [CelebrationPop] overlay centered on the current screen.
void showCelebrationOverlay(BuildContext context, {required Color color}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: CelebrationPop(
            color: color,
            onDone: () => entry.remove(),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
}
