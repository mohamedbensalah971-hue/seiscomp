import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../models.dart';
import '../localization.dart';
import '../widgets/puzzle_room_scenes.dart';
import '../services/game_feedback_service.dart';
import 'results.dart';

class _FloatingFeedback {
  final String text;
  final Offset position;
  final Color color;
  final DateTime created;

  _FloatingFeedback({
    required this.text,
    required this.position,
    required this.color,
  }) : created = DateTime.now();
}

class PuzzleGameScreen extends StatefulWidget {
  final String missionId;
  const PuzzleGameScreen({super.key, required this.missionId});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen>
    with TickerProviderStateMixin {
  // Gameplay stats tracking
  late DateTime _startTime;
  double? _firstActionTimeMs;
  int _wrongClicks = 0;
  int _distractorClicks = 0;
  int _hintsUsed = 0;
  final List<GameplayEvent> _events = [];

  // Game lifecycle states
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _resultSubmitted = false;
  bool _hintActive = false;
  bool _interactionReady = true;
  String _hintText = "";
  String? _failureNoticeText;
  Timer? _missionStartTimer;

  // Level 1: Dark Room state
  bool _isLit = false;

  // Level 2: Robot Room state
  bool _batterySelected = false;
  bool _isPowered = false;

  // Level 3: Door Room state
  bool _boxOpened = false;
  bool _keyFound = false;
  bool _keySelected = false;
  bool _doorOpened = false;

  // Level 4: Enchanted Garden state
  bool _wateringCanSelected = false;
  bool _wateringCanFilled = false;
  bool _plantWatered = false;

  // Level 5: Memory Vault state
  int _memoryStep = 0;
  bool _memorySequenceVisible = true;
  List<String> get _memorySequence => _difficulty.difficultyLevel >= 4
      ? const ['moon', 'star', 'gem', 'planet']
      : const ['moon', 'star', 'gem'];

  // Animation Controllers
  late AnimationController _timerController;
  late AnimationController _distractorMotionController;
  late AnimationController _itemBobController;
  late AnimationController _pulseController;
  late AnimationController _lightAnimController;
  late AnimationController _doorAnimController;
  late Animation<double> _lightAnim;
  late Animation<double> _doorAnim;

  // Custom Particle bursts
  final List<LevelParticle> _particles = [];
  Timer? _particleTimer;
  Timer? _floatTimer;

  // Wrong-tap feedback
  late AnimationController _flashController;
  late AnimationController _shakeController;
  String? _shakingObjectId;
  final List<_FloatingFeedback> _floatingFeedbacks = [];
  double _screenFlash = 0.0;

  // AI adaptation constraints
  late DifficultyParams _difficulty;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    final appState = Provider.of<AppState>(context, listen: false);
    _difficulty = appState.currentDifficulty;

    // Accessibility: reduce distractors when parent enabled the setting
    if (appState.reduceDistractors) {
      _difficulty = _difficulty.copyWith(
        maxDistractors: _difficulty.maxDistractors.clamp(0, 1),
        distractorIntensity: 0.1,
      );
    }

    final motionScale = appState.reduceMotion ? 0.0 : 1.0;

    // Timer limit based on difficulty (soft timer bar count down)
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _difficulty.timeLimitSeconds),
    );
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCompleted) {
        // level timeout or omit
        _handleLevelFailed(
          completionTimeSeconds: _difficulty.timeLimitSeconds.toDouble(),
        );
      }
    });

    // Animate moving distractors based on speed intensity from AI
    double distractorSpeed = _difficulty.distractorIntensity * motionScale;
    _distractorMotionController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: motionScale == 0
            ? 999999
            : (1400 / (distractorSpeed + 0.1)).round(),
      ),
    );
    if (motionScale > 0) {
      _distractorMotionController.repeat(reverse: true);
    }

    _itemBobController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: motionScale == 0 ? 999999 : 2600),
    );
    if (motionScale > 0) {
      _itemBobController.repeat(reverse: true);
    }

    // Glowing animations
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: motionScale == 0 ? 999999 : 1000),
    );
    if (motionScale > 0) {
      _pulseController.repeat(reverse: true);
    }

    _lightAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _lightAnim = CurvedAnimation(
      parent: _lightAnimController,
      curve: Curves.easeInOut,
    );

    _doorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _doorAnim = CurvedAnimation(
      parent: _doorAnimController,
      curve: Curves.easeOutBack,
    );

    _flashController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        )..addListener(() {
          if (mounted) setState(() => _screenFlash = _flashController.value);
        });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Voice: read mission goal when level starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      GameFeedbackService.instance.speakGoal(
        widget.missionId,
        appState.language,
        enabled: appState.voiceInstructions,
      );
    });

    _startAdaptiveMission();
  }

  void _startAdaptiveMission() {
    final wait = _difficulty.waitBeforeInteractionSeconds;
    if (wait <= 0) {
      _beginMission();
      return;
    }

    _interactionReady = false;
    _missionStartTimer = Timer(
      Duration(milliseconds: (wait * 1000).round()),
      () {
        if (!mounted) return;
        setState(() => _interactionReady = true);
        _beginMission();
      },
    );
  }

  void _beginMission() {
    _startTime = DateTime.now();
    _timerController.forward(from: 0);
    if (widget.missionId == 'memory_vault') {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && !_isCompleted && !_hintActive) {
          setState(() => _memorySequenceVisible = false);
        }
      });
    }
    // Auto hint check after the agent-specified delay.
    Future.delayed(Duration(seconds: _difficulty.hintDelaySeconds.round()), () {
      if (mounted && !_isCompleted && _events.isEmpty) {
        _triggerAutoHint();
      }
    });
  }

  void _triggerAutoHint() {
    setState(() {
      _hintActive = true;
      _hintText = _getHintString();
      if (widget.missionId == 'memory_vault') {
        _memorySequenceVisible = true;
      }
    });
    final appState = Provider.of<AppState>(context, listen: false);
    GameFeedbackService.instance.speakHint(
      widget.missionId,
      appState.language,
      enabled: appState.voiceInstructions,
    );
  }

  String _getHintString() {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.language;
    return AppLocalizations.get('hint_${widget.missionId}', lang);
  }

  double get _elapsedSeconds =>
      DateTime.now().difference(_startTime).inMilliseconds / 1000.0;

  @override
  void dispose() {
    _timerController.dispose();
    _distractorMotionController.dispose();
    _itemBobController.dispose();
    _pulseController.dispose();
    _lightAnimController.dispose();
    _doorAnimController.dispose();
    _missionStartTimer?.cancel();
    _flashController.dispose();
    _shakeController.dispose();
    _particleTimer?.cancel();
    _floatTimer?.cancel();
    super.dispose();
  }

  void _handleWrongTap(
    String objectId,
    Offset globalPos, {
    required bool isDistractor,
  }) {
    if (_isCompleted || _isPaused) return;

    _recordEvent(
      isDistractor
          ? GameplayEventType.tapDistractor
          : GameplayEventType.tapWrong,
      objectId,
      globalPos,
    );

    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.language;
    final reduceMotion = appState.reduceMotion;

    // Red / orange sparkle burst at tap location
    _triggerWrongBurst(globalPos, isDistractor: isDistractor);

    // Screen red flash
    if (!reduceMotion) {
      _flashController.forward(from: 0).then((_) {
        if (mounted) _flashController.reverse();
      });
    }

    // Shake the tapped object
    if (!reduceMotion) {
      setState(() => _shakingObjectId = objectId);
      _shakeController.forward(from: 0);
    }

    // Floating label near tap
    final label = isDistractor
        ? GameFeedbackService.instance.distractorLabel(lang)
        : GameFeedbackService.instance.randomWrongLabel(lang);
    setState(() {
      _floatingFeedbacks.add(
        _FloatingFeedback(
          text: label,
          position: globalPos,
          color: isDistractor ? AppColors.accentPink : AppColors.accentRed,
        ),
      );
    });
    _startFloatTimer();

    // Haptics + supportive voice (never punitive)
    if (isDistractor) {
      GameFeedbackService.instance.hapticDistractor();
    } else {
      GameFeedbackService.instance.hapticWrong();
    }
    GameFeedbackService.instance.speakWrong(
      lang: lang,
      voiceEnabled: appState.voiceInstructions,
      isDistractor: isDistractor,
      wrongCount: _wrongClicks + _distractorClicks,
    );
  }

  void _startFloatTimer() {
    _floatTimer?.cancel();
    _floatTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      _floatingFeedbacks.removeWhere(
        (f) => now.difference(f.created).inMilliseconds > 1200,
      );
      setState(() {});
      if (_floatingFeedbacks.isEmpty) timer.cancel();
    });
  }

  void _triggerWrongBurst(Offset origin, {required bool isDistractor}) {
    final random = math.Random();
    final count = isDistractor ? 45 : 35;
    final colors = isDistractor
        ? [AppColors.accentPink, AppColors.accentPurple, AppColors.accentYellow]
        : [AppColors.accentRed, const Color(0xFFFF6B6B), AppColors.accentPink];

    setState(() {
      for (int i = 0; i < count; i++) {
        double angle = random.nextDouble() * 2 * math.pi;
        double speed = 2.0 + random.nextDouble() * 7.0;
        _particles.add(
          LevelParticle(
            x: origin.dx,
            y: origin.dy,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed - 1.5,
            color: colors[random.nextInt(colors.length)],
            radius: 2.0 + random.nextDouble() * 5.0,
            opacity: 1.0,
          ),
        );
      }
    });
    _runParticleLoop();
  }

  void _runParticleLoop() {
    _particleTimer?.cancel();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() {
        for (var p in _particles) {
          p.update();
        }
        _particles.removeWhere((p) => p.opacity <= 0.05);
      });
      if (_particles.isEmpty) timer.cancel();
    });
  }

  void _recordEvent(GameplayEventType type, String objectId, Offset pos) {
    final offset = DateTime.now()
        .difference(_startTime)
        .inMilliseconds
        .toDouble();
    if (type == GameplayEventType.tapCorrect ||
        type == GameplayEventType.tapWrong ||
        type == GameplayEventType.tapDistractor) {
      _firstActionTimeMs ??= offset;
    }

    setState(() {
      _events.add(
        GameplayEvent(
          type: type,
          objectId: objectId,
          timeOffsetMs: offset,
          x: pos.dx,
          y: pos.dy,
        ),
      );

      if (type == GameplayEventType.tapWrong) {
        _wrongClicks++;
      } else if (type == GameplayEventType.tapDistractor) {
        _distractorClicks++;
      } else if (type == GameplayEventType.hintUsed) {
        _hintsUsed++;
      }
    });
  }

  // Particle explosion on correct taps
  void _triggerSparkBurst(Offset origin) {
    final random = math.Random();
    setState(() {
      for (int i = 0; i < 30; i++) {
        double angle = random.nextDouble() * 2 * math.pi;
        double speed = 1.0 + random.nextDouble() * 5.0;
        _particles.add(
          LevelParticle(
            x: origin.dx,
            y: origin.dy,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed - 2.0, // slight upward gravity
            color: random.nextBool()
                ? AppColors.secondary
                : AppColors.accentYellow,
            radius: 2.0 + random.nextDouble() * 4.0,
            opacity: 1.0,
          ),
        );
      }
    });
    _runParticleLoop();
  }

  void _handleCorrectClick(String objectId, Offset position) {
    if (_isCompleted || _isPaused) return;

    final appState = Provider.of<AppState>(context, listen: false);
    GameFeedbackService.instance.hapticCorrect();
    GameFeedbackService.instance.speakCorrect(
      appState.language,
      voiceEnabled: appState.voiceInstructions,
    );

    _recordEvent(GameplayEventType.tapCorrect, objectId, position);
    _triggerSparkBurst(position);

    // Switch between specific levels progress:
    if (widget.missionId == 'dark_room') {
      setState(() {
        _isLit = true;
        _isCompleted = true;
      });
      _lightAnimController.forward().then((_) {
        if (mounted) {
          _handleLevelCompleted();
        }
      });
    } else if (widget.missionId == 'robot_room') {
      if (objectId == 'battery' && !_batterySelected) {
        setState(() {
          _batterySelected = true;
        });
      } else if (objectId == 'cable' && _batterySelected) {
        setState(() {
          _isPowered = true;
          _isCompleted = true;
        });
        _handleLevelCompleted();
      }
    } else if (widget.missionId == 'door_room') {
      if (objectId == 'box' && !_boxOpened) {
        setState(() {
          _boxOpened = true;
          _keyFound = true;
        });
      } else if (objectId == 'key' && _keyFound && !_keySelected) {
        setState(() {
          _keySelected = true;
        });
      } else if (objectId == 'door' && _keySelected) {
        setState(() {
          _doorOpened = true;
          _isCompleted = true;
        });
        _doorAnimController.forward().then((_) {
          if (mounted) {
            _handleLevelCompleted();
          }
        });
      }
    } else if (widget.missionId == 'garden_room') {
      if (objectId == 'watering_can' && !_wateringCanSelected) {
        setState(() => _wateringCanSelected = true);
      } else if (objectId == 'garden_tap' &&
          _wateringCanSelected &&
          !_wateringCanFilled) {
        setState(() => _wateringCanFilled = true);
      } else if (objectId == 'flower' && _wateringCanFilled) {
        setState(() {
          _plantWatered = true;
          _isCompleted = true;
        });
        _handleLevelCompleted();
      }
    } else if (widget.missionId == 'memory_vault') {
      setState(() => _memoryStep++);
      if (_memoryStep >= _memorySequence.length) {
        setState(() => _isCompleted = true);
        _handleLevelCompleted();
      }
    }
  }

  void _handleMemoryTap(String objectId, Offset position) {
    if (_isCompleted || _isPaused) return;
    final expected = _memorySequence[_memoryStep];
    if (objectId == expected) {
      _handleCorrectClick(objectId, position);
      return;
    }
    _handleWrongTap(objectId, position, isDistractor: false);
    setState(() => _memoryStep = 0);
  }

  void _handleLampFailure(Offset position) {
    if (_isCompleted || _isPaused || _resultSubmitted) return;

    _recordEvent(GameplayEventType.tapWrong, 'lamp', position);
    _timerController.stop();

    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _isCompleted = true;
      _failureNoticeText = AppLocalizations.get(
        'lamp_failure_message',
        appState.language,
      );
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _handleLevelFailed(completionTimeSeconds: _elapsedSeconds);
      }
    });
  }

  Future<void> _handleLevelCompleted() async {
    if (_resultSubmitted) return;
    _resultSubmitted = true;
    _timerController.stop();

    // Star calculation rules based on time, hints, and clicks:
    int stars = 3;
    if (_wrongClicks + _distractorClicks > 4 || _hintsUsed > 0) {
      stars = 2;
    }
    if (_wrongClicks + _distractorClicks > 8 || _timerController.value > 0.8) {
      stars = 1;
    }

    // Gems reward
    int gems = 1;
    if (stars == 3) gems = 2; // bonus for flawless

    final appState = Provider.of<AppState>(context, listen: false);

    final result = SessionResult(
      id: '${widget.missionId}_${DateTime.now().millisecondsSinceEpoch}',
      childId: appState.selectedProfile!.id,
      missionId: widget.missionId,
      timestamp: DateTime.now(),
      difficultyLevel: _difficulty.difficultyLevel,
      completionTimeSeconds:
          DateTime.now().difference(_startTime).inMilliseconds / 1000.0,
      starsEarned: stars,
      gemsEarned: gems,
      totalClicks: _events.where((event) => event.isTap).length,
      wrongClicks: _wrongClicks,
      distractorClicks: _distractorClicks,
      hintsUsed: _hintsUsed,
      reactionTimeMs: _firstActionTimeMs ?? 0.0,
      events: _events,
    );

    // Save result to store and update AI adaptation
    await appState.submitSession(result);

    GameFeedbackService.instance.speakMissionComplete(
      appState.language,
      voiceEnabled: appState.voiceInstructions,
    );

    // Proceed to Results screen
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResultsScreen(session: result)),
        );
      }
    });
  }

  Future<void> _handleLevelFailed({double? completionTimeSeconds}) async {
    if (_resultSubmitted) return;
    _resultSubmitted = true;
    _timerController.stop();

    if (!_isCompleted) {
      setState(() => _isCompleted = true);
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final result = SessionResult(
      id: '${widget.missionId}_failed_${DateTime.now().millisecondsSinceEpoch}',
      childId: appState.selectedProfile!.id,
      missionId: widget.missionId,
      timestamp: DateTime.now(),
      difficultyLevel: _difficulty.difficultyLevel,
      completionTimeSeconds:
          completionTimeSeconds ?? _difficulty.timeLimitSeconds.toDouble(),
      starsEarned: 0,
      gemsEarned: 0,
      totalClicks: _events.where((event) => event.isTap).length,
      wrongClicks: _wrongClicks,
      distractorClicks: _distractorClicks,
      hintsUsed: _hintsUsed,
      reactionTimeMs: _firstActionTimeMs ?? 0.0,
      events: _events,
    );

    await appState.submitSession(result);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultsScreen(session: result)),
      );
    }
  }

  void _showPauseOverlay() {
    if (!_interactionReady) return;
    setState(() {
      _isPaused = true;
    });
    _timerController.stop();
  }

  void _resumeLevel() {
    setState(() {
      _isPaused = false;
    });
    _timerController.forward();
  }

  List<Widget> _buildFloatingLabels() {
    final now = DateTime.now();
    return _floatingFeedbacks.map((f) {
      final age = now.difference(f.created).inMilliseconds;
      final t = (age / 1200).clamp(0.0, 1.0);
      final opacity = 1.0 - t;
      final dy = -40.0 * t;
      return Positioned(
        left: f.position.dx - 60,
        top: f.position.dy + dy - 20,
        child: Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: f.color.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              f.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;

    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      body: SafeArea(
        child: Directionality(
          textDirection: AppLocalizations.getDirection(lang),
          child: Stack(
            children: [
              // Main Level Board Graphic Area
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: !_interactionReady,
                  child: _buildActiveLevelLayout(context),
                ),
              ),

              // Particles + floating wrong-tap labels
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: LevelSparkPainter(_particles),
                        size: Size.infinite,
                      ),
                      ..._buildFloatingLabels(),
                    ],
                  ),
                ),
              ),

              // Red flash on wrong tap
              if (_screenFlash > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: AppColors.accentRed.withValues(
                        alpha: 0.18 * _screenFlash,
                      ),
                    ),
                  ),
                ),

              // Top HUD HUD bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopHUDBar(context, lang),
              ),

              // Floating Goal Indicator Text
              Positioned(
                top: 70,
                left: 20,
                right: 20,
                child: _buildGoalText(lang),
              ),

              if (!_interactionReady)
                Positioned(
                  top: 128,
                  left: 24,
                  right: 24,
                  child: _buildLookFirstCard(lang),
                ),

              // Glowing Hint popups
              if (_hintActive)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: _buildHintCard(lang),
                ),

              if (_failureNoticeText != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(child: _buildFailureNotice(lang)),
                  ),
                ),

              // Custom Game Paused Modal
              if (_isPaused) Positioned.fill(child: _buildPausedOverlay(lang)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHUDBar(BuildContext context, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.pause_rounded,
              color: AppColors.textPrimary,
              size: 28,
            ),
            onPressed: _showPauseOverlay,
          ),

          // Central Timer bar countdown (Gentle progress)
          if (_difficulty.showTimerBar)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) {
                    double progress = 1.0 - _timerController.value;
                    final remainingSeconds =
                        (_difficulty.timeLimitSeconds * progress).ceil();
                    Color barColor = progress > 0.4
                        ? AppColors.secondary
                        : (progress > 0.15
                              ? AppColors.accentYellow
                              : AppColors.accentRed);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primary,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${AppLocalizations.get('level', lang)} ${_difficulty.difficultyLevel}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.timer_outlined,
                              color: barColor,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${remainingSeconds}s',
                              style: TextStyle(
                                color: barColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // Hint Lightbulb trigger
          IconButton(
            icon: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Icon(
                  Icons.lightbulb,
                  size: 28,
                  color: _hintActive
                      ? AppColors.accentYellow
                      : AppColors.textMuted.withValues(
                          alpha: 0.5 + (_pulseController.value * 0.3),
                        ),
                );
              },
            ),
            onPressed: !_interactionReady
                ? null
                : () {
                    if (!_hintActive) {
                      _recordEvent(
                        GameplayEventType.hintUsed,
                        'hint_button',
                        Offset.zero,
                      );
                      _triggerAutoHint();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalText(String lang) {
    String goalText = AppLocalizations.get('${widget.missionId}_goal', lang);
    return Center(
      child: GlassmorphicContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 16,
        color: Colors.white.withValues(alpha: 0.9),
        borderColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          goalText,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLookFirstCard(String lang) {
    return Center(
      child: GlassmorphicContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 16,
        color: AppColors.accentPurple.withValues(alpha: 0.9),
        borderColor: Colors.white.withValues(alpha: 0.35),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppLocalizations.get('look_first', lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintCard(String lang) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.95),
      borderColor: AppColors.accentYellow.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.accentYellow,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hintText,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textMuted, size: 20),
            onPressed: () {
              setState(() {
                _hintActive = false;
                if (widget.missionId == 'memory_vault') {
                  _memorySequenceVisible = false;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFailureNotice(String lang) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 22,
        color: AppColors.accentRed.withValues(alpha: 0.94),
        borderColor: Colors.white.withValues(alpha: 0.45),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 34,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.get('failure_title', lang),
                    style: AppTextStyles.displaySmall(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _failureNoticeText ?? '',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedOverlay(String lang) {
    return Container(
      color: AppColors.textPrimary.withValues(alpha: 0.4),
      child: Center(
        child: GlassmorphicContainer(
          width: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.get('game_paused', lang),
                style: AppTextStyles.displayMedium(context),
              ),
              const SizedBox(height: 24),

              // Resume
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _resumeLevel,
                child: Text(
                  AppLocalizations.get('resume', lang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Restart
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          PuzzleGameScreen(missionId: widget.missionId),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.get('restart', lang),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),

              // Back to map
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  AppLocalizations.get('back_to_map', lang),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Building individual level boards
  Widget _buildActiveLevelLayout(BuildContext context) {
    int maxDistractors = _difficulty.maxDistractors;
    final reduceMotion = Provider.of<AppState>(context).reduceMotion;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Level background (animated)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([_lightAnim, _doorAnim]),
            builder: (context, _) => _buildLevelBackground(),
          ),
        ),

        // Empty-space taps (behind objects so interactive items win)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (d) {
              _handleWrongTap(
                'empty_space',
                d.globalPosition,
                isDistractor: false,
              );
            },
            child: const SizedBox.expand(),
          ),
        ),

        // Distractors below interactive objects
        if (maxDistractors > 0 && !reduceMotion)
          Positioned.fill(child: _buildDistractorOverlay(maxDistractors)),

        // Additional wrong objects are generated from the agent's object-count
        // decision, so higher difficulty changes the playable scene itself.
        Positioned.fill(child: _buildExtraWrongObjectOverlay(maxDistractors)),

        // Interactive puzzle objects on top — always receive taps first
        Positioned.fill(child: _buildInteractiveGameplayElements()),
      ],
    );
  }

  Widget _buildExtraWrongObjectOverlay(int distractorCount) {
    final baseObjectCount = widget.missionId == 'robot_room' ? 3 : 4;
    final requestedCount =
        _difficulty.totalObjects - baseObjectCount - distractorCount;
    final extraCount = requestedCount.clamp(0, 5);
    if (extraCount == 0) return const SizedBox.shrink();

    const positions = [
      Offset(0.72, 0.27),
      Offset(0.34, 0.40),
      Offset(0.74, 0.57),
      Offset(0.32, 0.68),
      Offset(0.53, 0.50),
    ];
    const emojis = ['📘', '🍎', '🧸', '🕰️', '🌼'];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(extraCount, (index) {
            final position = positions[index];
            return Positioned(
              left: position.dx * constraints.maxWidth - 24,
              top: position.dy * constraints.maxHeight - 24,
              child: Semantics(
                button: true,
                label: 'Extra object ${index + 1}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (_isCompleted || _isPaused) return;
                      _recordEvent(
                        GameplayEventType.tapWrong,
                        'extra_wrong_$index',
                        Offset.zero,
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLevelBackground() {
    if (widget.missionId == 'dark_room') {
      return DarkRoomScene(lightLevel: _lightAnim.value, lightAnim: _lightAnim);
    } else if (widget.missionId == 'robot_room') {
      return RobotLabScene(
        isPowered: _isPowered,
        batteryConnected: _batterySelected,
        pulseAnim: _pulseController,
      );
    } else if (widget.missionId == 'door_room') {
      return DoorCorridorScene(
        boxOpened: _boxOpened,
        doorOpened: _doorOpened,
        doorAnim: _doorAnim,
      );
    } else if (widget.missionId == 'garden_room') {
      return _buildGardenBackground();
    } else {
      return _buildMemoryBackground();
    }
  }

  Widget _buildGardenBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE7FFF5), Color(0xFFFFF4D8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 110,
            left: 24,
            right: 24,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.42),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(120),
                ),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.28),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFBDE7A7), Color(0xFF7BC47F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 140,
            right: 38,
            child: Icon(
              Icons.wb_sunny_rounded,
              color: AppColors.accentYellow.withValues(alpha: 0.75),
              size: 52,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF191638), Color(0xFF30255F), Color(0xFF15142D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return CustomPaint(
            painter: _MemoryGridPainter(_pulseController.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildInteractiveGameplayElements() {
    if (widget.missionId == 'dark_room') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Lamp with realistic glow
              Positioned(
                top: h * 0.06,
                left: w * 0.5 - 50,
                child: Semantics(
                  button: true,
                  label: 'Lamp',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleLampFailure(Offset.zero),
                    child: RoomLamp(isLit: _isLit, glowAnim: _lightAnim),
                  ),
                ),
              ),

              // Lighter (wrong)
              Positioned(
                left: w * 0.08,
                bottom: h * 0.18,
                child: _buildTappableObject(
                  id: 'lighter',
                  emoji: '🔥',
                  label: 'Lighter',
                  isWrongChoice: true,
                  onTap: (pos) =>
                      _handleWrongTap('lighter', pos, isDistractor: false),
                ),
              ),

              // Sun (wrong)
              Positioned(
                left: w * 0.12,
                top: h * 0.28,
                child: _buildTappableObject(
                  id: 'sun_icon',
                  emoji: '☀️',
                  label: 'Sun',
                  isWrongChoice: true,
                  onTap: (pos) =>
                      _handleWrongTap('sun_icon', pos, isDistractor: false),
                ),
              ),

              // Switch (CORRECT) — centered lower area, large target
              Positioned(
                left: w * 0.55,
                bottom: h * 0.22,
                child: _buildTappableObject(
                  id: 'switch',
                  emoji: '🔌',
                  label: 'Switch',
                  isGlowing: !_isLit,
                  glowColor: _isLit ? AppColors.accentGreen : AppColors.primary,
                  onTap: (pos) => _handleCorrectClick('switch', pos),
                ),
              ),
            ],
          );
        },
      );
    } else if (widget.missionId == 'robot_room') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 80,
                left: w * 0.5 - 80,
                child: LabRobot(isPowered: _isPowered),
              ),
              Positioned(
                bottom: 120,
                left: 40,
                child: _buildTappableObject(
                  id: 'battery',
                  emoji: '🔋',
                  label: 'Battery',
                  isGlowing: !_batterySelected,
                  glowColor: _batterySelected
                      ? AppColors.accentGreen
                      : AppColors.secondary,
                  onTap: (pos) => _handleCorrectClick('battery', pos),
                ),
              ),
              Positioned(
                bottom: 120,
                right: 40,
                child: _buildTappableObject(
                  id: 'cable',
                  emoji: '🔌',
                  label: 'Cable',
                  isGlowing: _batterySelected && !_isPowered,
                  glowColor: AppColors.accentPurple,
                  onTap: (pos) {
                    if (_batterySelected) {
                      _handleCorrectClick('cable', pos);
                    } else {
                      _handleWrongTap('cable_early', pos, isDistractor: false);
                    }
                  },
                ),
              ),
              Positioned(
                bottom: 220,
                left: w * 0.4,
                child: _buildTappableObject(
                  id: 'wrench',
                  emoji: '🔧',
                  label: 'Wrench',
                  isWrongChoice: true,
                  onTap: (pos) =>
                      _handleWrongTap('wrench', pos, isDistractor: false),
                ),
              ),
            ],
          );
        },
      );
    } else if (widget.missionId == 'door_room') {
      // Door Room — scene handles door/box visuals; only interactive items here
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Invisible door tap zone (matches scene door position)
              Positioned(
                top: h * 0.18,
                left: w * 0.5 - 60,
                width: 120,
                height: 160,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTapDown: (d) {
                      if (_isCompleted || _isPaused) return;
                      if (_keySelected) {
                        _handleCorrectClick('door', d.globalPosition);
                      } else {
                        _handleWrongTap(
                          'door_locked',
                          d.globalPosition,
                          isDistractor: false,
                        );
                      }
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              if (!_boxOpened)
                Positioned(
                  bottom: h * 0.14,
                  left: w * 0.1,
                  child: _buildTappableObject(
                    id: 'box',
                    emoji: '📦',
                    label: 'Box',
                    isGlowing: true,
                    glowColor: AppColors.accentYellow,
                    onTap: (pos) => _handleCorrectClick('box', pos),
                  ),
                ),

              if (_boxOpened && !_keySelected)
                Positioned(
                  bottom: h * 0.16,
                  left: w * 0.12,
                  child: _buildTappableObject(
                    id: 'key',
                    emoji: '🔑',
                    label: 'Key',
                    isGlowing: true,
                    glowColor: AppColors.secondary,
                    onTap: (pos) => _handleCorrectClick('key', pos),
                  ),
                ),

              Positioned(
                bottom: h * 0.14,
                right: w * 0.1,
                child: _buildTappableObject(
                  id: 'hammer',
                  emoji: '🔨',
                  label: 'Hammer',
                  isWrongChoice: true,
                  onTap: (pos) =>
                      _handleWrongTap('hammer', pos, isDistractor: false),
                ),
              ),
            ],
          );
        },
      );
    } else if (widget.missionId == 'garden_room') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: h * 0.19,
                left: w * 0.5 - 44,
                child: _buildTappableObject(
                  id: 'flower',
                  emoji: _plantWatered ? '🌻' : '🥀',
                  label: 'Flower',
                  isGlowing: _wateringCanFilled && !_plantWatered,
                  glowColor: AppColors.accentGreen,
                  onTap: (pos) {
                    if (_wateringCanFilled) {
                      _handleCorrectClick('flower', pos);
                    } else {
                      _handleWrongTap('flower_early', pos, isDistractor: false);
                    }
                  },
                ),
              ),
              Positioned(
                bottom: h * 0.14,
                left: w * 0.10,
                child: _buildTappableObject(
                  id: 'watering_can',
                  emoji: _wateringCanFilled ? '💧' : '🪣',
                  label: 'Watering can',
                  isGlowing: !_wateringCanSelected,
                  glowColor: AppColors.secondary,
                  onTap: (pos) {
                    if (!_wateringCanSelected) {
                      _handleCorrectClick('watering_can', pos);
                    } else {
                      _handleWrongTap(
                        'watering_can_again',
                        pos,
                        isDistractor: false,
                      );
                    }
                  },
                ),
              ),
              Positioned(
                bottom: h * 0.14,
                right: w * 0.10,
                child: _buildTappableObject(
                  id: 'garden_tap',
                  emoji: '🚰',
                  label: 'Water tap',
                  isGlowing: _wateringCanSelected && !_wateringCanFilled,
                  glowColor: AppColors.accentSky,
                  onTap: (pos) {
                    if (_wateringCanSelected && !_wateringCanFilled) {
                      _handleCorrectClick('garden_tap', pos);
                    } else {
                      _handleWrongTap(
                        'garden_tap_early',
                        pos,
                        isDistractor: false,
                      );
                    }
                  },
                ),
              ),
              Positioned(
                bottom: h * 0.31,
                left: w * 0.5 - 36,
                child: _buildTappableObject(
                  id: 'garden_shovel',
                  emoji: '🪏',
                  label: 'Shovel',
                  isWrongChoice: true,
                  onTap: (pos) => _handleWrongTap(
                    'garden_shovel',
                    pos,
                    isDistractor: false,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          const ids = ['moon', 'star', 'gem', 'planet'];
          const emojis = ['🌙', '⭐', '💎', '🪐'];
          final positions = [
            Offset(w * 0.20, h * 0.42),
            Offset(w * 0.64, h * 0.42),
            Offset(w * 0.20, h * 0.67),
            Offset(w * 0.64, h * 0.67),
          ];
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: h * 0.17,
                left: 30,
                right: 30,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: 1,
                  child: GlassmorphicContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    borderRadius: 18,
                    color: const Color(0xFF25214F).withValues(alpha: 0.88),
                    borderColor: AppColors.accentPurple.withValues(alpha: 0.5),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey(_memorySequenceVisible),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _memorySequence
                            .map(
                              (id) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                child: Text(
                                  _memorySequenceVisible
                                      ? emojis[ids.indexOf(id)]
                                      : '•',
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: _memorySequenceVisible ? 1 : 0.5,
                                    ),
                                    fontSize: _memorySequenceVisible ? 27 : 34,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
              for (int index = 0; index < _memorySequence.length; index++)
                Positioned(
                  left: positions[index].dx,
                  top: positions[index].dy,
                  child: _buildTappableObject(
                    id: ids[index],
                    emoji: emojis[index],
                    label: ids[index],
                    isGlowing:
                        _memorySequenceVisible &&
                        _memoryStep < _memorySequence.length &&
                        _memorySequence[_memoryStep] == ids[index],
                    glowColor: AppColors.accentPurple,
                    onTap: (pos) => _handleMemoryTap(ids[index], pos),
                  ),
                ),
              Positioned(
                bottom: 42,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_memorySequence.length, (index) {
                    final completed = index < _memoryStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: completed ? 24 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: completed
                            ? AppColors.secondary
                            : Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  // Tappable game object widget builder
  Widget _buildTappableObject({
    required String id,
    required String emoji,
    required void Function(Offset globalPos) onTap,
    String? label,
    bool isGlowing = false,
    Color glowColor = AppColors.primary,
    bool isWrongChoice = false,
  }) {
    Offset? tapPos;
    final reduceMotion = Provider.of<AppState>(context).reduceMotion;

    return Semantics(
      button: true,
      label: label ?? id,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTapDown: (d) => tapPos = d.globalPosition,
          onTap: () {
            if (_isCompleted || _isPaused) return;
            final size = MediaQuery.of(context).size;
            final pos = tapPos ?? Offset(size.width * 0.5, size.height * 0.5);
            onTap(pos);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseController,
              _shakeController,
              _itemBobController,
            ]),
            builder: (context, child) {
              double pulse = isGlowing ? _pulseController.value * 6.0 : 0.0;
              double shakeX = 0;
              double bobX = 0;
              double bobY = 0;
              if (_shakingObjectId == id) {
                shakeX = math.sin(_shakeController.value * math.pi * 10) * 12;
              }
              if (!reduceMotion) {
                final phase = (id.hashCode % 360) * math.pi / 180;
                final bobT = _itemBobController.value * math.pi * 2;
                bobX = math.sin(bobT + phase) * 10;
                bobY = math.cos(bobT + phase * 1.4) * 8;
              }
              final showWrongGlow =
                  _shakingObjectId == id && _shakeController.isAnimating;

              return Transform.translate(
                offset: Offset(shakeX + bobX, bobY),
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: showWrongGlow
                        ? AppColors.accentRed.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: showWrongGlow
                          ? AppColors.accentRed
                          : (isGlowing
                                ? glowColor.withValues(alpha: 0.6)
                                : isWrongChoice
                                ? AppColors.textMuted.withValues(alpha: 0.25)
                                : AppColors.primary.withValues(alpha: 0.15)),
                      width: showWrongGlow ? 3 : 2,
                    ),
                    boxShadow: [
                      if (isGlowing)
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.35),
                          blurRadius: 12 + pulse,
                          spreadRadius: 2,
                        ),
                      if (showWrongGlow)
                        BoxShadow(
                          color: AppColors.accentRed.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                    ],
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 36)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Distractor UI builder overlay
  Widget _buildDistractorOverlay(int count) {
    // Positions of distractors
    final positions = [
      const Offset(0.2, 0.45),
      const Offset(0.75, 0.4),
      const Offset(0.5, 0.65),
      const Offset(0.15, 0.75),
      const Offset(0.8, 0.7),
    ];

    List<Widget> activeDistractors = [];

    for (int i = 0; i < count; i++) {
      if (i >= positions.length) break;
      final pos = positions[i];

      Widget distWidget;
      if (i == 0) {
        // Blinking Star with gentle drift
        distWidget = AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _distractorMotionController,
          ]),
          builder: (context, child) {
            final driftX =
                math.sin(
                  _distractorMotionController.value * math.pi * 2 + 0.5,
                ) *
                18;
            final driftY =
                math.cos(_distractorMotionController.value * math.pi * 2) * 12;
            return Opacity(
              opacity: 0.2 + (_pulseController.value * 0.8),
              child: Transform.translate(
                offset: Offset(driftX, driftY),
                child: child,
              ),
            );
          },
          child: const Text('⭐', style: TextStyle(fontSize: 40)),
        );
      } else if (i == 1) {
        // Floating Red Balloon
        distWidget = AnimatedBuilder(
          animation: _distractorMotionController,
          builder: (context, child) {
            double offsetY = _distractorMotionController.value * 40.0;
            double offsetX =
                math.sin(_distractorMotionController.value * math.pi * 2) * 14;
            return Transform.translate(
              offset: Offset(offsetX, -offsetY),
              child: child,
            );
          },
          child: const Text('🎈', style: TextStyle(fontSize: 44)),
        );
      } else if (i == 2) {
        // Spin Gear with bobbing
        distWidget = AnimatedBuilder(
          animation: _distractorMotionController,
          builder: (context, child) {
            final bobY =
                math.sin(_distractorMotionController.value * math.pi * 2) * 10;
            return Transform.translate(
              offset: Offset(0, bobY),
              child: Transform.rotate(
                angle: _distractorMotionController.value * 2 * math.pi,
                child: child,
              ),
            );
          },
          child: const Text('⚙️', style: TextStyle(fontSize: 38)),
        );
      } else if (i == 3) {
        // Bouncing Ball
        distWidget = AnimatedBuilder(
          animation: _distractorMotionController,
          builder: (context, child) {
            double offsetY =
                math.sin(_distractorMotionController.value * math.pi) * 50.0;
            double offsetX =
                math.cos(_distractorMotionController.value * math.pi * 2) * 16;
            return Transform.translate(
              offset: Offset(offsetX, -offsetY),
              child: child,
            );
          },
          child: const Text('⚽', style: TextStyle(fontSize: 34)),
        );
      } else {
        // Blinking Diamond with floating motion
        distWidget = AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _distractorMotionController,
          ]),
          builder: (context, child) {
            final driftX =
                math.sin(
                  _distractorMotionController.value * math.pi * 2 + 1.2,
                ) *
                16;
            final driftY =
                math.cos(
                  _distractorMotionController.value * math.pi * 2 + 0.8,
                ) *
                14;
            return Transform.translate(
              offset: Offset(driftX, driftY),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(
                        alpha: 0.3 * _pulseController.value,
                      ),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: const Text('💎', style: TextStyle(fontSize: 32)),
        );
      }

      activeDistractors.add(
        Positioned(
          left: pos.dx * MediaQuery.of(context).size.width,
          top: pos.dy * MediaQuery.of(context).size.height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTapDown: (d) {
                _handleWrongTap(
                  'distractor_$i',
                  d.globalPosition,
                  isDistractor: true,
                );
              },
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(child: distWidget),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: activeDistractors);
  }
}

class _MemoryGridPainter extends CustomPainter {
  final double pulse;

  const _MemoryGridPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.accentPurple.withValues(alpha: 0.07 + pulse * 0.04)
      ..strokeWidth = 1;
    const spacing = 38.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.08 + pulse * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      90 + pulse * 18,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MemoryGridPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

// Particle representation
class LevelParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double radius;
  double opacity;

  LevelParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
    required this.opacity,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.1; // gravity
    opacity -= 0.02;
  }
}

class LevelSparkPainter extends CustomPainter {
  final List<LevelParticle> particles;
  LevelSparkPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      if (p.opacity > 0) {
        paint.color = p.color.withValues(alpha: p.opacity);
        canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
