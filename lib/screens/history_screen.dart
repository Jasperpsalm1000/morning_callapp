import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/checkin.dart';
import '../services/stats.dart';
import '../widgets/fx.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Checkin> items = [];
  String filter = 'all';

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

  Future<void> confirmDelete(Checkin c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this check-in?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true && c.id != null) {
      await DbHelper.instance.delete(c.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final shown =
        filter == 'all' ? items : items.where((c) => c.label == filter).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'History',
          subtitle: 'Every check-in you have saved',
          icon: Icons.history,
        ),
        const SizedBox(height: 16),
        Reveal(
          delayMs: 100,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final f in ['all', 'positive', 'neutral', 'negative'])
                ChoiceChip(
                  avatar: f == 'all'
                      ? null
                      : Icon(
                          MoodStyle.icon(f),
                          size: 18,
                          color: MoodStyle.color(f),
                        ),
                  label: Text(MoodStyle.title(f)),
                  selected: filter == f,
                  showCheckmark: false,
                  selectedColor: f == 'all'
                      ? cs.primaryContainer
                      : MoodStyle.color(f).withValues(alpha: 0.18),
                  onSelected: (_) => setState(() => filter = f),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shown.length == 1 ? '1 check-in' : '${shown.length} check-ins',
          style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          Reveal(
            delayMs: 150,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Pulse(
                    child: Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: cs.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No check-ins to show.',
                    style: text.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        for (int i = 0; i < shown.length; i++) _entry(context, shown[i], i),
      ],
    );
  }

  Widget _entry(BuildContext context, Checkin c, int i) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = MoodStyle.color(c.label);

    return Reveal(
      key: ValueKey('entry-${c.id}-$filter'),
      delayMs: (i > 8 ? 8 : i) * 70,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Coloured strip on the left shows the mood at a glance.
                Container(width: 6, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    MoodStyle.icon(c.label),
                                    color: color,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    MoodStyle.title(c.label),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                DateFormat('d MMM yyyy, h:mm a').format(c.date),
                                style: text.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => confirmDelete(c),
                              icon: const Icon(Icons.delete_outline, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Yesterday', style: text.labelLarge),
                        const SizedBox(height: 2),
                        Text(c.yesterday),
                        const SizedBox(height: 10),
                        Text('Goals', style: text.labelLarge),
                        const SizedBox(height: 2),
                        Text(c.goals),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
