import 'dart:math';

import '../missions/mission_factory.dart';
import '../models.dart';

/// Applies the documented child-safe rule priority and explains every choice.
class DecisionEngine {
  const DecisionEngine._();

  static AIAdaptation decide({
    required String currentMissionId,
    required SessionResult currentSession,
    required MissionMetrics metrics,
    required BehavioralProfile profile,
  }) {
    final currentLevel = currentSession.difficultyLevel.clamp(1, 5);
    late final String missionType;
    late final DifficultyParams nextDifficulty;
    late final String recommendedMissionId;
    late final String distractorLevel;
    late final String reasonEn;
    late final String reasonFr;
    late final String reasonAr;
    late final String focusSkill;
    bool recommendCalm = false;

    if (!metrics.completed || profile.consecutiveFailures >= 2) {
      missionType = 'recovery';
      final nextLevel = max(1, currentLevel - 1);
      nextDifficulty = MissionFactory.forLevel(nextLevel).copyWith(
        maxDistractors: 1,
        distractorIntensity: 0.12,
        hintDelaySeconds: 5,
        hintLevel: 'high',
      );
      recommendedMissionId = 'dark_room';
      distractorLevel = 'reduced';
      focusSkill = 'attention';
      recommendCalm = true;
      reasonEn =
          'The next quest is shorter and calmer, with earlier hints, so the child can rebuild momentum.';
      reasonFr =
          'La prochaine mission est plus courte et plus calme, avec des indices plus rapides, afin de reprendre confiance.';
      reasonAr =
          'المهمة التالية أقصر وأكثر هدوءاً، مع تلميحات مبكرة لمساعدة الطفل على استعادة الزخم.';
    } else if (metrics.distractorClicks >= 3) {
      missionType = 'focus_training';
      final nextLevel = max(1, currentLevel - 1);
      nextDifficulty = MissionFactory.forLevel(nextLevel).copyWith(
        maxDistractors: 1,
        distractorIntensity: 0.12,
        hintDelaySeconds: 7,
        hintLevel: 'medium',
      );
      recommendedMissionId = 'dark_room';
      distractorLevel = 'reduced';
      focusSkill = 'attention';
      reasonEn =
          'Several distractors were tapped, so the next focus quest uses fewer and slower visual distractions.';
      reasonFr =
          'Plusieurs distracteurs ont été touchés. La prochaine mission de concentration en utilise moins et les ralentit.';
      reasonAr =
          'تم النقر على عدة مشتتات، لذلك تستخدم مهمة التركيز التالية مشتتات بصرية أقل وأبطأ.';
    } else if (metrics.wrongClicks >= 3) {
      missionType = 'impulse_control';
      final nextLevel = max(1, currentLevel - 1);
      nextDifficulty = MissionFactory.forLevel(nextLevel).copyWith(
        hintLevel: 'high',
        hintDelaySeconds: 7,
        waitBeforeInteractionSeconds: 2,
      );
      recommendedMissionId = 'robot_room';
      distractorLevel = 'normal';
      focusSkill = 'impulse_control';
      reasonEn =
          'The next quest adds a short look-before-tapping pause and more time for careful planning.';
      reasonFr =
          'La prochaine mission ajoute une courte pause avant de toucher et laisse plus de temps pour planifier.';
      reasonAr =
          'تضيف المهمة التالية فترة قصيرة للنظر قبل النقر ووقتاً أطول للتخطيط بهدوء.';
    } else if (metrics.hintsUsed >= 2) {
      missionType = 'guided_puzzle';
      nextDifficulty = MissionFactory.forLevel(
        currentLevel,
      ).copyWith(hintLevel: 'high', hintDelaySeconds: 6);
      focusSkill = profile.growthFocus;
      recommendedMissionId = _missionForSkill(focusSkill);
      distractorLevel = 'normal';
      reasonEn =
          'The next puzzle keeps the level steady and offers progressive hints a little earlier.';
      reasonFr =
          'Le prochain puzzle garde le même niveau et propose des indices progressifs un peu plus tôt.';
      reasonAr =
          'يحافظ اللغز التالي على المستوى نفسه ويقدم تلميحات تدريجية في وقت أبكر قليلاً.';
    } else if (metrics.completed &&
        metrics.wrongClicks == 0 &&
        metrics.distractorClicks == 0 &&
        metrics.hintsUsed == 0) {
      missionType = 'harder_logic';
      nextDifficulty = MissionFactory.forLevel(min(5, currentLevel + 1));
      recommendedMissionId = MissionFactory.nextMissionAfter(currentMissionId);
      distractorLevel = 'increased';
      focusSkill = profile.growthFocus;
      reasonEn =
          'The puzzle was completed accurately without hints, so the next quest increases difficulty by one step.';
      reasonFr =
          'Le puzzle a été terminé avec précision et sans indice. La prochaine mission augmente la difficulté d’un niveau.';
      reasonAr =
          'اكتمل اللغز بدقة ومن دون تلميحات، لذلك ترفع المهمة التالية الصعوبة درجة واحدة.';
    } else {
      missionType = 'balanced_puzzle';
      nextDifficulty = MissionFactory.forLevel(currentLevel);
      focusSkill = profile.growthFocus;
      recommendedMissionId = profile.totalMissions < 2
          ? MissionFactory.nextMissionAfter(currentMissionId)
          : _missionForSkill(focusSkill);
      distractorLevel = 'normal';
      reasonEn =
          'Performance was balanced, so the next quest keeps the same difficulty with normal support.';
      reasonFr =
          'La performance était équilibrée. La prochaine mission garde la même difficulté et un soutien normal.';
      reasonAr =
          'كان الأداء متوازناً، لذلك تحافظ المهمة التالية على مستوى الصعوبة نفسه مع دعم عادي.';
    }

    final support = _supportMessages(missionType);
    final confidence = min(0.96, 0.46 + profile.totalMissions * 0.07);
    return AIAdaptation(
      metrics: metrics,
      updatedProfile: profile,
      nextDifficulty: nextDifficulty,
      recommendedMissionId: recommendedMissionId,
      missionType: missionType,
      distractorLevel: distractorLevel,
      hintLevel: nextDifficulty.hintLevel,
      reasonEn: reasonEn,
      reasonFr: reasonFr,
      reasonAr: reasonAr,
      supportMessageEn: support.$1,
      supportMessageFr: support.$2,
      supportMessageAr: support.$3,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      focusSkill: focusSkill,
      recommendCalmPuzzle: recommendCalm,
    );
  }

  static String _missionForSkill(String skill) => switch (skill) {
    'attention' => 'dark_room',
    'impulse_control' => 'robot_room',
    'planning' => 'garden_room',
    'memory' => 'memory_vault',
    _ => 'door_room',
  };

  static (String, String, String) _supportMessages(String missionType) {
    return switch (missionType) {
      'recovery' => (
        'The child may benefit from a calm, achievable activity with early support.',
        'L’enfant peut bénéficier d’une activité calme et accessible avec un soutien précoce.',
        'قد يستفيد الطفل من نشاط هادئ وسهل الإنجاز مع دعم مبكر.',
      ),
      'focus_training' => (
        'Curiosity was high around moving objects. Fewer visual distractions are recommended for the next activity.',
        'La curiosité était forte face aux objets mobiles. Moins de distractions visuelles sont recommandées.',
        'كان الفضول مرتفعاً تجاه العناصر المتحركة. يوصى بمشتتات بصرية أقل في النشاط التالي.',
      ),
      'impulse_control' => (
        'A short pause before acting can support careful choices and step-by-step planning.',
        'Une courte pause avant d’agir peut soutenir des choix réfléchis et la planification étape par étape.',
        'يمكن لفترة قصيرة قبل التفاعل أن تدعم الاختيارات الهادئة والتخطيط خطوة بخطوة.',
      ),
      'guided_puzzle' => (
        'The child stayed engaged and can be supported with earlier, progressive visual hints.',
        'L’enfant est resté engagé et peut être soutenu par des indices visuels progressifs plus précoces.',
        'حافظ الطفل على التفاعل ويمكن دعمه بتلميحات بصرية تدريجية ومبكرة.',
      ),
      'harder_logic' => (
        'Strong, accurate play suggests the child is ready for one gradual increase in challenge.',
        'Un jeu précis et solide indique que l’enfant est prêt pour une augmentation progressive du défi.',
        'يشير اللعب القوي والدقيق إلى أن الطفل مستعد لزيادة تدريجية واحدة في التحدي.',
      ),
      _ => (
        'Performance was steady. Continue with a balanced activity and the current level of support.',
        'La performance était stable. Continuez avec une activité équilibrée et le niveau de soutien actuel.',
        'كان الأداء مستقراً. استمروا بنشاط متوازن وبمستوى الدعم الحالي.',
      ),
    };
  }
}
