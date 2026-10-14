import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/meditation_session.dart';

class SessionResultsScreen extends ConsumerStatefulWidget {
  final MeditationSession session;

  const SessionResultsScreen({super.key, required this.session});

  @override
  ConsumerState<SessionResultsScreen> createState() => _SessionResultsScreenState();
}

class _SessionResultsScreenState extends ConsumerState<SessionResultsScreen> {
  bool _isSaving = false;
  int _userRating = 5; // Default 5 stars

  Future<void> _saveAndClose() async {
    setState(() => _isSaving = true);
    try {
      final updatedSession = widget.session.copyWith(
        notes: 'Rating: $_userRating/5★',
      );
      await ref.read(sessionRepositoryProvider).saveSession(updatedSession);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final totalMinutes = (s.durationSeconds / 60).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text('SESSION SUMMARY'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MuseSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mode Header
              Text(
                '${s.mode.displayName.toUpperCase()} SESSION',
                style: const TextStyle(
                  color: MuseColors.cyanGlow,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: MuseSpacing.xs),
              Text(
                '$totalMinutes Minutes',
                style: const TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: MuseSpacing.xl),

              // Muse Mind State Breakdown Card
              MuseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MIND STATE BREAKDOWN',
                      style: TextStyle(
                        color: MuseColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.md),

                    // Multi-segment horizontal bar (signature Muse UI)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 20,
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
                    const SizedBox(height: MuseSpacing.md),

                    // Legend & percentages
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StateMetric(
                          label: 'Calm',
                          percent: s.calmPercent,
                          color: MuseColors.calmGlow,
                        ),
                        _StateMetric(
                          label: 'Neutral',
                          percent: s.neutralPercent,
                          color: MuseColors.neutralGlow,
                        ),
                        _StateMetric(
                          label: 'Active',
                          percent: s.activePercent,
                          color: MuseColors.activeGlow,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.lg),

              // Gamification Awards (Birds & Calm Points)
              Row(
                children: [
                  Expanded(
                    child: MuseCard(
                      child: Column(
                        children: [
                          const Icon(Icons.flutter_dash, color: MuseColors.cyanGlow, size: 32),
                          const SizedBox(height: MuseSpacing.xs),
                          Text(
                            '${s.birdsAwarded}',
                            style: const TextStyle(
                              color: MuseColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Birds Landed',
                            style: TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: MuseSpacing.md),
                  Expanded(
                    child: MuseCard(
                      child: Column(
                        children: [
                          const Icon(Icons.star, color: MuseColors.amberGlow, size: 32),
                          const SizedBox(height: MuseSpacing.xs),
                          Text(
                            '${s.calmPoints}',
                            style: const TextStyle(
                              color: MuseColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Calm Points',
                            style: TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MuseSpacing.lg),

              // Physiological Metrics (Heart Rate & Stillness)
              MuseCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.favorite, color: MuseColors.roseGlow, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          s.averageBpm > 0 ? '${s.averageBpm.round()} BPM' : '--',
                          style: const TextStyle(
                            color: MuseColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Avg Heart Rate',
                          style: TextStyle(color: MuseColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: MuseColors.cardBorder),
                    Column(
                      children: [
                        const Icon(Icons.accessibility_new, color: MuseColors.fitGood, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '${s.averageStillness.round()}%',
                          style: const TextStyle(
                            color: MuseColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Body Stillness',
                          style: TextStyle(color: MuseColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: MuseColors.cardBorder),
                    Column(
                      children: [
                        const Icon(Icons.refresh, color: MuseColors.cyanGlow, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '${s.recoveries}',
                          style: const TextStyle(
                            color: MuseColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Recoveries',
                          style: TextStyle(color: MuseColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.xl),

              // Interactive Rating Card — Trains NeuroShift AI
              MuseCard(
                borderColor: MuseColors.amberGlow.withValues(alpha: 0.4),
                backgroundColor: const Color(0xFF161F2E),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: MuseColors.amberGlow),
                        SizedBox(width: 6),
                        Text(
                          'TRAIN YOUR RECOMMENDATION ENGINE',
                          style: TextStyle(
                            color: MuseColors.amberGlow,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuseSpacing.xs),
                    const Text(
                      'How calm and effective did this practice feel?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MuseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: MuseSpacing.sm),

                    // Star selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final isSelected = star <= _userRating;
                        return IconButton(
                          icon: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? MuseColors.amberGlow : MuseColors.textMuted,
                            size: 34,
                          ),
                          onPressed: () => setState(() => _userRating = star),
                          splashRadius: 22,
                        );
                      }),
                    ),
                    Text(
                      _userRating == 5
                          ? 'Deeply calming & effective'
                          : _userRating == 4
                              ? 'Very good session'
                              : _userRating == 3
                                  ? 'Moderately calming'
                                  : _userRating == 2
                                      ? 'A bit challenging'
                                      : 'Not effective for me',
                      style: const TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.xl),

              // Save & Finish Button
              MuseButton(
                label: 'Save & Finish Practice',
                width: double.infinity,
                isLoading: _isSaving,
                onPressed: _saveAndClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMetric extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _StateMetric({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: MuseColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${percent.toInt()}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
