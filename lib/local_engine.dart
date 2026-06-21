import 'dart:math';
import 'ai_interface/ai_agent_service.dart';
import 'models.dart';

/// Rule-based fallback — works fully offline until the AI module is plugged in.
class LocalAIEngine implements AIAgentService {
  static final LocalAIEngine instance = LocalAIEngine._();
  LocalAIEngine._();

  @override
  AIAdaptation getAdaptation({
    required String childId,
    required String currentMissionId,
    required SessionResult currentSession,
    required List<SessionResult> history,
  }) =>
      calculateAdaptation(
        childId: childId,
        currentMissionId: currentMissionId,
        currentSession: currentSession,
        history: history,
      );

  @override
  Map<String, dynamic> getDashboardIndicators(List<SessionResult> sessions) =>
      computeDashboardMetrics(sessions);

  static AIAdaptation calculateAdaptation({
    required String childId,
    required String currentMissionId,
    required SessionResult currentSession,
    required List<SessionResult> history,
  }) {
    // 1. Gather metrics
    int distractorClicks = currentSession.distractorClicks;
    int wrongClicks = currentSession.wrongClicks;
    double completionTime = currentSession.completionTimeSeconds;
    int hintsUsed = currentSession.hintsUsed;
    bool completed = currentSession.starsEarned > 0;

    // 2. Compute adaptation difficulty params
    int nextMaxDistractors = 2;
    double nextDistractorIntensity = 0.4;
    int nextTotalObjects = 5;
    double nextHintDelaySeconds = 12.0;
    bool showTimerBar = true;
    String complexityLevel = 'Medium';
    bool recommendCalm = false;
    String nextMissionId = currentMissionId;

    // Logic based on child's performance:
    if (!completed) {
      // Failed or abandoned
      nextMaxDistractors = max(0, distractorClicks - 1);
      nextDistractorIntensity = 0.2;
      nextHintDelaySeconds = 8.0; // show hints faster
      complexityLevel = 'Easy';
      recommendCalm = true;
    } else {
      // Completed successfully
      if (distractorClicks > 3) {
        // High distractor attraction -> reduce distractors to help focus
        nextMaxDistractors = max(1, distractorClicks - 1);
        nextDistractorIntensity = 0.3;
      } else if (distractorClicks <= 1 && wrongClicks <= 1 && completionTime < 15.0) {
        // Very fast and accurate -> make it harder
        nextMaxDistractors = min(5, currentSession.distractorClicks + 2);
        nextDistractorIntensity = 0.6;
        nextTotalObjects = 7;
        nextHintDelaySeconds = 15.0;
        complexityLevel = 'Hard';
      } else {
        // Standard progression
        nextMaxDistractors = 2;
        nextDistractorIntensity = 0.4;
        complexityLevel = 'Medium';
      }

      if (wrongClicks > 4) {
        // High impulsive clicks -> trigger focus/impulse control mission suggestion
        complexityLevel = 'Medium';
        nextMaxDistractors = 3;
        nextDistractorIntensity = 0.5; // active training of impulse control
      }
    }

    // Determine the next recommended mission:
    // Simple cycle between: dark_room, robot_room, door_room
    if (currentMissionId == 'dark_room') {
      nextMissionId = 'robot_room';
    } else if (currentMissionId == 'robot_room') {
      nextMissionId = 'door_room';
    } else {
      nextMissionId = 'dark_room';
    }

    // Generate supportive diagnostic recommendations (avoiding clinical diagnosis)
    String supportMessageEn = "";
    String supportMessageFr = "";
    String supportMessageAr = "";

    if (wrongClicks > 4) {
      supportMessageEn = "Your child shows high energy but may benefit from slowing down before clicking. Practice the planning games to build patience.";
      supportMessageFr = "Votre enfant fait preuve de beaucoup d'énergie mais gagnerait à ralentir avant de cliquer. Entraînez-vous sur les jeux de planification.";
      supportMessageAr = "يُظهر طفلك طاقة عالية ولكنه قد يستفيد من التمهل قبل النقر. تدرب على ألعاب التخطيط لبناء الصبر.";
    } else if (distractorClicks > 3) {
      supportMessageEn = "Your child is highly curious and attracted to moving objects. Try reducing visual animations to help them maintain focus.";
      supportMessageFr = "Votre enfant est très curieux et attiré par les objets en mouvement. Essayez de réduire les animations visuelles pour l'aider à se concentrer.";
      supportMessageAr = "طفلك فضولي للغاية وينجذب للمؤثرات البصرية المتحركة. جرب تقليل الرسوم المتحركة في الإعدادات لمساعدته على التركيز.";
    } else if (hintsUsed >= 2) {
      supportMessageEn = "Your child is determined but needed some support with step-by-step logic. Try walking through the levels together.";
      supportMessageFr = "Votre enfant est déterminé mais a eu besoin de soutien pour la logique par étapes. Essayez de résoudre les niveaux ensemble.";
      supportMessageAr = "يتمتع طفلك بالإصرار ولكنه احتاج إلى دعم في استيعاب التوالي المنطقي للخطوات. جرب حل الألغاز معاً.";
    } else {
      supportMessageEn = "Excellent focus and consistency! Your child adapted well to changes and finished accurately.";
      supportMessageFr = "Excellente concentration ! Votre enfant s'est bien adapté aux changements de règles et a terminé avec précision.";
      supportMessageAr = "تركيز ممتاز واستقرار في الأداء! لقد تكيف طفلك بشكل رائع مع تغير القواعد وأنهى المهام بدقة.";
    }

    return AIAdaptation(
      nextDifficulty: DifficultyParams(
        maxDistractors: nextMaxDistractors,
        distractorIntensity: nextDistractorIntensity,
        totalObjects: nextTotalObjects,
        hintDelaySeconds: nextHintDelaySeconds,
        showTimerBar: showTimerBar,
        complexityLevel: complexityLevel,
      ),
      recommendedMissionId: nextMissionId,
      supportMessageEn: supportMessageEn,
      supportMessageFr: supportMessageFr,
      supportMessageAr: supportMessageAr,
      recommendCalmPuzzle: recommendCalm,
    );
  }

  // Aggregate stats across all history for the dashboard
  static Map<String, dynamic> computeDashboardMetrics(List<SessionResult> sessions) {
    if (sessions.isEmpty) {
      return {
        'attentionScore': 70.0,
        'impulseControlScore': 70.0,
        'averageReactionTimeSeconds': 2.0,
        'completedMissions': 0,
        'totalSessions': 0,
        'attentionHistory': <double>[],
        'impulseHistory': <double>[],
        'dates': <String>[],
      };
    }

    double totalAttention = 0.0;
    double totalImpulse = 0.0;
    double totalReactionTime = 0.0;
    int completed = 0;

    List<double> attentionHistory = [];
    List<double> impulseHistory = [];
    List<String> dates = [];

    // Order sessions chronologically
    final sortedSessions = List<SessionResult>.from(sessions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var session in sortedSessions) {
      // Calculate Attention Score: base 100%, subtract for distraction clicks, omissions, and high completion times
      double attention = 100.0;
      attention -= session.distractorClicks * 10;
      attention -= session.hintsUsed * 5;
      if (session.completionTimeSeconds > 25.0) {
        attention -= min(20.0, (session.completionTimeSeconds - 25.0) * 1.5);
      }
      attention = max(20.0, attention);

      // Calculate Impulse Control: base 100%, subtract for wrong clicks, rapid initial reaction time without correct choice
      double impulse = 100.0;
      impulse -= session.wrongClicks * 15;
      if (session.reactionTimeMs < 500 && session.wrongClicks > 0) {
        // clicked super fast and hit something wrong
        impulse -= 15.0;
      }
      impulse = max(20.0, impulse);

      totalAttention += attention;
      totalImpulse += impulse;
      totalReactionTime += (session.reactionTimeMs / 1000.0);
      if (session.starsEarned > 0) completed++;

      attentionHistory.add(attention);
      impulseHistory.add(impulse);
      
      // format date as "MM/dd" or just day name
      final month = session.timestamp.month;
      final day = session.timestamp.day;
      dates.add("$month/$day");
    }

    int count = sortedSessions.length;
    return {
      'attentionScore': (totalAttention / count).roundToDouble(),
      'impulseControlScore': (totalImpulse / count).roundToDouble(),
      'averageReactionTimeSeconds': double.parse((totalReactionTime / count).toStringAsFixed(1)),
      'completedMissions': completed,
      'totalSessions': count,
      'attentionHistory': attentionHistory,
      'impulseHistory': impulseHistory,
      'dates': dates,
    };
  }
}
