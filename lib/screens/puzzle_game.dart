import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../models.dart';
import '../localization.dart';
import '../widgets/puzzle_room_scenes.dart';
import 'results.dart';

class PuzzleGameScreen extends StatefulWidget {
  final String missionId;
  const PuzzleGameScreen({super.key, required this.missionId});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> with TickerProviderStateMixin {
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
  bool _hintActive = false;
  String _hintText = "";


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

  // Animation Controllers
  late AnimationController _timerController;
  late AnimationController _distractorMotionController;
  late AnimationController _pulseController;
  late AnimationController _lightAnimController;
  late AnimationController _doorAnimController;
  late Animation<double> _lightAnim;
  late Animation<double> _doorAnim;
  
  // Custom Particle bursts
  final List<LevelParticle> _particles = [];
  Timer? _particleTimer;

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
      _difficulty = DifficultyParams(
        maxDistractors: _difficulty.maxDistractors.clamp(0, 1),
        distractorIntensity: 0.1,
        totalObjects: _difficulty.totalObjects,
        hintDelaySeconds: _difficulty.hintDelaySeconds,
        showTimerBar: _difficulty.showTimerBar,
        complexityLevel: _difficulty.complexityLevel,
      );
    }

    final motionScale = appState.reduceMotion ? 0.0 : 1.0;

    // Timer limit based on difficulty (soft timer bar count down)
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    _timerController.forward();
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCompleted) {
        // level timeout or omit
        _handleLevelFailed();
      }
    });

    // Animate moving distractors based on speed intensity from AI
    double distractorSpeed = _difficulty.distractorIntensity * motionScale;
    _distractorMotionController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: motionScale == 0
            ? 999999
            : (2000 / (distractorSpeed + 0.1)).round(),
      ),
    );
    if (motionScale > 0) {
      _distractorMotionController.repeat(reverse: true);
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

    // Auto hint check after AI specified delay
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
    });
  }

  String _getHintString() {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.language;
    return AppLocalizations.get('hint_${widget.missionId}', lang);
  }

  @override
  void dispose() {
    _timerController.dispose();
    _distractorMotionController.dispose();
    _pulseController.dispose();
    _lightAnimController.dispose();
    _doorAnimController.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }

  void _recordEvent(GameplayEventType type, String objectId, Offset pos) {
    final offset = DateTime.now().difference(_startTime).inMilliseconds.toDouble();
    _firstActionTimeMs ??= offset;

    setState(() {
      _events.add(GameplayEvent(
        type: type,
        objectId: objectId,
        timeOffsetMs: offset,
        x: pos.dx,
        y: pos.dy,
      ));

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
        _particles.add(LevelParticle(
          x: origin.dx,
          y: origin.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 2.0, // slight upward gravity
          color: random.nextBool() ? AppColors.secondary : AppColors.accentYellow,
          radius: 2.0 + random.nextDouble() * 4.0,
          opacity: 1.0,
        ));
      }
    });

    _particleTimer?.cancel();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() {
        for (var p in _particles) {
          p.update();
        }
        _particles.removeWhere((p) => p.opacity <= 0.05);
      });
      if (_particles.isEmpty) {
        timer.cancel();
      }
    });
  }

  void _handleCorrectClick(String objectId, Offset position) {
    _recordEvent(GameplayEventType.tapCorrect, objectId, position);
    _triggerSparkBurst(position);

    // Switch between specific levels progress:
    if (widget.missionId == 'dark_room') {
      setState(() => _isLit = true);
      _lightAnimController.forward().then((_) {
        if (mounted) {
          setState(() => _isCompleted = true);
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
        setState(() => _doorOpened = true);
        _doorAnimController.forward().then((_) {
          if (mounted) {
            setState(() => _isCompleted = true);
            _handleLevelCompleted();
          }
        });
      }
    }
  }

  void _handleLevelCompleted() {
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
      completionTimeSeconds: DateTime.now().difference(_startTime).inSeconds.toDouble(),
      starsEarned: stars,
      gemsEarned: gems,
      totalClicks: _events.length,
      wrongClicks: _wrongClicks,
      distractorClicks: _distractorClicks,
      hintsUsed: _hintsUsed,
      reactionTimeMs: _firstActionTimeMs ?? 0.0,
      events: _events,
    );

    // Save result to store and update AI adaptation
    appState.submitSession(result);

    // Proceed to Results screen
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(session: result),
          ),
        );
      }
    });
  }

  void _handleLevelFailed() {
    final appState = Provider.of<AppState>(context, listen: false);
    final result = SessionResult(
      id: '${widget.missionId}_failed_${DateTime.now().millisecondsSinceEpoch}',
      childId: appState.selectedProfile!.id,
      missionId: widget.missionId,
      timestamp: DateTime.now(),
      completionTimeSeconds: 40.0,
      starsEarned: 0,
      gemsEarned: 0,
      totalClicks: _events.length,
      wrongClicks: _wrongClicks,
      distractorClicks: _distractorClicks,
      hintsUsed: _hintsUsed,
      reactionTimeMs: _firstActionTimeMs ?? 0.0,
      events: _events,
    );

    appState.submitSession(result);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(session: result),
        ),
      );
    }
  }

  void _showPauseOverlay() {
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
                child: _buildActiveLevelLayout(context),
              ),

              // Particles must not intercept pointer events (web + mobile)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LevelSparkPainter(_particles),
                    size: Size.infinite,
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

              // Glowing Hint popups
              if (_hintActive)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: _buildHintCard(lang),
                ),

              // Custom Game Paused Modal
              if (_isPaused)
                Positioned.fill(
                  child: _buildPausedOverlay(lang),
                ),
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
            icon: Icon(Icons.pause_rounded, color: AppColors.textPrimary, size: 28),
            onPressed: _showPauseOverlay,
          ),

          // Central Timer bar countdown (Gentle progress)
          if (_difficulty.showTimerBar)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) {
                    double progress = 1.0 - _timerController.value;
                    Color barColor = progress > 0.4 
                        ? AppColors.secondary 
                        : (progress > 0.15 ? AppColors.accentYellow : AppColors.accentRed);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
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
                      : AppColors.textMuted.withValues(alpha: 0.5 + (_pulseController.value * 0.3)),
                );
              },
            ),
            onPressed: () {
              if (!_hintActive) {
                _recordEvent(GameplayEventType.hintUsed, 'hint_button', Offset.zero);
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

  Widget _buildHintCard(String lang) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.95),
      borderColor: AppColors.accentYellow.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.accentYellow, size: 28),
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
              });
            },
          ),
        ],
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _resumeLevel,
                child: Text(
                  AppLocalizations.get('resume', lang),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              // Restart
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PuzzleGameScreen(missionId: widget.missionId),
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
            onTap: () {
              if (!_isCompleted && !_isPaused) {
                _recordEvent(GameplayEventType.tapWrong, 'empty_space', Offset.zero);
              }
            },
            child: const SizedBox.expand(),
          ),
        ),

        // Distractors below interactive objects
        if (maxDistractors > 0 && !reduceMotion)
          Positioned.fill(
            child: _buildDistractorOverlay(maxDistractors),
          ),

        // Interactive puzzle objects on top — always receive taps first
        Positioned.fill(
          child: _buildInteractiveGameplayElements(),
        ),
      ],
    );
  }

  Widget _buildLevelBackground() {
    if (widget.missionId == 'dark_room') {
      return DarkRoomScene(
        lightLevel: _lightAnim.value,
        lightAnim: _lightAnim,
      );
    } else if (widget.missionId == 'robot_room') {
      return RobotLabScene(
        isPowered: _isPowered,
        batteryConnected: _batterySelected,
        pulseAnim: _pulseController,
      );
    } else {
      return DoorCorridorScene(
        boxOpened: _boxOpened,
        doorOpened: _doorOpened,
        doorAnim: _doorAnim,
      );
    }
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
                child: RoomLamp(isLit: _isLit, glowAnim: _lightAnim),
              ),

              // Lighter (wrong)
              Positioned(
                left: w * 0.08,
                bottom: h * 0.18,
                child: _buildTappableObject(
                  id: 'lighter',
                  emoji: '🔥',
                  label: 'Lighter',
                  onTap: (pos) => _recordEvent(GameplayEventType.tapWrong, 'lighter', pos),
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
                  onTap: (pos) => _recordEvent(GameplayEventType.tapWrong, 'sun_icon', pos),
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
                  glowColor: _batterySelected ? AppColors.accentGreen : AppColors.secondary,
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
                      _recordEvent(GameplayEventType.tapWrong, 'cable_early', pos);
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
                  onTap: (pos) => _recordEvent(GameplayEventType.tapWrong, 'wrench', pos),
                ),
              ),
            ],
          );
        },
      );
    } else {
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
                    onTap: () {
                      if (_isCompleted || _isPaused) return;
                      if (_keySelected) {
                        _handleCorrectClick('door', Offset.zero);
                      } else {
                        _recordEvent(GameplayEventType.tapWrong, 'door_locked', Offset.zero);
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
                  onTap: (pos) => _recordEvent(GameplayEventType.tapWrong, 'hammer', pos),
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
    required Function(Offset) onTap,
    String? label,
    bool isGlowing = false,
    Color glowColor = AppColors.primary,
  }) {
    return Semantics(
      button: true,
      label: label ?? id,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            if (_isCompleted || _isPaused) return;
            onTap(Offset.zero);
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              double pulse = isGlowing ? _pulseController.value * 6.0 : 0.0;
              return Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isGlowing
                        ? glowColor.withValues(alpha: 0.6)
                        : AppColors.primary.withValues(alpha: 0.15),
                    width: 2,
                  ),
                  boxShadow: isGlowing
                      ? [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.35),
                            blurRadius: 12 + pulse,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 36),
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
        // Blinking Star
        distWidget = AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Opacity(
              opacity: 0.2 + (_pulseController.value * 0.8),
              child: child,
            );
          },
          child: const Text('⭐', style: TextStyle(fontSize: 40)),
        );
      } else if (i == 1) {
        // Floating Red Balloon
        distWidget = AnimatedBuilder(
          animation: _distractorMotionController,
          builder: (context, child) {
            double offset = _distractorMotionController.value * 25.0;
            return Transform.translate(
              offset: Offset(0, -offset),
              child: child,
            );
          },
          child: const Text('🎈', style: TextStyle(fontSize: 44)),
        );
      } else if (i == 2) {
        // Spin Gear
        distWidget = AnimatedBuilder(
          animation: _distractorMotionController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _distractorMotionController.value * 2 * math.pi,
              child: child,
            );
          },
          child: const Text('⚙️', style: TextStyle(fontSize: 38)),
        );
      } else if (i == 3) {
        // Bouncing Ball
        distWidget = AnimatedBuilder(
          animation: _distractorMotionController,
          builder: (context, child) {
            double offset = math.sin(_distractorMotionController.value * math.pi) * 35.0;
            return Transform.translate(
              offset: Offset(0, -offset),
              child: child,
            );
          },
          child: const Text('⚽', style: TextStyle(fontSize: 34)),
        );
      } else {
        // Blinking Diamond
        distWidget = AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3 * _pulseController.value),
                    blurRadius: 15,
                  )
                ],
              ),
              child: child,
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
              onTap: () {
                if (_isCompleted || _isPaused) return;
                _recordEvent(
                  GameplayEventType.tapDistractor,
                  'distractor_$i',
                  Offset.zero,
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
