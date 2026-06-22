import 'dart:convert';

class ChildProfile {
  final String id;
  final String name;
  final String avatar; // e.g. 'fox', 'owl', 'cat', 'panda'
  final int age;
  final int stars;
  final int gems;
  final Map<String, int> completedMissions; // missionId -> stars earned

  ChildProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.age,
    this.stars = 0,
    this.gems = 0,
    this.completedMissions = const {},
  });

  ChildProfile copyWith({
    String? name,
    String? avatar,
    int? age,
    int? stars,
    int? gems,
    Map<String, int>? completedMissions,
  }) {
    return ChildProfile(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      stars: stars ?? this.stars,
      gems: gems ?? this.gems,
      completedMissions: completedMissions ?? this.completedMissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'age': age,
      'stars': stars,
      'gems': gems,
      'completedMissions': completedMissions,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      avatar: map['avatar'] ?? 'fox',
      age: map['age'] ?? 6,
      stars: map['stars'] ?? 0,
      gems: map['gems'] ?? 0,
      completedMissions: Map<String, int>.from(map['completedMissions'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());
  factory ChildProfile.fromJson(String source) =>
      ChildProfile.fromMap(json.decode(source));
}

enum GameplayEventType {
  tapCorrect,
  tapWrong,
  tapDistractor,
  hintUsed,
  levelStart,
  levelEnd,
}

class GameplayEvent {
  final GameplayEventType type;
  final String objectId;
  final String itemName;
  final double timeOffsetMs; // milliseconds since level start
  final double x;
  final double y;

  GameplayEvent({
    required this.type,
    required this.objectId,
    String? itemName,
    required this.timeOffsetMs,
    required this.x,
    required this.y,
  }) : itemName = itemName ?? _displayName(objectId);

  String get objectRole => switch (type) {
    GameplayEventType.tapCorrect => 'correct',
    GameplayEventType.tapWrong => 'wrong',
    GameplayEventType.tapDistractor => 'distractor',
    GameplayEventType.hintUsed => 'hint',
    GameplayEventType.levelStart => 'system',
    GameplayEventType.levelEnd => 'system',
  };

  bool get isTap =>
      type == GameplayEventType.tapCorrect ||
      type == GameplayEventType.tapWrong ||
      type == GameplayEventType.tapDistractor;

  double get timeFromStartSeconds => timeOffsetMs / 1000.0;

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'objectId': objectId,
      'itemName': itemName,
      'objectRole': objectRole,
      'timeOffsetMs': timeOffsetMs,
      'timeFromStart': timeFromStartSeconds,
      'x': x,
      'y': y,
    };
  }

  factory GameplayEvent.fromMap(Map<String, dynamic> map) {
    return GameplayEvent(
      type:
          GameplayEventType.values[(map['type'] ?? 0).clamp(
            0,
            GameplayEventType.values.length - 1,
          )],
      objectId: map['objectId'] ?? map['itemId'] ?? '',
      itemName: map['itemName'],
      timeOffsetMs:
          (map['timeOffsetMs'] ?? ((map['timeFromStart'] ?? 0) * 1000))
              .toDouble(),
      x: (map['x'] ?? 0.0).toDouble(),
      y: (map['y'] ?? 0.0).toDouble(),
    );
  }

  static String _displayName(String id) {
    if (id.isEmpty) return '';
    return id
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class SessionResult {
  final String id;
  final String childId;
  final String missionId;
  final DateTime timestamp;
  final int difficultyLevel;
  final double completionTimeSeconds;
  final int starsEarned;
  final int gemsEarned;
  final int totalClicks;
  final int wrongClicks;
  final int distractorClicks;
  final int hintsUsed;
  final double reactionTimeMs; // time to first action
  final List<GameplayEvent> events;

  SessionResult({
    required this.id,
    required this.childId,
    required this.missionId,
    required this.timestamp,
    this.difficultyLevel = 2,
    required this.completionTimeSeconds,
    required this.starsEarned,
    required this.gemsEarned,
    required this.totalClicks,
    required this.wrongClicks,
    required this.distractorClicks,
    required this.hintsUsed,
    required this.reactionTimeMs,
    required this.events,
  });

  bool get completed => starsEarned > 0;
  bool get omission => !completed;
  int get commissionClicks => wrongClicks + distractorClicks;

  double? get usefulReactionTimeMs {
    for (final event in events) {
      if (event.type == GameplayEventType.tapCorrect) {
        return event.timeOffsetMs;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'missionId': missionId,
      'timestamp': timestamp.toIso8601String(),
      'difficultyLevel': difficultyLevel,
      'completionTimeSeconds': completionTimeSeconds,
      'starsEarned': starsEarned,
      'gemsEarned': gemsEarned,
      'totalClicks': totalClicks,
      'wrongClicks': wrongClicks,
      'distractorClicks': distractorClicks,
      'hintsUsed': hintsUsed,
      'reactionTimeMs': reactionTimeMs,
      'events': events.map((e) => e.toMap()).toList(),
    };
  }

  factory SessionResult.fromMap(Map<String, dynamic> map) {
    return SessionResult(
      id: map['id'] ?? '',
      childId: map['childId'] ?? '',
      missionId: map['missionId'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      difficultyLevel: map['difficultyLevel'] ?? 2,
      completionTimeSeconds: (map['completionTimeSeconds'] ?? 0).toDouble(),
      starsEarned: map['starsEarned'] ?? 0,
      gemsEarned: map['gemsEarned'] ?? 0,
      totalClicks: map['totalClicks'] ?? 0,
      wrongClicks: map['wrongClicks'] ?? 0,
      distractorClicks: map['distractorClicks'] ?? 0,
      hintsUsed: map['hintsUsed'] ?? 0,
      reactionTimeMs: (map['reactionTimeMs'] ?? 0.0).toDouble(),
      events: List<GameplayEvent>.from(
        (map['events'] as List<dynamic>? ?? []).map(
          (event) =>
              GameplayEvent.fromMap(Map<String, dynamic>.from(event as Map)),
        ),
      ),
    );
  }
}

class MissionMetrics {
  final double reactionTimeSeconds;
  final double usefulReactionTimeSeconds;
  final int wrongClicks;
  final int distractorClicks;
  final int correctClicks;
  final int hintsUsed;
  final bool completed;
  final bool omission;
  final int commissions;
  final double completionTimeSeconds;
  final double reactionTimeVariability;

  const MissionMetrics({
    required this.reactionTimeSeconds,
    required this.usefulReactionTimeSeconds,
    required this.wrongClicks,
    required this.distractorClicks,
    required this.correctClicks,
    required this.hintsUsed,
    required this.completed,
    required this.omission,
    required this.commissions,
    required this.completionTimeSeconds,
    required this.reactionTimeVariability,
  });

  Map<String, dynamic> toMap() => {
    'reactionTimeSeconds': reactionTimeSeconds,
    'usefulReactionTimeSeconds': usefulReactionTimeSeconds,
    'wrongClicks': wrongClicks,
    'distractorClicks': distractorClicks,
    'correctClicks': correctClicks,
    'hintsUsed': hintsUsed,
    'completed': completed,
    'omission': omission,
    'commissions': commissions,
    'completionTimeSeconds': completionTimeSeconds,
    'reactionTimeVariability': reactionTimeVariability,
  };
}

class BehavioralProfile {
  final String childId;
  final double attentionScore;
  final double impulseControlScore;
  final double planningScore;
  final double memoryScore;
  final double averageReactionTimeSeconds;
  final double attentionVariability;
  final double engagementScore;
  final String overallTrend;
  final String strongestSkill;
  final String growthFocus;
  final int successStreak;
  final int currentDifficulty;
  final int totalMissions;
  final int consecutiveFailures;

  const BehavioralProfile({
    required this.childId,
    required this.attentionScore,
    required this.impulseControlScore,
    required this.planningScore,
    required this.memoryScore,
    required this.averageReactionTimeSeconds,
    required this.attentionVariability,
    required this.engagementScore,
    required this.overallTrend,
    required this.strongestSkill,
    required this.growthFocus,
    required this.successStreak,
    required this.currentDifficulty,
    required this.totalMissions,
    required this.consecutiveFailures,
  });

  factory BehavioralProfile.empty(String childId) => BehavioralProfile(
    childId: childId,
    attentionScore: 70,
    impulseControlScore: 70,
    planningScore: 70,
    memoryScore: 70,
    averageReactionTimeSeconds: 2,
    attentionVariability: 0,
    engagementScore: 70,
    overallTrend: 'steady',
    strongestSkill: 'attention',
    growthFocus: 'planning',
    successStreak: 0,
    currentDifficulty: 2,
    totalMissions: 0,
    consecutiveFailures: 0,
  );

  Map<String, dynamic> toMap() => {
    'childId': childId,
    'attentionScore': attentionScore,
    'impulseControlScore': impulseControlScore,
    'planningScore': planningScore,
    'memoryScore': memoryScore,
    'averageReactionTimeSeconds': averageReactionTimeSeconds,
    'attentionVariability': attentionVariability,
    'engagementScore': engagementScore,
    'overallTrend': overallTrend,
    'strongestSkill': strongestSkill,
    'growthFocus': growthFocus,
    'successStreak': successStreak,
    'currentDifficulty': currentDifficulty,
    'totalMissions': totalMissions,
    'consecutiveFailures': consecutiveFailures,
  };

  factory BehavioralProfile.fromMap(Map<String, dynamic> map) {
    return BehavioralProfile(
      childId: map['childId'] ?? '',
      attentionScore: (map['attentionScore'] ?? 70).toDouble(),
      impulseControlScore: (map['impulseControlScore'] ?? 70).toDouble(),
      planningScore: (map['planningScore'] ?? 70).toDouble(),
      memoryScore: (map['memoryScore'] ?? 70).toDouble(),
      averageReactionTimeSeconds: (map['averageReactionTimeSeconds'] ?? 2)
          .toDouble(),
      attentionVariability: (map['attentionVariability'] ?? 0).toDouble(),
      engagementScore: (map['engagementScore'] ?? 70).toDouble(),
      overallTrend: map['overallTrend'] ?? 'steady',
      strongestSkill: map['strongestSkill'] ?? 'attention',
      growthFocus: map['growthFocus'] ?? 'planning',
      successStreak: map['successStreak'] ?? 0,
      currentDifficulty: map['currentDifficulty'] ?? 2,
      totalMissions: map['totalMissions'] ?? 0,
      consecutiveFailures: map['consecutiveFailures'] ?? 0,
    );
  }
}

class DifficultyParams {
  final int difficultyLevel; // 1 to 5
  final int maxDistractors; // 0 to 5
  final double distractorIntensity; // 0.0 to 1.0
  final int totalObjects;
  final double hintDelaySeconds;
  final int timeLimitSeconds;
  final bool showTimerBar;
  final String complexityLevel; // Easy, Medium, Hard
  final String hintLevel; // high, medium, low
  final double waitBeforeInteractionSeconds;

  const DifficultyParams({
    this.difficultyLevel = 2,
    this.maxDistractors = 1,
    this.distractorIntensity = 0.35,
    this.totalObjects = 6,
    this.hintDelaySeconds = 10,
    this.timeLimitSeconds = 35,
    this.showTimerBar = true,
    this.complexityLevel = 'Medium',
    this.hintLevel = 'medium',
    this.waitBeforeInteractionSeconds = 0,
  });

  DifficultyParams copyWith({
    int? difficultyLevel,
    int? maxDistractors,
    double? distractorIntensity,
    int? totalObjects,
    double? hintDelaySeconds,
    int? timeLimitSeconds,
    bool? showTimerBar,
    String? complexityLevel,
    String? hintLevel,
    double? waitBeforeInteractionSeconds,
  }) {
    return DifficultyParams(
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      maxDistractors: maxDistractors ?? this.maxDistractors,
      distractorIntensity: distractorIntensity ?? this.distractorIntensity,
      totalObjects: totalObjects ?? this.totalObjects,
      hintDelaySeconds: hintDelaySeconds ?? this.hintDelaySeconds,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      showTimerBar: showTimerBar ?? this.showTimerBar,
      complexityLevel: complexityLevel ?? this.complexityLevel,
      hintLevel: hintLevel ?? this.hintLevel,
      waitBeforeInteractionSeconds:
          waitBeforeInteractionSeconds ?? this.waitBeforeInteractionSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'difficultyLevel': difficultyLevel,
      'maxDistractors': maxDistractors,
      'distractorIntensity': distractorIntensity,
      'totalObjects': totalObjects,
      'hintDelaySeconds': hintDelaySeconds,
      'timeLimitSeconds': timeLimitSeconds,
      'showTimerBar': showTimerBar,
      'complexityLevel': complexityLevel,
      'hintLevel': hintLevel,
      'waitBeforeInteractionSeconds': waitBeforeInteractionSeconds,
    };
  }

  factory DifficultyParams.fromMap(Map<String, dynamic> map) {
    return DifficultyParams(
      difficultyLevel: map['difficultyLevel'] ?? 2,
      maxDistractors: map['maxDistractors'] ?? 1,
      distractorIntensity: (map['distractorIntensity'] ?? 0.35).toDouble(),
      totalObjects: map['totalObjects'] ?? 6,
      hintDelaySeconds: (map['hintDelaySeconds'] ?? 10).toDouble(),
      timeLimitSeconds: map['timeLimitSeconds'] ?? 35,
      showTimerBar: map['showTimerBar'] ?? true,
      complexityLevel: map['complexityLevel'] ?? 'Medium',
      hintLevel: map['hintLevel'] ?? 'medium',
      waitBeforeInteractionSeconds: (map['waitBeforeInteractionSeconds'] ?? 0)
          .toDouble(),
    );
  }
}

class AIAdaptation {
  final MissionMetrics metrics;
  final BehavioralProfile updatedProfile;
  final DifficultyParams nextDifficulty;
  final String recommendedMissionId;
  final String missionType;
  final String distractorLevel;
  final String hintLevel;
  final String reasonEn;
  final String reasonFr;
  final String reasonAr;
  final String supportMessageEn;
  final String supportMessageFr;
  final String supportMessageAr;
  final double confidence;
  final String focusSkill;
  final bool recommendCalmPuzzle;

  const AIAdaptation({
    required this.metrics,
    required this.updatedProfile,
    required this.nextDifficulty,
    required this.recommendedMissionId,
    required this.missionType,
    required this.distractorLevel,
    required this.hintLevel,
    required this.reasonEn,
    required this.reasonFr,
    required this.reasonAr,
    required this.supportMessageEn,
    required this.supportMessageFr,
    required this.supportMessageAr,
    required this.confidence,
    required this.focusSkill,
    this.recommendCalmPuzzle = false,
  });

  String reasonForLanguage(String language) => switch (language) {
    'fr' => reasonFr,
    'ar' => reasonAr,
    _ => reasonEn,
  };

  String supportForLanguage(String language) => switch (language) {
    'fr' => supportMessageFr,
    'ar' => supportMessageAr,
    _ => supportMessageEn,
  };
}
