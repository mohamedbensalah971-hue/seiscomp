import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../localization.dart';
import 'profile_select.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showResetConfirmation(
    BuildContext context,
    String lang,
    AppState appState,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(
            'Reset All Data?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'This action will permanently delete all player profiles, settings, and session metrics. This cannot be undone!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.get('back', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
              ),
              onPressed: () async {
                await appState.clearAllData();
                if (context.mounted) {
                  // Pop twice to return to splash
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileSelectScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Confirm Reset',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.get('settings_title', lang),
          style: AppTextStyles.displaySmall(context),
        ),
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: AppLocalizations.getDirection(lang),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Language configuration card
              _buildSectionHeader(
                context,
                AppLocalizations.get('language_sec', lang),
              ),
              const SizedBox(height: 8),
              _buildLanguageCard(appState),
              const SizedBox(height: 24),

              // Audio controller card
              _buildSectionHeader(
                context,
                AppLocalizations.get('sound_sec', lang),
              ),
              const SizedBox(height: 8),
              _buildAudioCard(context, appState, lang),
              const SizedBox(height: 24),

              // Accessibility config card
              _buildSectionHeader(
                context,
                AppLocalizations.get('accessibility_sec', lang),
              ),
              const SizedBox(height: 8),
              _buildAccessibilityCard(context, appState, lang),
              const SizedBox(height: 24),

              // Reset / Storage card
              _buildSectionHeader(
                context,
                AppLocalizations.get('data_sec', lang),
              ),
              const SizedBox(height: 8),
              _buildDataPrivacyCard(context, appState, lang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.displaySmall(
        context,
      ).copyWith(color: AppColors.secondary),
    );
  }

  Widget _buildLanguageCard(AppState appState) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildLanguageTile(appState, 'en', '🇬🇧 English'),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2), height: 1),
          _buildLanguageTile(appState, 'fr', '🇫🇷 Français'),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2), height: 1),
          _buildLanguageTile(appState, 'ar', '🇸🇦 العربية'),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(AppState appState, String code, String label) {
    bool isSelected = appState.language == code;
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.secondary)
          : null,
      onTap: () => appState.setLanguage(code),
    );
  }

  Widget _buildAudioCard(BuildContext context, AppState appState, String lang) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Music Slider
          Row(
            children: [
              const Icon(Icons.music_note, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.get('music_vol', lang),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    Slider(
                      value: appState.musicVolume,
                      onChanged: (val) {
                        appState.setSoundVolume(val, appState.sfxVolume);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // SFX Slider
          Row(
            children: [
              const Icon(Icons.volume_up, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.get('sfx_vol', lang),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    Slider(
                      value: appState.sfxVolume,
                      onChanged: (val) {
                        appState.setSoundVolume(appState.musicVolume, val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Voice Guidelines
          SwitchListTile(
            title: Text(
              AppLocalizations.get('voice_instr', lang),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            value: appState.voiceInstructions,
            onChanged: (val) => appState.setVoiceInstructions(val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityCard(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Reduce Motion
          SwitchListTile(
            title: Text(
              AppLocalizations.get('reduce_motion', lang),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'Simplifies slide transitions and particle animations',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: appState.reduceMotion,
            onChanged: (val) => appState.setReduceMotion(val),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),

          // Reduce Distractors
          SwitchListTile(
            title: Text(
              AppLocalizations.get('reduce_distractors', lang),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'Reduces active level distractors to help focus',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: appState.reduceDistractors,
            onChanged: (val) => appState.setReduceDistractors(val),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),

          // Colorblind Mode
          SwitchListTile(
            title: Text(
              AppLocalizations.get('colorblind_mode', lang),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'Uses distinct textures and shapes in puzzle levels',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: appState.colorblindMode,
            onChanged: (val) => appState.setColorblindMode(val),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),

          // Larger Text
          SwitchListTile(
            title: Text(
              AppLocalizations.get('larger_text', lang),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'Increases display readability on gameplay text UI',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            value: appState.largerText,
            onChanged: (val) => appState.setLargerText(val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDataPrivacyCard(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Delete active child profile
          if (appState.selectedProfile != null)
            ListTile(
              title: const Text(
                'Delete Current Profile',
                style: TextStyle(color: AppColors.accentRed),
              ),
              leading: const Icon(
                Icons.person_remove_outlined,
                color: AppColors.accentRed,
              ),
              onTap: () async {
                final id = appState.selectedProfile!.id;
                await appState.deleteProfile(id);
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileSelectScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              contentPadding: EdgeInsets.zero,
            ),
          if (appState.selectedProfile != null)
            Divider(color: AppColors.textMuted.withValues(alpha: 0.2)),

          // Reset everything
          ListTile(
            title: Text(
              AppLocalizations.get('clear_all', lang),
              style: const TextStyle(
                color: AppColors.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: AppColors.accentRed,
            ),
            onTap: () => _showResetConfirmation(context, lang, appState),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
