import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resource_evaluation.dart';
import '../models/resource_item.dart';

class ResourceRankingNotifier extends Notifier<Map<String, ResourceEvaluation>> {
  @override
  Map<String, ResourceEvaluation> build() {
    return {};
  }

  void recordEvaluation(ResourceEvaluation eval) {
    state = {
      ...state,
      eval.resourceId: eval,
    };
  }

  ResourceEvaluation? getEvaluationFor(String resourceId) => state[resourceId];
}

final resourceRankingsProvider =
    NotifierProvider<ResourceRankingNotifier, Map<String, ResourceEvaluation>>(
  ResourceRankingNotifier.new,
);

/// Returns the 20 catalog resources sorted dynamically by their performance score:
/// High-performing resources stay at the top ("Recommended for your brain"), while low-performing ones are demoted.
final rankedResourcesProvider = Provider<List<ResourceItem>>((ref) {
  final evaluations = ref.watch(resourceRankingsProvider);

  final list = List<ResourceItem>.from(ResourceItem.catalog);

  list.sort((a, b) {
    final evalA = evaluations[a.id];
    final evalB = evaluations[b.id];

    if (evalA == null && evalB == null) return 0;
    if (evalA != null && evalB == null) return -1; // Evaluated resources prioritized
    if (evalA == null && evalB != null) return 1;

    // Both evaluated: higher score wins
    return evalB!.performanceScore.compareTo(evalA!.performanceScore);
  });

  return list;
});
