import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/checkin.dart';

class Stats {
  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Number of days in a row (ending today or yesterday) with a check-in.
  static int streak(List<Checkin> items) {
    final days = items.map((c) => dayKey(c.date)).toSet();
    var d = DateTime.now();
    if (!days.contains(dayKey(d))) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    int count = 0;
    while (days.contains(dayKey(d))) {
      count++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return count;
  }

  /// The most recent check-in made today, or null.
  static Checkin? today(List<Checkin> items) {
    final key = dayKey(DateTime.now());
    for (final c in items) {
      if (dayKey(c.date) == key) return c;
    }
    return null;
  }

  static double averageScore(List<Checkin> items) {
    if (items.isEmpty) return 0;
    final total = items.fold<double>(0, (sum, c) => sum + c.score);
    return total / items.length;
  }

  static Map<String, int> moodCounts(List<Checkin> items) {
    final counts = {'positive': 0, 'neutral': 0, 'negative': 0};
    for (final c in items) {
      counts[c.label] = (counts[c.label] ?? 0) + 1;
    }
    return counts;
  }

  static String commonMood(List<Checkin> items) {
    if (items.isEmpty) return '-';
    final counts = moodCounts(items);
    String best = 'neutral';
    int bestCount = -1;
    counts.forEach((mood, n) {
      if (n > bestCount) {
        best = mood;
        bestCount = n;
      }
    });
    return best;
  }
}

class MoodStyle {
  static Color color(String label) {
    switch (label) {
      case 'positive':
        return const Color(0xFF16A34A);
      case 'negative':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static IconData icon(String label) {
    switch (label) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  static String title(String label) {
    if (label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1);
  }
}
