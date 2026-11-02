import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/meditation_session.dart';
import '../../resources/models/resource_evaluation.dart';
import '../../resources/providers/resource_ranking_provider.dart';
import '../../resources/widgets/rl_session_feedback_card.dart';

class SessionResultsScreen extends ConsumerStatefulWidget {
  final MeditationSession session;

  const SessionResultsScreen({super.key, required this.session});

  @override
  ConsumerState<SessionResultsScreen> createState() => _SessionResultsScreenState();
}

class _SessionResultsScreenState extends ConsumerState<SessionResultsScreen> {
  bool _isSaving = false;
  RlFeedbackData _feedback = const RlFeedbackData();

  @override
  void initState() {
    super.initState();
    // Ensure session is stored immediately so calm score is never lost if user closes the app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(sessionRepositoryProvider).saveSession(widget.session);
      } catch (_) {}
    });
  }

  bool get _hasSensorTelemetry =>
      widget.session.calmPercent > 0 ||
      widget.session.neutralPercent > 0 ||
      widget.session.activePercent > 0;

  ResourceEvaluation _buildEvaluation() {
    final s = widget.session;
    final temp = ResourceEvaluation(
      resourceId: 'mode_${s.mode.type.name}',
      resourceTitle: '${s.mode.displayName} Practice',
      category: 'Guided Meditation',
      calmPercent: s.calmPercent,
      neutralPercent: s.neutralPercent,
      activePercent: s.activePercent,
      durationSeconds: s.durationSeconds,
      averageBpm: s.averageBpm > 0 ? s.averageBpm : null,
      averageStillness: s.averageStillness,
      starRating: _feedback.starRating,
      moodShift: _feedback.derivedMoodShift,
      wouldRecommend: _feedback.wouldUseAgain,
      usedHeadband: _hasSensorTelemetry,
      notes: _feedback.notes.trim().isNotEmpty ? _feedback.notes.trim() : null,
      timestamp: DateTime.now(),
      preValence: _feedback.preValence,
      postValence: _feedback.postValence,
      mentalCalmScore: _feedback.mentalCalmScore,
      bodyRelaxationScore: _feedback.bodyRelaxationScore,
      focusClarityScore: _feedback.focusClarityScore,
      pacingFit: _feedback.pacingFit,
      outcomeTags: _feedback.outcomeTags,
      wouldUseAgain: _feedback.wouldUseAgain,
    );

    return ResourceEvaluation(
      resourceId: temp.resourceId,
      resourceTitle: temp.resourceTitle,
      category: temp.category,
      calmPercent: temp.calmPercent,
      neutralPercent: temp.neutralPercent,
      activePercent: temp.activePercent,
      durationSeconds: temp.durationSeconds,
      averageBpm: temp.averageBpm,
      averageStillness: temp.averageStillness,
      starRating: temp.starRating,
      moodShift: temp.moodShift,
      wouldRecommend: temp.performanceScore >= 60.0 && _feedback.wouldUseAgain,
      usedHeadband: temp.usedHeadband,
      notes: temp.notes,
      timestamp: temp.timestamp,
      preValence: temp.preValence,
      postValence: temp.postValence,
      mentalCalmScore: temp.mentalCalmScore,
      bodyRelaxationScore: temp.bodyRelaxationScore,
      focusClarityScore: temp.focusClarityScore,
      pacingFit: temp.pacingFit,
      outcomeTags: temp.outcomeTags,
      wouldUseAgain: temp.wouldUseAgain,
    );
  }

  Future<void> _saveAndClose() async {
    setState(() => _isSaving = true);
    try {
      final evaluation = _buildEvaluation();
      ref.read(resourceRankingsProvider.notifier).recordEvaluation(evaluation);

      final effCalm = evaluation.effectiveCalmPercent;
      final effNeutral = evaluation.effectiveNeutralPercent;
      final effActive = evaluation.effectiveActivePercent;

      final updatedSession = widget.session.copyWith(
        calmPercent: effCalm,
        neutralPercent: effNeutral,
        activePercent: effActive,
        notes:
            'State: ${_feedback.preValence}➔${_feedback.postValence} | Rating: ${_feedback.starRating}/5★ | RL Score: ${evaluation.performanceScore.round()}% | Pacing: ${_feedback.pacingFit} | Tags: ${_feedback.outcomeTags.join(", ")}',
      );
      await ref.read(sessionRepositoryProvider).saveSession(updatedSession);

      await ref.read(sessionRepositoryProvider).saveActivityEvaluation(
            sessionId: updatedSession.id,
            userId: updatedSession.userId,
            startedAt: updatedSession.startedAt,
            completedAt: updatedSession.completedAt,
            evaluation: evaluation,
          );

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
    final previewEval = _buildEvaluation();
    final nextRec = ref
        .read(resourceRankingsProvider.notifier)
        .recommendFromEvaluation(previewEval);
    final displayCalm = previewEval.effectiveCalmPercent;
    final displayNeutral = previewEval.effectiveNeutralPercent;
    final displayActive = previewEval.effectiveActivePercent;

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text('Session Summary'),
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
              const SizedBox(height: MuseSpacing.lg),

              // Muse Mind State Breakdown Card
              MuseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _hasSensorTelemetry
                              ? 'MIND STATE BREAKDOWN (MUSE 2)'
                              : 'ESTIMATED STATE BREAKDOWN (RL MODEL)',
                          style: const TextStyle(
                            color: MuseColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuseSpacing.md),

                    // Multi-segment horizontal bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 20,
                        child: Row(
                          children: [
                            if (displayCalm > 0)
                              Expanded(
                                flex: (displayCalm * 10).round().clamp(1, 1000),
                                child: Container(color: MuseColors.calmGlow),
                              ),
                            if (displayNeutral > 0)
                              Expanded(
                                flex: (displayNeutral * 10).round().clamp(1, 1000),
                                child: Container(color: MuseColors.neutralGlow),
                              ),
                            if (displayActive > 0)
                              Expanded(
                                flex: (displayActive * 10).round().clamp(1, 1000),
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
                          percent: displayCalm,
                          color: MuseColors.calmGlow,
                        ),
                        _StateMetric(
                          label: 'Neutral',
                          percent: displayNeutral,
                          color: MuseColors.neutralGlow,
                        ),
                        _StateMetric(
                          label: 'Active',
                          percent: displayActive,
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
              const SizedBox(height: MuseSpacing.lg),

              // Comprehensive RL Feedback & Adaptive Recommendation Form
              RlSessionFeedbackForm(
                value: _feedback,
                usedHeadband: _hasSensorTelemetry,
                previewEvaluation: previewEval,
                nextRecommendation: nextRec,
                onChanged: (updated) => setState(() => _feedback = updated),
              ),
              const SizedBox(height: MuseSpacing.xl),

              // Save & Finish Button
              MuseButton(
                label: 'Save Feedback & Finish Practice',
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
