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
      id: this.id,
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
  factory ChildProfile.fromJson(String source) => ChildProfile.fromMap(json.decode(source));
}

enum GameplayEventType {
  tapCorrect,
  tapWrong,
  tapDistractor,
  hintUsed,
  levelStart,
  levelEnd
}

class GameplayEvent {
  final GameplayEventType type;
  final String objectId;
  final double timeOffsetMs; // milliseconds since level start
  final double x;
  final double y;

  GameplayEvent({
    required this.type,
    required this.objectId,
    required this.timeOffsetMs,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'objectId': objectId,
      'timeOffsetMs': timeOffsetMs,
      'x': x,
      'y': y,
    };
  }

  factory GameplayEvent.fromMap(Map<String, dynamic> map) {
    return GameplayEvent(
      type: GameplayEventType.values[map['type'] ?? 0],
      objectId: map['objectId'] ?? '',
      timeOffsetMs: (map['timeOffsetMs'] ?? 0).toDouble(),
      x: (map['x'] ?? 0.0).toDouble(),
      y: (map['y'] ?? 0.0).toDouble(),
    );
  }
}

class SessionResult {
  final String id;
  final String childId;
  final String missionId;
  final DateTime timestamp;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'missionId': missionId,
      'timestamp': timestamp.toIso8601String(),
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
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      completionTimeSeconds: (map['completionTimeSeconds'] ?? 0).toDouble(),
      starsEarned: map['starsEarned'] ?? 0,
      gemsEarned: map['gemsEarned'] ?? 0,
      totalClicks: map['totalClicks'] ?? 0,
      wrongClicks: map['wrongClicks'] ?? 0,
      distractorClicks: map['distractorClicks'] ?? 0,
      hintsUsed: map['hintsUsed'] ?? 0,
      reactionTimeMs: (map['reactionTimeMs'] ?? 0.0).toDouble(),
      events: List<GameplayEvent>.from(
        (map['events'] as List<dynamic>? ?? []).map((e) => GameplayEvent.fromMap(e)),
      ),
    );
  }
}

class DifficultyParams {
  final int maxDistractors; // 0 to 5
  final double distractorIntensity; // 0.0 to 1.0 (blinking rate / movement speed)
  final int totalObjects; // number of scene objects
  final double hintDelaySeconds; // time before hint becomes active
  final bool showTimerBar;
  final String complexityLevel; // 'Easy', 'Medium', 'Hard'

  const DifficultyParams({
    this.maxDistractors = 2,
    this.distractorIntensity = 0.4,
    this.totalObjects = 5,
    this.hintDelaySeconds = 12.0,
    this.showTimerBar = true,
    this.complexityLevel = 'Medium',
  });

  Map<String, dynamic> toMap() {
    return {
      'maxDistractors': maxDistractors,
      'distractorIntensity': distractorIntensity,
      'totalObjects': totalObjects,
      'hintDelaySeconds': hintDelaySeconds,
      'showTimerBar': showTimerBar,
      'complexityLevel': complexityLevel,
    };
  }

  factory DifficultyParams.fromMap(Map<String, dynamic> map) {
    return DifficultyParams(
      maxDistractors: map['maxDistractors'] ?? 2,
      distractorIntensity: (map['distractorIntensity'] ?? 0.4).toDouble(),
      totalObjects: map['totalObjects'] ?? 5,
      hintDelaySeconds: (map['hintDelaySeconds'] ?? 12.0).toDouble(),
      showTimerBar: map['showTimerBar'] ?? true,
      complexityLevel: map['complexityLevel'] ?? 'Medium',
    );
  }
}

class AIAdaptation {
  final DifficultyParams nextDifficulty;
  final String recommendedMissionId;
  final String supportMessageEn;
  final String supportMessageFr;
  final String supportMessageAr;
  final bool recommendCalmPuzzle;

  AIAdaptation({
    required this.nextDifficulty,
    required this.recommendedMissionId,
    required this.supportMessageEn,
    required this.supportMessageFr,
    required this.supportMessageAr,
    this.recommendCalmPuzzle = false,
  });
}
