import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/features/chat/data/clinical_knowledge_base.dart';
import 'package:neuroshift_mobile/features/chat/services/rag_retrieval_service.dart';
import 'package:neuroshift_mobile/features/resources/models/resource_item.dart';

import 'evaluation/retrieval_eval_set.dart';

void main() {
  group('Nova Hybrid RAG Retrieval & Knowledge Base Tests', () {
    test('Knowledge base chunks have verified sources, limitations, and valid catalog resource IDs', () {
      final catalogIds = ResourceItem.catalog.map((r) => r.id).toSet();

      for (final chunk in ClinicalKnowledgeBase.chunks) {
        expect(chunk.id, isNotEmpty);
        expect(chunk.title, isNotEmpty);
        expect(chunk.summary, isNotEmpty);
        expect(chunk.limitations, isNotEmpty, reason: 'Chunk ${chunk.id} missing limitations');
        expect(chunk.reviewedOn, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        if (chunk.evidence == EvidenceQuality.established ||
            chunk.evidence == EvidenceQuality.limited) {
          expect(
            chunk.sources,
            isNotEmpty,
            reason: 'Chunk ${chunk.id} must cite at least one source',
          );
        }

        if (chunk.recommendedResourceId != null) {
          expect(
            catalogIds.contains(chunk.recommendedResourceId),
            isTrue,
            reason:
                'Chunk ${chunk.id} references unknown resource ID ${chunk.recommendedResourceId}',
          );
        }
      }
    });

    test('Achieves >=95% top-1 accuracy on answerable evaluation queries and 0% false evidence on out-of-scope queries', () {
      int answerableTotal = 0;
      int answerableHits = 0;
      int outOfScopeTotal = 0;
      int falsePositives = 0;
      final misses = <String>[];

      for (final item in retrievalEvalSet) {
        final res = RagRetrievalService.retrieve(item.query);
        if (item.expectNone) {
          outOfScopeTotal++;
          if (res.hasEvidence) {
            falsePositives++;
            misses.add('Out-of-scope matched: "${item.query}" -> ${res.top?.id}');
          }
        } else {
          answerableTotal++;
          final topId = res.top?.id;
          if (topId != null && item.acceptNew.contains(topId)) {
            answerableHits++;
          } else {
            misses.add(
              'Miss: "${item.query}" -> got $topId, expected ${item.acceptNew}',
            );
          }
        }
      }

      final accuracy = answerableHits / answerableTotal;
      expect(
        accuracy,
        greaterThanOrEqualTo(0.95),
        reason: 'Answerable accuracy was ${(accuracy * 100).toStringAsFixed(1)}%. Misses:\n${misses.join('\n')}',
      );
      expect(outOfScopeTotal, greaterThan(0));
      expect(
        falsePositives,
        equals(0),
        reason: 'Out-of-scope queries falsely returned evidence:\n${misses.join('\n')}',
      );
    });

    test('Retrieves acute anxiety & grounding chunks for panic and spiralling thoughts', () {
      final panicRes = RagRetrievalService.retrieve(
        'I am having a panic attack and my heart is racing',
      );
      expect(panicRes.hasEvidence, isTrue);
      expect(panicRes.top!.id, equals('anx_acute'));
      expect(panicRes.confidence, greaterThan(0.5));

      final spiralRes = RagRetrievalService.retrieve(
        'My thoughts keep spiralling and I cannot get out of my head',
      );
      expect(spiralRes.hasEvidence, isTrue);
      expect(spiralRes.top!.id, equals('grounding'));
    });

    test('Retrieves EEG artifact explanation when user asks why delta is always highest', () {
      final deltaRes = RagRetrievalService.retrieve(
        'Why is delta always the dominant brainwave on my headband?',
      );
      expect(deltaRes.hasEvidence, isTrue);
      expect(deltaRes.top!.id, equals('eeg_artifacts'));

      final stateRes = RagRetrievalService.retrieve(
        'How does the system classify calm, neutral, and active states?',
      );
      expect(stateRes.hasEvidence, isTrue);
      expect(stateRes.top!.id, equals('app_state_classification'));
    });

    test('Retrieves NeuroShift privacy & recording facts accurately', () {
      final res = RagRetrievalService.retrieve(
        'What happens if I delete my recording?',
      );
      expect(res.hasEvidence, isTrue);
      expect(res.top!.id, equals('app_privacy_data'));
    });

    test('Returns empty result for greetings, gibberish, and unrelated general trivia', () {
      expect(RagRetrievalService.retrieve('Hi Nova').hasEvidence, isFalse);
      expect(RagRetrievalService.retrieve('randomgibberish12345').hasEvidence, isFalse);
      expect(
        RagRetrievalService.retrieve('What is the capital of France?').hasEvidence,
        isFalse,
      );
    });
  });
}
