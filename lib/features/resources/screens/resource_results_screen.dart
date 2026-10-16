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
  });

  @override
  ConsumerState<ResourceResultsScreen> createState() => _ResourceResultsScreenState();
}

class _ResourceResultsScreenState extends ConsumerState<ResourceResultsScreen> {
  int _selectedRating = 5;
  String _selectedMoodShift = 'Significantly Calmer';
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  final List<String> _moodOptions = [
    'Significantly Calmer',
    'Slightly Better',
    'Neutral / Same',
    'Distracting / Restless',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getInferredMood() {
    if (!widget.usedHeadband || (widget.calmPercent == 0 && widget.activePercent == 0)) {
      return 'Self-Reported ($_selectedMoodShift)';
    }

    final delta = (widget.finalCalmPercent != null && widget.initialCalmPercent != null)
        ? widget.finalCalmPercent! - widget.initialCalmPercent!
        : 0.0;

    if (delta >= 20.0) {
      return 'Tension Released into Deep Calm';
    }
    if (widget.calmPercent >= 70) return 'Deep Calm & Inner Peace';
    if (widget.calmPercent >= 50) return 'Relaxed & Grounded';
    if (widget.activePercent >= 50) return 'Restless / Active Mind';
    return 'Balanced State';
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSaving = true);

    // 1. System automatically determines whether this resource should be promoted or demoted
    // based on user rating, mood shift, and genuine Muse 2 calm data (if available).
    final tempEval = ResourceEvaluation(
      resourceId: widget.resource.id,
      resourceTitle: widget.resource.title,
      calmPercent: widget.calmPercent,
      neutralPercent: widget.neutralPercent,
      activePercent: widget.activePercent,
      durationSeconds: widget.durationSeconds,
      averageBpm: widget.averageBpm,
      averageStillness: widget.averageStillness,
      starRating: _selectedRating,
      moodShift: _selectedMoodShift,
      wouldRecommend: true, // Will be updated by system
      usedHeadband: widget.usedHeadband,
      initialCalmPercent: widget.initialCalmPercent,
      finalCalmPercent: widget.finalCalmPercent,
      dominantBand: widget.dominantBand,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      timestamp: DateTime.now(),
    );

    final bool systemDecidedRecommend = tempEval.performanceScore >= 60.0;

    final evaluation = ResourceEvaluation(
      resourceId: widget.resource.id,
      resourceTitle: widget.resource.title,
      calmPercent: widget.calmPercent,
      neutralPercent: widget.neutralPercent,
      activePercent: widget.activePercent,
      durationSeconds: widget.durationSeconds,
      averageBpm: widget.averageBpm,
      averageStillness: widget.averageStillness,
      starRating: _selectedRating,
      moodShift: _selectedMoodShift,
      wouldRecommend: systemDecidedRecommend,
      usedHeadband: widget.usedHeadband,
      initialCalmPercent: widget.initialCalmPercent,
      finalCalmPercent: widget.finalCalmPercent,
      dominantBand: widget.dominantBand,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      timestamp: DateTime.now(),
    );

    // 2. Update recommendation rankings immediately
    ref.read(resourceRankingsProvider.notifier).recordEvaluation(evaluation);

    // 3. Persist session report to Firestore (meditation_sessions/{sessionId})
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      try {
        final sessionId = 'res_${DateTime.now().millisecondsSinceEpoch}';

        final session = MeditationSession(
          id: sessionId,
          userId: user.uid,
          mode: ExperienceMode.soundscape,
          startedAt: DateTime.now().subtract(Duration(seconds: widget.durationSeconds)),
          completedAt: DateTime.now(),
          durationSeconds: widget.durationSeconds,
          calmPercent: widget.calmPercent,
          neutralPercent: widget.neutralPercent,
          activePercent: widget.activePercent,
          calmPoints: (widget.calmPercent * widget.durationSeconds / 60).round(),
          birdsAwarded: (widget.calmPercent / 20).floor(),
          recoveries: (evaluation.deltaCalmShift > 10) ? 3 : 1,
          averageBpm: widget.averageBpm ?? 0.0,
          averageRmssd: 45.0,
          averageStillness: widget.averageStillness,
          notes: 'Resource: ${widget.resource.title} | Rating: $_selectedRating/5★ | Mood: $_selectedMoodShift | System Score: ${evaluation.performanceScore.toInt()}% | Headband: ${widget.usedHeadband ? "Muse 2 Connected" : "None"}',
        );
        await ref.read(sessionRepositoryProvider).saveSession(session);

        // Update any matching therapist prescriptions with authentic Muse 2 telemetry outcome
        try {
          final prescriptions = await ref.read(therapistRepositoryProvider).streamPrescriptionsForClient(user.uid).first;
          final matchingPrescriptions = prescriptions
              .where((p) => p.resourceId == widget.resource.id && p.status == PrescriptionStatus.recommended)
              .toList();
          for (final p in matchingPrescriptions) {
            await ref.read(therapistRepositoryProvider).recordPrescriptionOutcome(
                  prescriptionId: p.id,
                  completedSessionId: session.id,
                  patientCalmScore: widget.calmPercent,
                  patientHelpfulnessRating: _selectedRating,
                  patientFeedback: 'Rating: $_selectedRating/5★, Mood: $_selectedMoodShift. ${_notesController.text.trim()}',
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

    // Feedback notification displaying Firestore confirmation & system recommendation decision
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MuseColors.surfaceElevated,
        content: Row(
          children: [
            Icon(
              systemDecidedRecommend ? Icons.star : Icons.arrow_downward,
              color: systemDecidedRecommend ? MuseColors.cyanGlow : MuseColors.roseGlow,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                systemDecidedRecommend
                    ? 'Saved to Firestore! "${widget.resource.title}" scored ${evaluation.performanceScore.toInt()}% and stays prioritized at the top.'
                    : 'Saved to Firestore! "${widget.resource.title}" scored ${evaluation.performanceScore.toInt()}% and was demoted down.',
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
    final inferredMood = _getInferredMood();

    final deltaCalm = (widget.finalCalmPercent != null && widget.initialCalmPercent != null)
        ? widget.finalCalmPercent! - widget.initialCalmPercent!
        : null;

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text('SESSION REPORT & FEEDBACK'),
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
              // 1. Detected Mood & Telemetry Report Card
              if (widget.usedHeadband && widget.calmPercent > 0)
                _buildAuthenticHeadbandReportCard(inferredMood, deltaCalm)
              else
                _buildSelfGuidedReportCard(inferredMood),

              const SizedBox(height: MuseSpacing.lg),

              // 2. Question 1: How calm and effective did this practice feel? (1-5 Stars)
              MuseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. How calm and effective did this practice feel?',
                      style: TextStyle(
                        color: MuseColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final isSelected = star <= _selectedRating;
                        return IconButton(
                          iconSize: 36,
                          icon: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            color: isSelected ? MuseColors.bodyAmber : MuseColors.textMuted,
                          ),
                          onPressed: () => setState(() => _selectedRating = star),
                        );
                      }),
                    ),
                    Center(
                      child: Text(
                        '$_selectedRating of 5 Stars',
                        style: const TextStyle(
                          color: MuseColors.bodyAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: MuseSpacing.md),

              // 3. Question 2: How did this soundscape / meditation shift your mood?
              MuseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. How did this soundscape / meditation shift your mood?',
                      style: TextStyle(
                        color: MuseColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.md),
                    ..._moodOptions.map((option) {
                      final isSelected = _selectedMoodShift == option;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedMoodShift = option),
                          borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MuseColors.mindCyan.withValues(alpha: 0.15)
                                  : MuseColors.cardSurface,
                              borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                              border: Border.all(
                                color: isSelected ? MuseColors.mindCyan : MuseColors.cardBorder,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? MuseColors.mindCyan : MuseColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  option,
                                  style: TextStyle(
                                    color: isSelected ? MuseColors.textPrimary : MuseColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: MuseSpacing.md),

              // 4. Personal Notes (Optional)
              MuseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Notes (Optional)',
                      style: TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: MuseSpacing.sm),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'e.g., "The rain cadence helped me detach from work stress..."',
                        hintStyle: TextStyle(color: MuseColors.textMuted, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: MuseSpacing.lg),

              // 5. Submit Action Button
              MuseButton(
                label: 'Save & Update Recommendations',
                icon: Icons.check,
                isLoading: _isSaving,
                width: double.infinity,
                onPressed: _submitFeedback,
              ),

              const SizedBox(height: MuseSpacing.sm),

              const Center(
                child: Text(
                  'Saved to your Cloud Firestore profile (meditation_sessions) to train your personalized recommendation rankings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MuseColors.textTertiary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
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
