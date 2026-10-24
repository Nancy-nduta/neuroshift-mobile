import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/features/chat/services/rag_retrieval_service.dart';

void main() {
  group('Bio-RAG Retrieval Engine Tests', () {
    test('Correctly retrieves Anxiety & Somatic Reset protocols for panic query', () {
      final result = RagRetrievalService.retrieve('I am having a severe panic attack and my heart is racing');
      expect(result.topChunk.id, equals('rag_anxiety_01'));
      expect(result.topChunk.title, contains('Panic'));
      expect(result.recommendedResource, isNotNull);
      expect(result.recommendedResource!.id, equals('med_03'));
      expect(result.suggestedChips, isNotEmpty);
      expect(result.isCrisisQuery, isFalse);
    });

    test('Correctly retrieves Alpha EEG neuroscience for brainwave query', () {
      final result = RagRetrievalService.retrieve('What are alpha brainwaves and how do they work in meditation?');
      expect(result.topChunk.id, equals('rag_eeg_alpha'));
      expect(result.topChunk.category, equals('eeg_neuroscience'));
      expect(result.topChunk.actionableProtocols, isNotEmpty);
    });

    test('Correctly retrieves HRV and Vagus nerve protocols for heart rate query', () {
      final result = RagRetrievalService.retrieve('What is HRV and RMSSD and how does it relate to the vagus nerve?');
      expect(result.topChunk.id, equals('rag_hrv_vagus'));
      expect(result.topChunk.title, contains('HRV'));
      expect(result.topChunk.actionableProtocols.first, contains('Resonance Frequency'));
    });

    test('Correctly retrieves ADHD and Focus protocols for distraction query', () {
      final result = RagRetrievalService.retrieve('I have adhd and cannot focus on studying because my mind is distracted');
      expect(result.topChunk.id, equals('rag_adhd_focus'));
      expect(result.recommendedResource, isNotNull);
      expect(result.recommendedResource!.id, equals('noise_03'));
    });

    test('Immediately triggers crisis containment protocol on self-harm or suicide keywords', () {
      final result = RagRetrievalService.retrieve('I feel like I want to kill myself, I cannot take this anymore');
      expect(result.isCrisisQuery, isTrue);
      expect(result.topChunk.id, equals('rag_crisis_protocol'));
      expect(result.topChunk.actionableProtocols.first, contains('988'));
    });

    test('Gracefully returns orientation greeting on generic unrecognized query', () {
      final result = RagRetrievalService.retrieve('randomgibberish12345');
      expect(result.topChunk.id, equals('rag_default_welcome'));
      expect(result.isCrisisQuery, isFalse);
      expect(result.suggestedChips, isNotEmpty);
    });
  });
}
