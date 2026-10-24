import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/features/chat/models/ai_chat_message.dart';
import 'package:neuroshift_mobile/features/chat/services/ai_wellness_service.dart';
import 'package:neuroshift_mobile/models/signal_reading.dart';

void main() {
  group('AiWellnessService Conversational, RAG, Telemetry, Error & Safety Tests', () {
    test('1. Greetings return a brief friendly reply without RAG evidence or resource cards', () async {
      final hiReply = await AiWellnessService.getResponse('Hi Nova', const []);
      expect(hiReply.isUser, isFalse);
      expect(hiReply.responseMode, equals(NovaResponseMode.deterministic));
      expect(hiReply.recommendedResource, isNull);
      expect(hiReply.sourceReferences, isEmpty);
      expect(hiReply.text, contains('Nova'));

      final howAreYouReply = await AiWellnessService.getResponse(
        'How are you doing today?',
        const [],
      );
      expect(howAreYouReply.responseMode, equals(NovaResponseMode.deterministic));
      expect(howAreYouReply.recommendedResource, isNull);
    });

    test('2. Thanks and farewells respond naturally without attaching resource cards', () async {
      final thanksReply = await AiWellnessService.getResponse(
        'Thank you so much Nova',
        const [],
      );
      expect(thanksReply.responseMode, equals(NovaResponseMode.deterministic));
      expect(thanksReply.recommendedResource, isNull);
      expect(thanksReply.text.toLowerCase(), contains('welcome'));

      final byeReply = await AiWellnessService.getResponse('Goodbye', const []);
      expect(byeReply.responseMode, equals(NovaResponseMode.deterministic));
      expect(byeReply.recommendedResource, isNull);
      expect(byeReply.text.toLowerCase(), contains('take good care'));
    });

    test('3. Emotional disclosure acknowledges feelings, asks a gentle follow-up question, and does not push a resource card', () async {
      final reply = await AiWellnessService.getResponse(
        "I've had a really difficult day.",
        const [],
      );
      expect(reply.isUser, isFalse);
      expect(reply.recommendedResource, isNull);
      expect(reply.text, contains('?'));
      expect(reply.text.toLowerCase(), contains('sorry'));
    });

    test('4. Multi-turn conversation retains context across turns (presentation anxiety follow-up)', () async {
      final history = <AiChatMessage>[];

      const turn1User = "I'm anxious about my presentation tomorrow.";
      history.add(
        AiChatMessage(
          id: 'u1',
          text: turn1User,
          isUser: true,
          timestamp: DateTime(2026, 10, 24, 10, 0),
          responseMode: NovaResponseMode.user,
        ),
      );
      final turn1Reply = await AiWellnessService.getResponse(turn1User, history);
      history.add(turn1Reply);
      expect(turn1Reply.text.toLowerCase(), contains('presentation'));
      expect(turn1Reply.recommendedResource, isNull);

      const turn2User = "I'm scared I'll forget everything.";
      history.add(
        AiChatMessage(
          id: 'u2',
          text: turn2User,
          isUser: true,
          timestamp: DateTime(2026, 10, 24, 10, 1),
          responseMode: NovaResponseMode.user,
        ),
      );
      final turn2Reply = await AiWellnessService.getResponse(turn2User, history);
      expect(turn2Reply.text.toLowerCase(), contains('presentation'));
      expect(turn2Reply.text.toLowerCase(), anyOf(contains('blank'), contains('forget')));
      expect(turn2Reply.text, contains('?'));
      expect(turn2Reply.recommendedResource, isNull);
    });

    test('5. Clinical/wellness question ("What is HRV?") returns grounded answer with sources and no unsolicited resource card', () async {
      final reply = await AiWellnessService.getResponse('What is HRV?', const []);
      expect(reply.responseMode, equals(NovaResponseMode.offlineKnowledge));
      expect(reply.text, contains('RMSSD'));
      expect(reply.sourceReferences, isNotEmpty);
      expect(
        reply.sourceReferences.any((s) => s.title.contains('Heart Rate Variability')),
        isTrue,
      );
      expect(reply.recommendedResource, isNull);
    });

    test('6. Resource recommendations are attached only when user asks for an exercise/audio or during acute panic', () async {
      final exerciseReply = await AiWellnessService.getResponse(
        'Can you help me calm down?',
        const [],
      );
      expect(exerciseReply.recommendedResource, isNotNull);

      final boxBreathingReply = await AiWellnessService.getResponse(
        'Guide me through box breathing',
        const [],
      );
      expect(boxBreathingReply.recommendedResource, isNotNull);

      final panicReply = await AiWellnessService.getResponse(
        'I am having a panic attack and my heart is racing',
        const [],
      );
      expect(panicReply.recommendedResource, isNotNull);
    });

    test('7. Telemetry question when headband is disconnected or stale clearly states live data is unavailable', () async {
      final disconnectedReply = await AiWellnessService.getResponse(
        'What do my brainwaves mean?',
        const [],
        isConnected: false,
        currentTelemetry: null,
      );
      expect(disconnectedReply.text.toLowerCase(), contains('not connected'));
      expect(disconnectedReply.text, contains('AF7'));
      expect(disconnectedReply.recommendedResource, isNull);

      final now = DateTime(2026, 10, 24, 12, 0, 0);
      final staleTelemetry = SignalReading(
        timestamp: now.subtract(const Duration(seconds: 90)),
        mindState: MindState.calm,
        alpha: 20.0,
        beta: 10.0,
        theta: 8.0,
        delta: 25.0,
        gamma: 3.0,
      );
      final staleReply = await AiWellnessService.getResponse(
        'Analyze my current brainwaves',
        const [],
        isConnected: true,
        currentTelemetry: staleTelemetry,
        now: now,
      );
      expect(staleReply.text.toLowerCase(), contains('more than 30 seconds old'));
      expect(staleReply.text, isNot(contains('20.0 µV')));
    });

    test('8. Fresh connected telemetry is reported cautiously on telemetry questions and omitted on unrelated questions', () async {
      final now = DateTime(2026, 10, 24, 12, 0, 0);
      final freshTelemetry = SignalReading(
        timestamp: now.subtract(const Duration(seconds: 5)),
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

      final bioReply = await AiWellnessService.getResponse(
        'Analyze my current brainwaves and mind state',
        const [],
        currentTelemetry: freshTelemetry,
        isConnected: true,
        now: now,
      );
      expect(bioReply.text, contains('ACTIVE'));
      expect(bioReply.text, contains('11.2 µV'));
      expect(bioReply.text, contains('22.8 µV'));
      expect(bioReply.text, contains('86 BPM'));
      expect(bioReply.text, contains('29.4 ms'));
      expect(bioReply.text.toLowerCase(), contains('heuristic'));

      // Unrelated question must NOT inject the live biometric numbers.
      final unrelatedReply = await AiWellnessService.getResponse(
        'What is behavioural activation?',
        const [],
        currentTelemetry: freshTelemetry,
        isConnected: true,
        now: now,
      );
      expect(unrelatedReply.text, isNot(contains('22.8 µV')));
      expect(unrelatedReply.text, isNot(contains('86 BPM')));
    });

    test('9. App feature & privacy questions answer from actual NeuroShift design without inventing features', () async {
      final reply = await AiWellnessService.getResponse(
        'What happens if I delete my recording?',
        const [],
      );
      expect(reply.responseMode, equals(NovaResponseMode.offlineKnowledge));
      expect(reply.text.toLowerCase(), contains('audio-recording feature'));
      expect(reply.text.toLowerCase(), contains('session'));
      expect(reply.recommendedResource, isNull);
    });

    test('10. Online Gemini integration sends header key, bounded non-duplicated history, and returns model text', () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;
      Map<String, dynamic>? capturedBody;

      Future<GeminiHttpResponse> mockTransport(
        Uri uri,
        Map<String, String> headers,
        String body,
      ) async {
        capturedUri = uri;
        capturedHeaders = headers;
        capturedBody = jsonDecode(body) as Map<String, dynamic>;
        return GeminiHttpResponse(
          200,
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text':
                          'Heart-rate variability (HRV) measures the natural millisecond changes between heartbeats.'
                    }
                  ]
                }
              }
            ]
          }),
        );
      }

      final history = <AiChatMessage>[
        AiChatMessage(
          id: 'welcome',
          text: 'Hello, I am Nova',
          isUser: false,
          timestamp: DateTime(2026, 10, 24, 9, 0),
        ),
        AiChatMessage(
          id: 'u1',
          text: 'I want to learn about my heart metrics.',
          isUser: true,
          timestamp: DateTime(2026, 10, 24, 9, 1),
          responseMode: NovaResponseMode.user,
        ),
        AiChatMessage(
          id: 'a1',
          text: 'Sure, what would you like to know?',
          isUser: false,
          timestamp: DateTime(2026, 10, 24, 9, 2),
          responseMode: NovaResponseMode.gemini,
        ),
        // Caller (AiWellnessChatScreen) appends current user message before calling getResponse:
        AiChatMessage(
          id: 'u2',
          text: 'What is HRV?',
          isUser: true,
          timestamp: DateTime(2026, 10, 24, 9, 3),
          responseMode: NovaResponseMode.user,
        ),
      ];

      final reply = await AiWellnessService.getResponse(
        'What is HRV?',
        history,
        apiKeyOverride: 'test-gemini-key',
        transport: mockTransport,
      );

      expect(reply.responseMode, equals(NovaResponseMode.gemini));
      expect(
        reply.text,
        equals(
          'Heart-rate variability (HRV) measures the natural millisecond changes between heartbeats.',
        ),
      );
      expect(reply.sourceReferences, isNotEmpty);
      expect(reply.recommendedResource, isNull);

      // Verify security: API key is sent in header, NOT in URL query parameters.
      expect(capturedUri!.queryParameters.containsKey('key'), isFalse);
      expect(capturedHeaders!['x-goog-api-key'], equals('test-gemini-key'));

      // Verify system_instruction & contents structure without duplicate current user turn.
      expect(capturedBody!['system_instruction'], isNotNull);
      final contents = capturedBody!['contents'] as List;
      expect(contents.length, equals(3)); // u1 -> a1 -> u2 (with RAG evidence)
      expect(contents[0]['role'], equals('user'));
      expect(contents[1]['role'], equals('model'));
      expect(contents[2]['role'], equals('user'));
      final finalTurnText =
          ((contents[2]['parts'] as List).first as Map)['text'] as String;
      expect(finalTurnText, contains('USER MESSAGE:\nWhat is HRV?'));
      expect(finalTurnText, contains('[hrv_basics]'));
      expect(finalTurnText, isNot(contains('LIVE TELEMETRY CONTEXT')));
    });

    test('11. Backend proxy mode sends Authorization Bearer token without exposing a client Gemini key', () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;

      Future<GeminiHttpResponse> mockProxyTransport(
        Uri uri,
        Map<String, String> headers,
        String body,
      ) async {
        capturedUri = uri;
        capturedHeaders = headers;
        return GeminiHttpResponse(
          200,
          jsonEncode({'reply': 'Proxied response from backend.'}),
        );
      }

      final reply = await AiWellnessService.getResponse(
        'What is HRV?',
        const [],
        proxyUrlOverride: 'https://api.neuroshift.example/v1/nova',
        authToken: 'firebase-jwt-token',
        transport: mockProxyTransport,
      );

      expect(reply.responseMode, equals(NovaResponseMode.gemini));
      expect(reply.text, equals('Proxied response from backend.'));
      expect(capturedUri.toString(), equals('https://api.neuroshift.example/v1/nova'));
      expect(capturedHeaders!['Authorization'], equals('Bearer firebase-jwt-token'));
      expect(capturedHeaders!.containsKey('x-goog-api-key'), isFalse);
    });

    test('12. Handles timeouts, rate limits (429), malformed JSON, and network errors honestly via offlineFallback', () async {
      final timeoutReply = await AiWellnessService.getResponse(
        'What is HRV?',
        const [],
        apiKeyOverride: 'test-key',
        transport: (uri, headers, body) => Future.error(TimeoutException('Timed out')),
      );
      expect(timeoutReply.responseMode, equals(NovaResponseMode.offlineFallback));
      expect(timeoutReply.fallbackReason, contains('timed out'));

      final rateLimitReply = await AiWellnessService.getResponse(
        'What is HRV?',
        const [],
        apiKeyOverride: 'test-key',
        transport: (uri, headers, body) async =>
            const GeminiHttpResponse(429, '{"error":"quota"}'),
      );
      expect(rateLimitReply.responseMode, equals(NovaResponseMode.offlineFallback));
      expect(rateLimitReply.fallbackReason, contains('rate limit'));

      final malformedReply = await AiWellnessService.getResponse(
        'What is HRV?',
        const [],
        apiKeyOverride: 'test-key',
        transport: (uri, headers, body) async =>
            const GeminiHttpResponse(200, 'not-valid-json{{{'),
      );
      expect(malformedReply.responseMode, equals(NovaResponseMode.offlineFallback));
      expect(malformedReply.fallbackReason, contains('malformed JSON'));

      final socketErrorReply = await AiWellnessService.getResponse(
        'What is HRV?',
        const [],
        apiKeyOverride: 'test-key',
        transport: (uri, headers, body) =>
            Future.error(const SocketException('No internet')),
      );
      expect(socketErrorReply.responseMode, equals(NovaResponseMode.offlineFallback));
      expect(socketErrorReply.fallbackReason, contains('network connection'));
    });

    test('13. Unsupported medication/diagnosis questions and out-of-scope trivia admit limitations without resource cards', () async {
      final medReply = await AiWellnessService.getResponse(
        'Should I increase my sertraline dose to 100mg?',
        const [],
      );
      expect(medReply.responseMode, equals(NovaResponseMode.offlineFallback));
      expect(medReply.recommendedResource, isNull);
      expect(medReply.text.toLowerCase(), contains('medical'));
      expect(medReply.text.toLowerCase(), anyOf(contains('physician'), contains('pharmacist')));

      final triviaReply = await AiWellnessService.getResponse(
        'What is the capital of France?',
        const [],
      );
      expect(triviaReply.responseMode, equals(NovaResponseMode.offlineFallback));
      expect(triviaReply.recommendedResource, isNull);
      expect(triviaReply.text.toLowerCase(), contains('reference notes'));
    });

    test('14. Crisis & safety screening handles direct, imminent, indirect, follow-up, negated, false-positive, and regional cases', () async {
      // Direct high risk (US locale)
      final directUs = await AiWellnessService.getResponse(
        'I want to hurt myself',
        const [],
        countryCode: 'US',
      );
      expect(directUs.responseMode, equals(NovaResponseMode.safetyProtocol));
      expect(directUs.safetyStatus, equals(SafetyStatus.high));
      expect(directUs.recommendedResource, isNull);
      expect(directUs.text, contains('988'));
      expect(directUs.text, contains('911'));

      // Direct high risk (UK locale)
      final directGb = await AiWellnessService.getResponse(
        'I want to kill myself',
        const [],
        countryCode: 'GB',
      );
      expect(directGb.safetyStatus, equals(SafetyStatus.high));
      expect(directGb.text, contains('999'));
      expect(directGb.text, contains('116 123'));

      // Unknown / international locale does not pretend 988 works everywhere
      final directIntl = await AiWellnessService.getResponse(
        'I want to end my life right now',
        const [],
        countryCode: 'KE',
      );
      expect(directIntl.safetyStatus, equals(SafetyStatus.imminent));
      expect(directIntl.text, contains('local emergency number'));
      expect(directIntl.text, contains('findahelpline.com'));

      // Indirect / ambiguous distress asks a direct, compassionate safety question
      final indirect = await AiWellnessService.getResponse(
        'I just cannot do this anymore, everyone would be better off without me',
        const [],
      );
      expect(indirect.responseMode, equals(NovaResponseMode.safetyProtocol));
      expect(indirect.safetyStatus, equals(SafetyStatus.ambiguous));
      expect(indirect.text.toLowerCase(), contains('thoughts of ending your life'));

      // Affirmative follow-up to ambiguous safety check escalates to high risk
      final followUpEscalated = await AiWellnessService.getResponse(
        'Yes, I am',
        [indirect],
        countryCode: 'US',
      );
      expect(followUpEscalated.safetyStatus, equals(SafetyStatus.high));
      expect(followUpEscalated.text, contains('988'));

      // Negated statement does NOT trigger crisis protocol
      final negated = await AiWellnessService.getResponse(
        "I'm not suicidal and I don't want to hurt myself, I'm just really tired today",
        const [],
      );
      expect(negated.safetyStatus, equals(SafetyStatus.none));
      expect(negated.responseMode, isNot(equals(NovaResponseMode.safetyProtocol)));

      // Substring regression ("studied" / "diet" must NEVER match "die")
      final dietQuery = await AiWellnessService.getResponse(
        'I studied hard for my diet exam and feel stressed',
        const [],
      );
      expect(dietQuery.safetyStatus, equals(SafetyStatus.none));
      expect(dietQuery.responseMode, isNot(equals(NovaResponseMode.safetyProtocol)));
    });
  });
}
