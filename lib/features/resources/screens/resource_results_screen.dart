import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/experience_mode.dart';
import '../../../models/meditation_session.dart';
import '../../../models/therapist_prescription.dart';
import '../models/resource_evaluation.dart';
import '../models/resource_item.dart';
import '../providers/resource_ranking_provider.dart';

import '../widgets/rl_session_feedback_card.dart';

class ResourceResultsScreen extends ConsumerStatefulWidget {
  final ResourceItem resource;
  final int durationSeconds;
  final double calmPercent;
  final double neutralPercent;
  final double activePercent;
  final double? averageBpm;
  final double averageStillness;
  final bool usedHeadband;
  final double? initialCalmPercent;
  final double? finalCalmPercent;
  final String? dominantBand;
  final bool isPrescription;
  final String? therapistName;
  final String? prescriptionId;

  const ResourceResultsScreen({
    super.key,
    required this.resource,
    required this.durationSeconds,
    required this.calmPercent,
    required this.neutralPercent,
    required this.activePercent,
    this.averageBpm,
    required this.averageStillness,
    required this.usedHeadband,
    this.initialCalmPercent,
    this.finalCalmPercent,
    this.dominantBand,
    this.isPrescription = false,
    this.therapistName,
    this.prescriptionId,
  });

  @override
  ConsumerState<ResourceResultsScreen> createState() => _ResourceResultsScreenState();
}

class _ResourceResultsScreenState extends ConsumerState<ResourceResultsScreen> {
  RlFeedbackData _feedback = const RlFeedbackData();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Auto-save practice session immediately so calm score is recorded even if user exits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSaveInitialSession();
    });
  }

  void _autoSaveInitialSession() {
    try {
      final user = ref.read(authStateProvider).value;
      final uid = user?.uid ?? 'anonymous';
      final now = DateTime.now();
      final startedAt = now.subtract(Duration(seconds: widget.durationSeconds));
      final sessionId = 'res__';

      final session = MeditationSession(
        id: sessionId,
        userId: uid,
        mode: ExperienceMode.soundscape,
        startedAt: startedAt,
        completedAt: now,
        durationSeconds: widget.durationSeconds,
        calmPercent: widget.calmPercent,
        neutralPercent: widget.neutralPercent,
        activePercent: widget.activePercent,
        calmPoints: (widget.calmPercent * widget.durationSeconds / 60).round(),
        birdsAwarded: (widget.calmPercent / 20).floor(),
        recoveries: widget.calmPercent >= 60 ? 3 : 1,
        averageBpm: widget.averageBpm ?? 0.0,
        averageRmssd: 45.0,
        averageStillness: widget.averageStillness,
        notes: 'Resource:  | Completed',
      );
      ref.read(sessionRepositoryProvider).saveSession(session);
    } catch (_) {}
  }

  ResourceEvaluation _buildCurrentEvaluation() {
    final temp = ResourceEvaluation(
      resourceId: widget.resource.id,
      resourceTitle: widget.resource.title,
      category: widget.resource.category.label,
      calmPercent: widget.calmPercent,
      neutralPercent: widget.neutralPercent,
      activePercent: widget.activePercent,
      durationSeconds: widget.durationSeconds,
      averageBpm: widget.averageBpm,
      averageStillness: widget.averageStillness,
      starRating: _feedback.starRating,
      moodShift: _feedback.derivedMoodShift,
      wouldRecommend: _feedback.wouldUseAgain,
      usedHeadband: widget.usedHeadband,
      initialCalmPercent: widget.initialCalmPercent,
      finalCalmPercent: widget.finalCalmPercent,
      dominantBand: widget.dominantBand,
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

    final systemDecidedRecommend =
        temp.performanceScore >= 60.0 && _feedback.wouldUseAgain;

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
      wouldRecommend: systemDecidedRecommend,
      usedHeadband: temp.usedHeadband,
      initialCalmPercent: temp.initialCalmPercent,
      finalCalmPercent: temp.finalCalmPercent,
      dominantBand: temp.dominantBand,
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

  Future<void> _submitFeedback() async {
    setState(() => _isSaving = true);

    final evaluation = _buildCurrentEvaluation();
    final systemDecidedRecommend = evaluation.wouldRecommend;

    // 1. Update RL Contextual Bandit rankings immediately
    ref.read(resourceRankingsProvider.notifier).recordEvaluation(evaluation);

    // 2. Persist both meditation_sessions and activity_sessions to Firestore
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      try {
        final now = DateTime.now();
        final startedAt = now.subtract(Duration(seconds: widget.durationSeconds));
        final sessionId = 'res_${now.millisecondsSinceEpoch}';

        final effCalm = evaluation.effectiveCalmPercent;
        final effNeutral = evaluation.effectiveNeutralPercent;
        final effActive = evaluation.effectiveActivePercent;

        final session = MeditationSession(
          id: sessionId,
          userId: user.uid,
          mode: ExperienceMode.soundscape,
          startedAt: startedAt,
          completedAt: now,
          durationSeconds: widget.durationSeconds,
          calmPercent: effCalm,
          neutralPercent: effNeutral,
          activePercent: effActive,
          calmPoints: (effCalm * widget.durationSeconds / 60).round(),
          birdsAwarded: (effCalm / 20).floor(),
          recoveries: (evaluation.deltaCalmShift > 10 || evaluation.valenceDelta >= 2) ? 3 : 1,
          averageBpm: widget.averageBpm ?? 0.0,
          averageRmssd: 45.0,
          averageStillness: widget.averageStillness,
          notes:
              'Resource: ${widget.resource.title} | State: ${_feedback.preValence}➔${_feedback.postValence} | RL Score: ${evaluation.performanceScore.toInt()}% | Tags: ${_feedback.outcomeTags.join(", ")} | Sensor: ${widget.usedHeadband ? "Muse 2" : "Self-Report RL"}',
        );
        await ref.read(sessionRepositoryProvider).saveSession(session);

        // Save structured RL training record to activity_sessions
        await ref.read(sessionRepositoryProvider).saveActivityEvaluation(
              sessionId: sessionId,
              userId: user.uid,
              startedAt: startedAt,
              completedAt: now,
              evaluation: evaluation,
            );

        // Update any matching therapist prescriptions
        try {
          final prescriptions = await ref
              .read(therapistRepositoryProvider)
              .streamPrescriptionsForClient(user.uid)
              .first;
          final matchingPrescriptions = prescriptions
              .where((p) =>
                  p.resourceId == widget.resource.id &&
                  p.status == PrescriptionStatus.recommended)
              .toList();
          for (final p in matchingPrescriptions) {
            await ref.read(therapistRepositoryProvider).recordPrescriptionOutcome(
                  prescriptionId: p.id,
                  completedSessionId: session.id,
                  patientCalmScore: effCalm,
                  patientHelpfulnessRating: _feedback.starRating,
                  patientFeedback:
                      'State Shift: ${_feedback.preValence}➔${_feedback.postValence}/5, Pacing: ${_feedback.pacingFit}, Benefits: ${_feedback.outcomeTags.join(", ")}. ${_feedback.notes.trim()}',
                );
          }
        } catch (e) {
          debugPrint('Error updating therapist prescription outcome: $e');
        }
      } catch (e) {
        debugPrint('Error saving resource session to firestore: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    final nextRec = ref
        .read(resourceRankingsProvider.notifier)
        .recommendFromEvaluation(evaluation);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MuseColors.surfaceElevated,
        content: Row(
          children: [
            Icon(
              systemDecidedRecommend ? Icons.auto_awesome : Icons.tune_rounded,
              color: systemDecidedRecommend ? MuseColors.cyanGlow : MuseColors.bodyAmber,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.isPrescription
                    ? 'Session saved & shared with ${widget.therapistName ?? "Practitioner"}!'
                    : 'RL Model Updated (${evaluation.performanceScore.toInt()}% match)! Next recommended: "${nextRec.resource.title}".',
                style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previewEval = _buildCurrentEvaluation();
    final inferredMood = previewEval.inferredMood;
    final nextRec = ref
        .read(resourceRankingsProvider.notifier)
        .recommendFromEvaluation(previewEval);

    final deltaCalm = (widget.finalCalmPercent != null && widget.initialCalmPercent != null)
        ? widget.finalCalmPercent! - widget.initialCalmPercent!
        : null;

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text('Session Summary & Feedback'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MuseSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isPrescription) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MuseColors.cyanGlow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MuseColors.cyanGlow.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, color: MuseColors.cyanGlow, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prescribed by ${widget.therapistName ?? "Practitioner"} • Telemetry Shared',
                          style: const TextStyle(
                            color: MuseColors.cyanGlow,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),
              ],

              // 1. Detected Mood & Telemetry Report Card
              if (widget.usedHeadband && widget.calmPercent > 0)
                _buildAuthenticHeadbandReportCard(inferredMood, deltaCalm)
              else
                _buildSelfGuidedReportCard(inferredMood),

              const SizedBox(height: MuseSpacing.lg),

              // 2. Comprehensive RL Feedback & Adaptive Recommendation Form
              RlSessionFeedbackForm(
                value: _feedback,
                usedHeadband: widget.usedHeadband && widget.calmPercent > 0,
                previewEvaluation: previewEval,
                nextRecommendation: nextRec,
                onChanged: (updated) => setState(() => _feedback = updated),
              ),

              const SizedBox(height: MuseSpacing.lg),

              // 3. Submit Action Button
              MuseButton(
                label: widget.isPrescription
                    ? 'Complete Prescribed Session'
                    : 'Save Feedback & Update Recommendations',
                icon: Icons.check,
                isLoading: _isSaving,
                width: double.infinity,
                onPressed: _submitFeedback,
              ),

              const SizedBox(height: MuseSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  /// Authentic Muse 2 report card displaying genuine EEG telemetry, state transition, and biometrics
  Widget _buildAuthenticHeadbandReportCard(String inferredMood, double? deltaCalm) {
    return MuseCard(
      borderColor: MuseColors.cyanGlow,
      backgroundColor: MuseColors.cyanGlow.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MuseColors.cyanGlow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: MuseColors.cyanGlow, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MUSE 2 DETECTED MOOD STATE',
                      style: TextStyle(
                        color: MuseColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      inferredMood,
                      style: const TextStyle(
                        color: MuseColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuseSpacing.md),

          // Relaxation shift gradient if recorded
          if (deltaCalm != null && widget.initialCalmPercent != null && widget.finalCalmPercent != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: deltaCalm >= 0
                    ? MuseColors.fitGood.withValues(alpha: 0.15)
                    : MuseColors.activeGlow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: deltaCalm >= 0 ? MuseColors.fitGood : MuseColors.activeGlow,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    deltaCalm >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: deltaCalm >= 0 ? MuseColors.fitGood : MuseColors.activeGlow,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Relaxation Shift: Started at ${widget.initialCalmPercent!.toInt()}% Calm ➔ Reached ${widget.finalCalmPercent!.toInt()}% Calm (${deltaCalm >= 0 ? '+' : ''}${deltaCalm.toInt()}% Shift)',
                      style: TextStyle(
                        color: deltaCalm >= 0 ? MuseColors.fitGood : MuseColors.activeGlow,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MuseSpacing.sm),
          ],

          if (widget.dominantBand != null)
            Text(
              'Dominant frequency: ${widget.dominantBand} waves during "${widget.resource.title}".',
              style: const TextStyle(color: MuseColors.textSecondary, fontSize: 12),
            ),

          const SizedBox(height: MuseSpacing.md),

          // 3-Way Frequency Breakdown from genuine samples
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (widget.calmPercent * 10).toInt().clamp(1, 1000),
                  child: Container(height: 8, color: MuseColors.fitGood),
                ),
                Expanded(
                  flex: (widget.neutralPercent * 10).toInt().clamp(1, 1000),
                  child: Container(height: 8, color: MuseColors.neutralGlow),
                ),
                Expanded(
                  flex: (widget.activePercent * 10).toInt().clamp(1, 1000),
                  child: Container(height: 8, color: MuseColors.activeGlow),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Calm Alpha', value: '${widget.calmPercent.toInt()}%', color: MuseColors.fitGood),
              _StatItem(label: 'Neutral', value: '${widget.neutralPercent.toInt()}%', color: MuseColors.neutralGlow),
              _StatItem(label: 'Active Beta', value: '${widget.activePercent.toInt()}%', color: MuseColors.activeGlow),
            ],
          ),

          if (widget.averageBpm != null || widget.averageStillness > 0) ...[
            const Divider(color: MuseColors.cardBorder, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (widget.averageBpm != null && widget.averageBpm! > 0)
                  _StatItem(
                    label: 'Average Pulse',
                    value: '${widget.averageBpm!.toInt()} BPM',
                    color: MuseColors.heartRose,
                  ),
                _StatItem(
                  label: 'Body Stillness',
                  value: '${widget.averageStillness.toInt()}%',
                  color: MuseColors.breathMint,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Self-guided report card when Muse 2 was not streaming
  Widget _buildSelfGuidedReportCard(String inferredMood) {
    return MuseCard(
      borderColor: MuseColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MuseColors.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headphones, color: MuseColors.mindCyan, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRACTICE MODE',
                      style: TextStyle(
                        color: MuseColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Self-Guided Session',
                      style: TextStyle(
                        color: MuseColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuseSpacing.sm),
          const Text(
            'Muse 2 headband was not connected during this session, so EEG brainwave and heart rate telemetry were not recorded. Your feedback below will tune your personal recommendations.',
            style: TextStyle(
              color: MuseColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: MuseColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
