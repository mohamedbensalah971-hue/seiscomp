import 'dart:math';

import '../models.dart';

/// Converts raw gameplay events into non-diagnostic gameplay metrics.
class BehaviorAnalyzer {
  const BehaviorAnalyzer._();

  static MissionMetrics analyze(
    SessionResult session,
    List<SessionResult> history,
  ) {
    final fallbackSeconds = DifficultyParamsFactory.timeLimitFor(
      session.difficultyLevel,
    ).toDouble();
    final reactionSeconds = session.reactionTimeMs > 0
        ? session.reactionTimeMs / 1000.0
        : fallbackSeconds;
    final usefulReactionSeconds = session.usefulReactionTimeMs != null
        ? session.usefulReactionTimeMs! / 1000.0
        : fallbackSeconds;
    final correctClicks = session.events
        .where((event) => event.type == GameplayEventType.tapCorrect)
        .length;

    final reactionTimes = history
        .where((item) => item.reactionTimeMs > 0)
        .map((item) => item.reactionTimeMs / 1000.0)
        .toList();

    return MissionMetrics(
      reactionTimeSeconds: reactionSeconds,
      usefulReactionTimeSeconds: usefulReactionSeconds,
      wrongClicks: session.wrongClicks,
      distractorClicks: session.distractorClicks,
      correctClicks: correctClicks,
      hintsUsed: session.hintsUsed,
      completed: session.completed,
      omission: session.omission,
      commissions: session.commissionClicks,
      completionTimeSeconds: session.completionTimeSeconds,
      reactionTimeVariability: standardDeviation(reactionTimes),
    );
  }

  static double standardDeviation(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values
            .map((value) => pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }
}

/// Keeps the analyzer independent from the mission factory module.
class DifficultyParamsFactory {
  const DifficultyParamsFactory._();

  static int timeLimitFor(int level) => switch (level.clamp(1, 5)) {
    1 => 40,
    2 => 35,
    3 => 30,
    4 => 25,
    _ => 20,
  };
}
