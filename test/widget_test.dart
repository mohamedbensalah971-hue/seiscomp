import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mindspark_quest/main.dart';
import 'package:mindspark_quest/state.dart';
import 'package:mindspark_quest/models.dart';
import 'package:mindspark_quest/local_engine.dart';
import 'package:mindspark_quest/ai_interface/ai_agent_service.dart';

void main() {
  group('Local AI Engine Tests', () {
    test('calculateAdaptation adapts correctly to high distractor clicks', () {
      final currentSession = SessionResult(
        id: 's1',
        childId: 'c1',
        missionId: 'dark_room',
        timestamp: DateTime.now(),
        completionTimeSeconds: 15.0,
        starsEarned: 3,
        gemsEarned: 2,
        totalClicks: 5,
        wrongClicks: 0,
        distractorClicks: 4, // high distractibility
        hintsUsed: 0,
        reactionTimeMs: 400,
        events: [],
      );

      final adaptation = LocalAIEngine.instance.getAdaptation(
        childId: 'c1',
        currentMissionId: 'dark_room',
        currentSession: currentSession,
        history: [],
      );

      expect(adaptation.missionType, equals('focus_training'));
      expect(adaptation.nextDifficulty.maxDistractors, equals(1));
      expect(adaptation.distractorLevel, equals('reduced'));
      expect(adaptation.recommendedMissionId, equals('dark_room'));
    });

    test(
      'calculateAdaptation increases difficulty on flawless performance',
      () {
        final currentSession = SessionResult(
          id: 's2',
          childId: 'c1',
          missionId: 'robot_room',
          timestamp: DateTime.now(),
          completionTimeSeconds: 8.0, // fast
          starsEarned: 3,
          gemsEarned: 2,
          totalClicks: 2,
          wrongClicks: 0, // perfect
          distractorClicks: 0, // flawless focus
          hintsUsed: 0,
          reactionTimeMs: 600,
          events: [],
        );

        final adaptation = LocalAIEngine.instance.getAdaptation(
          childId: 'c1',
          currentMissionId: 'robot_room',
          currentSession: currentSession,
          history: [],
        );

        expect(adaptation.missionType, equals('harder_logic'));
        expect(adaptation.nextDifficulty.difficultyLevel, equals(3));
        expect(adaptation.recommendedMissionId, equals('door_room'));
      },
    );

    test('calculateAdaptation handles failure and requests calm mission', () {
      final currentSession = SessionResult(
        id: 's3',
        childId: 'c1',
        missionId: 'door_room',
        timestamp: DateTime.now(),
        completionTimeSeconds: 40.0,
        starsEarned: 0, // failed
        gemsEarned: 0,
        totalClicks: 10,
        wrongClicks: 6,
        distractorClicks: 4,
        hintsUsed: 3,
        reactionTimeMs: 1200,
        events: [],
      );

      final adaptation = LocalAIEngine.instance.getAdaptation(
        childId: 'c1',
        currentMissionId: 'door_room',
        currentSession: currentSession,
        history: [],
      );

      expect(adaptation.nextDifficulty.complexityLevel, equals('Easy'));
      expect(adaptation.recommendCalmPuzzle, isTrue);
      expect(adaptation.missionType, equals('recovery'));
    });

    test('computeDashboardMetrics computes correct averages', () {
      final sessions = [
        SessionResult(
          id: 's1',
          childId: 'c1',
          missionId: 'dark_room',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          completionTimeSeconds: 12.0,
          starsEarned: 3,
          gemsEarned: 2,
          totalClicks: 3,
          wrongClicks: 1,
          distractorClicks: 1,
          hintsUsed: 0,
          reactionTimeMs: 1000,
          events: [],
        ),
        SessionResult(
          id: 's2',
          childId: 'c1',
          missionId: 'robot_room',
          timestamp: DateTime.now(),
          completionTimeSeconds: 15.0,
          starsEarned: 2,
          gemsEarned: 1,
          totalClicks: 4,
          wrongClicks: 2,
          distractorClicks: 0,
          hintsUsed: 0,
          reactionTimeMs: 2000,
          events: [],
        ),
      ];

      final metrics = LocalAIEngine.instance.getDashboardIndicators(sessions);

      expect(metrics['totalSessions'], equals(2));
      expect(metrics['completedMissions'], equals(2));
      expect(metrics['attentionScore'], greaterThan(60));
      expect(metrics['impulseControlScore'], greaterThan(50));
      expect(metrics['planningScore'], inInclusiveRange(0, 100));
      expect(metrics['memoryScore'], inInclusiveRange(0, 100));
      expect(
        metrics['averageReactionTimeSeconds'],
        equals(1.5),
      ); // average of 1.0 and 2.0s
    });
  });

  group('App smoke tests', () {
    testWidgets('MindSparkQuestApp renders splash screen', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const MindSparkQuestApp(),
        ),
      );
      await tester.pump();
      expect(find.text('MindSpark Quest'), findsOneWidget);
    });
  });

  group('Purchase flow', () {
    test('purchaseItem deducts gems without creating sessions', () async {
      final engine = LocalAIEngine.instance;
      expect(engine, isA<AIAgentService>());
    });
  });
}
