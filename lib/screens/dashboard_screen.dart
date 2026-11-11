import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/checkin.dart';
import '../services/stats.dart';
import '../widgets/fx.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Dashboard',
          subtitle: 'How your mood and goals look over time',
          icon: Icons.insights,
        ),
        const SizedBox(height: 20),
        if (items.isEmpty)
          const Reveal(
            delayMs: 150,
            child: _Panel(
              title: 'Nothing here yet',
              icon: Icons.hourglass_empty,
              child: Text(
                'Make your first morning call. Your charts will appear here after your first check-in.',
              ),
            ),
          )
        else ...[
          Reveal(delayMs: 100, child: _moodHero(context)),
          const SizedBox(height: 16),
          Reveal(delayMs: 220, child: _statsGrid(context)),
          const SizedBox(height: 16),
          Reveal(delayMs: 340, child: _trendCard(context)),
          const SizedBox(height: 16),
          Reveal(delayMs: 460, child: _splitCard(context)),
          const SizedBox(height: 16),
          Reveal(delayMs: 580, child: _recentGoalsCard(context)),
        ],
      ],
    );
  }

  // ---------- Big mood score card ----------
  Widget _moodHero(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final avg = Stats.averageScore(items);
    final score = (avg * 100).round();
    final fill = ((avg + 1) / 2).clamp(0.0, 1.0).toDouble();

    String note;
    if (avg > 0.2) {
      note = 'You have been feeling good lately. Keep it going.';
    } else if (avg < -0.2) {
      note = 'It has been a heavier stretch. Be kind to yourself.';
    } else {
      note = 'Steady and balanced overall.';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your mood score',
            style: text.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          CountUp(
            value: score,
            signed: true,
            style: text.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: fill),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: text.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ---------- Stat tiles ----------
  Widget _statsGrid(BuildContext context) {
    final avg = Stats.averageScore(items);
    final common = Stats.commonMood(items);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.event_available,
                label: 'Total check-ins',
                count: items.length,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department,
                label: 'Current streak',
                count: Stats.streak(items),
                color: Colors.orange,
                pulse: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.insights,
                label: 'Average mood (-100 to +100)',
                count: (avg * 100).round(),
                signed: true,
                color: MoodStyle.color(
                  avg > 0.2 ? 'positive' : (avg < -0.2 ? 'negative' : 'neutral'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: MoodStyle.icon(common),
                label: 'Most common mood',
                value: MoodStyle.title(common),
                color: MoodStyle.color(common),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- Line chart ----------
  Widget _trendCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Last 14 check-ins, oldest on the left.
    final recent = items.take(14).toList().reversed.toList();
    final spots = <FlSpot>[
      for (int i = 0; i < recent.length; i++) FlSpot(i.toDouble(), recent[i].score),
    ];
    final maxX = recent.length > 1 ? (recent.length - 1).toDouble() : 1.0;

    return _Panel(
      title: 'Mood over time',
      icon: Icons.show_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: -1,
                maxY: 1,
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        String label = '';
                        if (value == 1) label = 'Good';
                        if (value == 0) label = 'Okay';
                        if (value == -1) label = 'Low';
                        return Text(label, style: const TextStyle(fontSize: 11));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: recent.length > 7 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (value != i.toDouble() || i < 0 || i >= recent.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('d/M').format(recent[i].date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                    ),
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.28),
                          cs.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Each point is one check-in. Higher means a more positive day.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------- Pie chart ----------
  Widget _splitCard(BuildContext context) {
    final counts = Stats.moodCounts(items);
    final sections = <PieChartSectionData>[];

    counts.forEach((mood, n) {
      if (n == 0) return;
      sections.add(
        PieChartSectionData(
          value: n.toDouble(),
          color: MoodStyle.color(mood),
          title: '$n',
          radius: 52,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    });

    return _Panel(
      title: 'Mood split',
      icon: Icons.pie_chart_outline,
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 3,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final mood in ['positive', 'neutral', 'negative'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: MoodStyle.color(mood),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${MoodStyle.title(mood)}: ${counts[mood]}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Recent goals ----------
  Widget _recentGoalsCard(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final recent = items.take(3).toList();

    return _Panel(
      title: 'Recent goals',
      icon: Icons.flag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      MoodStyle.icon(c.label),
                      size: 18,
                      color: MoodStyle.color(c.label),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE, d MMM').format(c.date),
                          style: text.labelMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(c.goals),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Panel({required this.title, required this.child, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final int? count;
  final bool signed;
  final bool pulse;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.color,
    this.value,
    this.count,
    this.signed = false,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final valueStyle =
        text.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    final iconWidget = Icon(icon, color: color);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pulse ? Pulse(child: iconWidget) : iconWidget,
            const SizedBox(height: 10),
            if (count != null)
              CountUp(value: count!, signed: signed, style: valueStyle)
            else
              Text(value ?? '', style: valueStyle),
            const SizedBox(height: 2),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
