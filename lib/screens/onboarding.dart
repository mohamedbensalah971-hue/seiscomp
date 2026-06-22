import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../localization.dart';
import 'profile_select.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _consentChecked = false;
  String _pinCode = '';

  final List<OnboardItem> _items = [
    OnboardItem(
      titleKey: 'explore_rooms_title',
      subKey: 'explore_rooms_sub',
      icon: Icons.meeting_room_outlined,
      glowColor: AppColors.primary,
    ),
    OnboardItem(
      titleKey: 'solve_puzzles_title',
      subKey: 'solve_puzzles_sub',
      icon: Icons.extension_outlined,
      glowColor: AppColors.secondary,
    ),
    OnboardItem(
      titleKey: 'earn_rewards_title',
      subKey: 'earn_rewards_sub',
      icon: Icons.star_border_outlined,
      glowColor: AppColors.accentYellow,
    ),
  ];

  void _onNext() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPinKeyTapped(String val) {
    setState(() {
      if (val == 'delete') {
        if (_pinCode.isNotEmpty) {
          _pinCode = _pinCode.substring(0, _pinCode.length - 1);
        }
      } else {
        if (_pinCode.length < 4) {
          _pinCode += val;
        }
      }
    });
  }

  Future<void> _onCompleteSetup() async {
    if (_pinCode.length == 4 && _consentChecked) {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.setParentPin(_pinCode);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: AppLocalizations.getDirection(lang),
          child: Column(
            children: [
              // Top Bar Language Select
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<String>(
                      dropdownColor: AppColors.backgroundCard,
                      underline: Container(),
                      value: lang,
                      items: const [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(
                            '🇬🇧 English',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'fr',
                          child: Text(
                            '🇫🇷 Français',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text(
                            '🇸🇦 العربية',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) appState.setLanguage(val);
                      },
                    ),
                  ],
                ),
              ),

              // Page Slider
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: 4, // 3 onboarding slides + 1 PIN setup screen
                  itemBuilder: (context, index) {
                    if (index < 3) {
                      final item = _items[index];
                      return _buildSlide(item, lang);
                    } else {
                      return _buildParentPinScreen(lang);
                    }
                  },
                ),
              ),

              // Bottom Indicator / Actions
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _onBack,
                        child: Text(
                          AppLocalizations.get('back', lang),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),

                    // Page indicators (dots)
                    Row(
                      children: List.generate(4, (idx) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: _currentPage == idx ? 16.0 : 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: _currentPage == idx
                                ? AppColors.secondary
                                : AppColors.textMuted,
                          ),
                        );
                      }),
                    ),

                    // Next/Complete button
                    if (_currentPage < 3)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _onNext,
                        child: Text(
                          AppLocalizations.get('next', lang),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (_consentChecked && _pinCode.length == 4)
                              ? AppColors.secondary
                              : AppColors.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: (_consentChecked && _pinCode.length == 4)
                            ? _completeSetupAction
                            : null,
                        child: Text(
                          AppLocalizations.get('get_started', lang),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeSetupAction() {
    _onCompleteSetup();
  }

  Widget _buildSlide(OnboardItem item, String lang) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic container
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.glowColor.withValues(alpha: 0.1),
              border: Border.all(
                color: item.glowColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.glowColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(item.icon, size: 80, color: item.glowColor),
          ),
          const SizedBox(height: 48),

          Text(
            AppLocalizations.get(item.titleKey, lang),
            style: AppTextStyles.displayMedium(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            AppLocalizations.get(item.subKey, lang),
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParentPinScreen(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section Title
          Text(
            AppLocalizations.get('parent_setup', lang),
            style: AppTextStyles.displayMedium(context),
          ),
          const SizedBox(height: 16),

          // Privacy Card
          GlassmorphicContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.get('parent_consent_title', lang),
                      style: AppTextStyles.displaySmall(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.get('parent_consent_desc', lang),
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(
                    AppLocalizations.get('parent_consent_check', lang),
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textPrimary),
                  ),
                  activeColor: AppColors.primary,
                  checkColor: Colors.white,
                  value: _consentChecked,
                  onChanged: (val) {
                    setState(() {
                      _consentChecked = val ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PIN card
          GlassmorphicContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  AppLocalizations.get('create_pin_title', lang),
                  style: AppTextStyles.displaySmall(context),
                ),
                Text(
                  AppLocalizations.get('create_pin_subtitle', lang),
                  style: AppTextStyles.bodySmall(context),
                ),
                const SizedBox(height: 16),

                // PIN dots indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (idx) {
                    bool isFilled = _pinCode.length > idx;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isFilled
                              ? AppColors.primaryLight
                              : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Numeric keyboard
                _buildNumericKeyboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericKeyboard() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, idx) {
        String label = '';
        if (idx < 9) {
          label = '${idx + 1}';
        } else if (idx == 9) {
          label = 'C';
        } else if (idx == 10) {
          label = '0';
        } else if (idx == 11) {
          label = '⌫';
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (label == 'C') {
                setState(() => _pinCode = '');
              } else if (label == '⌫') {
                _onPinKeyTapped('delete');
              } else if (label.isNotEmpty) {
                _onPinKeyTapped(label);
              }
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardItem {
  final String titleKey;
  final String subKey;
  final IconData icon;
  final Color glowColor;

  OnboardItem({
    required this.titleKey,
    required this.subKey,
    required this.icon,
    required this.glowColor,
  });
}
