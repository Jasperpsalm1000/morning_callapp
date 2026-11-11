import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/checkin.dart';
import '../services/sentiment_service.dart';
import '../services/voice_service.dart';
import '../widgets/fx.dart';

class CallScreen extends StatefulWidget {
  /// When true, the call starts by itself (used when you tap the
  /// morning notification).
  final bool autoStart;

  const CallScreen({super.key, this.autoStart = false});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final VoiceService voice = VoiceService();
  final TextEditingController yesterdayCtrl = TextEditingController();
  final TextEditingController goalsCtrl = TextEditingController();

  String status = 'Tap the green button to start your morning call';
  bool inCall = false;
  bool cancelled = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => startCall());
    }
  }

  Future<void> startCall() async {
    if (inCall) return;
    cancelled = false;
    setState(() {
      inCall = true;
      status = 'Connecting...';
    });

    final ok = await voice.init();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        inCall = false;
        status =
            'Voice is not available. Allow the microphone for this app, or type your answers below.';
      });
      return;
    }

    // Question 1
    setState(() => status = 'Asking: How did yesterday go?');
    await voice.speak('Good morning. How did yesterday go?');
    if (!mounted || cancelled) return;
    setState(() => status = 'Listening...');
    final a1 = await voice.listen();
    if (!mounted || cancelled) return;
    yesterdayCtrl.text = a1;

    // Question 2
    setState(() => status = 'Asking: What are your goals for today?');
    await voice.speak('Got it. What are your goals for today?');
    if (!mounted || cancelled) return;
    setState(() => status = 'Listening...');
    final a2 = await voice.listen();
    if (!mounted || cancelled) return;
    goalsCtrl.text = a2;

    // Goodbye
    await voice.speak('Thank you. Have a great day.');
    if (!mounted || cancelled) return;
    setState(() {
      inCall = false;
      status = 'Call ended. Check your answers, then tap Save.';
    });
  }

  Future<void> endCall() async {
    cancelled = true;
    await voice.stop();
    if (!mounted) return;
    setState(() {
      inCall = false;
      status = 'Call ended. You can type or edit your answers, then tap Save.';
    });
  }

  Future<void> save() async {
    final y = yesterdayCtrl.text.trim();
    final g = goalsCtrl.text.trim();

    if (y.isEmpty || g.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both answers')),
      );
      return;
    }

    setState(() => saving = true);
    final result = SentimentService.analyze(y);

    await DbHelper.instance.insert(
      Checkin(
        createdAt: DateTime.now().toIso8601String(),
        yesterday: y,
        goals: g,
        score: result.score,
        label: result.label,
      ),
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, true);
    messenger.showSnackBar(
      SnackBar(content: Text('Saved. Your mood looks ${result.label}.')),
    );
  }

  @override
  void dispose() {
    voice.stop();
    yesterdayCtrl.dispose();
    goalsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      prefixIcon: Icon(icon),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = inCall ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(title: const Text('Morning call')),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: FloatingBackground()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status pill
                  Reveal(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          status,
                          key: ValueKey(status),
                          textAlign: TextAlign.center,
                          style: text.titleMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Call button with rings while the call is running
                  Reveal(
                    delayMs: 120,
                    child: RingPulse(
                      active: inCall,
                      color: Colors.red,
                      child: GestureDetector(
                        onTap: inCall ? endCall : startCall,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.all(inCall ? 14 : 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.18),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: accent,
                            child: Icon(
                              inCall ? Icons.call_end : Icons.call,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    inCall ? 'Tap to end the call' : 'Tap to start the call',
                    style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  Reveal(
                    delayMs: 240,
                    child: TextField(
                      controller: yesterdayCtrl,
                      maxLines: 4,
                      minLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          _field('How did yesterday go?', Icons.history_edu),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Reveal(
                    delayMs: 340,
                    child: TextField(
                      controller: goalsCtrl,
                      maxLines: 4,
                      minLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          _field('Your goals for today', Icons.flag_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delayMs: 440,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (inCall || saving) ? null : save,
                        icon: const Icon(Icons.check),
                        label: const Text('Save check-in'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Your answers stay on this phone.',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
