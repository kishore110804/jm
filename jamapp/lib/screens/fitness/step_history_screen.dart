import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/step_counter_service.dart';
import '../../utils/theme_config.dart';

class StepHistoryScreen extends StatefulWidget {
  const StepHistoryScreen({Key? key}) : super(key: key);

  @override
  State<StepHistoryScreen> createState() => _StepHistoryScreenState();
}

class _StepHistoryScreenState extends State<StepHistoryScreen> {
  final StepCounterService _stepService = StepCounterService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklyData = [];
  String _selectedPeriod = 'Week';

  @override
  void initState() {
    super.initState();
    _loadStepHistory();
  }

  Future<void> _loadStepHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get step data for the past 7 days
      final stepHistory = await _stepService.getStepHistory(7);

      if (mounted) {
        setState(() {
          _weeklyData = stepHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate statistics
  int get totalSteps =>
      _weeklyData.fold(0, (sum, item) => sum + (item['steps'] as int? ?? 0));
  double get averageSteps =>
      _weeklyData.isEmpty ? 0 : totalSteps / _weeklyData.length;
  int get highestSteps =>
      _weeklyData.isEmpty
          ? 0
          : _weeklyData.fold(
            0,
            (max, item) =>
                (item['steps'] as int? ?? 0) > max ? item['steps'] as int : max,
          );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Step History',
          style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
        ),
        backgroundColor: ThemeConfig.backgroundBlack,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: ThemeConfig.primaryGreen,
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadStepHistory,
                color: ThemeConfig.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              ['Week', 'Month', 'Year'].map((period) {
                                final isSelected = period == _selectedPeriod;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPeriod = period;
                                    });
                                    // In a real app, this would update the chart data
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? ThemeConfig.primaryGreen
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      period,
                                      style: GoogleFonts.poppins(
                                        color:
                                            isSelected
                                                ? Colors.black
                                                : ThemeConfig.textIvory,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Statistics cards
                      Row(
                        children: [
                          _buildStatCard(
                            'Total Steps',
                            totalSteps.toString(),
                            Icons.directions_walk,
                            ThemeConfig.primaryGreen,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Daily Average',
                            averageSteps.toStringAsFixed(0),
                            Icons.trending_up,
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Best Day',
                            highestSteps.toString(),
                            Icons.emoji_events,
                            Colors.amber,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'This Week',
                            '${(totalSteps / 70000 * 100).toStringAsFixed(1)}%',
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Chart
                      Text(
                        'Step History',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.textIvory,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        padding: const EdgeInsets.all(16),
                        child:
                            _weeklyData.isEmpty
                                ? Center(
                                  child: Text(
                                    'No step data available',
                                    style: GoogleFonts.poppins(
                                      color: ThemeConfig.textIvory.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                )
                                : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: (highestSteps * 1.2).toDouble(),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        tooltipBgColor: Colors.grey[800]!,
                                        tooltipPadding: const EdgeInsets.all(8),
                                        tooltipMargin: 8,
                                        getTooltipItem: (
                                          BarChartGroupData group,
                                          int groupIndex,
                                          BarChartRodData rod,
                                          int rodIndex,
                                        ) {
                                          return BarTooltipItem(
                                            rod.toY.round().toString(),
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
                                            if (value.toInt() >=
                                                _weeklyData.length) {
                                              return const SizedBox.shrink();
                                            }
                                            // Parse date from data
                                            final dateStr =
                                                _weeklyData[value
                                                        .toInt()]['date']
                                                    as String? ??
                                                '';
                                            DateTime? date;
                                            try {
                                              date = DateFormat(
                                                'yyyy-MM-dd',
                                              ).parse(dateStr);
                                            } catch (e) {
                                              return const SizedBox.shrink();
                                            }

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                DateFormat('E').format(date),
                                                style: GoogleFonts.poppins(
                                                  color: ThemeConfig.textIvory
                                                      .withOpacity(0.7),
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
                                            String text;
                                            if (value == 0) {
                                              text = '0';
                                            } else if (value == highestSteps) {
                                              text = '${highestSteps ~/ 1000}K';
                                            } else {
                                              return const SizedBox.shrink();
                                            }

                                            return Text(
                                              text,
                                              style: GoogleFonts.poppins(
                                                color: ThemeConfig.textIvory
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                          reservedSize: 30,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey[800]!,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups:
                                        List.generate(_weeklyData.length, (
                                          index,
                                        ) {
                                          final data = _weeklyData[index];
                                          final steps =
                                              data['steps'] as int? ?? 0;

                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: steps.toDouble(),
                                                color: ThemeConfig.primaryGreen,
                                                width: 15,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(
                                                        4,
                                                      ),
                                                      topRight: Radius.circular(
                                                        4,
                                                      ),
                                                    ),
                                              ),
                                            ],
                                          );
                                        }).reversed.toList(),
                                  ),
                                ),
                      ),

                      const SizedBox(height: 24),

                      // Daily breakdown
                      Text(
                        'Daily Breakdown',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.textIvory,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._weeklyData.map((data) {
                        final date = data['date'] as String? ?? '';
                        final steps = data['steps'] as int? ?? 0;
                        final target = data['target'] as int? ?? 10000;

                        DateTime? dateObj;
                        try {
                          dateObj = DateFormat('yyyy-MM-dd').parse(date);
                        } catch (e) {
                          dateObj = null;
                        }

                        final dateStr =
                            dateObj != null
                                ? DateFormat('EEEE, MMM d').format(dateObj)
                                : date;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: ThemeConfig.textIvory,
                                    ),
                                  ),
                                  steps >= target
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ThemeConfig.primaryGreen
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Goal Achieved',
                                          style: GoogleFonts.poppins(
                                            color: ThemeConfig.primaryGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_walk,
                                    color: ThemeConfig.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$steps steps',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ThemeConfig.textIvory,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${steps >= target ? 100 : ((steps / target) * 100).toInt()}% of goal',
                                    style: GoogleFonts.poppins(
                                      color: ThemeConfig.textIvory.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: steps / target > 1 ? 1 : steps / target,
                                backgroundColor: Colors.grey[800],
                                color: ThemeConfig.primaryGreen,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.textIvory.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
