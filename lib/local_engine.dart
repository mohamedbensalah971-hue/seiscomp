import 'agent/behavior_analyzer.dart';
import 'agent/decision_engine.dart';
import 'agent/profile_updater.dart';
import 'ai_interface/ai_agent_service.dart';
import 'models.dart';

/// Explainable, rule-based agent that runs entirely on the device.
class LocalAIEngine implements AIAgentService {
  static final LocalAIEngine instance = LocalAIEngine._();
  LocalAIEngine._();

  @override
  MissionMetrics analyzeMission(
    SessionResult session,
    List<SessionResult> history,
  ) => BehaviorAnalyzer.analyze(session, history);

  @override
  BehavioralProfile buildBehavioralProfile(
    String childId,
    List<SessionResult> sessions,
  ) => ProfileUpdater.build(childId, sessions);

  @override
  AIAdaptation getAdaptation({
    required String childId,
    required String currentMissionId,
    required SessionResult currentSession,
    required List<SessionResult> history,
  }) {
    final allSessions = List<SessionResult>.from(history);
    if (!allSessions.any((session) => session.id == currentSession.id)) {
      allSessions.add(currentSession);
    }
    final metrics = analyzeMission(currentSession, allSessions);
    final profile = buildBehavioralProfile(childId, allSessions);

    return DecisionEngine.decide(
      currentMissionId: currentMissionId,
      currentSession: currentSession,
      metrics: metrics,
      profile: profile,
    );
  }

  @override
  Map<String, dynamic> getDashboardIndicators(List<SessionResult> sessions) {
    final profile = buildBehavioralProfile(
      sessions.isEmpty ? '' : sessions.first.childId,
      sessions,
    );
    final chronological = List<SessionResult>.from(sessions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final scoreHistory = chronological
        .map(ProfileUpdater.scoreSession)
        .toList();

    return {
      'attentionScore': profile.attentionScore,
      'impulseControlScore': profile.impulseControlScore,
      'planningScore': profile.planningScore,
      'memoryScore': profile.memoryScore,
      'averageReactionTimeSeconds': profile.averageReactionTimeSeconds,
      'attentionVariability': profile.attentionVariability,
      'engagementScore': profile.engagementScore,
      'overallTrend': profile.overallTrend,
      'strongestSkill': profile.strongestSkill,
      'growthFocus': profile.growthFocus,
      'successStreak': profile.successStreak,
      'modelConfidence': _confidenceFor(profile.totalMissions),
      'completedMissions': sessions
          .where((session) => session.completed)
          .length,
      'totalSessions': sessions.length,
      'attentionHistory': scoreHistory.map((score) => score.attention).toList(),
      'impulseHistory': scoreHistory
          .map((score) => score.impulseControl)
          .toList(),
      'planningHistory': scoreHistory.map((score) => score.planning).toList(),
      'memoryHistory': scoreHistory.map((score) => score.memory).toList(),
      'dates': chronological
          .map(
            (session) => '${session.timestamp.month}/${session.timestamp.day}',
          )
          .toList(),
    };
  }

  static double _confidenceFor(int missionCount) => double.parse(
    (0.46 + missionCount * 0.07).clamp(0.46, 0.96).toStringAsFixed(2),
  );
}
