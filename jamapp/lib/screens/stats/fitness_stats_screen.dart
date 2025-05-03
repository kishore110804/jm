// Displays fitness statistics and progress visualization
import 'package:flutter/material.dart';

class FitnessStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const FitnessStatsWidget({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fitness Statistics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 10),
        Text('Steps: ${stats['steps']}'),
        Text('Calories: ${stats['calories']}'),
        Text('Distance: ${stats['distance']} km'),
        Text('Workouts: ${stats['workouts']}'),
      ],
    );
  }
}
