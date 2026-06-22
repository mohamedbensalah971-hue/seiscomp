import '../models.dart';

/// Produces concrete frontend parameters from the agent's difficulty decision.
class MissionFactory {
  const MissionFactory._();

  static DifficultyParams forLevel(int requestedLevel) {
    final level = requestedLevel.clamp(1, 5);
    return switch (level) {
      1 => const DifficultyParams(
        difficultyLevel: 1,
        maxDistractors: 1,
        distractorIntensity: 0.15,
        totalObjects: 4,
        hintDelaySeconds: 6,
        timeLimitSeconds: 40,
        complexityLevel: 'Easy',
        hintLevel: 'high',
      ),
      2 => const DifficultyParams(),
      3 => const DifficultyParams(
        difficultyLevel: 3,
        maxDistractors: 2,
        distractorIntensity: 0.45,
        totalObjects: 8,
        hintDelaySeconds: 12,
        timeLimitSeconds: 30,
        complexityLevel: 'Medium',
        hintLevel: 'medium',
      ),
      4 => const DifficultyParams(
        difficultyLevel: 4,
        maxDistractors: 3,
        distractorIntensity: 0.6,
        totalObjects: 10,
        hintDelaySeconds: 15,
        timeLimitSeconds: 25,
        complexityLevel: 'Hard',
        hintLevel: 'low',
      ),
      _ => const DifficultyParams(
        difficultyLevel: 5,
        maxDistractors: 4,
        distractorIntensity: 0.75,
        totalObjects: 12,
        hintDelaySeconds: 18,
        timeLimitSeconds: 20,
        complexityLevel: 'Hard',
        hintLevel: 'low',
      ),
    };
  }

  static String nextMissionAfter(String currentMissionId) =>
      switch (currentMissionId) {
        'dark_room' => 'robot_room',
        'robot_room' => 'door_room',
        'door_room' => 'garden_room',
        'garden_room' => 'memory_vault',
        _ => 'dark_room',
      };
}
