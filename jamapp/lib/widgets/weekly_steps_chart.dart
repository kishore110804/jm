import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme_config.dart';

class WeeklyStepsChart extends StatelessWidget {
  final List<int> stepsData;

  const WeeklyStepsChart({Key? key, required this.stepsData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure we have 7 days of data
    final List<int> data =
        stepsData.length < 7
            ? [...stepsData, ...List.filled(7 - stepsData.length, 0)]
            : stepsData.sublist(0, 7);

    // Calculate max steps for y-axis scaling
    final maxSteps =
        data.isEmpty
            ? 10000
            : (data.reduce((a, b) => a > b ? a : b) * 1.2).ceil();

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 6.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSteps.toDouble(),
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey[800]!,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final steps = data[groupIndex];
                      return BarTooltipItem(
                        '$steps steps',
                        const TextStyle(
                          color: ThemeConfig.textIvory,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[index],
                              style: const TextStyle(
                                color: ThemeConfig.textIvory,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Text('');
                        }
                        String text;
                        if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          text = value.toInt().toString();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: ThemeConfig.textIvory,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups:
                    data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final steps = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: steps.toDouble(),
                            color: ThemeConfig.primaryGreen,
                            width:
                                constraints.maxWidth /
                                14, // Dynamic width based on available space
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
