import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'state.dart';
import 'theme.dart';
import 'screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MindSparkQuestApp(),
    ),
  );
}

class MindSparkQuestApp extends StatelessWidget {
  const MindSparkQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    double textScale = appState.largerText ? 1.25 : 1.0;

    return MaterialApp(
      title: 'MindSpark Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        textTheme: GoogleFonts.nunitoTextTheme(
          ThemeData.light().textTheme.apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundSurface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.backgroundSurface,
          onSurface: AppColors.textPrimary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.secondary;
            return AppColors.textMuted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.secondary.withValues(alpha: 0.5);
            }
            return AppColors.textMuted.withValues(alpha: 0.3);
          }),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.secondary,
          thumbColor: AppColors.secondary,
          inactiveTrackColor: AppColors.textMuted.withValues(alpha: 0.3),
          overlayColor: AppColors.secondary.withValues(alpha: 0.2),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundSurface,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.textMuted,
        ),
      ),
      builder: (context, child) {
        final isRtl = appState.language == 'ar';
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
