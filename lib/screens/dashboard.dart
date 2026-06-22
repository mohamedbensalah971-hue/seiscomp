import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state.dart';
import '../theme.dart';
import '../models.dart';
import '../localization.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.language;
    final child = appState.selectedProfile;

    if (child == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text('No active profile', style: TextStyle(color: AppColors.textPrimary))),
      );
    }

    final history = appState.getSessionHistoryForCurrentChild();
    final metrics = appState.aiAgent.getDashboardIndicators(history);

    final double attentionScore = metrics['attentionScore'];
    final double impulseScore = metrics['impulseControlScore'];
    final double reactionTime = metrics['averageReactionTimeSeconds'];
    final int completedCount = metrics['completedMissions'];

    final List<double> attentionHistory = List<double>.from(metrics['attentionHistory']);
    final List<double> impulseHistory = List<double>.from(metrics['impulseHistory']);
    final List<String> dates = List<String>.from(metrics['dates']);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${child.name}\'s Dashboard 🔒',
          style: const TextStyle(fontFamily: AppTextStyles.fontDisplay, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: AppLocalizations.getDirection(lang),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Summary indicators
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        AppLocalizations.get('attention', lang),
                        '$attentionScore%',
                        AppColors.secondary,
                        Icons.visibility,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        AppLocalizations.get('impulse_control', lang),
                        '$impulseScore%',
                        AppColors.accentPurple,
                        Icons.timer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        AppLocalizations.get('reaction_time', lang),
                        '$reactionTime ${AppLocalizations.get('seconds', lang)}',
                        AppColors.accentYellow,
                        Icons.speed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        AppLocalizations.get('completed_missions_title', lang),
                        '$completedCount',
                        AppColors.accentGreen,
                        Icons.sports_esports_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Chart Section
                Text(
                  'Focus & Self-Control Progress',
                  style: AppTextStyles.displaySmall(context),
                ),
                const SizedBox(height: 12),
                _buildProgressChart(context, attentionHistory, impulseHistory, dates),
                const SizedBox(height: 20),

                // AI suggestions card
                Text(
                  AppLocalizations.get('suggestion', lang),
                  style: AppTextStyles.displaySmall(context),
                ),
                const SizedBox(height: 12),
                _buildAISuggestionCard(context, appState),
                const SizedBox(height: 20),

                // Recent Session Logs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.get('recent_sessions', lang),
                      style: AppTextStyles.displaySmall(context),
                    ),
                    Text(
                      'Total: ${history.length}',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSessionList(context, history, lang),
                const SizedBox(height: 20),

                // Diagnostic Notice Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.get('diagnostic_notice', lang),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                '• Active',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(BuildContext context, List<double> attention, List<double> impulse, List<String> dates) {
    if (attention.length < 2) {
      return GlassmorphicContainer(
        height: 180,
        child: Center(
          child: Text(
            'Play more levels to view progress graphs!',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    // Chart configuration
    List<FlSpot> attentionSpots = [];
    List<FlSpot> impulseSpots = [];

    for (int i = 0; i < attention.length; i++) {
      attentionSpots.add(FlSpot(i.toDouble(), attention[i]));
      impulseSpots.add(FlSpot(i.toDouble(), impulse[i]));
    }

    return GlassmorphicContainer(
      padding: const EdgeInsets.only(top: 24, bottom: 8, right: 24, left: 8),
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.textMuted.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < dates.length) {
                    return Text(dates[idx], style: TextStyle(color: AppColors.textMuted, fontSize: 10));
                  }
                  return const Text('');
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%', style: TextStyle(color: AppColors.textMuted, fontSize: 10));
                },
                reservedSize: 36,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Attention graph
            LineChartBarData(
              spots: attentionSpots,
              isCurved: true,
              color: AppColors.secondary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.secondary.withOpacity(0.15),
              ),
            ),
            // Impulse graph
            LineChartBarData(
              spots: impulseSpots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISuggestionCard(BuildContext context, AppState appState) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.primary.withOpacity(0.3),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.glowColor,
            child: Icon(Icons.psychology, color: AppColors.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Level Recommendation',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  appState.lastFeedbackMessage,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(BuildContext context, List<SessionResult> history, String lang) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text('No played levels yet.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length > 5 ? 5 : history.length, // Limit list length
      itemBuilder: (context, idx) {
        final res = history[idx];
        bool isSuccess = res.starsEarned > 0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textMuted.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    res.missionId == 'dark_room' 
                        ? Icons.lightbulb_outline 
                        : (res.missionId == 'robot_room' ? Icons.android : Icons.lock_open),
                    color: isSuccess ? AppColors.secondary : AppColors.accentRed,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.get('${res.missionId}_title', lang),
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Time: ${res.completionTimeSeconds.round()}s  •  Wrong: ${res.wrongClicks + res.distractorClicks}',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: List.generate(3, (starIdx) {
                  return Icon(
                    Icons.star,
                    size: 14,
                    color: starIdx < res.starsEarned 
                        ? AppColors.accentYellow 
                        : AppColors.textMuted.withOpacity(0.2),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
