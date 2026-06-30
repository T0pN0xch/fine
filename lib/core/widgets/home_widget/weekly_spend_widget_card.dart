import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

/// The visual content rendered into the home-screen widget image
/// (Design 1: donut total on the left, 7-day spend bars on the right).
/// Kept as a plain, theme-independent widget (no BuildContext-based
/// AppColorsExt) since it's rendered off-screen via HomeWidget.renderFlutterWidget
/// without a full app theme/MediaQuery context.
class WeeklySpendWidgetCard extends StatelessWidget {
  /// 7 entries, oldest first, matching AppDatabase.getWeeklySpending().
  final List<MapEntry<DateTime, double>> weekly;

  /// Category name -> amount spent this week, already sorted descending,
  /// capped to at most 5 entries (4 categories + "Other" bucket) by the caller.
  final List<MapEntry<String, double>> categoryBreakdown;

  const WeeklySpendWidgetCard({
    super.key,
    required this.weekly,
    required this.categoryBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final total = weekly.fold(0.0, (s, e) => s + e.value);
    final maxVal = weekly.fold(0.0, (m, e) => e.value > m ? e.value : m);

    return Container(
      width: 642,
      height: 300,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THIS WEEK',
            style: TextStyle(
              color: Color(0xFF8A84A8),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 3,
                          centerSpaceRadius: 62,
                          sections: [
                            for (int i = 0; i < categoryBreakdown.length; i++)
                              PieChartSectionData(
                                value: categoryBreakdown[i].value,
                                color: AppColors.vividColors[
                                    i % AppColors.vividColors.length],
                                radius: 32,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.formatCompact(total),
                            style: const TextStyle(
                              color: Color(0xFF2B2640),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'spent',
                            style: TextStyle(
                              color: Color(0xFF8A84A8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int i = 0; i < weekly.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: maxVal == 0
                                      ? 6
                                      : 16 +
                                          150 *
                                              (weekly[i].value / maxVal)
                                                  .clamp(0.0, 1.0),
                                  decoration: BoxDecoration(
                                    color: weekly[i].value > 0
                                        ? AppColors.categoryColors[
                                            i % AppColors.categoryColors.length]
                                        : const Color(0xFFEDEAFB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _dayLabel(weekly[i].key),
                                  style: const TextStyle(
                                    color: Color(0xFF8A84A8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  static String _dayLabel(DateTime d) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  }
}
