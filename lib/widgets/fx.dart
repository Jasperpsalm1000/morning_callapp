import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------
// Shared animation helpers used by every screen.
// ---------------------------------------------------------------

/// Fades and slides a widget up when it first appears.
class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const Reveal({super.key, required this.child, this.delayMs = 0});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delayMs <= 0) {
      _c.forward();
    } else {
      _timer = Timer(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Slowly pulsing scale. Good for icons.
class Pulse extends StatefulWidget {
  final Widget child;
  const Pulse({super.key, required this.child});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.15).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Soft coloured blobs that drift slowly. Put it behind a page.
class FloatingBackground extends StatefulWidget {
  const FloatingBackground({super.key});

  @override
  State<FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<FloatingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(Color color, double left, double top, double size) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2 * pi;
        return LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            return Stack(
              children: [
                _blob(cs.primary, w * 0.05 + sin(t) * 40,
                    h * 0.03 + cos(t) * 40, 240),
                _blob(cs.tertiary, w * 0.55 + cos(t) * 50,
                    h * 0.30 + sin(t + 2) * 50, 280),
                _blob(cs.secondary, w * 0.10 + sin(t + 4) * 40,
                    h * 0.65 + cos(t + 3) * 40, 260),
              ],
            );
          },
        );
      },
    );
  }
}

/// Big page title with a gradient colour and an icon badge on the right.
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Reveal(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                  ).createShader(rect),
                  child: Text(
                    title,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Pulse(child: Icon(icon, color: Colors.white, size: 26)),
          ),
        ],
      ),
    );
  }
}

/// A number that counts up from 0 when it appears.
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final bool signed;

  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.signed = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (context, v, _) {
        final sign = (signed && v >= 0) ? '+' : '';
        return Text('$sign$v', style: style);
      },
    );
  }
}

/// Rings that spread out around [child] while [active] is true.
class RingPulse extends StatefulWidget {
  final bool active;
  final Color color;
  final double size;
  final double baseSize;
  final Widget child;

  const RingPulse({
    super.key,
    required this.active,
    required this.color,
    required this.child,
    this.size = 210,
    this.baseSize = 100,
  });

  @override
  State<RingPulse> createState() => _RingPulseState();
}

class _RingPulseState extends State<RingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(RingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ring(double p) {
    final d = widget.baseSize + (widget.size - widget.baseSize) * p;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.color.withValues(alpha: (1 - p) * 0.55),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              if (!widget.active) return const SizedBox.shrink();
              return Stack(
                alignment: Alignment.center,
                children: [
                  _ring(_c.value),
                  _ring((_c.value + 1 / 3) % 1),
                  _ring((_c.value + 2 / 3) % 1),
                ],
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}
