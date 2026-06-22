import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../localization.dart';
import 'puzzle_game.dart';
import 'profile_select.dart';
import 'settings.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  int _activeTab = 0; // 0 = Map, 1 = Treasures (Rewards)

  // Demo Shop Items
  final List<ShopItem> _shopItems = [
    ShopItem(
      id: 'skin_star_fox',
      name: 'Star Fox 🦊',
      cost: 2,
      type: 'skin',
      emoji: '🦊',
    ),
    ShopItem(
      id: 'skin_cosmo_owl',
      name: 'Cosmo Owl 🦉',
      cost: 4,
      type: 'skin',
      emoji: '🦉',
    ),
    ShopItem(
      id: 'skin_neon_cat',
      name: 'Neon Cat 🐱',
      cost: 6,
      type: 'skin',
      emoji: '🐱',
    ),
    ShopItem(
      id: 'pet_helper_bot',
      name: 'Robo-Buddy 🤖',
      cost: 3,
      type: 'pet',
      emoji: '🤖',
    ),
    ShopItem(
      id: 'pet_magical_dragon',
      name: 'Lil Dragon 🐲',
      cost: 8,
      type: 'pet',
      emoji: '🐲',
    ),
  ];

  void _showMissionIntro(
    BuildContext context,
    String missionId,
    String lang,
    int currentStars,
  ) {
    final appState = Provider.of<AppState>(context, listen: false);
    final difficulty = appState.currentDifficulty;
    String titleKey = '${missionId}_title';
    String descKey = '${missionId}_desc';

    final skills = switch (missionId) {
      'dark_room' => ['skill_attention', 'skill_focus'],
      'robot_room' => ['skill_planning', 'skill_logic'],
      'door_room' => ['skill_memory', 'skill_logic'],
      'garden_room' => ['skill_planning', 'skill_attention'],
      _ => ['skill_memory', 'skill_focus'],
    };

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassmorphicContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top icon illustration based on mission
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      _missionIcon(missionId),
                      size: 60,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  AppLocalizations.get(titleKey, lang),
                  style: AppTextStyles.displayMedium(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  AppLocalizations.get(descKey, lang),
                  style: AppTextStyles.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Trained skills
                Text(
                  '${AppLocalizations.get('skills', lang)}:',
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((sk) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.get(sk, lang),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildConfigChip(
                      Icons.tune_rounded,
                      '${AppLocalizations.get('level', lang)} ${difficulty.difficultyLevel}',
                    ),
                    _buildConfigChip(
                      Icons.timer_outlined,
                      '${difficulty.timeLimitSeconds} ${AppLocalizations.get('seconds', lang)}',
                    ),
                    _buildConfigChip(
                      Icons.lightbulb_outline,
                      AppLocalizations.get(
                        'hint_${difficulty.hintLevel}',
                        lang,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.get('back', lang)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PuzzleGameScreen(missionId: missionId),
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.get('lets_go', lang),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _buyItem(AppState appState, ShopItem item) async {
    if (appState.selectedProfile!.gems < item.cost) return;

    final success = await appState.purchaseItem(
      itemId: item.id,
      itemType: item.type,
      gemCost: item.cost,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unlocked ${item.name}! ✨'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      setState(() {});
    }
  }

  void _equipItem(AppState appState, ShopItem item) {
    appState.equipItem(item.type, item.id);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final child = appState.selectedProfile;

    if (child == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final equippedSkin = appState.getEquippedItem('skin');
    final equippedPet = appState.getEquippedItem('pet', defaultValue: 'none');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Directionality(
            textDirection: AppLocalizations.getDirection(lang),
            child: Column(
              children: [
                // Custom Header displaying profile stats
                _buildHeader(
                  context,
                  child,
                  equippedSkin,
                  equippedPet,
                  appState,
                ),

                // Active Screen Contents
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _activeTab == 0
                        ? _buildMapContent(child, lang, appState)
                        : _buildTreasuresContent(
                            child,
                            appState,
                            equippedSkin,
                            equippedPet,
                          ),
                  ),
                ),

                // Custom Navigation Bar
                _buildBottomNavBar(lang),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    child,
    String equippedSkin,
    String equippedPet,
    AppState appState,
  ) {
    // Look up equipped items
    String currentEmoji = '🦊';
    if (equippedSkin == 'skin_star_fox') currentEmoji = '🦊✨';
    if (equippedSkin == 'skin_cosmo_owl') currentEmoji = '🦉🚀';
    if (equippedSkin == 'skin_neon_cat') currentEmoji = '🐱🌟';
    if (equippedSkin == 'default') {
      currentEmoji = child.avatar == 'fox'
          ? '🦊'
          : child.avatar == 'owl'
          ? '🦉'
          : child.avatar == 'cat'
          ? '🐱'
          : child.avatar == 'panda'
          ? '🐼'
          : child.avatar == 'bear'
          ? '🐻'
          : '🐰';
    }

    String petDisplay = "";
    if (equippedPet == 'pet_helper_bot') petDisplay = " 🤖";
    if (equippedPet == 'pet_magical_dragon') petDisplay = " 🐲";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.textMuted.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: User Profile Icon
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.backgroundCard,
                  radius: 20,
                  child: Text(
                    currentEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(petDisplay, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(
                      'AI • ${AppLocalizations.get('level', appState.language)} ${appState.currentDifficulty.difficultyLevel}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Rewards display
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.accentYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${child.stars}',
                      style: const TextStyle(
                        color: AppColors.accentYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.diamond,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${child.gems}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Settings
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(child, String lang, AppState appState) {
    // Rooms definition
    final rooms = [
      RoomNode(
        id: 'dark_room',
        icon: Icons.lightbulb,
        color: AppColors.primary,
        unlockStars: 0,
      ),
      RoomNode(
        id: 'robot_room',
        icon: Icons.android,
        color: AppColors.secondary,
        unlockStars: 1,
      ),
      RoomNode(
        id: 'door_room',
        icon: Icons.lock_open,
        color: AppColors.accentPurple,
        unlockStars: 2,
      ),
      RoomNode(
        id: 'garden_room',
        icon: Icons.local_florist_rounded,
        color: AppColors.accentGreen,
        unlockStars: 3,
      ),
      RoomNode(
        id: 'memory_vault',
        icon: Icons.hub_rounded,
        color: AppColors.accentPink,
        unlockStars: 4,
      ),
    ];

    // Determine completion statuses
    final completedMissions = child.completedMissions;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      itemCount: rooms.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAgentRecommendationCard(context, lang, appState);
        }
        final idx = index - 1;
        final r = rooms[idx];
        final isRecommended = r.id == appState.recommendedMissionId;

        // Locked until previous room has at least 2 stars (plan progression rule)
        bool isUnlocked =
            idx == 0 ||
            (completedMissions[rooms[idx - 1].id] ?? 0) >= 2 ||
            isRecommended;
        int starsEarned = completedMissions[r.id] ?? 0;

        return Column(
          children: [
            // Level Selector Node Card
            GestureDetector(
              onTap: isUnlocked
                  ? () => _showMissionIntro(context, r.id, lang, starsEarned)
                  : null,
              child: Opacity(
                opacity: isUnlocked ? 1.0 : 0.4,
                child: GlassmorphicContainer(
                  padding: const EdgeInsets.all(20),
                  color: isUnlocked
                      ? r.color.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.02),
                  borderColor: isRecommended
                      ? AppColors.accentYellow.withValues(alpha: 0.7)
                      : isUnlocked
                      ? r.color.withValues(alpha: 0.4)
                      : AppColors.textMuted.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      // Circular level icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked
                              ? r.color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isUnlocked
                                ? r.color.withValues(alpha: 0.4)
                                : AppColors.textMuted,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isUnlocked ? r.icon : Icons.lock_outline,
                          size: 32,
                          color: isUnlocked ? r.color : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Level text description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isRecommended)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentYellow.withValues(
                                    alpha: 0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.get('ai_recommended', lang),
                                  style: const TextStyle(
                                    color: AppColors.accentYellow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            Text(
                              AppLocalizations.get('${r.id}_title', lang),
                              style: AppTextStyles.displaySmall(context),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.get('${r.id}_desc', lang),
                              style: AppTextStyles.bodySmall(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Rating stars earned
                      if (isUnlocked)
                        Column(
                          children: [
                            Row(
                              children: List.generate(3, (starIdx) {
                                return Icon(
                                  Icons.star,
                                  size: 18,
                                  color: starIdx < starsEarned
                                      ? AppColors.accentYellow
                                      : AppColors.textMuted.withValues(
                                          alpha: 0.3,
                                        ),
                                );
                              }),
                            ),
                            if (starsEarned > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '✓ Play Again',
                                  style: TextStyle(
                                    color: AppColors.accentGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Connection divider between nodes
            if (idx < rooms.length - 1)
              Container(
                height: 40,
                width: 3,
                color: isUnlocked
                    ? r.color.withValues(alpha: 0.4)
                    : AppColors.textMuted.withValues(alpha: 0.25),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAgentRecommendationCard(
    BuildContext context,
    String lang,
    AppState appState,
  ) {
    final confidence = appState.lastDecisionConfidence;
    final completed = appState.selectedProfile?.completedMissions.length ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(16),
        color: AppColors.primary.withValues(alpha: 0.08),
        borderColor: AppColors.primary.withValues(alpha: 0.35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.glowColor,
              child: Icon(Icons.auto_awesome, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.get('daily_ai_quest', lang),
                    style: AppTextStyles.displaySmall(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.get(
                      'decision_${appState.lastDecisionType}',
                      lang,
                    ),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appState.lastDecisionReason,
                    style: AppTextStyles.bodySmall(context),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: confidence,
                            minHeight: 7,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.10,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(confidence * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildConfigChip(
                        Icons.psychology_alt_rounded,
                        AppLocalizations.get(appState.lastFocusSkill, lang),
                      ),
                      _buildConfigChip(
                        Icons.route_rounded,
                        '$completed/5 ${AppLocalizations.get('mission_progress', lang)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.get('next_mission', lang)}: ${AppLocalizations.get('${appState.recommendedMissionId}_title', lang)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildConfigChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.secondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _missionIcon(String missionId) => switch (missionId) {
    'dark_room' => Icons.lightbulb_outline_rounded,
    'robot_room' => Icons.smart_toy_outlined,
    'door_room' => Icons.lock_open_rounded,
    'garden_room' => Icons.local_florist_rounded,
    'memory_vault' => Icons.hub_rounded,
    _ => Icons.extension_rounded,
  };

  Widget _buildTreasuresContent(
    child,
    AppState appState,
    String equippedSkin,
    String equippedPet,
  ) {
    final lang = appState.language;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Screen intro message
          Text(
            AppLocalizations.get('my_treasures', lang),
            style: AppTextStyles.displayMedium(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // shop item list
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _shopItems.length,
            itemBuilder: (context, idx) {
              final item = _shopItems[idx];
              bool isPurchased = appState.isItemPurchased(item.id);

              bool isEquipped = false;
              if (item.type == 'skin' && equippedSkin == item.id) {
                isEquipped = true;
              }
              if (item.type == 'pet' && equippedPet == item.id) {
                isEquipped = true;
              }

              bool canAfford = child.gems >= item.cost;

              return GlassmorphicContainer(
                color: isEquipped
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.backgroundCard,
                borderColor: isEquipped
                    ? AppColors.primaryLight
                    : AppColors.textMuted.withValues(alpha: 0.2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Item graphic emoji
                    Text(item.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),

                    // Item details
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action button based on state
                    if (isEquipped)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentGreen.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.get('equipped', lang),
                          style: const TextStyle(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else if (isPurchased)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _equipItem(appState, item),
                        child: Text(
                          AppLocalizations.get('use', lang),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford
                              ? AppColors.secondary
                              : AppColors.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: canAfford
                            ? () => _buyItem(appState, item)
                            : null,
                        icon: const Icon(
                          Icons.diamond,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          '${item.cost}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(String lang) {
    return BottomNavigationBar(
      backgroundColor: AppColors.backgroundSurface,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textMuted,
      currentIndex: _activeTab,
      onTap: (idx) {
        setState(() {
          _activeTab = idx;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Missions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.stars_outlined),
          label: 'Treasures',
        ),
      ],
    );
  }
}

class ShopItem {
  final String id;
  final String name;
  final int cost;
  final String type; // skin or pet
  final String emoji;

  ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.type,
    required this.emoji,
  });
}

class RoomNode {
  final String id;
  final IconData icon;
  final Color color;
  final int unlockStars;

  RoomNode({
    required this.id,
    required this.icon,
    required this.color,
    required this.unlockStars,
  });
}
