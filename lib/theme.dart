import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft, lively light palette — warm cream base with playful pastels.
class AppColors {
  static const Color background = Color(0xFFFFFBF7);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundSurface = Color(0xFFFFF5EE);

  static const Color primary = Color(0xFF7C6CF0);
  static const Color primaryLight = Color(0xFFA99BF5);
  static const Color secondary = Color(0xFF5ECFC3);
  static const Color secondaryLight = Color(0xFF8DE4DB);

  static const Color accentPurple = Color(0xFFB388FF);
  static const Color accentGreen = Color(0xFF6BCB9A);
  static const Color accentYellow = Color(0xFFFFD166);
  static const Color accentRed = Color(0xFFFF8A7A);
  static const Color accentPink = Color(0xFFFF9EC4);
  static const Color accentSky = Color(0xFF87CEEB);
  static const Color accentPeach = Color(0xFFFFBE98);

  static const Color textPrimary = Color(0xFF3D3D5C);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textMuted = Color(0xFFA0A0B8);

  static const Color roomWall = Color(0xFFF5EDE4);
  static const Color roomFloor = Color(0xFFE8D5C4);
  static const Color roomShadow = Color(0x1A3D3D5C);

  static const Color glowColor = Color(0x337C6CF0);
  static const Color successGlow = Color(0x336BCB9A);
  static const Color warningGlow = Color(0x33FFD166);
  static const Color errorGlow = Color(0x33FF8A7A);
}

class AppTextStyles {
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle displayMedium(BuildContext context) => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle displaySmall(BuildContext context) => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static TextStyle button(BuildContext context) => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.8,
  );

  static const String fontDisplay = 'Outfit';
  static const String fontBody = 'Nunito';
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondary = LinearGradient(
    colors: [AppColors.secondary, AppColors.secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.accentPurple, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient background = LinearGradient(
    colors: [Color(0xFFFFFBF7), Color(0xFFFFF0E8), Color(0xFFE8F4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sky = LinearGradient(
    colors: [Color(0xFFE8F4FF), Color(0xFFFFF5EE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient warmRoom = LinearGradient(
    colors: [Color(0xFFFFF8E7), Color(0xFFFFE8CC), Color(0xFFFFD699)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkRoom = LinearGradient(
    colors: [Color(0xFF2A2840), Color(0xFF1A1830), Color(0xFF0F0E18)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient error = LinearGradient(
    colors: [AppColors.accentRed, Color(0xFFFFB4A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [AppColors.accentGreen, Color(0xFF9AE6C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFF7C6CF0), Color(0xFFB388FF), Color(0xFF5ECFC3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 12.0,
    this.color,
    this.borderColor,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Colors.white.withValues(alpha: 0.85);
    final border = borderColor ?? AppColors.primary.withValues(alpha: 0.12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlowButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const GlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.colors = const [AppColors.primary, AppColors.accentPurple],
    this.icon,
    this.height = 54,
    this.borderRadius = 16,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(colors: widget.colors),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
