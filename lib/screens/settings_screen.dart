import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../widgets/fx.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ReminderSettings? settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsService.load();
    if (!mounted) return;
    setState(() => settings = s);
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggle(bool value) async {
    final s = settings!;
    if (value) {
      final allowed = await NotificationService.requestPermission();
      if (!mounted) return;
      if (!allowed) {
        _say('Notifications are blocked. Allow them for this app in your phone settings.');
        return;
      }
      await NotificationService.scheduleDaily(s.hour, s.minute);
    } else {
      await NotificationService.cancelDaily();
    }
    final updated =
        ReminderSettings(enabled: value, hour: s.hour, minute: s.minute);
    await SettingsService.save(updated);
    if (!mounted) return;
    setState(() => settings = updated);
  }

  Future<void> _pickTime() async {
    final s = settings!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
    );
    if (picked == null) return;

    final updated = ReminderSettings(
      enabled: s.enabled,
      hour: picked.hour,
      minute: picked.minute,
    );
    await SettingsService.save(updated);
    if (updated.enabled) {
      await NotificationService.scheduleDaily(updated.hour, updated.minute);
    }
    if (!mounted) return;
    setState(() => settings = updated);
  }

  Future<void> _test() async {
    final allowed = await NotificationService.requestPermission();
    if (!mounted) return;
    if (!allowed) {
      _say('Notifications are blocked. Allow them for this app in your phone settings.');
      return;
    }
    await NotificationService.showTest();
  }

  Future<void> _copyCsv() async {
    final items = await DbHelper.instance.getAll();
    String esc(String s) {
      final escaped = s.replaceAll('"', '""');
      return '"$escaped"';
    }

    final buf = StringBuffer('date,mood,score,yesterday,goals\n');
    for (final c in items.reversed) {
      buf.writeln(
        '${c.createdAt},${c.label},${c.score.toStringAsFixed(3)},${esc(c.yesterday)},${esc(c.goals)}',
      );
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    _say('Copied ${items.length} check-ins. Paste them into any app or spreadsheet.');
  }

  Future<void> _deleteAll() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'Every check-in on this phone will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await DbHelper.instance.deleteAll();
      if (!mounted) return;
      _say('All data deleted.');
    }
  }

  Widget _badge(BuildContext context, IconData icon, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: c, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final s = settings;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle: 'Your morning reminder and your data',
          icon: Icons.settings,
        ),
        const SizedBox(height: 16),
        if (s == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          Reveal(
            delayMs: 100,
            child: Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: _badge(context, Icons.alarm),
                    title: const Text('Morning reminder'),
                    subtitle: const Text('A notification that opens your call'),
                    value: s.enabled,
                    onChanged: _toggle,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: _badge(context, Icons.access_time),
                    title: const Text('Reminder time'),
                    subtitle: Text(
                      TimeOfDay(hour: s.hour, minute: s.minute).format(context),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickTime,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: _badge(
                      context,
                      Icons.notifications_active_outlined,
                      color: cs.tertiary,
                    ),
                    title: const Text('Send a test reminder now'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _test,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Reveal(
            delayMs: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'On some phones (Tecno, Infinix, Xiaomi, Samsung) the battery saver can block reminders. '
                'If yours does not arrive, set this app to "Unrestricted" in the phone battery settings.',
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            delayMs: 300,
            child: Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: _badge(
                      context,
                      Icons.copy,
                      color: Colors.teal,
                    ),
                    title: const Text('Copy my data (CSV)'),
                    subtitle: const Text('Paste into a spreadsheet or note'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _copyCsv,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: _badge(
                      context,
                      Icons.delete_outline,
                      color: cs.error,
                    ),
                    title: Text(
                      'Delete all my data',
                      style: TextStyle(color: cs.error),
                    ),
                    trailing: Icon(Icons.chevron_right, color: cs.error),
                    onTap: _deleteAll,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Reveal(
            delayMs: 400,
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'All your check-ins are stored only on this phone.',
                    style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
