import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/checkin.dart';
import '../services/app_nav.dart';
import '../services/stats.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<Checkin> items = [];

  @override
  void initState() {
    super.initState();
    DbHelper.changes.addListener(load);
    load();
  }

  @override
  void dispose() {
    DbHelper.changes.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    final data = await DbHelper.instance.getAll();
    if (!mounted) return;
    setState(() => items = data);
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get greetingEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '☀️';
    if (h < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final today = Stats.today(items);
    final streak = Stats.streak(items);

    return Stack(
      children: [
        // Moving background (does not block touches)
        const Positioned.fill(
          child: IgnorePointer(child: _FloatingBackground()),
        ),

        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Greeting row
            _Reveal(
              delayMs: 0,
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
                            greeting,
                            style: text.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM').format(DateTime.now()),
                          style: text.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Wave(emoji: greetingEmoji),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Big call card (3D tilt)
            _Reveal(
              delayMs: 150,
              child: _Tilt3D(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Positioned.fill(child: _Bubbles()),
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  today == null
                                      ? 'Your morning call'
                                      : 'Checked in today',
                                  style: text.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  today == null
                                      ? 'Two questions, about two minutes. How did yesterday go, and what are your goals for today?'
                                      : 'You can still make another call if you want to add more.',
                                  style: text.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _PulsingButton(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: cs.primary,
                                    ),
                                    onPressed: () =>
                                        AppNav.openCall(autoStart: false),
                                    icon: const Icon(Icons.call),
                                    label: const Text('Start morning call'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Small stats
            _Reveal(
              delayMs: 300,
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                      value: streak,
                      label: 'day streak',
                      pulse: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.event_available,
                      color: cs.primary,
                      value: items.length,
                      label: 'check-ins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rotating quote
            const _Reveal(delayMs: 450, child: _QuoteStrip()),
            const SizedBox(height: 16),

            _Reveal(
              delayMs: 600,
              child: today != null
                  ? _TodayCard(checkin: today)
                  : _EmptyHint(),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------
// Animated helpers (all private to this file)
// ---------------------------------------------------------------

/// Slow drifting coloured blobs behind the page.
class _FloatingBackground extends StatefulWidget {
  const _FloatingBackground();

  @override
  State<_FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<_FloatingBackground>
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
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
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

/// Small circles floating inside the call card.
class _Bubbles extends StatefulWidget {
  const _Bubbles();

  @override
  State<_Bubbles> createState() => _BubblesState();
}

class _BubblesState extends State<_Bubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 * pi;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -20 + sin(t) * 15,
                top: -30 + cos(t) * 15,
                child: _circle(120, 0.12),
              ),
              Positioned(
                left: 20 + cos(t) * 20,
                bottom: -40 + sin(t) * 12,
                child: _circle(90, 0.10),
              ),
              Positioned(
                right: 70 + sin(t + 2) * 12,
                bottom: 30 + cos(t) * 10,
                child: _circle(22, 0.22),
              ),
              Positioned(
                left: 170 + cos(t + 1) * 10,
                top: 18 + sin(t) * 10,
                child: _circle(12, 0.25),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Makes the card tilt in 3D. Sways by itself, follows mouse/finger.
/// Uses Listener so it never blocks page scrolling.
class _Tilt3D extends StatefulWidget {
  final Widget child;
  const _Tilt3D({required this.child});

  @override
  State<_Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<_Tilt3D> with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  Offset? _p; // pointer position from -1 to 1

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  void _update(Offset local) {
    final size = context.size;
    if (size == null || size.width == 0 || size.height == 0) return;
    final dx = ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final dy = ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
    setState(() => _p = Offset(dx, dy));
  }

  void _reset() => setState(() => _p = null);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => _update(e.localPosition),
      onExit: (_) => _reset(),
      child: Listener(
        onPointerDown: (e) => _update(e.localPosition),
        onPointerMove: (e) => _update(e.localPosition),
        onPointerUp: (_) => _reset(),
        onPointerCancel: (_) => _reset(),
        child: AnimatedBuilder(
          animation: _idle,
          builder: (context, child) {
            final t = _idle.value * 2 * pi;
            final rx = _p == null ? sin(t) * 0.03 : -_p!.dy * 0.12;
            final ry = _p == null ? cos(t) * 0.05 : _p!.dx * 0.12;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(rx)
                ..rotateY(ry),
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Expanding rings behind the call button.
class _PulsingButton extends StatefulWidget {
  final Widget child;
  const _PulsingButton({required this.child});

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ring(double p) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: (1 - p) * 0.6,
          child: Transform.scale(
            scale: 1 + p * 0.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _ring(_c.value),
            _ring((_c.value + 0.5) % 1),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Gentle swaying emoji next to the greeting.
class _Wave extends StatefulWidget {
  final String emoji;
  const _Wave({required this.emoji});

  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2 * pi;
        return Transform.translate(
          offset: Offset(0, sin(t) * 5),
          child: Transform.rotate(
            angle: sin(t) * 0.25,
            child: Text(widget.emoji, style: const TextStyle(fontSize: 40)),
          ),
        );
      },
    );
  }
}

/// Fade and slide up when the section first appears.
class _Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _Reveal({required this.child, this.delayMs = 0});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.15),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
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

/// Slowly pulsing scale, used for the fire icon.
class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
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

/// A line of motivation that changes every few seconds.
class _QuoteStrip extends StatefulWidget {
  const _QuoteStrip();

  @override
  State<_QuoteStrip> createState() => _QuoteStripState();
}

class _QuoteStripState extends State<_QuoteStrip> {
  static const quotes = [
    'Small steps every day add up to big change.',
    'Start where you are. Use what you have.',
    'Your future is built by what you do today.',
    'Progress, not perfection.',
    'One good morning can change the whole day.',
  ];

  int index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => index = (index + 1) % quotes.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.format_quote, color: cs.tertiary),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  quotes[index],
                  key: ValueKey(index),
                  style: text.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Cards
// ---------------------------------------------------------------

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final bool pulse;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final iconWidget = Icon(icon, color: color, size: 32);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            pulse ? _Pulse(child: iconWidget) : iconWidget,
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => Text(
                    '$v',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(label, style: text.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final Checkin checkin;
  const _TodayCard({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = MoodStyle.color(checkin.label);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(MoodStyle.icon(checkin.label), color: color),
                const SizedBox(width: 8),
                Text(
                  'Mood: ${MoodStyle.title(checkin.label)}',
                  style: text.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Yesterday', style: text.labelLarge),
            const SizedBox(height: 2),
            Text(checkin.yesterday),
            const SizedBox(height: 14),
            Text("Today's goals", style: text.labelLarge),
            const SizedBox(height: 2),
            Text(checkin.goals),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            _Pulse(child: Icon(Icons.wb_sunny_outlined)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No check-in yet today. Make your morning call to start your streak.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}