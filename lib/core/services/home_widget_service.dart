import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../data/database/app_database.dart';
import '../widgets/home_widget/weekly_spend_widget_card.dart';

/// Refreshes the "This Week" home-screen widget (Design 1: donut total +
/// 7-day spend bars). Renders the same card shown in the design mockups as
/// an image via HomeWidget.renderFlutterWidget, then asks the native
/// AppWidgetProvider to redraw with the new image.
class HomeWidgetService {
  static const _imageKey = 'weekly_spend_card';
  static const _providerName = 'FinanceWidgetProvider';

  static Future<void> refresh(AppDatabase db) async {
    final weekly = await db.getWeeklySpending();

    final now = DateTime.now();
    final weekStart = weekly.isNotEmpty ? weekly.first.key : now;
    final weekEnd = weekly.isNotEmpty ? weekly.last.key : now;
    final spendingByCategory =
        await db.getCategorySpendingByRange(weekStart, weekEnd);

    final categories = await db.getAllCategories();
    final catMap = {for (final c in categories) c.id: c};

    final entries = spendingByCategory.entries
        .map((e) => MapEntry(catMap[e.key]?.name ?? 'Other', e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Cap to top 4 + an "Other" bucket for the remainder, matching the
    // design's 5-slice donut.
    List<MapEntry<String, double>> breakdown;
    if (entries.length > 5) {
      final top4 = entries.take(4).toList();
      final otherTotal =
          entries.skip(4).fold(0.0, (s, e) => s + e.value);
      breakdown = [...top4, MapEntry('Other', otherTotal)];
    } else {
      breakdown = entries;
    }
    if (breakdown.isEmpty) {
      breakdown = [const MapEntry('No spending', 1.0)];
    }

    const logicalSize = Size(642, 300);
    try {
      await HomeWidget.renderFlutterWidget(
        // fl_chart's PieChart needs a MediaQuery/Directionality ancestor,
        // which renderFlutterWidget's detached render tree doesn't provide
        // on its own.
        MediaQuery(
          data: const MediaQueryData(size: logicalSize),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: WeeklySpendWidgetCard(
                weekly: weekly, categoryBreakdown: breakdown),
          ),
        ),
        logicalSize: logicalSize,
        pixelRatio: 3,
        key: _imageKey,
      );
      await HomeWidget.updateWidget(
        name: _providerName,
        androidName: _providerName,
      );
    } catch (_) {
      // Widget not pinned / platform doesn't support it yet — non-fatal.
    }
  }
}
