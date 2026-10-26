import 'package:flutter/material.dart';
import '../../../core/theme/muse_colors.dart';
import '../models/resource_evaluation.dart';
import '../providers/resource_ranking_provider.dart';

class RlFeedbackData {
  final int preValence;
  final int postValence;
  final int mentalCalmScore;
  final int bodyRelaxationScore;
  final int focusClarityScore;
  final String pacingFit;
  final List<String> outcomeTags;
  final bool wouldUseAgain;
  final int starRating;
  final String notes;

  const RlFeedbackData({
    this.preValence = 2,
    this.postValence = 4,
    this.mentalCalmScore = 4,
    this.bodyRelaxationScore = 4,
    this.focusClarityScore = 4,
    this.pacingFit = 'Just Right',
    this.outcomeTags = const ['Eased Anxiety', 'Relaxed Body'],
    this.wouldUseAgain = true,
    this.starRating = 5,
    this.notes = '',
  });

  String get derivedMoodShift {
    final delta = postValence - preValence;
    if (pacingFit == 'Audio Distracting' || postValence <= 1) {
      return 'Distracting / Restless';
    }
    if (delta >= 2 || (postValence == 5 && mentalCalmScore >= 4)) {
      return 'Significantly Calmer';
    }
    if (delta == 1 || postValence >= 4) {
      return 'Slightly Better';
    }
    return 'Neutral / Same';
  }

  RlFeedbackData copyWith({
    int? preValence,
    int? postValence,
    int? mentalCalmScore,
    int? bodyRelaxationScore,
    int? focusClarityScore,
    String? pacingFit,
    List<String>? outcomeTags,
    bool? wouldUseAgain,
    int? starRating,
    String? notes,
  }) {
    return RlFeedbackData(
      preValence: preValence ?? this.preValence,
      postValence: postValence ?? this.postValence,
      mentalCalmScore: mentalCalmScore ?? this.mentalCalmScore,
      bodyRelaxationScore: bodyRelaxationScore ?? this.bodyRelaxationScore,
      focusClarityScore: focusClarityScore ?? this.focusClarityScore,
      pacingFit: pacingFit ?? this.pacingFit,
      outcomeTags: outcomeTags ?? this.outcomeTags,
      wouldUseAgain: wouldUseAgain ?? this.wouldUseAgain,
      starRating: starRating ?? this.starRating,
      notes: notes ?? this.notes,
    );
  }
}

class RlSessionFeedbackForm extends StatelessWidget {
  final RlFeedbackData value;
  final ValueChanged<RlFeedbackData> onChanged;
  final ResourceEvaluation previewEvaluation;
  final RlNextRecommendation nextRecommendation;
  final bool usedHeadband;

  const RlSessionFeedbackForm({
    super.key,
    required this.value,
    required this.onChanged,
    required this.previewEvaluation,
    required this.nextRecommendation,
    required this.usedHeadband,
  });

  static const List<Map<String, dynamic>> _valenceStates = [
    {'score': 1, 'emoji': '😣', 'label': 'Very Tense'},
    {'score': 2, 'emoji': '😟', 'label': 'Stressed'},
    {'score': 3, 'emoji': '😐', 'label': 'Neutral'},
    {'score': 4, 'emoji': '🙂', 'label': 'Calm'},
    {'score': 5, 'emoji': '😌', 'label': 'Restored'},
  ];

  static const List<String> _availableTags = [
    'Eased Anxiety',
    'Slowed Thoughts',
    'Relaxed Body',
    'Steady Breath',
    'Better Focus',
    'Sleep Ready',
  ];

  static const List<String> _pacingOptions = [
    'Just Right',
    'Too Short',
    'Too Long',
    'Audio Distracting',
  ];

  @override
  Widget build(BuildContext context) {
    final delta = value.postValence - value.preValence;
    final deltaColor = delta > 0
        ? MuseColors.breathMint
        : (delta == 0 ? MuseColors.cyanGlow : MuseColors.heartRose);
    final deltaLabel = delta > 0
        ? '+$delta State Shift (Calm Gained)'
        : (delta == 0 ? 'Steady State Maintained' : '$delta State Shift');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==================== 1. ADAPTIVE RL INSIGHT & NEXT RECOMMENDATION ====================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MuseColors.cyanGlow.withValues(alpha: 0.16),
                MuseColors.surfaceElevated,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: MuseColors.cyanGlow.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MuseColors.cyanGlow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: MuseColors.cyanGlow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usedHeadband
                              ? 'Sensor + RL Model Calibration'
                              : 'Sensor-Free Adaptive Recommendation',
                          style: const TextStyle(
                            color: MuseColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          usedHeadband
                              ? 'Blending Muse 2 EEG with your feedback'
                              : 'Estimated Calm: ${previewEvaluation.effectiveCalmPercent.round()}% • RL Match: ${previewEvaluation.performanceScore.round()}%',
                          style: const TextStyle(
                            color: MuseColors.cyanGlow,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: MuseColors.breathMint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${previewEvaluation.performanceScore.round()} pts',
                      style: const TextStyle(
                        color: MuseColors.breathMint,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                nextRecommendation.policyReason,
                style: const TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MuseColors.spaceBackground.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MuseColors.cardBorder.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      nextRecommendation.resource.category.icon,
                      color: nextRecommendation.resource.category.color,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UP NEXT FOR YOU • ${nextRecommendation.suggestedPracticeMode.toUpperCase()}',
                            style: const TextStyle(
                              color: MuseColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextRecommendation.resource.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MuseColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nextRecommendation.resource.durationLabel,
                      style: const TextStyle(
                        color: MuseColors.cyanGlow,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ==================== 2. BEFORE vs AFTER STATE CHECK-IN ====================
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MuseColors.cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MuseColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '1. State Shift Check-In',
                    style: TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: deltaColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      deltaLabel,
                      style: TextStyle(
                        color: deltaColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Helps our reinforcement learning model measure your stress reduction even without a sensor.',
                style: TextStyle(color: MuseColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                'How did you feel BEFORE starting?',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildValenceRow(
                selectedScore: value.preValence,
                onSelect: (score) => onChanged(value.copyWith(preValence: score)),
              ),
              const SizedBox(height: 16),
              const Text(
                'How do you feel RIGHT NOW?',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildValenceRow(
                selectedScore: value.postValence,
                onSelect: (score) => onChanged(value.copyWith(postValence: score)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ==================== 3. MULTI-DIMENSIONAL IMPACT SCORES ====================
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MuseColors.cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MuseColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '2. Session Impact Breakdown',
                style: TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Rate how well this practice supported each area (1 = Low, 5 = High).',
                style: TextStyle(color: MuseColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _buildDimensionRow(
                icon: Icons.psychology_outlined,
                title: 'Mental Quietude',
                subtitle: 'Calmed racing thoughts',
                color: MuseColors.cyanGlow,
                score: value.mentalCalmScore,
                onSelect: (s) => onChanged(value.copyWith(mentalCalmScore: s)),
              ),
              const Divider(color: MuseColors.cardBorder, height: 22),
              _buildDimensionRow(
                icon: Icons.accessibility_new_rounded,
                title: 'Body Relaxation',
                subtitle: 'Released muscle tension',
                color: MuseColors.breathMint,
                score: value.bodyRelaxationScore,
                onSelect: (s) => onChanged(value.copyWith(bodyRelaxationScore: s)),
              ),
              const Divider(color: MuseColors.cardBorder, height: 22),
              _buildDimensionRow(
                icon: Icons.center_focus_strong_outlined,
                title: 'Focus & Clarity',
                subtitle: 'Present & emotionally grounded',
                color: MuseColors.bodyAmber,
                score: value.focusClarityScore,
                onSelect: (s) => onChanged(value.copyWith(focusClarityScore: s)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ==================== 4. WHAT HELPED MOST + PACING FIT ====================
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MuseColors.cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MuseColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '3. Personalize Future Recommendations',
                style: TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'What benefits did you notice? (Select any)',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = value.outcomeTags.contains(tag);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tag),
                    labelStyle: TextStyle(
                      color: isSelected ? MuseColors.spaceBackground : MuseColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    backgroundColor: MuseColors.surfaceElevated,
                    selectedColor: MuseColors.cyanGlow,
                    checkmarkColor: MuseColors.spaceBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? MuseColors.cyanGlow : MuseColors.cardBorder,
                      ),
                    ),
                    onSelected: (selected) {
                      final nextTags = List<String>.from(value.outcomeTags);
                      if (selected) {
                        nextTags.add(tag);
                      } else {
                        nextTags.remove(tag);
                      }
                      onChanged(value.copyWith(outcomeTags: nextTags));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'How was the pacing & audio guidance?',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pacingOptions.map((option) {
                  final isSelected = value.pacingFit == option;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(option),
                    labelStyle: TextStyle(
                      color: isSelected ? MuseColors.spaceBackground : MuseColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    backgroundColor: MuseColors.surfaceElevated,
                    selectedColor: option == 'Audio Distracting'
                        ? MuseColors.heartRose
                        : MuseColors.breathMint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : MuseColors.cardBorder,
                      ),
                    ),
                    onSelected: (_) => onChanged(value.copyWith(pacingFit: option)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommend similar practices?',
                          style: TextStyle(
                            color: MuseColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Trains Nova\'s recommendation policy',
                          style: TextStyle(
                            color: MuseColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Yes', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.thumb_up_alt_outlined, size: 15),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('No', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.thumb_down_alt_outlined, size: 15),
                      ),
                    ],
                    selected: {value.wouldUseAgain},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return value.wouldUseAgain
                              ? MuseColors.breathMint.withValues(alpha: 0.25)
                              : MuseColors.heartRose.withValues(alpha: 0.25);
                        }
                        return MuseColors.surfaceElevated;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return value.wouldUseAgain
                              ? MuseColors.breathMint
                              : MuseColors.heartRose;
                        }
                        return MuseColors.textSecondary;
                      }),
                    ),
                    onSelectionChanged: (s) =>
                        onChanged(value.copyWith(wouldUseAgain: s.first)),
                  ),
                ],
              ),
              const Divider(color: MuseColors.cardBorder, height: 26),
              const Text(
                'Overall Session Rating',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => onChanged(value.copyWith(starRating: star)),
                    icon: Icon(
                      star <= value.starRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: star <= value.starRating
                          ? MuseColors.bodyAmber
                          : MuseColors.textMuted,
                      size: 34,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (txt) => onChanged(value.copyWith(notes: txt)),
                style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Optional note (e.g., what worked or what you need next)...',
                  hintStyle: const TextStyle(color: MuseColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: MuseColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MuseColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MuseColors.cardBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValenceRow({
    required int selectedScore,
    required ValueChanged<int> onSelect,
  }) {
    return Row(
      children: _valenceStates.map((item) {
        final score = item['score'] as int;
        final isSelected = selectedScore == score;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(score),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? MuseColors.cyanGlow.withValues(alpha: 0.18)
                    : MuseColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? MuseColors.cyanGlow : MuseColors.cardBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    item['emoji'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? MuseColors.textPrimary : MuseColors.textMuted,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDimensionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int score,
    required ValueChanged<int> onSelect,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: MuseColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (idx) {
            final val = idx + 1;
            final active = val <= score;
            return GestureDetector(
              onTap: () => onSelect(val),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(left: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? color.withValues(alpha: 0.22)
                      : MuseColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? color : MuseColors.cardBorder,
                  ),
                ),
                child: Text(
                  '$val',
                  style: TextStyle(
                    color: active ? MuseColors.textPrimary : MuseColors.textMuted,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
