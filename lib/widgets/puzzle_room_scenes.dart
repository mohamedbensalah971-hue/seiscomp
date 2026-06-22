import 'package:flutter/material.dart';
import '../theme.dart';

/// Immersive room backgrounds with animated lighting and environment details.
class DarkRoomScene extends StatelessWidget {
  final double lightLevel; // 0.0 = dark, 1.0 = fully lit
  final Animation<double> lightAnim;

  const DarkRoomScene({
    super.key,
    required this.lightLevel,
    required this.lightAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lightAnim,
      builder: (context, _) {
        final t = lightAnim.value.clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base room (always visible structure)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFF3D3A52),
                      const Color(0xFFFFF8E7),
                      t,
                    )!,
                    Color.lerp(
                      const Color(0xFF252338),
                      const Color(0xFFFFE8CC),
                      t,
                    )!,
                    Color.lerp(
                      const Color(0xFF151320),
                      const Color(0xFFE8D5C4),
                      t,
                    )!,
                  ],
                ),
              ),
            ),

            // Moonlight through window (fades when lit)
            Opacity(
              opacity: (1.0 - t) * 0.7,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.6, -0.5),
                    radius: 0.8,
                    colors: [Color(0x334477AA), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Warm lamp glow when lit
            Opacity(
              opacity: t,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.2),
                    radius: 1.0,
                    colors: [
                      Color(0x66FFD166),
                      Color(0x33FFBE98),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Floor
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        const Color(0xFF1A1828),
                        AppColors.roomFloor,
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFF0F0E16),
                        const Color(0xFFD4C4B0),
                        t,
                      )!,
                    ],
                  ),
                ),
              ),
            ),

            // Back wall panel
            Positioned(
              top: 40,
              left: 24,
              right: 24,
              height: 180,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF2E2B42),
                    AppColors.roomWall,
                    t,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color.lerp(
                      Colors.white10,
                      AppColors.primary.withValues(alpha: 0.15),
                      t,
                    )!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1 * (1 - t)),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            // Window on wall
            Positioned(
              top: 60,
              right: 48,
              child: Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF1A2840),
                    AppColors.accentSky.withValues(alpha: 0.5),
                    t,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color.lerp(
                      Colors.white24,
                      AppColors.primary.withValues(alpha: 0.3),
                      t,
                    )!,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 1.0 - t * 0.8,
                    child: const Text('🌙', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),

            // Rug on floor
            Positioned(
              bottom: 30,
              left: 40,
              right: 40,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF3A2848),
                    AppColors.accentPeach.withValues(alpha: 0.4),
                    t,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),

            // Side table
            Positioned(
              bottom: 80,
              left: 30,
              child: _FurniturePiece(
                width: 60,
                height: 50,
                color: Color.lerp(
                  const Color(0xFF4A4038),
                  const Color(0xFFC4A882),
                  t,
                )!,
                lit: t > 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class RobotLabScene extends StatelessWidget {
  final bool isPowered;
  final bool batteryConnected;
  final Animation<double> pulseAnim;

  const RobotLabScene({
    super.key,
    required this.isPowered,
    required this.batteryConnected,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F4FF), Color(0xFFF0F4FF), Color(0xFFE0E8F5)],
            ),
          ),
        ),

        // Lab grid floor
        CustomPaint(painter: _GridFloorPainter(), size: Size.infinite),

        // Workbench
        Positioned(
          bottom: 60,
          left: 20,
          right: 20,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD4C4B0),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.roomShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),

        // Shelves with tools
        Positioned(top: 50, left: 16, child: _ShelfDecor()),

        // Battery cable line when connected
        if (batteryConnected)
          Positioned(
            bottom: 140,
            left: 80,
            child: CustomPaint(
              size: const Size(200, 40),
              painter: _CablePainter(isActive: isPowered),
            ),
          ),

        // Power indicator lights
        Positioned(
          top: 30,
          right: 24,
          child: Row(
            children: List.generate(3, (i) {
              final active = isPowered || (batteryConnected && i == 0);
              return AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, __) {
                  return Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? (isPowered
                                ? AppColors.accentGreen
                                : AppColors.accentYellow)
                          : AppColors.textMuted.withValues(alpha: 0.3),
                      boxShadow: active && isPowered
                          ? [
                              BoxShadow(
                                color: AppColors.accentGreen.withValues(
                                  alpha: 0.4 + pulseAnim.value * 0.3,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

class DoorCorridorScene extends StatelessWidget {
  final bool boxOpened;
  final bool doorOpened;
  final Animation<double> doorAnim;

  const DoorCorridorScene({
    super.key,
    required this.boxOpened,
    required this.doorOpened,
    required this.doorAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: doorAnim,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF5EE),
                    Color(0xFFF5EDE4),
                    Color(0xFFE8DDD4),
                  ],
                ),
              ),
            ),

            // Corridor perspective lines
            CustomPaint(
              painter: _CorridorPainter(doorOpen: doorAnim.value),
              size: Size.infinite,
            ),

            // Door frame
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 160,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.roomShadow,
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Door panel (swings open)
                      Transform(
                        alignment: Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(-doorAnim.value * 1.2),
                        child: Container(
                          width: 150,
                          height: 210,
                          decoration: BoxDecoration(
                            color: doorOpened
                                ? const Color(0xFF6B5344)
                                : const Color(0xFFA08060),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF5A4030),
                              width: 2,
                            ),
                          ),
                          child: doorOpened
                              ? null
                              : const Center(
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: Color(0xFFFFD166),
                                    size: 36,
                                  ),
                                ),
                        ),
                      ),

                      // Light flooding through when open
                      if (doorAnim.value > 0.1)
                        Opacity(
                          opacity: doorAnim.value,
                          child: Container(
                            width: 140,
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.accentYellow.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Wooden box
            if (!boxOpened)
              Positioned(
                bottom: 100,
                left: 40,
                child: _WoodenBox(isOpen: false),
              ),

            // Open box with key popping out
            if (boxOpened && !doorOpened)
              Positioned(
                bottom: 100,
                left: 40,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, val, child) {
                    return Transform.translate(
                      offset: Offset(0, -20 * val),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _WoodenBox(isOpen: true),
                          Positioned(
                            top: -30 * val,
                            left: 20,
                            child: Transform.scale(
                              scale: val,
                              child: const Text(
                                '🔑',
                                style: TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FurniturePiece extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final bool lit;

  const _FurniturePiece({
    required this.width,
    required this.height,
    required this.color,
    required this.lit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: lit
                ? AppColors.accentYellow.withValues(alpha: 0.2)
                : AppColors.roomShadow,
            blurRadius: lit ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _ShelfDecor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 80, height: 8, color: const Color(0xFFC4A882)),
        const SizedBox(height: 4),
        Row(
          children: const [
            Text('🧪', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('📐', style: TextStyle(fontSize: 20)),
          ],
        ),
      ],
    );
  }
}

class _WoodenBox extends StatelessWidget {
  final bool isOpen;

  const _WoodenBox({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: isOpen ? 50 : 60,
      decoration: BoxDecoration(
        color: const Color(0xFFA08060),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6B5344), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.roomShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isOpen
          ? Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 20,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D2817),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
          : const Center(child: Text('📦', style: TextStyle(fontSize: 28))),
    );
  }
}

class _GridFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(
        Offset(x, size.height * 0.6),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = size.height * 0.6; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CablePainter extends CustomPainter {
  final bool isActive;

  _CablePainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? AppColors.accentGreen : AppColors.textMuted
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CablePainter old) => old.isActive != isActive;
}

class _CorridorPainter extends CustomPainter {
  final double doorOpen;

  _CorridorPainter({required this.doorOpen});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    canvas.drawLine(Offset(cx, 300), Offset(0, size.height), paint);
    canvas.drawLine(Offset(cx, 300), Offset(size.width, size.height), paint);

    if (doorOpen > 0) {
      final glow = Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppColors.accentYellow.withValues(alpha: 0.3 * doorOpen),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCenter(center: Offset(cx, 200), width: 200, height: 200),
            );
      canvas.drawCircle(Offset(cx, 200), 80 * doorOpen, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _CorridorPainter old) =>
      old.doorOpen != doorOpen;
}

/// Animated lamp widget with realistic glow.
class RoomLamp extends StatelessWidget {
  final bool isLit;
  final Animation<double> glowAnim;

  const RoomLamp({super.key, required this.isLit, required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (context, _) {
        final glow = isLit ? glowAnim.value : 0.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lamp shade glow
            if (glow > 0)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentYellow.withValues(
                        alpha: 0.5 * glow,
                      ),
                      blurRadius: 60 * glow,
                      spreadRadius: 20 * glow,
                    ),
                  ],
                ),
              ),
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.wb_incandescent_rounded,
                  size: 100,
                  color: isLit
                      ? Color.lerp(
                          Colors.white54,
                          AppColors.accentYellow,
                          glow,
                        )!
                      : Colors.white24,
                ),
                if (isLit)
                  Icon(
                    Icons.wb_incandescent_rounded,
                    size: 100,
                    color: AppColors.accentYellow.withValues(alpha: 0.6 * glow),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 50,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF6B5344),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Animated robot with eye blink when powered.
class LabRobot extends StatefulWidget {
  final bool isPowered;

  const LabRobot({super.key, required this.isPowered});

  @override
  State<LabRobot> createState() => _LabRobotState();
}

class _LabRobotState extends State<LabRobot>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void didUpdateWidget(LabRobot old) {
    super.didUpdateWidget(old);
    if (widget.isPowered && !old.isPowered) {
      _blinkController.forward().then((_) => _blinkController.reverse());
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isPowered
                ? AppColors.accentGreen.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isPowered
                  ? AppColors.accentGreen
                  : AppColors.textMuted.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: widget.isPowered
                ? [
                    BoxShadow(
                      color: AppColors.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.smart_toy_rounded,
            size: 120,
            color: widget.isPowered
                ? AppColors.accentGreen
                : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: TextStyle(
            color: widget.isPowered
                ? AppColors.accentGreen
                : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          child: Text(
            widget.isPowered ? '🤖 Robot Online!' : '🤖 Robot Offline',
          ),
        ),
      ],
    );
  }
}
