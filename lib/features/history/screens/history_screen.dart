import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroshift_mobile/core/providers/app_providers.dart';
import 'package:neuroshift_mobile/core/theme/muse_colors.dart';
import 'package:neuroshift_mobile/core/theme/muse_spacing.dart';
import 'package:neuroshift_mobile/core/widgets/muse_card.dart';
import 'package:neuroshift_mobile/features/meditate/screens/session_results_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(userSessionsProvider);

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text('HISTORY & INSIGHTS'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: sessionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: MuseColors.cyanGlow),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error loading history: $err',
              style: const TextStyle(color: MuseColors.roseGlow),
            ),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(MuseSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: MuseColors.cardSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: MuseColors.cardBorder),
                        ),
                        child: const Icon(Icons.bar_chart, color: MuseColors.textSecondary, size: 36),
                      ),
                      const SizedBox(height: MuseSpacing.lg),
                      const Text(
                        'No Sessions Yet',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: MuseSpacing.xs),
                      const Text(
                        'Your completed meditations, calm percentages, and birds will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: MuseColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Calculate aggregate stats
            int totalCalmPoints = 0;
            int totalBirds = 0;
            int totalMinutes = 0;

            for (final s in sessions) {
              totalCalmPoints += s.calmPoints;
              totalBirds += s.birdsAwarded;
              totalMinutes += (s.durationSeconds / 60).round();
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(MuseSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Aggregated Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: MuseCard(
                                padding: const EdgeInsets.symmetric(vertical: MuseSpacing.md),
                                child: Column(
                                  children: [
                                    Text(
                                      '$totalMinutes',
                                      style: const TextStyle(
                                        color: MuseColors.textPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Calm Mins',
                                      style: TextStyle(color: MuseColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: MuseSpacing.sm),
                            Expanded(
                              child: MuseCard(
                                padding: const EdgeInsets.symmetric(vertical: MuseSpacing.md),
                                child: Column(
                                  children: [
                                    Text(
                                      '$totalBirds',
                                      style: const TextStyle(
                                        color: MuseColors.cyanGlow,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Birds',
                                      style: TextStyle(color: MuseColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: MuseSpacing.sm),
                            Expanded(
                              child: MuseCard(
                                padding: const EdgeInsets.symmetric(vertical: MuseSpacing.md),
                                child: Column(
                                  children: [
                                    Text(
                                      '$totalCalmPoints',
                                      style: const TextStyle(
                                        color: MuseColors.amberGlow,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Points',
                                      style: TextStyle(color: MuseColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MuseSpacing.xl),
                        const Text(
                          'RECENT SESSIONS',
                          style: TextStyle(
                            color: MuseColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final s = sessions[index];
                        final durationMin = (s.durationSeconds / 60).toStringAsFixed(1);
                        final dateStr = '${s.completedAt.month}/${s.completedAt.day} at ${s.completedAt.hour.toString().padLeft(2, '0')}:${s.completedAt.minute.toString().padLeft(2, '0')}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: MuseSpacing.md),
                          child: MuseCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SessionResultsScreen(session: s),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s.mode.displayName,
                                      style: const TextStyle(
                                        color: MuseColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '$durationMin mins',
                                      style: const TextStyle(
                                        color: MuseColors.cyanGlow,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: MuseColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: MuseSpacing.md),

                                // Calm % Mini Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: SizedBox(
                                    height: 8,
                                    child: Row(
                                      children: [
                                        if (s.calmPercent > 0)
                                          Expanded(
                                            flex: (s.calmPercent * 10).round().clamp(1, 1000),
                                            child: Container(color: MuseColors.calmGlow),
                                          ),
                                        if (s.neutralPercent > 0)
                                          Expanded(
                                            flex: (s.neutralPercent * 10).round().clamp(1, 1000),
                                            child: Container(color: MuseColors.neutralGlow),
                                          ),
                                        if (s.activePercent > 0)
                                          Expanded(
                                            flex: (s.activePercent * 10).round().clamp(1, 1000),
                                            child: Container(color: MuseColors.activeGlow),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: MuseSpacing.sm),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${s.calmPercent.round()}% Calm',
                                      style: const TextStyle(
                                        color: MuseColors.calmGlow,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.flutter_dash, size: 14, color: MuseColors.cyanGlow),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${s.birdsAwarded}',
                                          style: const TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.star, size: 14, color: MuseColors.amberGlow),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${s.calmPoints}',
                                          style: const TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: sessions.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
