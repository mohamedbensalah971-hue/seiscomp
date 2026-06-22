import 'dart:math';

import '../models.dart';
import 'behavior_analyzer.dart';

class SessionIndicatorScores {
  final double attention;
  final double impulseControl;
  final double planning;
  final double memory;

  const SessionIndicatorScores({
    required this.attention,
    required this.impulseControl,
    required this.planning,
    required this.memory,
  });
}

/// Builds a lightweight, positive gameplay profile from recent local sessions.
class ProfileUpdater {
  const ProfileUpdater._();

  static BehavioralProfile build(String childId, List<SessionResult> sessions) {
    if (sessions.isEmpty) return BehavioralProfile.empty(childId);

    final chronological = List<SessionResult>.from(sessions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final recent = chronological.length > 10
        ? chronological.sublist(chronological.length - 10)
        : chronological;
    final scores = recent.map(scoreSession).toList();
    final reactionTimes = recent
        .where((session) => session.reactionTimeMs > 0)
        .map((session) => session.reactionTimeMs / 1000.0)
        .toList();

    int consecutiveFailures = 0;
    for (final session in chronological.reversed) {
      if (session.completed) break;
      consecutiveFailures++;
    }

    return BehavioralProfile(
      childId: childId,
      attentionScore: _average(scores.map((score) => score.attention)),
      impulseControlScore: _average(
        scores.map((score) => score.impulseControl),
      ),
      planningScore: _average(scores.map((score) => score.planning)),
      memoryScore: _average(scores.map((score) => score.memory)),
      averageReactionTimeSeconds: reactionTimes.isEmpty
          ? 2
          : _roundOne(
              reactionTimes.reduce((a, b) => a + b) / reactionTimes.length,
            ),
      attentionVariability: _roundTwo(
        BehaviorAnalyzer.standardDeviation(reactionTimes),
      ),
      currentDifficulty: chronological.last.difficultyLevel.clamp(1, 5),
      totalMissions: chronological.length,
      consecutiveFailures: consecutiveFailures,
    );
  }

  static SessionIndicatorScores scoreSession(SessionResult session) {
    final timeLimit = DifficultyParamsFactory.timeLimitFor(
      session.difficultyLevel,
    );
    final rapidCommission =
        session.reactionTimeMs > 0 &&
        session.reactionTimeMs < 500 &&
        session.commissionClicks > 0;

    final attention = _clampScore(
      100 -
          session.distractorClicks * 12 -
          session.hintsUsed * 5 -
          (session.omission ? 20 : 0) -
          (session.completionTimeSeconds > timeLimit * 0.85 ? 8 : 0),
    );
    final impulse = _clampScore(
      100 -
          session.wrongClicks * 13 -
          session.distractorClicks * 4 -
          (rapidCommission ? 12 : 0),
    );
    final planning = _clampScore(
      100 -
          session.wrongClicks * 8 -
          session.hintsUsed * 8 -
          (session.omission ? 22 : 0) -
          (session.completionTimeSeconds > timeLimit ? 8 : 0),
    );
    final memory = _clampScore(
      100 -
          session.hintsUsed * 15 -
          session.wrongClicks * 5 -
          (session.omission ? 18 : 0),
    );

    return SessionIndicatorScores(
      attention: attention,
      impulseControl: impulse,
      planning: planning,
      memory: memory,
    );
  }

  static double _average(Iterable<double> values) {
    final list = values.toList();
    return (list.reduce((a, b) => a + b) / list.length).roundToDouble();
  }

  static double _clampScore(num score) =>
      max(0, min(100, score.toDouble())).roundToDouble();
  static double _roundOne(double value) =>
      double.parse(value.toStringAsFixed(1));
  static double _roundTwo(double value) =>
      double.parse(value.toStringAsFixed(2));
}
