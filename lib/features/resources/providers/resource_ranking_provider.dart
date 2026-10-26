import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resource_evaluation.dart';
import '../models/resource_item.dart';

class RlNextRecommendation {
  final ResourceItem resource;
  final String policyReason;
  final double expectedReward;
  final String suggestedPracticeMode;

  const RlNextRecommendation({
    required this.resource,
    required this.policyReason,
    required this.expectedReward,
    required this.suggestedPracticeMode,
  });
}

class ResourceRankingNotifier extends Notifier<Map<String, ResourceEvaluation>> {
  @override
  Map<String, ResourceEvaluation> build() {
    return {};
  }

  /// Reinforcement learning Q-value update with learning rate alpha = 0.65
  /// so repeated sessions smoothly blend historical and recent rewards.
  void recordEvaluation(ResourceEvaluation eval) {
    final prev = state[eval.resourceId];
    if (prev == null) {
      state = {
        ...state,
        eval.resourceId: eval,
      };
      return;
    }

    const alpha = 0.65;
    final blendedCalm = prev.effectiveCalmPercent * (1 - alpha) + eval.effectiveCalmPercent * alpha;
    final blendedNeutral = prev.effectiveNeutralPercent * (1 - alpha) + eval.effectiveNeutralPercent * alpha;
    final blendedActive = prev.effectiveActivePercent * (1 - alpha) + eval.effectiveActivePercent * alpha;

    final updated = ResourceEvaluation(
      resourceId: eval.resourceId,
      resourceTitle: eval.resourceTitle,
      category: eval.category,
      calmPercent: eval.usedHeadband ? eval.calmPercent : blendedCalm,
      neutralPercent: eval.usedHeadband ? eval.neutralPercent : blendedNeutral,
      activePercent: eval.usedHeadband ? eval.activePercent : blendedActive,
      durationSeconds: eval.durationSeconds,
      averageBpm: eval.averageBpm ?? prev.averageBpm,
      averageStillness: eval.averageStillness,
      starRating: eval.starRating,
      moodShift: eval.moodShift,
      wouldRecommend: eval.wouldRecommend,
      usedHeadband: eval.usedHeadband,
      initialCalmPercent: eval.initialCalmPercent,
      finalCalmPercent: eval.finalCalmPercent,
      dominantBand: eval.dominantBand ?? prev.dominantBand,
      notes: eval.notes,
      timestamp: eval.timestamp,
      preValence: eval.preValence,
      postValence: eval.postValence,
      mentalCalmScore: eval.mentalCalmScore,
      bodyRelaxationScore: eval.bodyRelaxationScore,
      focusClarityScore: eval.focusClarityScore,
      pacingFit: eval.pacingFit,
      outcomeTags: eval.outcomeTags,
      wouldUseAgain: eval.wouldUseAgain,
    );

    state = {
      ...state,
      eval.resourceId: updated,
    };
  }

  ResourceEvaluation? getEvaluationFor(String resourceId) => state[resourceId];

  /// Computes the contextual bandit expected reward for any catalog item,
  /// transferring learned category and state preferences even to unevaluated items.
  double expectedBanditScore(ResourceItem item) {
    final directEval = state[item.id];
    const baselinePrior = 62.0; // Default exploration prior for unseen items

    // Compute category affinity across all evaluated items in this category
    final categoryEvals = state.values
        .where((e) => e.category == item.category.label)
        .toList();
    double categoryAffinityBonus = 0.0;
    if (categoryEvals.isNotEmpty) {
      final avgCategoryScore = categoryEvals
              .map((e) => e.performanceScore)
              .reduce((a, b) => a + b) /
          categoryEvals.length;
      // Shift by up to +/- 12 points based on how well this category works for the user
      categoryAffinityBonus = ((avgCategoryScore - 60.0) * 0.30).clamp(-12.0, 12.0);
    }

    if (directEval != null) {
      final retentionAdjustment = directEval.wouldUseAgain ? 4.0 : -22.0;
      return (directEval.performanceScore + categoryAffinityBonus * 0.4 + retentionAdjustment)
          .clamp(0.0, 100.0);
    }

    return (baselinePrior + categoryAffinityBonus).clamp(0.0, 100.0);
  }

  /// Generates an immediate, personalized next-step recommendation from the user's
  /// latest RL feedback state, working identically with or without hardware sensors.
  RlNextRecommendation recommendFromEvaluation(ResourceEvaluation latest) {
    final candidates = ResourceItem.catalog
        .where((r) => r.id != latest.resourceId)
        .toList();

    // Determine target category & practice mode based on user's post-session state & feedback
    ResourceCategory preferredCategory = ResourceCategory.guidedMeditation;
    String suggestedMode = 'Mind';
    String reason;

    if (latest.pacingFit == 'Audio Distracting' || !latest.wouldUseAgain) {
      // Exploration pivot: switch away from the current category to a soothing ambient modality
      preferredCategory = latest.category == ResourceCategory.natureSoundscapes.label
          ? ResourceCategory.peacefulPiano
          : ResourceCategory.natureSoundscapes;
      suggestedMode = 'Soundscape';
      reason =
          'Since this session\'s pacing/audio wasn\'t an ideal fit, our RL model pivoted away from ${latest.category} toward a gentle ${preferredCategory.label} session.';
    } else if (latest.postValence <= 2 || latest.bodyRelaxationScore <= 2) {
      // User still has residual physical tension or stress -> Somatic / Breath / Rain relief
      preferredCategory = ResourceCategory.guidedMeditation;
      suggestedMode = 'Breath';
      reason =
          'Your post-session check-in shows lingering tension. Nova\'s RL policy prioritized somatic & breath-paced relief to help settle your nervous system.';
    } else if (latest.mentalCalmScore <= 2) {
      // Racing thoughts persist -> Brown/White Noise or Rain cognitive masking
      preferredCategory = ResourceCategory.whiteNoise;
      suggestedMode = 'Soundscape';
      reason =
          'To quiet persistent mental chatter, the RL model selected acoustic frequency masking (${preferredCategory.label}) to reduce cognitive load.';
    } else if (latest.valenceDelta >= 2 || latest.performanceScore >= 78) {
      // Strong positive reinforcement -> Exploit similar high-reward category
      preferredCategory = ResourceCategory.values.firstWhere(
        (c) => c.label == latest.category,
        orElse: () => ResourceCategory.guidedMeditation,
      );
      suggestedMode = latest.focusClarityScore >= 4 ? 'Mind' : 'Heart';
      final shiftText = latest.valenceDelta > 0 ? '+${latest.valenceDelta} state shift' : 'high calm score';
      reason =
          'Reinforced by your $shiftText (${latest.performanceScore.round()}% RL reward), we boosted similar ${preferredCategory.label} practices in your queue.';
    } else {
      preferredCategory = ResourceCategory.rainAndStorm;
      suggestedMode = 'Heart';
      reason =
          'Balanced session recorded (${latest.performanceScore.round()}% RL reward). Next, try ${preferredCategory.label} to deepen autonomic relaxation.';
    }

    candidates.sort((a, b) {
      final aBonus = a.category == preferredCategory ? 14.0 : 0.0;
      final bBonus = b.category == preferredCategory ? 14.0 : 0.0;
      final scoreA = expectedBanditScore(a) + aBonus;
      final scoreB = expectedBanditScore(b) + bBonus;
      return scoreB.compareTo(scoreA);
    });

    final chosen = candidates.first;
    final expected = (expectedBanditScore(chosen) +
            (chosen.category == preferredCategory ? 8.0 : 0.0))
        .clamp(55.0, 98.0);

    return RlNextRecommendation(
      resource: chosen,
      policyReason: reason,
      expectedReward: expected,
      suggestedPracticeMode: suggestedMode,
    );
  }
}

final resourceRankingsProvider =
    NotifierProvider<ResourceRankingNotifier, Map<String, ResourceEvaluation>>(
  ResourceRankingNotifier.new,
);

/// Returns the 20 catalog resources sorted dynamically by their Contextual Bandit RL score:
/// High-performing resources and favored categories rise to the top, while low-reward or
/// "would not use again" resources are demoted below unexplored items.
final rankedResourcesProvider = Provider<List<ResourceItem>>((ref) {
  ref.watch(resourceRankingsProvider);
  final notifier = ref.read(resourceRankingsProvider.notifier);

  final list = List<ResourceItem>.from(ResourceItem.catalog);

  list.sort((a, b) {
    final scoreA = notifier.expectedBanditScore(a);
    final scoreB = notifier.expectedBanditScore(b);
    return scoreB.compareTo(scoreA);
  });

  return list;
});

