import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../localization.dart';

/// Voice + haptic feedback for puzzle interactions (offline TTS).
class GameFeedbackService {
  static final GameFeedbackService instance = GameFeedbackService._();
  GameFeedbackService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  String _lastSpoken = '';
  DateTime _lastSpeakTime = DateTime.fromMillisecondsSinceEpoch(0);
  final Random _random = Random();

  Future<void> init() async {
    if (_ready) return;
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.15);
    await _tts.setVolume(1.0);
    _ready = true;
  }

  Future<void> _setLanguage(String lang) async {
    switch (lang) {
      case 'fr':
        await _tts.setLanguage('fr-FR');
        break;
      case 'ar':
        await _tts.setLanguage('ar-SA');
        break;
      default:
        await _tts.setLanguage('en-US');
    }
  }

  Future<void> speakGoal(String missionId, String lang, {required bool enabled}) async {
    if (!enabled) return;
    await init();
    await _setLanguage(lang);
    final text = AppLocalizations.get('${missionId}_goal', lang);
    await _speak(text);
  }

  Future<void> speakWrong({
    required String lang,
    required bool voiceEnabled,
    required bool isDistractor,
    required int wrongCount,
  }) async {
    if (!voiceEnabled) return;
    await init();
    await _setLanguage(lang);

    String key;
    if (isDistractor) {
      key = 'voice_distractor';
    } else if (wrongCount >= 4) {
      key = 'voice_slow_down';
    } else if (wrongCount >= 2) {
      key = 'voice_focus';
    } else {
      key = 'voice_try_again';
    }
    await _speak(AppLocalizations.get(key, lang));
  }

  Future<void> speakHint(String missionId, String lang, {required bool enabled}) async {
    if (!enabled) return;
    await init();
    await _setLanguage(lang);
    await _speak(AppLocalizations.get('hint_$missionId', lang));
  }

  Future<void> speakCorrect(String lang, {required bool voiceEnabled}) async {
    if (!voiceEnabled) return;
    await init();
    await _setLanguage(lang);
    await _speak(AppLocalizations.get('voice_great', lang));
  }

  Future<void> speakMissionComplete(String lang, {required bool voiceEnabled}) async {
    if (!voiceEnabled) return;
    await init();
    await _setLanguage(lang);
    await _speak(AppLocalizations.get('voice_mission_complete', lang));
  }

  Future<void> _speak(String text) async {
    // Avoid spamming identical lines within 2 seconds
    final now = DateTime.now();
    if (text == _lastSpoken && now.difference(_lastSpeakTime).inSeconds < 2) {
      return;
    }
    _lastSpoken = text;
    _lastSpeakTime = now;
    await _tts.stop();
    await _tts.speak(text);
  }

  void hapticWrong() => HapticFeedback.lightImpact();
  void hapticDistractor() => HapticFeedback.mediumImpact();
  void hapticCorrect() => HapticFeedback.heavyImpact();

  String randomWrongLabel(String lang) {
    final keys = ['float_wrong_1', 'float_wrong_2', 'float_wrong_3'];
    return AppLocalizations.get(keys[_random.nextInt(keys.length)], lang);
  }

  String distractorLabel(String lang) =>
      AppLocalizations.get('float_distractor', lang);

  void dispose() {
    _tts.stop();
  }
}
