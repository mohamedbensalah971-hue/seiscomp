import '../models.dart';
import 'ai_agent_service.dart';

/// HTTP client placeholder for your teammate's AI API.
/// Replace [baseUrl] and wire [getAdaptation] to their endpoint.
class RemoteAIClient implements AIAgentService {
  final String baseUrl;

  RemoteAIClient({required this.baseUrl});

  @override
  AIAdaptation getAdaptation({
    required String childId,
    required String currentMissionId,
    required SessionResult currentSession,
    required List<SessionResult> history,
  }) {
    throw UnimplementedError(
      'Connect RemoteAIClient to the AI teammate API at $baseUrl',
    );
  }

  @override
  Map<String, dynamic> getDashboardIndicators(List<SessionResult> sessions) {
    throw UnimplementedError(
      'Connect RemoteAIClient to the AI teammate API at $baseUrl',
    );
  }
}
