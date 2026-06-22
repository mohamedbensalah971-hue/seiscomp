import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../localization.dart';
import 'onboarding.dart';
import 'profile_select.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = List.generate(40, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.init();

    // Let splash play for 2.5 seconds to show transition
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      if (appState.parentPin == null) {
        // First launch, configure PIN and parent settings
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        // Go straight to Profile Selector
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Stack(
          children: [
            // Ambient particle painter
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                for (var p in _particles) {
                  p.update();
                }
                return CustomPaint(
                  painter: ParticlePainter(_particles),
                  child: Container(),
                );
              },
            ),

            // Background soft glowing lights
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 100,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      blurRadius: 90,
                    ),
                  ],
                ),
              ),
            ),

            // Central content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Magical Glowing brain icon representation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutBack,
                    builder: (context, val, child) {
                      return Transform.scale(scale: val, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.backgroundCard,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons
                            .wb_incandescent_outlined, // clean magical bulb representation
                        size: 72,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Title
                  Text(
                    AppLocalizations.get('app_title', lang),
                    style: AppTextStyles.displayLarge(context).copyWith(
                      shadows: [
                        const Shadow(
                          color: AppColors.primary,
                          blurRadius: 15,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // App Subtitle
                  Text(
                    AppLocalizations.get('splash_subtitle', lang),
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 64),

                  // Sparkly loading bar indicator
                  SizedBox(
                    width: 140,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                      ),
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
}

class Particle {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double speed = 0.0005 + Random().nextDouble() * 0.001;
  double radius = 1.0 + Random().nextDouble() * 3.0;
  double opacity = 0.1 + Random().nextDouble() * 0.6;
  final double angle = Random().nextDouble() * 2 * pi;

  void update() {
    x += cos(angle) * speed;
    y += sin(angle) * speed;

    if (x < 0 || x > 1 || y < 0 || y > 1) {
      x = Random().nextDouble();
      y = Random().nextDouble();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = AppColors.primaryLight.withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
