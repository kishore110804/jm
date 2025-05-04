import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jamapp/services/step_counter_service.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/native_step_counter.dart';
import '../utils/theme_config.dart';

class WeeklyStepsChart extends StatefulWidget {
  const WeeklyStepsChart({Key? key}) : super(key: key);

  @override
  State<WeeklyStepsChart> createState() => _WeeklyStepsChartState();
}

class _WeeklyStepsChartState extends State<WeeklyStepsChart> {
  final StepCounterService _stepService = StepCounterService();
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate fake weekly data
      _weeklyData = _generateWeeklyData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateWeeklyData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> weekData = [];
    final random = Random();

    // Generate the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Current day uses the actual step count
      final int stepCount =
          i == 0
              ? _stepService.steps
              : random.nextInt(12000) +
                  2000; // Random between 2000-14000 for past days

      weekData.add({
        'date': dateStr,
        'dayName': _getDayName(date.weekday),
        'steps': stepCount,
        'target': 10000,
        'progress': stepCount / 10000,
      });
    }

    return weekData;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ThemeConfig.primaryGreen),
      );
    }

    if (_weeklyData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 15000,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.grey[800]!,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${_weeklyData[groupIndex]['steps']} steps',
                      GoogleFonts.poppins(
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
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          _weeklyData[value.toInt()]['dayName'],
                          style: GoogleFonts.poppins(
                            color: ThemeConfig.textIvory.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt() == 0
                              ? '0'
                              : '${(value.toInt() / 1000).toString()}k',
                          style: GoogleFonts.poppins(
                            color: ThemeConfig.textIvory.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups:
                  _weeklyData.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> dayData = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: dayData['steps'].toDouble(),
                          color:
                              dayData['steps'] >= dayData['target']
                                  ? ThemeConfig.primaryGreen
                                  : ThemeConfig.primaryGreen.withOpacity(0.5),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primaryGreen.withOpacity(0.2),
              foregroundColor: ThemeConfig.primaryGreen,
            ),
            child: Text(
              'Refresh Data',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
