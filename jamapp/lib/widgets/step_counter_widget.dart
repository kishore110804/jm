import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/native_step_counter.dart';
import '../utils/theme_config.dart';

class StepCounterWidget extends StatefulWidget {
  final int goal;
  final VoidCallback? onTap;

  const StepCounterWidget({Key? key, this.goal = 10000, this.onTap})
    : super(key: key);

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  final NativeStepCounter _stepCounter = NativeStepCounter();
  StreamSubscription<int>? _stepSubscription;
  int _steps = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStepCounter();
  }

  Future<void> _initializeStepCounter() async {
    try {
      final initialized = await _stepCounter.initialize();

      if (initialized) {
        // Listen for step updates
        _stepSubscription = _stepCounter.stepStream.listen((steps) {
          if (mounted) {
            setState(() {
              _steps = steps;
            });
          }
        });

        // Set initial steps
        _steps = _stepCounter.steps;
      }

      if (mounted) {
        setState(() {
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

  @override
  void dispose() {
    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage of goal achieved
    final double percentage = _steps / widget.goal;
    final double cappedPercentage = percentage > 1.0 ? 1.0 : percentage;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  color: ThemeConfig.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Steps',
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.textIvory,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Steps are simulated for demo purposes',
                  child: Icon(
                    Icons.info_outline,
                    color: ThemeConfig.textIvory.withOpacity(0.5),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator(
                  color: ThemeConfig.primaryGreen,
                )
                : CircularPercentIndicator(
                  radius: 70.0,
                  lineWidth: 13.0,
                  animation: true,
                  animateFromLastPercent: true,
                  percent: cappedPercentage,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _steps.toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: ThemeConfig.textIvory,
                        ),
                      ),
                      Text(
                        'steps',
                        style: GoogleFonts.poppins(
                          color: ThemeConfig.textIvory.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: ThemeConfig.primaryGreen,
                  backgroundColor: Colors.grey[800]!,
                ),
            const SizedBox(height: 16),
            Text(
              _steps >= widget.goal
                  ? 'Goal achieved! 🎉'
                  : '${widget.goal - _steps} steps to goal',
              style: GoogleFonts.poppins(
                color:
                    _steps >= widget.goal
                        ? ThemeConfig.primaryGreen
                        : ThemeConfig.textIvory.withOpacity(0.7),
                fontWeight:
                    _steps >= widget.goal ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await _stepCounter.forceSync();
                      setState(() {
                        _steps = _stepCounter.steps;
                        _isLoading = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.primaryGreen,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Refresh',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _showManualEntryDialog(context);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: ThemeConfig.primaryGreen,
                  tooltip: 'Add steps manually',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualEntryDialog(BuildContext context) async {
    int? stepsToAdd;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Add Steps Manually',
              style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the number of steps to add:',
                  style: GoogleFonts.poppins(
                    color: ThemeConfig.textIvory.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: ThemeConfig.primaryGreen,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'e.g. 500',
                    hintStyle: TextStyle(
                      color: ThemeConfig.textIvory.withOpacity(0.4),
                    ),
                  ),
                  onChanged: (value) {
                    stepsToAdd = int.tryParse(value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, stepsToAdd);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primaryGreen,
                  foregroundColor: Colors.black,
                ),
                child: Text('Add Steps', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    ).then((value) async {
      if (value != null && value > 0) {
        await _stepCounter.addStepsManually(value);
        setState(() {
          _steps = _stepCounter.steps;
        });
      }
    });
  }
}
