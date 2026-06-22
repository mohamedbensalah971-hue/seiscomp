import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'ai_interface/ai_agent_service.dart';
import 'local_engine.dart';

class AppState extends ChangeNotifier {
  static const String settingsBoxName = 'settings_box';
  static const String profilesBoxName = 'profiles_box';
  static const String sessionsBoxName = 'sessions_box';

  late Box _settingsBox;
  late Box _profilesBox;
  late Box _sessionsBox;

  bool _initialized = false;
  bool get initialized => _initialized;

  // Selected Profile
  ChildProfile? _selectedProfile;
  ChildProfile? get selectedProfile => _selectedProfile;

  // Profiles list
  List<ChildProfile> _profiles = [];
  List<ChildProfile> get profiles => _profiles;

  // Settings & Accessibility
  String _language = 'en'; // 'en', 'fr', 'ar'
  String get language => _language;

  bool _reduceMotion = false;
  bool get reduceMotion => _reduceMotion;

  bool _reduceDistractors = false;
  bool get reduceDistractors => _reduceDistractors;

  bool _colorblindMode = false;
  bool get colorblindMode => _colorblindMode;

  bool _largerText = false;
  bool get largerText => _largerText;

  double _musicVolume = 0.5;
  double get musicVolume => _musicVolume;

  double _sfxVolume = 0.8;
  double get sfxVolume => _sfxVolume;

  bool _voiceInstructions = true;
  bool get voiceInstructions => _voiceInstructions;

  String? _parentPin;
  String? get parentPin => _parentPin;

  // Active AI parameters for the current profile
  DifficultyParams _currentDifficulty = const DifficultyParams();
  DifficultyParams get currentDifficulty => _currentDifficulty;

  String _recommendedMissionId = 'dark_room';
  String get recommendedMissionId => _recommendedMissionId;

  // Last adaptation details
  String _lastFeedbackMessage = "Let's explore your first puzzle room!";
  String get lastFeedbackMessage => _lastFeedbackMessage;

  BehavioralProfile _behavioralProfile = BehavioralProfile.empty('');
  BehavioralProfile get behavioralProfile => _behavioralProfile;

  String _lastDecisionType = 'balanced_puzzle';
  String get lastDecisionType => _lastDecisionType;

  String _lastDecisionReason = 'The first quest begins with balanced support.';
  String get lastDecisionReason => _lastDecisionReason;

  AIAgentService _aiAgent = LocalAIEngine.instance;
  AIAgentService get aiAgent => _aiAgent;

  void setAIAgent(AIAgentService agent) {
    _aiAgent = agent;
    notifyListeners();
  }

  // Initialize Hive and load data
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    _settingsBox = await Hive.openBox(settingsBoxName);
    _profilesBox = await Hive.openBox(profilesBoxName);
    _sessionsBox = await Hive.openBox(sessionsBoxName);

    // Load Settings
    _language = _settingsBox.get('language', defaultValue: 'en');
    _reduceMotion = _settingsBox.get('reduceMotion', defaultValue: false);
    _reduceDistractors = _settingsBox.get(
      'reduceDistractors',
      defaultValue: false,
    );
    _colorblindMode = _settingsBox.get('colorblindMode', defaultValue: false);
    _largerText = _settingsBox.get('largerText', defaultValue: false);
    _musicVolume = _settingsBox.get('musicVolume', defaultValue: 0.5);
    _sfxVolume = _settingsBox.get('sfxVolume', defaultValue: 0.8);
    _voiceInstructions = _settingsBox.get(
      'voiceInstructions',
      defaultValue: true,
    );
    _parentPin = _settingsBox.get('parentPin');

    // Load Profiles
    _loadProfiles();

    // Load last active profile if available
    String? lastProfileId = _settingsBox.get('last_profile_id');
    if (lastProfileId != null && _profiles.any((p) => p.id == lastProfileId)) {
      _selectedProfile = _profiles.firstWhere((p) => p.id == lastProfileId);
      _loadAIParamsForCurrentChild();
    }

    _initialized = true;
    notifyListeners();
  }

  void _loadProfiles() {
    List<dynamic> rawProfiles = _profilesBox.values.toList();
    _profiles = rawProfiles.map((p) {
      if (p is Map) {
        return ChildProfile.fromMap(Map<String, dynamic>.from(p));
      } else {
        return ChildProfile.fromJson(p.toString());
      }
    }).toList();
  }

  // Language & Accessibility Mutators
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _settingsBox.put('language', lang);
    if (_selectedProfile != null) {
      _loadAIParamsForCurrentChild();
    }
    notifyListeners();
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    await _settingsBox.put('reduceMotion', value);
    notifyListeners();
  }

  Future<void> setReduceDistractors(bool value) async {
    _reduceDistractors = value;
    await _settingsBox.put('reduceDistractors', value);
    notifyListeners();
  }

  Future<void> setColorblindMode(bool value) async {
    _colorblindMode = value;
    await _settingsBox.put('colorblindMode', value);
    notifyListeners();
  }

  Future<void> setLargerText(bool value) async {
    _largerText = value;
    await _settingsBox.put('largerText', value);
    notifyListeners();
  }

  Future<void> setSoundVolume(double music, double sfx) async {
    _musicVolume = music;
    _sfxVolume = sfx;
    await _settingsBox.put('musicVolume', music);
    await _settingsBox.put('sfxVolume', sfx);
    notifyListeners();
  }

  Future<void> setVoiceInstructions(bool value) async {
    _voiceInstructions = value;
    await _settingsBox.put('voiceInstructions', value);
    notifyListeners();
  }

  Future<void> setParentPin(String pin) async {
    _parentPin = pin;
    await _settingsBox.put('parentPin', pin);
    notifyListeners();
  }

  // Profile Management
  Future<void> addProfile(String name, String avatar, int age) async {
    String id = DateTime.now().millisecondsSinceEpoch.toString();
    ChildProfile profile = ChildProfile(
      id: id,
      name: name,
      avatar: avatar,
      age: age,
    );

    await _profilesBox.put(id, profile.toMap());
    _loadProfiles();

    if (_selectedProfile == null) {
      await selectProfile(id);
    } else {
      notifyListeners();
    }
  }

  Future<void> selectProfile(String? id) async {
    if (id == null) {
      _selectedProfile = null;
      await _settingsBox.delete('last_profile_id');
    } else {
      _selectedProfile = _profiles.firstWhere((p) => p.id == id);
      await _settingsBox.put('last_profile_id', id);
      _loadAIParamsForCurrentChild();
    }
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    await _profilesBox.delete(id);
    // Delete all session history for this child
    List<dynamic> keys = _sessionsBox.keys.toList();
    for (var key in keys) {
      var map = _sessionsBox.get(key);
      if (map != null && map['childId'] == id) {
        await _sessionsBox.delete(key);
      }
    }

    final perProfileSettingKeys = _settingsBox.keys
        .where((key) => key.toString().contains(id))
        .toList();
    await _settingsBox.deleteAll(perProfileSettingKeys);

    _loadProfiles();
    if (_selectedProfile?.id == id) {
      _selectedProfile = null;
      await _settingsBox.delete('last_profile_id');
    }
    notifyListeners();
  }

  // Session History Management
  List<SessionResult> getSessionHistoryForCurrentChild() {
    if (_selectedProfile == null) return [];
    List<dynamic> rawSessions = _sessionsBox.values.toList();
    return rawSessions
        .map((s) => SessionResult.fromMap(Map<String, dynamic>.from(s)))
        .where((s) => s.childId == _selectedProfile!.id)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first
  }

  void _loadAIParamsForCurrentChild() {
    if (_selectedProfile == null) return;

    // Read last stored adaptation or set default
    Map? diffMap = _settingsBox.get('difficulty_${_selectedProfile!.id}');
    if (diffMap != null) {
      _currentDifficulty = DifficultyParams.fromMap(
        Map<String, dynamic>.from(diffMap),
      );
    } else {
      _currentDifficulty = const DifficultyParams();
    }

    _recommendedMissionId = _settingsBox.get(
      'recommended_mission_${_selectedProfile!.id}',
      defaultValue: 'dark_room',
    );

    final rawProfile = _settingsBox.get(
      'behavioral_profile_${_selectedProfile!.id}',
    );
    _behavioralProfile = rawProfile is Map
        ? BehavioralProfile.fromMap(Map<String, dynamic>.from(rawProfile))
        : _aiAgent.buildBehavioralProfile(
            _selectedProfile!.id,
            getSessionHistoryForCurrentChild(),
          );

    _lastDecisionType = _settingsBox.get(
      'last_decision_type_${_selectedProfile!.id}',
      defaultValue: 'balanced_puzzle',
    );

    // Load last support message
    String langCode = _language == 'fr'
        ? 'Fr'
        : (_language == 'ar' ? 'Ar' : 'En');
    _lastFeedbackMessage = _settingsBox.get(
      'last_feedback_${_selectedProfile!.id}_$langCode',
      defaultValue: _language == 'fr'
          ? "Explorons ton premier puzzle !"
          : (_language == 'ar'
                ? "لنستكشف أول غرفة ألغاز لك!"
                : "Let's explore your first puzzle room!"),
    );
    _lastDecisionReason = _settingsBox.get(
      'last_reason_${_selectedProfile!.id}_$langCode',
      defaultValue: _language == 'fr'
          ? 'La première mission commence avec un soutien équilibré.'
          : (_language == 'ar'
                ? 'تبدأ المهمة الأولى بدعم متوازن.'
                : 'The first quest begins with balanced support.'),
    );
  }

  // Record Level Finished & Trigger AI Adaptation
  Future<void> submitSession(SessionResult session) async {
    if (_selectedProfile == null) return;

    // 1. Save session to Hive
    await _sessionsBox.put(session.id, session.toMap());

    // 2. Update child profile currencies & completions
    int updatedStars = _selectedProfile!.stars + session.starsEarned;
    int updatedGems = _selectedProfile!.gems + session.gemsEarned;

    Map<String, int> updatedMissions = Map<String, int>.from(
      _selectedProfile!.completedMissions,
    );
    int currentBestStars = updatedMissions[session.missionId] ?? 0;
    if (session.starsEarned > currentBestStars) {
      updatedMissions[session.missionId] = session.starsEarned;
    }

    ChildProfile updatedProfile = _selectedProfile!.copyWith(
      stars: updatedStars,
      gems: updatedGems,
      completedMissions: updatedMissions,
    );

    // Save updated profile
    await _profilesBox.put(updatedProfile.id, updatedProfile.toMap());

    // Update active variable
    _selectedProfile = updatedProfile;
    _loadProfiles(); // reload lists

    // 3. Compute adaptation parameters using history + local engine
    List<SessionResult> history = getSessionHistoryForCurrentChild();
    AIAdaptation adaptation = _aiAgent.getAdaptation(
      childId: _selectedProfile!.id,
      currentMissionId: session.missionId,
      currentSession: session,
      history: history,
    );

    // 4. Save difficulty & recommended parameters
    _currentDifficulty = _reduceDistractors
        ? adaptation.nextDifficulty.copyWith(
            maxDistractors: min(1, adaptation.nextDifficulty.maxDistractors),
            distractorIntensity: 0.1,
          )
        : adaptation.nextDifficulty;

    _recommendedMissionId = adaptation.recommendedMissionId;
    _behavioralProfile = adaptation.updatedProfile;
    _lastDecisionType = adaptation.missionType;

    await _settingsBox.put(
      'difficulty_${_selectedProfile!.id}',
      _currentDifficulty.toMap(),
    );
    await _settingsBox.put(
      'recommended_mission_${_selectedProfile!.id}',
      _recommendedMissionId,
    );
    await _settingsBox.put(
      'behavioral_profile_${_selectedProfile!.id}',
      _behavioralProfile.toMap(),
    );
    await _settingsBox.put(
      'last_decision_type_${_selectedProfile!.id}',
      _lastDecisionType,
    );

    // Save feedback messages in all languages
    await _settingsBox.put(
      'last_feedback_${_selectedProfile!.id}_En',
      adaptation.supportMessageEn,
    );
    await _settingsBox.put(
      'last_feedback_${_selectedProfile!.id}_Fr',
      adaptation.supportMessageFr,
    );
    await _settingsBox.put(
      'last_feedback_${_selectedProfile!.id}_Ar',
      adaptation.supportMessageAr,
    );
    await _settingsBox.put(
      'last_reason_${_selectedProfile!.id}_En',
      adaptation.reasonEn,
    );
    await _settingsBox.put(
      'last_reason_${_selectedProfile!.id}_Fr',
      adaptation.reasonFr,
    );
    await _settingsBox.put(
      'last_reason_${_selectedProfile!.id}_Ar',
      adaptation.reasonAr,
    );

    String langCode = _language == 'fr'
        ? 'Fr'
        : (_language == 'ar' ? 'Ar' : 'En');
    _lastFeedbackMessage = _settingsBox.get(
      'last_feedback_${_selectedProfile!.id}_$langCode',
    );
    _lastDecisionReason = adaptation.reasonForLanguage(_language);

    notifyListeners();
  }

  bool isItemPurchased(String itemId) {
    if (_selectedProfile == null) return false;
    return _settingsBox.get(
          'purchased_${_selectedProfile!.id}_$itemId',
          defaultValue: false,
        ) ==
        true;
  }

  String getEquippedItem(String type, {String defaultValue = 'default'}) {
    if (_selectedProfile == null) return defaultValue;
    return _settingsBox.get(
      'equipped_${_selectedProfile!.id}_$type',
      defaultValue: defaultValue,
    );
  }

  Future<bool> purchaseItem({
    required String itemId,
    required String itemType,
    required int gemCost,
  }) async {
    if (_selectedProfile == null || _selectedProfile!.gems < gemCost) {
      return false;
    }

    final profile = _selectedProfile!;
    final updated = profile.copyWith(gems: profile.gems - gemCost);
    await _profilesBox.put(updated.id, updated.toMap());
    await _settingsBox.put('purchased_${profile.id}_$itemId', true);
    await _settingsBox.put('equipped_${profile.id}_$itemType', itemId);

    _selectedProfile = updated;
    _loadProfiles();
    notifyListeners();
    return true;
  }

  Future<void> equipItem(String type, String itemId) async {
    if (_selectedProfile == null) return;
    await _settingsBox.put('equipped_${_selectedProfile!.id}_$type', itemId);
    notifyListeners();
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _settingsBox.clear();
    await _profilesBox.clear();
    await _sessionsBox.clear();

    _profiles = [];
    _selectedProfile = null;
    _language = 'en';
    _reduceMotion = false;
    _reduceDistractors = false;
    _colorblindMode = false;
    _largerText = false;
    _musicVolume = 0.5;
    _sfxVolume = 0.8;
    _voiceInstructions = true;
    _parentPin = null;
    _currentDifficulty = const DifficultyParams();
    _recommendedMissionId = 'dark_room';
    _behavioralProfile = BehavioralProfile.empty('');
    _lastDecisionType = 'balanced_puzzle';
    _lastDecisionReason = 'The first quest begins with balanced support.';
    _lastFeedbackMessage = "Let's explore your first puzzle room!";

    notifyListeners();
  }
}
