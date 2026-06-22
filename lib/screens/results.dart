import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../models.dart';
import '../localization.dart';
import 'puzzle_game.dart';
import 'world_map.dart';

class ResultsScreen extends StatefulWidget {
  final SessionResult session;
  const ResultsScreen({super.key, required this.session});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final List<ConfettiParticle> _confetti = List.generate(
    80,
    (index) => ConfettiParticle(),
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final res = widget.session;
    final bool isCompleted = res.starsEarned > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Deep dark gradient backdrop
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.background),
          ),

          // Confetti on success
          if (isCompleted)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                for (var c in _confetti) {
                  c.update();
                }
                return CustomPaint(
                  size: Size.infinite,
                  painter: ConfettiPainter(_confetti),
                  child: Container(),
                );
              },
            ),

          SafeArea(
            child: Directionality(
              textDirection: AppLocalizations.getDirection(lang),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // --- Header ---
                      Text(
                        isCompleted
                            ? AppLocalizations.get('mission_complete', lang)
                            : AppLocalizations.get('keep_trying', lang),
                        style: AppTextStyles.displayLarge(context).copyWith(
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          shadows: isCompleted
                              ? [
                                  Shadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // --- Stars Card ---
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: GlassmorphicContainer(
                          padding: const EdgeInsets.all(24),
                          borderColor: isCompleted
                              ? AppColors.accentYellow.withValues(alpha: 0.4)
                              : AppColors.textMuted.withValues(alpha: 0.2),
                          color: isCompleted
                              ? AppColors.accentYellow.withValues(alpha: 0.06)
                              : AppColors.backgroundCard.withValues(alpha: 0.6),
                          child: Column(
                            children: [
                              // Stars row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (idx) {
                                  final bool isFilled = idx < res.starsEarned;
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0.0,
                                      end: isFilled ? 1.0 : 0.0,
                                    ),
                                    duration: Duration(
                                      milliseconds: 400 + idx * 200,
                                    ),
                                    curve: Curves.elasticOut,
                                    builder: (context, val, child) {
                                      return Transform.scale(
                                        scale: val,
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      isFilled
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 70,
                                      color: isFilled
                                          ? const Color(0xFFE0A20A)
                                          : AppColors.textMuted.withValues(
                                              alpha: 0.35,
                                            ),
                                      shadows: isFilled
                                          ? [
                                              const Shadow(
                                                color: AppColors.accentYellow,
                                                blurRadius: 20,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 20),

                              // Mission name
                              Text(
                                AppLocalizations.get(
                                  '${res.missionId}_title',
                                  lang,
                                ),
                                style: AppTextStyles.displayMedium(context),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              Text(
                                isCompleted
                                    ? AppLocalizations.get(
                                        'congratulations',
                                        lang,
                                      )
                                    : AppLocalizations.get(
                                        'practice_message',
                                        lang,
                                      ),
                                style: GoogleFonts.nunito(
                                  color: isCompleted
                                      ? AppColors.accentGreen
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Divider(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Metrics
                              _buildStatRow(
                                Icons.timer_outlined,
                                AppLocalizations.get('time', lang),
                                '${res.completionTimeSeconds.round()} ${AppLocalizations.get('seconds', lang)}',
                              ),
                              _buildStatRow(
                                Icons.lightbulb_outline,
                                AppLocalizations.get('hints_used', lang),
                                '${res.hintsUsed}',
                              ),
                              _buildStatRow(
                                Icons.bolt_rounded,
                                AppLocalizations.get('reaction_time', lang),
                                '${(res.reactionTimeMs / 1000).toStringAsFixed(1)} ${AppLocalizations.get('seconds', lang)}',
                              ),
                              _buildStatRow(
                                Icons.auto_awesome_motion_rounded,
                                AppLocalizations.get('distractor_clicks', lang),
                                '${res.distractorClicks}',
                              ),
                              _buildStatRow(
                                Icons.ads_click_rounded,
                                AppLocalizations.get('accuracy', lang),
                                res.wrongClicks == 0 &&
                                        res.distractorClicks == 0
                                    ? AppLocalizations.get(
                                        'accuracy_great',
                                        lang,
                                      )
                                    : (res.wrongClicks + res.distractorClicks <
                                              4
                                          ? AppLocalizations.get(
                                              'accuracy_good',
                                              lang,
                                            )
                                          : AppLocalizations.get(
                                              'accuracy_practice',
                                              lang,
                                            )),
                              ),
                              const SizedBox(height: 16),

                              // Rewards row
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        AppColors.accentPurple.withValues(
                                          alpha: 0.1,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildRewardChip(
                                        Icons.star_rounded,
                                        '+${res.starsEarned}',
                                        AppColors.accentYellow,
                                      ),
                                      Container(
                                        width: 1,
                                        height: 32,
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                      _buildRewardChip(
                                        Icons.diamond_rounded,
                                        '+${res.gemsEarned}',
                                        AppColors.secondary,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Explainable AI decision card ---
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(16),
                        borderColor: AppColors.primary.withValues(alpha: 0.3),
                        color: AppColors.primary.withValues(alpha: 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.psychology_outlined,
                                    color: AppColors.secondary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.get(
                                          'agent_adapted',
                                          lang,
                                        ),
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        AppLocalizations.get(
                                          'decision_${appState.lastDecisionType}',
                                          lang,
                                        ),
                                        style: GoogleFonts.nunito(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              appState.lastDecisionReason,
                              style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildDecisionChip(
                                  Icons.route_rounded,
                                  AppLocalizations.get(
                                    '${appState.recommendedMissionId}_title',
                                    lang,
                                  ),
                                ),
                                _buildDecisionChip(
                                  Icons.tune_rounded,
                                  '${AppLocalizations.get('level', lang)} ${appState.currentDifficulty.difficultyLevel}',
                                ),
                                _buildDecisionChip(
                                  Icons.timer_outlined,
                                  '${appState.currentDifficulty.timeLimitSeconds} ${AppLocalizations.get('seconds', lang)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // --- Action Buttons ---
                      if (isCompleted) ...[
                        GlowButton(
                          label: AppLocalizations.get('go_to_map', lang),
                          icon: Icons.map_rounded,
                          colors: const [
                            AppColors.secondary,
                            AppColors.accentGreen,
                          ],
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const WorldMapScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
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
                                    PuzzleGameScreen(missionId: res.missionId),
                              ),
                            );
                          },
                          child: Text(
                            AppLocalizations.get('play_again', lang),
                            style: GoogleFonts.nunito(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ] else ...[
                        GlowButton(
                          label: AppLocalizations.get('try_again', lang),
                          icon: Icons.refresh_rounded,
                          colors: const [
                            AppColors.primary,
                            AppColors.accentPurple,
                          ],
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PuzzleGameScreen(missionId: res.missionId),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const WorldMapScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: Text(
                            AppLocalizations.get('back_to_map', lang),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondary, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti Particle
// ---------------------------------------------------------------------------

class ConfettiParticle {
  double x = Random().nextDouble();
  double y = -0.1 - Random().nextDouble() * 0.5;
  double speedY = 0.004 + Random().nextDouble() * 0.012;
  double speedX = -0.003 + Random().nextDouble() * 0.006;
  double size = 5.0 + Random().nextDouble() * 9.0;
  double rotation = Random().nextDouble() * 6.28;
  double rotationSpeed = (-0.05 + Random().nextDouble() * 0.1);
  Color color = AppColors.secondary;

  ConfettiParticle() {
    final colors = [
      AppColors.primary,
      AppColors.primaryLight,
      AppColors.secondary,
      AppColors.accentYellow,
      AppColors.accentPink,
      const Color(0xFFFF7675),
      AppColors.accentGreen,
    ];
    color = colors[Random().nextInt(colors.length)];
  }

  void update() {
    y += speedY;
    x += speedX;
    rotation += rotationSpeed;
    if (y > 1.1) {
      y = -0.1;
      x = Random().nextDouble();
    }
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = p.color.withValues(alpha: 0.85);
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
