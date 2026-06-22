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

  double get overall => (attention + impulseControl + planning + memory) / 4.0;
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

    int successStreak = 0;
    for (final session in chronological.reversed) {
      if (!session.completed) break;
      successStreak++;
    }

    final attention = _weightedAverage(
      scores.map((score) => score.attention).toList(),
    );
    final impulse = _weightedAverage(
      scores.map((score) => score.impulseControl).toList(),
    );
    final planning = _weightedAverage(
      scores.map((score) => score.planning).toList(),
    );
    final memory = _weightedAverage(
      scores.map((score) => score.memory).toList(),
    );
    final skills = <String, double>{
      'attention': attention,
      'impulse_control': impulse,
      'planning': planning,
      'memory': memory,
    };
    final strongestSkill = skills.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final growthFocus = skills.entries
        .reduce((a, b) => a.value <= b.value ? a : b)
        .key;
    final engagement = _weightedAverage(
      recent.map(_engagementForSession).toList(),
    );

    return BehavioralProfile(
      childId: childId,
      attentionScore: attention,
      impulseControlScore: impulse,
      planningScore: planning,
      memoryScore: memory,
      averageReactionTimeSeconds: reactionTimes.isEmpty
          ? 2
          : _roundOne(
              reactionTimes.reduce((a, b) => a + b) / reactionTimes.length,
            ),
      attentionVariability: _roundTwo(
        BehaviorAnalyzer.standardDeviation(reactionTimes),
      ),
      engagementScore: engagement,
      overallTrend: _trendFor(scores),
      strongestSkill: strongestSkill,
      growthFocus: growthFocus,
      successStreak: successStreak,
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

  static double _weightedAverage(List<double> values) {
    if (values.isEmpty) return 70;
    double weightedTotal = 0;
    double totalWeight = 0;
    for (int index = 0; index < values.length; index++) {
      final weight = (index + 1).toDouble();
      weightedTotal += values[index] * weight;
      totalWeight += weight;
    }
    return (weightedTotal / totalWeight).roundToDouble();
  }

  static double _engagementForSession(SessionResult session) {
    double score = session.completed ? 78 : 52;
    score += session.starsEarned * 5;
    score -= min(18, session.hintsUsed * 4);
    if (session.totalClicks > 0) score += 4;
    return _clampScore(score);
  }

  static String _trendFor(List<SessionIndicatorScores> scores) {
    if (scores.length < 4) return 'steady';
    final split = scores.length ~/ 2;
    final earlier = scores.take(split).map((score) => score.overall).toList();
    final recent = scores.skip(split).map((score) => score.overall).toList();
    final earlierAverage = earlier.reduce((a, b) => a + b) / earlier.length;
    final recentAverage = recent.reduce((a, b) => a + b) / recent.length;
    final delta = recentAverage - earlierAverage;
    if (delta >= 4) return 'improving';
    if (delta <= -5) return 'needs_support';
    return 'steady';
  }

  static double _clampScore(num score) =>
      max(0, min(100, score.toDouble())).roundToDouble();
  static double _roundOne(double value) =>
      double.parse(value.toStringAsFixed(1));
  static double _roundTwo(double value) =>
      double.parse(value.toStringAsFixed(2));
}
