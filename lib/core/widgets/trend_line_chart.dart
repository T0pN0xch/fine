import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

/// A smooth curved line chart with a draggable value tooltip, matching the
/// "Statistic" reference style — used by Insights and Wallet net worth.
class TrendLineChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  final Color color;
  final String Function(DateTime date)? bottomLabel;

  const TrendLineChart({
    super.key,
    required this.data,
    required this.color,
    this.bottomLabel,
  });

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (int i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].value)
    ];
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.2 + 1;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: bottomLabel != null,
              reservedSize: 20,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (bottomLabel == null || idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  bottomLabel!(data[idx].key),
                  style: TextStyle(color: context.colors.textHint, fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchSpotThreshold: 40,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => color,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tooltipMargin: 12,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final idx = s.x.toInt();
              final date = idx >= 0 && idx < data.length ? data[idx].key : null;
              return LineTooltipItem(
                CurrencyFormatter.formatCompact(s.y),
                const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
                children: date != null
                    ? [
                        TextSpan(
                          text: '\n${DateFormat('d MMM yyyy').format(date)}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
                        ),
                      ]
                    : null,
              );
            }).toList(),
          ),
          getTouchedSpotIndicator: (barData, indicators) {
            return indicators.map((i) {
              return TouchedSpotIndicatorData(
                FlLine(color: color, strokeWidth: 1.5),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: color,
                  ),
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: context.colors.surfaceVariant,
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }
}
