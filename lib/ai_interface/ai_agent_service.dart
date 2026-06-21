import '../models.dart';

/// Contract shared with the AI teammate. Swap [LocalAIEngine] for a remote
/// implementation without touching game screens.
abstract class AIAgentService {
  AIAdaptation getAdaptation({
    required String childId,
    required String currentMissionId,
    required SessionResult currentSession,
    required List<SessionResult> history,
  });

  Map<String, dynamic> getDashboardIndicators(List<SessionResult> sessions);
}
