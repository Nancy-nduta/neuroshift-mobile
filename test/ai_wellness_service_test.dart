import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/features/chat/services/ai_wellness_service.dart';
import 'package:neuroshift_mobile/models/signal_reading.dart';

void main() {
  group('AiWellnessService Bio-RAG Tests', () {
    test('Synthesizes empathetic somatic guidance for anxiety query', () async {
      final response = await AiWellnessService.getResponse(
        'I am feeling severe anxiety and need immediate help',
        [],
      );
      expect(response.isUser, isFalse);
      expect(response.text, contains('Panic'));
      expect(response.text, contains('Physiological Sigh'));
      expect(response.recommendedResource, isNotNull);
      expect(response.suggestedChips, isNotEmpty);
    });

    test('Injects live biometric telemetry when user asks to analyze current brainwaves', () async {
      final fakeTelemetry = SignalReading(
        timestamp: DateTime.now(),
        mindState: MindState.active,
        alpha: 11.2,
        beta: 22.8,
        theta: 8.4,
        delta: 28.5,
        gamma: 4.1,
        heartRateBpm: 86,
        hrvRmssd: 29.4,
        stillnessScore: 94.0,
      );

      final response = await AiWellnessService.getResponse(
        'Analyze my current brainwaves and mind state',
        [],
        currentTelemetry: fakeTelemetry,
        isConnected: true,
      );

      expect(response.isUser, isFalse);
      expect(response.text, contains('Live Neural Telemetry Analysis'));
      expect(response.text, contains('ACTIVE'));
      expect(response.text, contains('Beta Arousal (22.8 µV)'));
      expect(response.text, contains('86 BPM'));
    });

    test('Identifies Calm state correctly in biometric analysis', () async {
      final fakeCalm = SignalReading(
        timestamp: DateTime.now(),
        mindState: MindState.calm,
        alpha: 24.5,
        beta: 9.8,
        theta: 12.0,
        delta: 30.0,
        gamma: 3.5,
        heartRateBpm: 64,
        hrvRmssd: 68.2,
        stillnessScore: 98.0,
      );

      final response = await AiWellnessService.getResponse(
        'Am I calm right now?',
        [],
        currentTelemetry: fakeCalm,
        isConnected: true,
      );

      expect(response.text, contains('CALM'));
      expect(response.text, contains('Alpha Synchrony (24.5 µV)'));
      expect(response.text, contains('64 BPM'));
      expect(response.text, contains('68.2 ms'));
    });

    test('Provides immediate emergency crisis hotline on self-harm prompts', () async {
      final response = await AiWellnessService.getResponse(
        'I want to hurt myself',
        [],
      );

      expect(response.text, contains('988 Suicide & Crisis Lifeline'));
      expect(response.text, contains('741741'));
    });
  });
}
