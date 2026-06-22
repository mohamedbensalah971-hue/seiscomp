import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../localization.dart';
import 'world_map.dart';
import 'dashboard.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final List<String> _avatars = [
    'fox',
    'owl',
    'cat',
    'panda',
    'bear',
    'rabbit',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showAddProfileDialog(BuildContext context, String lang) {
    String name = '';
    String selectedAvatar = _avatars.first;
    int selectedAge = 7;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassmorphicContainer(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.get('create_profile_title', lang),
                        style: AppTextStyles.displaySmall(context),
                      ),
                      const SizedBox(height: 16),

                      // Avatar Grid Picker
                      Text(
                        'Select Character',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: _avatars.map((avatar) {
                          final isSelected = selectedAvatar == avatar;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedAvatar = avatar;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.secondary.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.backgroundCard,
                                child: Text(
                                  _getAvatarEmoji(avatar),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Name Input
                      TextField(
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.get(
                            'whats_your_name',
                            lang,
                          ),
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) {
                          name = val;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Age picker
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.get('age', lang)}:',
                            style: AppTextStyles.bodyLarge(context),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [6, 7, 8, 9, 10, 11, 12].map((age) {
                              bool isSelected = selectedAge == age;
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedAge = age;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$age',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Create button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              AppLocalizations.get('back', lang),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (name.trim().isNotEmpty) {
                                final appState = Provider.of<AppState>(
                                  context,
                                  listen: false,
                                );
                                appState.addProfile(
                                  name.trim(),
                                  selectedAvatar,
                                  selectedAge,
                                );
                                Navigator.pop(dialogContext);
                              }
                            },
                            child: Text(
                              AppLocalizations.get('lets_go', lang),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showParentPinGate(
    BuildContext context,
    String lang,
    String correctPin,
    AppState appState,
  ) {
    String inputPin = '';
    bool hasError = false;

    showDialog(
      context: context,
      builder: (BuildContext pinDialogContext) {
        return StatefulBuilder(
          builder: (context, setPinState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassmorphicContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.accentRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.get('parent_pin_prompt', lang),
                      style: AppTextStyles.displaySmall(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Input Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (idx) {
                        bool isFilled = inputPin.length > idx;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled
                                ? AppColors.accentRed
                                : Colors.transparent,
                            border: Border.all(
                              color: isFilled
                                  ? AppColors.accentRed
                                  : AppColors.textMuted,
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    if (hasError)
                      Text(
                        AppLocalizations.get('invalid_pin', lang),
                        style: TextStyle(
                          color: AppColors.accentRed,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Custom Numeric Keyboard for PIN entry
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
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
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              setPinState(() {
                                hasError = false;
                                if (label == 'C') {
                                  inputPin = '';
                                } else if (label == '⌫') {
                                  if (inputPin.isNotEmpty) {
                                    inputPin = inputPin.substring(
                                      0,
                                      inputPin.length - 1,
                                    );
                                  }
                                } else if (label.isNotEmpty &&
                                    inputPin.length < 4) {
                                  inputPin += label;
                                }
                              });

                              if (inputPin.length == 4) {
                                if (inputPin == correctPin) {
                                  Navigator.pop(pinDialogContext);
                                  final profile =
                                      appState.selectedProfile ??
                                      (appState.profiles.isNotEmpty
                                          ? appState.profiles.first
                                          : null);
                                  if (profile != null &&
                                      appState.selectedProfile?.id !=
                                          profile.id) {
                                    await appState.selectProfile(profile.id);
                                  }
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const DashboardScreen(),
                                    ),
                                  );
                                } else {
                                  setPinState(() {
                                    inputPin = '';
                                    hasError = true;
                                  });
                                }
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.primary.withValues(
                                  alpha: 0.06,
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(pinDialogContext),
                      child: Text(
                        AppLocalizations.get('back', lang),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getAvatarEmoji(String avatar) {
    switch (avatar) {
      case 'fox':
        return '🦊';
      case 'owl':
        return '🦉';
      case 'cat':
        return '🐱';
      case 'panda':
        return '🐼';
      case 'bear':
        return '🐻';
      case 'rabbit':
        return '🐰';
      default:
        return '🦊';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final profiles = appState.profiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Directionality(
          textDirection: AppLocalizations.getDirection(lang),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header (PIN Setup, Reset and info)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.get('who_is_playing', lang),
                      style: AppTextStyles.displayMedium(context),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        // Enter settings directly or via PIN
                        _showParentPinGate(
                          context,
                          lang,
                          appState.parentPin ?? '0000',
                          appState,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Grid of profiles
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: profiles.length + 1,
                    itemBuilder: (context, idx) {
                      if (idx < profiles.length) {
                        final profile = profiles[idx];
                        bool isSelected =
                            appState.selectedProfile?.id == profile.id;

                        return GestureDetector(
                          onTap: () async {
                            final profileId = profile.id;
                            await appState.selectProfile(profileId);
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WorldMapScreen(),
                              ),
                            );
                          },
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              double scale = isSelected
                                  ? 1.0 + (_pulseController.value * 0.04)
                                  : 1.0;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: GlassmorphicContainer(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : const Color(0x1F222147),
                              borderColor: isSelected
                                  ? AppColors.primaryLight
                                  : const Color(0x24FFFFFF),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: AppColors.backgroundCard,
                                    child: Text(
                                      _getAvatarEmoji(profile.avatar),
                                      style: const TextStyle(fontSize: 36),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    profile.name,
                                    style: AppTextStyles.displaySmall(context),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: AppColors.accentYellow,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${profile.stars}',
                                        style: TextStyle(
                                          color: AppColors.accentYellow,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.diamond,
                                        color: AppColors.secondary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${profile.gems}',
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        // "Add Player" box
                        return GestureDetector(
                          onTap: () => _showAddProfileDialog(context, lang),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.3,
                                ),
                                width: 2,
                                style: BorderStyle.solid, // solid fallback
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_circle_outline,
                                  size: 44,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.get('add_player', lang),
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),

                // Parent dashboard entry gate
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundCard,
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    _showParentPinGate(
                      context,
                      lang,
                      appState.parentPin ?? '0000',
                      appState,
                    );
                  },
                  icon: const Icon(
                    Icons.dashboard_outlined,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    AppLocalizations.get('parent_dashboard_btn', lang),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
