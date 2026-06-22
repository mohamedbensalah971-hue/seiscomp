import 'package:flutter_test/flutter_test.dart';
import 'package:mindspark_quest/local_engine.dart';
import 'package:mindspark_quest/missions/mission_factory.dart';
import 'package:mindspark_quest/models.dart';

SessionResult session({
  String id = 'session',
  int difficulty = 2,
  bool completed = true,
  int wrong = 0,
  int distractors = 0,
  int hints = 0,
  double reactionMs = 800,
  double completionSeconds = 10,
  DateTime? timestamp,
  List<GameplayEvent> events = const [],
}) {
  return SessionResult(
    id: id,
    childId: 'child',
    missionId: 'dark_room',
    timestamp: timestamp ?? DateTime(2026, 6, 22),
    difficultyLevel: difficulty,
    completionTimeSeconds: completionSeconds,
    starsEarned: completed ? 3 : 0,
    gemsEarned: completed ? 1 : 0,
    totalClicks: wrong + distractors + (completed ? 1 : 0),
    wrongClicks: wrong,
    distractorClicks: distractors,
    hintsUsed: hints,
    reactionTimeMs: reactionMs,
    events: events,
  );
}

void main() {
  group('Documented agent pipeline', () {
    test(
      'analyzes roles, useful reaction time, omissions, and commissions',
      () {
        final result = session(
          wrong: 1,
          distractors: 1,
          events: [
            GameplayEvent(
              type: GameplayEventType.tapDistractor,
              objectId: 'star',
              timeOffsetMs: 800,
              x: 0,
              y: 0,
            ),
            GameplayEvent(
              type: GameplayEventType.tapWrong,
              objectId: 'lamp',
              timeOffsetMs: 1300,
              x: 0,
              y: 0,
            ),
            GameplayEvent(
              type: GameplayEventType.tapCorrect,
              objectId: 'switch',
              timeOffsetMs: 2500,
              x: 0,
              y: 0,
            ),
          ],
        );

        final metrics = LocalAIEngine.instance.analyzeMission(result, [result]);

        expect(metrics.reactionTimeSeconds, 0.8);
        expect(metrics.usefulReactionTimeSeconds, 2.5);
        expect(metrics.correctClicks, 1);
        expect(metrics.commissions, 2);
        expect(metrics.omission, isFalse);
        expect(result.events.first.objectRole, 'distractor');
      },
    );

    test('distractor rule has priority over impulse-control rule', () {
      final result = session(wrong: 4, distractors: 3);

      final decision = LocalAIEngine.instance.getAdaptation(
        childId: 'child',
        currentMissionId: 'dark_room',
        currentSession: result,
        history: [result],
      );

      expect(decision.missionType, 'focus_training');
      expect(decision.distractorLevel, 'reduced');
      expect(decision.nextDifficulty.maxDistractors, 1);
    });

    test('wrong clicks add a look-before-tapping pause and more time', () {
      final result = session(wrong: 3, completionSeconds: 18);

      final decision = LocalAIEngine.instance.getAdaptation(
        childId: 'child',
        currentMissionId: 'dark_room',
        currentSession: result,
        history: [result],
      );

      expect(decision.missionType, 'impulse_control');
      expect(decision.nextDifficulty.waitBeforeInteractionSeconds, 2);
      expect(decision.nextDifficulty.timeLimitSeconds, 40);
      expect(decision.hintLevel, 'high');
    });

    test('profile indicators remain non-diagnostic values from 0 to 100', () {
      final sessions = [
        session(id: 'one', distractors: 2, wrong: 1),
        session(
          id: 'two',
          completed: false,
          distractors: 4,
          wrong: 5,
          hints: 2,
          completionSeconds: 35,
        ),
      ];

      final profile = LocalAIEngine.instance.buildBehavioralProfile(
        'child',
        sessions,
      );

      for (final score in [
        profile.attentionScore,
        profile.impulseControlScore,
        profile.planningScore,
        profile.memoryScore,
      ]) {
        expect(score, inInclusiveRange(0, 100));
      }
      expect(profile.totalMissions, 2);
      expect(profile.consecutiveFailures, 1);
    });

    test('recent improvement drives trend, engagement, and success streak', () {
      final sessions = [
        session(
          id: 'old-1',
          completed: false,
          wrong: 5,
          distractors: 4,
          hints: 2,
          timestamp: DateTime(2026, 6, 1),
        ),
        session(
          id: 'old-2',
          wrong: 4,
          distractors: 3,
          hints: 2,
          timestamp: DateTime(2026, 6, 2),
        ),
        session(id: 'new-1', timestamp: DateTime(2026, 6, 3)),
        session(id: 'new-2', timestamp: DateTime(2026, 6, 4)),
      ];

      final profile = LocalAIEngine.instance.buildBehavioralProfile(
        'child',
        sessions,
      );

      expect(profile.overallTrend, 'improving');
      expect(profile.engagementScore, inInclusiveRange(0, 100));
      expect(profile.successStreak, 3);
      expect(profile.strongestSkill, isNotEmpty);
      expect(profile.growthFocus, isNotEmpty);
    });

    test('model confidence grows as local evidence accumulates', () {
      final first = session(id: 'first');
      final history = List.generate(
        6,
        (index) => session(
          id: 'history-$index',
          timestamp: DateTime(2026, 6, index + 1),
        ),
      );

      final earlyDecision = LocalAIEngine.instance.getAdaptation(
        childId: 'child',
        currentMissionId: 'dark_room',
        currentSession: first,
        history: [first],
      );
      final matureDecision = LocalAIEngine.instance.getAdaptation(
        childId: 'child',
        currentMissionId: 'dark_room',
        currentSession: history.last,
        history: history,
      );

      expect(matureDecision.confidence, greaterThan(earlyDecision.confidence));
      expect(matureDecision.focusSkill, isNotEmpty);
    });
  });

  test('mission factory follows the five documented difficulty rows', () {
    final expected = [
      (4, 1, 40, 'high'),
      (6, 1, 35, 'medium'),
      (8, 2, 30, 'medium'),
      (10, 3, 25, 'low'),
      (12, 4, 20, 'low'),
    ];

    for (var index = 0; index < expected.length; index++) {
      final config = MissionFactory.forLevel(index + 1);
      final row = expected[index];
      expect(config.totalObjects, row.$1);
      expect(config.maxDistractors, row.$2);
      expect(config.timeLimitSeconds, row.$3);
      expect(config.hintLevel, row.$4);
    }
  });

  test('mission journey includes garden and memory levels', () {
    expect(MissionFactory.nextMissionAfter('door_room'), 'garden_room');
    expect(MissionFactory.nextMissionAfter('garden_room'), 'memory_vault');
    expect(MissionFactory.nextMissionAfter('memory_vault'), 'dark_room');
  });
}
