// Interface for tracking workouts and fitness activities
abstract class FitnessTracker {
  Future<void> trackWorkout(
    String workoutType,
    int duration,
    double caloriesBurned,
  );
  Future<void> logSteps(int steps);
  Future<void> logDistance(double distance);
  Future<void> logCalories(double calories);
  Future<Map<String, dynamic>> getDailyStats();
  Future<Map<String, dynamic>> getWeeklyStats();
}
