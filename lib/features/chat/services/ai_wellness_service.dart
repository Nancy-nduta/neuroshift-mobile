import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import '../../../models/signal_reading.dart';
import '../../resources/models/resource_item.dart';
import '../data/clinical_knowledge_base.dart';
import '../models/ai_chat_message.dart';
import 'crisis_detector.dart';
import 'intent_classifier.dart';
import 'rag_retrieval_service.dart';

/// Lightweight HTTP response container so [AiWellnessService] can use either
/// `dart:io` [HttpClient] in production or an injected mock in unit tests.
class GeminiHttpResponse {
  final int statusCode;
  final String body;

  const GeminiHttpResponse(this.statusCode, this.body);
}

/// Signature for pluggable HTTP transport used by [AiWellnessService].
typedef GeminiTransport = Future<GeminiHttpResponse> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

class _GeminiCallOutcome {
  final String? text;
  final String? errorReason;

  const _GeminiCallOutcome({this.text, this.errorReason});
}

class AiWellnessService {
  static const String _defaultModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3-flash-preview',
  );

  static const List<String> _fallbackModels = [
    'gemini-3-flash-preview',
    'gemini-3.8-flash',
    'gemini-flash-latest',
    'gemini-3.1-flash-lite',
    'gemini-flash-lite-latest',
  ];

  static const Duration requestTimeout = Duration(seconds: 12);
  static const Duration maxTelemetryAge = Duration(seconds: 30);
  static const int maxHistoryMessages = 8;

  static const CrisisDetector _crisisDetector = CrisisDetector();
  static const IntentClassifier _intentClassifier = IntentClassifier();
  static String? _cachedDotEnvApiKey;

  static Future<String> _resolveRuntimeApiKey(String? apiKeyOverride) async {
    if (apiKeyOverride != null) return apiKeyOverride.trim();
    const envApiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envApiKey.isNotEmpty) return envApiKey.trim();

    // Keep unit and widget tests deterministic unless apiKeyOverride is passed.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return '';
    }

    if (_cachedDotEnvApiKey != null) return _cachedDotEnvApiKey!;
    try {
      final dotEnvContent = await rootBundle.loadString('.env');
      for (final rawLine in const LineSplitter().convert(dotEnvContent)) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        if (line.startsWith('GEMINI_API_KEY=')) {
          final value = line.substring('GEMINI_API_KEY='.length).trim();
          _cachedDotEnvApiKey = value;
          return value;
        }
      }
    } catch (_) {
      // .env asset not present; remain in offline mode.
    }
    _cachedDotEnvApiKey = '';
    return '';
  }

  /// Configurable system instruction establishing Nova's role, tone,
  /// evidence rules, telemetry caution, and clinical boundaries.
  static const String defaultSystemInstruction = '''
You are Nova, the deeply empathetic, evidence-informed biofeedback therapist and emotional wellness guide inside the NeuroShift mobile app.

ROLE & THERAPEUTIC PURPOSE:
- Act as a compassionate, supportive, and insightful biofeedback therapist. The user relies on you to feel heard, understood, calm, and grounded, especially when a human therapist is not immediately available.
- Respond directly and warmly to what the user says with genuine therapeutic presence.
- When a user shares a difficult emotion, anxiety, or hard day, acknowledge their feelings in plain language, validate their experience, and ask ONE gentle, relevant follow-up question.

BIOMETRIC & BRAINWAVE INTERPRETATION:
- When LIVE TELEMETRY CONTEXT is provided, you must actively interpret and synthesize their real-time numbers into a clear, therapeutic reflection:
  • Frontal Alpha (8–13 Hz) vs. Beta (13–30 Hz): Explain what their ratio means. Alpha dominance reflects a relaxed "flow state", parasympathetic restoration, and mental spaciousness. Beta elevation reflects active analytical thinking, mental chatter, tension, or vigilance.
  • Heart Rate (PPG) & HRV (RMSSD): Explain how RMSSD reflects their vagal tone and parasympathetic nervous system (the body's natural brake on stress and fight-or-flight). Higher HRV indicates resilient recovery; lower HRV suggests sympathetic arousal.
  • Frontal Theta (4–8 Hz) & Delta (0.5–4 Hz): Reflect on internal calm, mindfulness, or sensory stillness.
- Connect their brainwaves and heart rhythm to how they feel physically and mentally right now, and draw a solid, compassionate conclusion so they understand what is happening inside their body.
- Offer an empathetic, therapeutic next step (such as a grounding breath, relaxing shoulders, or an inviting question) so they feel safe, supported, and cared for.
- If the headband is disconnected, explain what their baseline biometrics indicate, and ask how they are feeling right now so you can support them as their personal wellness guide.

EVIDENCE & HONESTY:
- Ground wellness, EEG, HRV, and NeuroShift app answers in the provided REFERENCE EVIDENCE when present.
- Distinguish established clinical guidance from small studies or general practice.
- Never invent clinical diagnoses or prescribe medication. You are an AI wellness guide and therapeutic companion.
''';

  /// Main entry point for generating a Nova reply.
  static Future<AiChatMessage> getResponse(
    String userPrompt,
    List<AiChatMessage> history, {
    SignalReading? currentTelemetry,
    bool isConnected = false,
    String? apiKeyOverride,
    String? proxyUrlOverride,
    String? authToken,
    String? countryCode,
    GeminiTransport? transport,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final trimmed = userPrompt.trim();

    // Extract prior conversation context (ignoring the current user message if
    // the caller already appended it to `history`, and ignoring the static
    // welcome banner when looking at conversational continuity).
    final priorHistory = _extractPriorHistory(history, trimmed);
    final lastAssistant = _lastAssistantMessage(priorHistory);
    final lastUser = _lastUserMessage(priorHistory);

    // -------------------------------------------------------------------------
    // 1. DETERMINISTIC SAFETY / CRISIS CHECK (Always runs first)
    // -------------------------------------------------------------------------
    final previousSafety = lastAssistant?.safetyStatus ?? SafetyStatus.none;
    final safety = _crisisDetector.assess(
      trimmed,
      previousAssistantStatus: previousSafety,
    );

    if (safety.needsProtocol) {
      final replyText = CrisisResponses.build(
        safety.status,
        countryCode: countryCode,
        followUp: previousSafety != SafetyStatus.none,
      );
      return AiChatMessage(
        id: 'crisis_${timestamp.millisecondsSinceEpoch}',
        text: replyText,
        isUser: false,
        timestamp: timestamp,
        responseMode: NovaResponseMode.safetyProtocol,
        safetyStatus: safety.status,
        suggestedChips: safety.status == SafetyStatus.ambiguous
            ? const [
                'I am safe, just overwhelmed',
                'Yes, I am having dark thoughts',
                'Show crisis helplines',
              ]
            : const [
                'I am safe right now',
                'How can I reach a helpline?',
              ],
      );
    }

    // -------------------------------------------------------------------------
    // 2. INTENT CLASSIFICATION
    // -------------------------------------------------------------------------
    final intent = _intentClassifier.classify(
      trimmed,
      previousAssistantText: lastAssistant?.text,
    );

    // Handle greetings and thanks/farewells deterministically without RAG or
    // resource cards so "Hi Nova" is always fast, natural, and uncluttered.
    if (intent == NovaIntent.greeting) {
      return _buildGreetingReply(trimmed, timestamp);
    }
    if (intent == NovaIntent.thanksOrFarewell) {
      return _buildThanksOrFarewellReply(trimmed, timestamp);
    }

    // -------------------------------------------------------------------------
    // 3. CONDITIONAL RAG RETRIEVAL (With Multi-Turn Context Fallback)
    // -------------------------------------------------------------------------
    final ragResult = _retrieveForIntent(
      intent: intent,
      userPrompt: trimmed,
      previousUserPrompt: lastUser?.text,
      previousAssistantText: lastAssistant?.text,
    );

    // -------------------------------------------------------------------------
    // 4. CONDITIONAL BIOMETRIC TELEMETRY EVALUATION
    // -------------------------------------------------------------------------
    final telemetryFresh = isConnected &&
        currentTelemetry != null &&
        timestamp.difference(currentTelemetry.timestamp).abs() <= maxTelemetryAge;

    final includeTelemetry = intent == NovaIntent.telemetryQuestion;

    // If the user explicitly asks about their live readings while the headband
    // is disconnected or stale, we can still use Gemini (if configured) with
    // explicit instructions that the headband is offline, or answer directly.
    final telemetryPromptContext = includeTelemetry
        ? _formatBiometricContext(
            currentTelemetry,
            isConnected: isConnected,
            isFresh: telemetryFresh,
          )
        : null;

    // -------------------------------------------------------------------------
    // 5. SEPARATE OPTIONAL RESOURCE SELECTION
    // -------------------------------------------------------------------------
    final recommendedResource = _selectResourceIfAppropriate(
      intent: intent,
      userPrompt: trimmed,
      ragResult: ragResult,
    );

    final sources = <KnowledgeSource>[
      for (final hit in ragResult.hits) ...hit.chunk.sources,
    ];
    final deduplicatedSources = _deduplicateSources(sources);

    // -------------------------------------------------------------------------
    // 6. ONLINE GEMINI / PROXY GENERATION (When Configured)
    // -------------------------------------------------------------------------
    const envProxyUrl = String.fromEnvironment('NOVA_PROXY_URL');
    final resolvedApiKey = await _resolveRuntimeApiKey(apiKeyOverride);
    final resolvedProxyUrl = (proxyUrlOverride ?? envProxyUrl).trim();
    final hasOnlineConfig =
        resolvedApiKey.isNotEmpty || resolvedProxyUrl.isNotEmpty;

    String? fallbackReason;
    if (hasOnlineConfig) {
      final outcome = await _queryOnlineModel(
        apiKey: resolvedApiKey,
        proxyUrl: resolvedProxyUrl,
        authToken: authToken,
        userPrompt: trimmed,
        priorHistory: priorHistory,
        intent: intent,
        ragResult: ragResult,
        telemetryContext: telemetryPromptContext,
        transport: transport,
      );

      if (outcome.text != null && outcome.text!.trim().isNotEmpty) {
        return AiChatMessage(
          id: 'ai_${timestamp.millisecondsSinceEpoch}',
          text: outcome.text!.trim(),
          isUser: false,
          timestamp: timestamp,
          responseMode: NovaResponseMode.gemini,
          sourceReferences: deduplicatedSources,
          recommendedResource: recommendedResource,
          suggestedChips: _suggestedChipsFor(intent, ragResult),
        );
      }
      fallbackReason = outcome.errorReason ??
          'Online AI generation was unavailable — showing offline reply.';
    }

    // -------------------------------------------------------------------------
    // 7. HONEST OFFLINE SYNTHESIS & CONVERSATIONAL FALLBACK
    // -------------------------------------------------------------------------
    return _buildOfflineResponse(
      userPrompt: trimmed,
      intent: intent,
      ragResult: ragResult,
      priorHistory: priorHistory,
      currentTelemetry: currentTelemetry,
      isConnected: isConnected,
      telemetryFresh: telemetryFresh,
      recommendedResource: recommendedResource,
      sources: deduplicatedSources,
      fallbackReason: fallbackReason,
      timestamp: timestamp,
    );
  }

  // ===========================================================================
  // DETERMINISTIC GREETINGS & FAREWELLS
  // ===========================================================================

  static AiChatMessage _buildGreetingReply(String userPrompt, DateTime timestamp) {
    final isHowAreYou = IntentClassifier.isHowAreYou(userPrompt);
    final text = isHowAreYou
        ? "I'm doing well, thank you for asking! I'm here and ready to listen. How are things going with you today?"
        : "Hi there! I'm Nova. How are you feeling today, or what's on your mind?";

    return AiChatMessage(
      id: 'ai_${timestamp.millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: timestamp,
      responseMode: NovaResponseMode.deterministic,
      suggestedChips: const [
        "I've had a stressful day",
        'What is HRV?',
        'Guide me through breathing',
        'How does NeuroShift work?',
      ],
    );
  }

  static AiChatMessage _buildThanksOrFarewellReply(
    String userPrompt,
    DateTime timestamp,
  ) {
    final isFarewell = IntentClassifier.isFarewell(userPrompt);
    final text = isFarewell
        ? 'Take good care of yourself. I am here whenever you want to check in or talk again.'
        : "You're very welcome. Let me know if you'd like to keep talking or explore anything else.";

    return AiChatMessage(
      id: 'ai_${timestamp.millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: timestamp,
      responseMode: NovaResponseMode.deterministic,
      suggestedChips: const [
        'Guide me through a quick reset',
        'Explain my brainwaves',
      ],
    );
  }

  // ===========================================================================
  // CONDITIONAL RAG RETRIEVAL
  // ===========================================================================

  static RagRetrievalResult _retrieveForIntent({
    required NovaIntent intent,
    required String userPrompt,
    String? previousUserPrompt,
    String? previousAssistantText,
  }) {
    if (intent == NovaIntent.greeting || intent == NovaIntent.thanksOrFarewell) {
      return RagRetrievalResult.empty;
    }

    if (intent == NovaIntent.appQuestion) {
      final appHits = RagRetrievalService.retrieve(
        userPrompt,
        categories: const {'app', 'support'},
      );
      if (appHits.hasEvidence) return appHits;
    }

    var primary = RagRetrievalService.retrieve(userPrompt);
    if (primary.hasEvidence) return primary;

    // Multi-turn retrieval fallback: if the user sends a short follow-up like
    // "Yes please" or "I'm scared I'll forget everything", combine with the
    // previous turn so topical evidence can still be retrieved when appropriate.
    if (previousUserPrompt != null && previousUserPrompt.isNotEmpty) {
      final combined = RagRetrievalService.retrieve('$previousUserPrompt $userPrompt');
      if (combined.hasEvidence) return combined;
    }
    if (intent == NovaIntent.exerciseRequest &&
        previousAssistantText != null &&
        previousAssistantText.isNotEmpty) {
      final fromOffer = RagRetrievalService.retrieve(previousAssistantText);
      if (fromOffer.hasEvidence) return fromOffer;
    }

    return RagRetrievalResult.empty;
  }

  // ===========================================================================
  // RESOURCE SELECTION (Decoupled from Conversation Answer)
  // ===========================================================================

  static ResourceItem? _selectResourceIfAppropriate({
    required NovaIntent intent,
    required String userPrompt,
    required RagRetrievalResult ragResult,
  }) {
    final wantsExercise = intent == NovaIntent.exerciseRequest;
    final wantsAudio = IntentClassifier.asksForAudio(userPrompt);
    final acuteStress = IntentClassifier.isAcuteStress(userPrompt);

    if (!wantsExercise && !wantsAudio && !acuteStress) {
      return null;
    }

    final resourceId = ragResult.top?.recommendedResourceId ??
        (acuteStress ? 'med_03' : (wantsExercise ? 'med_03' : null));
    if (resourceId == null) return null;

    for (final item in ResourceItem.catalog) {
      if (item.id == resourceId) return item;
    }
    return null;
  }

  // ===========================================================================
  // TELEMETRY FORMATTING
  // ===========================================================================

  static String _formatBiometricContext(
    SignalReading? telemetry, {
    required bool isConnected,
    required bool isFresh,
  }) {
    if (!isConnected || telemetry == null) {
      return 'Headband Status: Disconnected (no live EEG or PPG data is available).';
    }
    if (!isFresh) {
      return 'Headband Status: Connected, but the last reading is stale (>30s old). Ask the user to check headband fit before interpreting live numbers.';
    }

    final stateStr = telemetry.mindState.name.toUpperCase();
    final bpmStr = (telemetry.heartRateBpm != null && telemetry.heartRateBpm! > 0)
        ? '${telemetry.heartRateBpm} BPM'
        : 'Measuring pulse...';
    final hrvStr = (telemetry.hrvRmssd != null && telemetry.hrvRmssd! > 0)
        ? '${telemetry.hrvRmssd!.toStringAsFixed(1)} ms'
        : 'Measuring HRV...';
    final alphaRatio = telemetry.alpha / (telemetry.beta + 0.0001);

    return 'LIVE BIOMETRIC TELEMETRY CONTEXT (Streamed live from Muse 2 sensors):\n'
        '• Current MindState Pattern: $stateStr (Alpha/Beta ratio: ${alphaRatio.toStringAsFixed(2)})\n'
        '• Frontal Alpha (8–13 Hz): ${telemetry.alpha.toStringAsFixed(1)} µV (Reflects mental calm, restorative flow, spacious awareness)\n'
        '• Frontal Beta (13–30 Hz): ${telemetry.beta.toStringAsFixed(1)} µV (Reflects active thinking, analytical focus, mental chatter, or tension)\n'
        '• Frontal Theta (4–8 Hz): ${telemetry.theta.toStringAsFixed(1)} µV (Reflects deep relaxation, meditation, memory consolidation)\n'
        '• Frontal Delta (0.5–4 Hz): ${telemetry.delta.toStringAsFixed(1)} µV (Slow-wave rest; also influenced by natural ocular blinks)\n'
        '• Heart Rate (PPG): $bpmStr\n'
        '• Heart Rate Variability (HRV RMSSD): $hrvStr (Vagal tone indicator; higher indicates parasympathetic rest & digest activation)\n'
        '• Physical Stillness: ${telemetry.stillnessScore.toStringAsFixed(0)}%\n\n'
        'THERAPEUTIC INSTRUCTION FOR NOVA:\n'
        'As the user\'s personal biofeedback therapist, analyze what these specific real-time brainwave and heart values reveal about their internal mental and emotional state. '
        'Connect their Alpha/Beta balance and HRV vagal tone to how they feel, draw a solid and comforting conclusion, and offer gentle therapeutic next steps so they feel safe and cared for.';
  }

  // ===========================================================================
  // ONLINE GEMINI / BACKEND PROXY REQUEST PIPELINE
  // ===========================================================================

  static Future<_GeminiCallOutcome> _queryOnlineModel({
    required String apiKey,
    required String proxyUrl,
    required String? authToken,
    required String userPrompt,
    required List<AiChatMessage> priorHistory,
    required NovaIntent intent,
    required RagRetrievalResult ragResult,
    required String? telemetryContext,
    GeminiTransport? transport,
  }) async {
    final useProxy = proxyUrl.isNotEmpty;
    final Uri uri;
    try {
      uri = useProxy
          ? Uri.parse(proxyUrl)
          : Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent',
            );
    } catch (_) {
      return const _GeminiCallOutcome(
        errorReason: 'Invalid AI endpoint configuration — showing offline reply.',
      );
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (!useProxy && apiKey.isNotEmpty) 'x-goog-api-key': apiKey,
      if (useProxy && authToken != null && authToken.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final payload = _buildGeminiPayload(
      userPrompt: userPrompt,
      priorHistory: priorHistory,
      intent: intent,
      ragResult: ragResult,
      telemetryContext: telemetryContext,
    );

    final send = transport ?? _defaultHttpTransport;
    final encodedPayload = jsonEncode(payload);
    try {
      var response = await send(uri, headers, encodedPayload)
          .timeout(requestTimeout);

      // If calling Google's Gemini endpoint directly in production and a model
      // experiences temporary 503 demand spikes or 404 retirement, try the
      // verified backup Flash models automatically.
      if (!useProxy &&
          transport == null &&
          (response.statusCode == 503 || response.statusCode == 404)) {
        for (final backupModel in _fallbackModels) {
          if (backupModel == _defaultModel) continue;
          final backupUri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$backupModel:generateContent',
          );
          response = await send(backupUri, headers, encodedPayload)
              .timeout(requestTimeout);
          if (response.statusCode == 200) break;
        }
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          // Support both standard Gemini generateContent format and a simple
          // `{ "reply": "..." }` proxy response format.
          final directReply = decoded['reply'];
          if (directReply is String && directReply.trim().isNotEmpty) {
            return _GeminiCallOutcome(text: directReply.trim());
          }
          final candidates = decoded['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final first = candidates.first;
            if (first is Map<String, dynamic>) {
              final content = first['content'];
              if (content is Map<String, dynamic>) {
                final parts = content['parts'];
                if (parts is List && parts.isNotEmpty) {
                  final buffer = StringBuffer();
                  for (final part in parts) {
                    if (part is Map<String, dynamic> && part['text'] is String) {
                      buffer.write(part['text'] as String);
                    }
                  }
                  final combined = buffer.toString().trim();
                  if (combined.isNotEmpty) {
                    return _GeminiCallOutcome(text: combined);
                  }
                }
              }
            }
          }
        }
        return const _GeminiCallOutcome(
          errorReason:
              'Online AI returned an empty or unreadable response — showing offline reply.',
        );
      }

      if (response.statusCode == 429) {
        return const _GeminiCallOutcome(
          errorReason: 'Online AI rate limit reached — showing offline reply.',
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const _GeminiCallOutcome(
          errorReason:
              'Online AI authentication was rejected — showing offline reply.',
        );
      }
      return _GeminiCallOutcome(
        errorReason:
            'Online AI service returned HTTP ${response.statusCode} — showing offline reply.',
      );
    } on TimeoutException {
      return const _GeminiCallOutcome(
        errorReason: 'Online AI request timed out — showing offline reply.',
      );
    } on FormatException {
      return const _GeminiCallOutcome(
        errorReason:
            'Online AI returned malformed JSON — showing offline reply.',
      );
    } on SocketException {
      return const _GeminiCallOutcome(
        errorReason: 'No network connection to AI service — showing offline reply.',
      );
    } catch (_) {
      return const _GeminiCallOutcome(
        errorReason: 'Online AI service was unreachable — showing offline reply.',
      );
    }
  }

  /// Exposed for unit testing to verify exact request structure, history
  /// bounding, role alternation, evidence grounding, and telemetry gating.
  static Map<String, dynamic> buildRequestPayloadForTest({
    required String userPrompt,
    required List<AiChatMessage> priorHistory,
    required NovaIntent intent,
    required RagRetrievalResult ragResult,
    String? telemetryContext,
  }) {
    return _buildGeminiPayload(
      userPrompt: userPrompt,
      priorHistory: priorHistory,
      intent: intent,
      ragResult: ragResult,
      telemetryContext: telemetryContext,
    );
  }

  static Map<String, dynamic> _buildGeminiPayload({
    required String userPrompt,
    required List<AiChatMessage> priorHistory,
    required NovaIntent intent,
    required RagRetrievalResult ragResult,
    required String? telemetryContext,
  }) {
    final contents = <Map<String, dynamic>>[];

    // Bound conversation history to the most recent turns.
    final bounded = priorHistory.length > maxHistoryMessages
        ? priorHistory.sublist(priorHistory.length - maxHistoryMessages)
        : priorHistory;

    for (final msg in bounded) {
      final role = msg.isUser ? 'user' : 'model';
      final text = msg.text.trim();
      if (text.isEmpty) continue;

      // Merge consecutive turns of the same role to satisfy Gemini's strict
      // alternating turn requirement.
      if (contents.isNotEmpty && contents.last['role'] == role) {
        final prevParts = contents.last['parts'] as List<Map<String, dynamic>>;
        final prevText = prevParts.first['text'] as String;
        prevParts.first['text'] = '$prevText\n$text';
      } else {
        contents.add({
          'role': role,
          'parts': <Map<String, dynamic>>[
            {'text': text},
          ],
        });
      }
    }

    // Gemini requires the first turn in `contents` to have role == 'user'.
    while (contents.isNotEmpty && contents.first['role'] != 'user') {
      contents.removeAt(0);
    }

    // Build the current user turn with clearly separated context blocks.
    final turnBuffer = StringBuffer();
    turnBuffer.writeln('USER MESSAGE:\n$userPrompt');
    turnBuffer.writeln('\nDETECTED INTENT: ${intent.name}');

    if (ragResult.hasEvidence) {
      turnBuffer.writeln('\nREFERENCE EVIDENCE (Ground factual claims here):');
      for (final hit in ragResult.hits) {
        final c = hit.chunk;
        turnBuffer.writeln(
          '- [${c.id}] ${c.title} (Evidence: ${c.evidence.name}, Reviewed: ${c.reviewedOn})',
        );
        turnBuffer.writeln('  Summary: ${c.summary}');
        if (c.keyPoints.isNotEmpty) {
          turnBuffer.writeln('  Key Points: ${c.keyPoints.join(' | ')}');
        }
        turnBuffer.writeln('  Limitations: ${c.limitations}');
        if (c.safetyNotes != null) {
          turnBuffer.writeln('  Safety Note: ${c.safetyNotes}');
        }
      }
    } else {
      turnBuffer.writeln(
        '\nREFERENCE EVIDENCE: None matched in the local clinical/app knowledge base. '
        'If the user is sharing feelings, respond empathetically and ask one gentle follow-up question. '
        'If the user is asking for unverified medical/clinical facts, state your limitations honestly.',
      );
    }

    if (telemetryContext != null) {
      turnBuffer.writeln('\nLIVE TELEMETRY CONTEXT:\n$telemetryContext');
    }

    final currentTurnText = turnBuffer.toString().trim();
    if (contents.isNotEmpty && contents.last['role'] == 'user') {
      final prevParts = contents.last['parts'] as List<Map<String, dynamic>>;
      final prevText = prevParts.first['text'] as String;
      prevParts.first['text'] = '$prevText\n\n$currentTurnText';
    } else {
      contents.add({
        'role': 'user',
        'parts': <Map<String, dynamic>>[
          {'text': currentTurnText},
        ],
      });
    }

    return {
      'system_instruction': {
        'parts': [
          {'text': defaultSystemInstruction.trim()},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 1024,
        'thinkingConfig': {
          'thinkingBudget': 0,
        },
      },
    };
  }

  static Future<GeminiHttpResponse> _defaultHttpTransport(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = requestTimeout;
    try {
      final request = await client.postUrl(uri);
      headers.forEach(request.headers.set);
      request.add(utf8.encode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      return GeminiHttpResponse(response.statusCode, responseBody);
    } finally {
      client.close(force: true);
    }
  }

  // ===========================================================================
  // OFFLINE CONVERSATION & GROUNDED SYNTHESIS
  // ===========================================================================

  static AiChatMessage _buildOfflineResponse({
    required String userPrompt,
    required NovaIntent intent,
    required RagRetrievalResult ragResult,
    required List<AiChatMessage> priorHistory,
    required SignalReading? currentTelemetry,
    required bool isConnected,
    required bool telemetryFresh,
    required ResourceItem? recommendedResource,
    required List<KnowledgeSource> sources,
    required String? fallbackReason,
    required DateTime timestamp,
  }) {
    final effectiveFallbackReason = fallbackReason ??
        'Online AI is not configured in this build — using built-in offline guidance.';

    // 1. Live Telemetry Question
    if (intent == NovaIntent.telemetryQuestion) {
      final text = _buildTelemetryExplanation(
        userPrompt: userPrompt,
        telemetry: currentTelemetry,
        isConnected: isConnected,
        isFresh: telemetryFresh,
        ragResult: ragResult,
      );
      return AiChatMessage(
        id: 'ai_${timestamp.millisecondsSinceEpoch}',
        text: text,
        isUser: false,
        timestamp: timestamp,
        responseMode: fallbackReason != null
            ? NovaResponseMode.offlineFallback
            : NovaResponseMode.offlineKnowledge,
        fallbackReason: fallbackReason,
        sourceReferences: sources,
        recommendedResource: recommendedResource,
        suggestedChips: const [
          'Why is delta often high?',
          'What is HRV?',
          'Guide me through slow breathing',
        ],
      );
    }

    // 2. Empathetic Emotional Support (with Multi-Turn Continuity)
    if (intent == NovaIntent.emotionalSupport) {
      final text = _buildEmotionalSupportReply(
        userPrompt: userPrompt,
        priorHistory: priorHistory,
        ragResult: ragResult,
      );
      return AiChatMessage(
        id: 'ai_${timestamp.millisecondsSinceEpoch}',
        text: text,
        isUser: false,
        timestamp: timestamp,
        responseMode: NovaResponseMode.offlineFallback,
        fallbackReason: effectiveFallbackReason,
        sourceReferences: IntentClassifier.isAcuteStress(userPrompt) ? sources : const [],
        recommendedResource: recommendedResource,
        suggestedChips: IntentClassifier.isAcuteStress(userPrompt)
            ? const [
                'Walk me through 5-4-3-2-1 grounding',
                'Guide me through slow breathing',
                'I just want to talk about it',
              ]
            : const [
                'I want to talk more about what happened',
                'Help me slow down my racing thoughts',
                'Guide me through a calming exercise',
              ],
      );
    }

    // 3. Guided Exercise Request
    if (intent == NovaIntent.exerciseRequest) {
      final chunk = ragResult.top ??
          ClinicalKnowledgeBase.byId('slow_breathing') ??
          ClinicalKnowledgeBase.chunks.first;
      final buffer = StringBuffer();
      buffer.writeln(
        "Let's take this one step at a time together using **${chunk.title}**:\n",
      );
      buffer.writeln(chunk.summary);
      if (chunk.keyPoints.isNotEmpty) {
        buffer.writeln('\n**How to try it right now:**');
        for (final step in chunk.keyPoints) {
          buffer.writeln('• $step');
        }
      }
      if (chunk.safetyNotes != null) {
        buffer.writeln('\n*Note: ${chunk.safetyNotes}*');
      }
      return AiChatMessage(
        id: 'ai_${timestamp.millisecondsSinceEpoch}',
        text: buffer.toString().trim(),
        isUser: false,
        timestamp: timestamp,
        responseMode: fallbackReason != null
            ? NovaResponseMode.offlineFallback
            : NovaResponseMode.offlineKnowledge,
        fallbackReason: fallbackReason,
        sourceReferences: _deduplicateSources(chunk.sources),
        recommendedResource: recommendedResource,
        suggestedChips: chunk.followUpQuestions.isNotEmpty
            ? chunk.followUpQuestions
            : const ['How does slow breathing work?', 'Try 5-4-3-2-1 grounding'],
      );
    }

    // 4. Grounded App or Clinical/Wellness Question (when evidence exists)
    if (ragResult.hasEvidence) {
      final top = ragResult.top!;
      final buffer = StringBuffer();
      buffer.writeln(top.summary);
      if (top.keyPoints.isNotEmpty) {
        buffer.writeln('\n**Key points:**');
        for (final point in top.keyPoints) {
          buffer.writeln('• $point');
        }
      }
      if (top.limitations.isNotEmpty) {
        buffer.writeln('\n*Context & limitations: ${top.limitations}*');
      }
      if (top.safetyNotes != null) {
        buffer.writeln('\n*Safety note: ${top.safetyNotes}*');
      }

      return AiChatMessage(
        id: 'ai_${timestamp.millisecondsSinceEpoch}',
        text: buffer.toString().trim(),
        isUser: false,
        timestamp: timestamp,
        responseMode: fallbackReason != null
            ? NovaResponseMode.offlineFallback
            : NovaResponseMode.offlineKnowledge,
        fallbackReason: fallbackReason,
        sourceReferences: sources,
        recommendedResource: recommendedResource,
        suggestedChips: top.followUpQuestions.isNotEmpty
            ? top.followUpQuestions
            : _suggestedChipsFor(intent, ragResult),
      );
    }

    // 5. Out-of-scope, unverified clinical/medication question, or general query
    final text = _buildUncertainOrOutOfScopeReply(userPrompt, priorHistory);
    return AiChatMessage(
      id: 'ai_${timestamp.millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: timestamp,
      responseMode: NovaResponseMode.offlineFallback,
      fallbackReason: effectiveFallbackReason,
      suggestedChips: const [
        'What can Nova help with?',
        'What is HRV?',
        'Guide me through a breathing exercise',
      ],
    );
  }

  static String _buildTelemetryExplanation({
    required String userPrompt,
    required SignalReading? telemetry,
    required bool isConnected,
    required bool isFresh,
    required RagRetrievalResult ragResult,
  }) {
    final buffer = StringBuffer();
    if (!isConnected || telemetry == null) {
      buffer.writeln(
        'Your Muse 2 headband is not connected right now, so I do not have live EEG or heart-rate readings to display.',
      );
      buffer.writeln(
        '\nWhen you connect the headband, NeuroShift reads frontal EEG from the **AF7** sensor (Alpha `8–12 Hz` and Beta `13–30 Hz`) and pulse/HRV from the optical PPG sensor to estimate whether your current pattern looks **Calm**, **Neutral**, or **Active**.',
      );
      if (ragResult.top != null) {
        buffer.writeln('\n${ragResult.top!.summary}');
      }
      return buffer.toString().trim();
    }

    if (!isFresh) {
      buffer.writeln(
        'Your Muse 2 headband appears connected, but the latest reading is more than 30 seconds old, so I will not interpret stale numbers as your live state. Please check that the headband sensors are resting snugly against your forehead and ears.',
      );
      return buffer.toString().trim();
    }

    final stateName = telemetry.mindState.name.toUpperCase();
    final alpha = telemetry.alpha;
    final beta = telemetry.beta;
    final alphaRatio = alpha / (beta + 0.0001);
    final bpm = telemetry.heartRateBpm;
    final hrv = telemetry.hrvRmssd;

    buffer.writeln(
      'Here is what your Muse 2 real-time sensors reveal about your mind and body right now:\n',
    );
    buffer.writeln(
      '• **Current Mind State**: **$stateName** (heuristic pattern based on your frontal AF7 Alpha-to-Beta ratio).',
    );
    buffer.writeln(
      '• **Frontal Alpha (8–12 Hz)**: `${alpha.toStringAsFixed(1)} µV` — ${alphaRatio >= 1.15 ? "Strong alpha dominance indicates a restorative flow state with quiet mental chatter." : "Moderate alpha rhythm; your mind is awake and receptive."}',
    );
    buffer.writeln(
      '• **Frontal Beta (13–30 Hz)**: `${beta.toStringAsFixed(1)} µV` — ${beta >= alpha ? "Elevated beta suggests active cognitive processing, mental scanning, or subtle forehead tension." : "Low beta indicates minimal cognitive stress and calm focus."}',
    );
    if (bpm != null && bpm > 0) {
      buffer.writeln('• **Heart Rate (PPG)**: `$bpm BPM` (${bpm < 75 ? "calm, steady resting pulse" : "active cardiovascular rhythm"}).');
    }
    if (hrv != null && hrv > 0) {
      buffer.writeln(
        '• **Short-Window HRV (RMSSD)**: `${hrv.toStringAsFixed(1)} ms` (${hrv >= 45 ? "high vagal tone, reflecting active parasympathetic recovery" : "sympathetic readiness; gentle slow breaths can help settle this"}).',
      );
    }
    buffer.writeln(
      '• **Head Stillness**: `${telemetry.stillnessScore.toStringAsFixed(0)}%`.',
    );
    buffer.writeln(
      '\n**Therapeutic Synthesis**: ${alphaRatio >= 1.0 && (hrv == null || hrv >= 40) ? "Your nervous system is in a coherent, grounded state. Your mind has quieted down and your heart rhythm is settled." : "Your brain and heart show active focus or light tension. Let your shoulders drop away from your ears, unclench your jaw, and let's take a slow, gentle breath together."}',
    );
    buffer.writeln(
      '\n*Keep in mind: single-channel forehead EEG is sensitive to eye blinks and jaw clenching. Use these numbers as a gentle reflection alongside how you actually feel.*',
    );
    return buffer.toString().trim();
  }

  static String _buildEmotionalSupportReply({
    required String userPrompt,
    required List<AiChatMessage> priorHistory,
    required RagRetrievalResult ragResult,
  }) {
    final lower = userPrompt.toLowerCase();
    final lastUserText = _lastUserMessage(priorHistory)?.text.toLowerCase() ?? '';

    // Acute panic / overwhelm: acknowledge first, then offer one simple
    // grounding step without overwhelming them.
    if (IntentClassifier.isAcuteStress(userPrompt)) {
      return "I'm right here with you. When your body feels like it's racing or panicking, it can be really frightening, even when you're not in physical danger.\n\n"
          "If it feels okay right now, let your shoulders drop slightly and try one slow exhale that is a little longer than your inhale. Would you like me to walk you through a short grounding or breathing step, or would you rather just talk through what's happening?";
    }

    // Multi-turn continuation: e.g., user previously mentioned a presentation,
    // exam, interview, or talk, and now says "I'm scared I'll forget everything".
    final combinedContext = '$lastUserText $lower';
    final isPerformanceContext = RegExp(
      r'\b(presentation|speech|talk|interview|exam|test|meeting|stage|audience|pitch)\b',
    ).hasMatch(combinedContext);
    final isFearOfForgetting = RegExp(
      r'\b(forget|blank|freeze|mess up|stumble|fail|embarrass)\b',
    ).hasMatch(lower);

    if (isPerformanceContext && isFearOfForgetting) {
      return "Going blank or forgetting your words is one of the most common fears before a presentation—when you care about doing well, your mind naturally scans for what could go wrong.\n\n"
          "Would it help to talk through a simple way to anchor your key points on a single card so you don't have to rely on memory alone, or is there a specific part of the presentation that feels hardest?";
    }

    if (isPerformanceContext) {
      return "It makes complete sense that you're feeling anxious ahead of your presentation—anticipatory nerves are a very normal response when something matters to you.\n\n"
          "What part of it is weighing on you the most right now?";
    }

    if (RegExp(r'\b(difficult|hard|rough|tough|bad|awful|terrible|long|exhausting) (day|week|night|morning|time)\b')
        .hasMatch(lower)) {
      return "I'm really sorry today has been so heavy. Carrying a difficult day takes a lot out of you, and you don't have to rush into fixing it right this second.\n\n"
          "Do you feel like sharing what made today so hard, or would you prefer to just take things slow for a moment?";
    }

    if (RegExp(r'\b(lonely|alone|isolated)\b').hasMatch(lower)) {
      return "Feeling lonely or disconnected can be really painful to sit with. Thank you for telling me how you're feeling.\n\n"
          "Has this feeling been building up for a while, or did something specific bring it on today?";
    }

    if (RegExp(r'\b(tired|exhausted|drained|burnt out|burned out)\b').hasMatch(lower)) {
      return "It sounds like you're running on empty right now. Being that drained makes everything else feel ten times harder.\n\n"
          "Have you been under a lot of pressure lately, or has rest itself been hard to come by?";
    }

    // General empathetic reflection with continuity if prior user turn exists.
    if (lastUserText.isNotEmpty) {
      return "Thank you for sharing more about that—it sounds really stressful to carry. What feels like the hardest part of this for you right now?";
    }

    return "I hear you, and I'm really sorry you're dealing with that right now. Would you like to tell me a bit more about what's been going on, or what feels heaviest at the moment?";
  }

  static String _buildUncertainOrOutOfScopeReply(
    String userPrompt,
    List<AiChatMessage> priorHistory,
  ) {
    final lower = userPrompt.toLowerCase();

    // Medication, diagnosis, or clinical treatment boundary.
    if (RegExp(
      r'\b(medication|medicine|dose|dosage|mg|pill|prescription|antidepressant|ssri|sertraline|fluoxetine|prozac|lexapro|xanax|benzodiazepine|diagnose|diagnosis|bipolar|schizophrenia|disorder)\b',
    ).hasMatch(lower)) {
      return "I can't provide medical diagnoses or advice on medications and dosages—that requires a physician, psychiatrist, or pharmacist who knows your medical history.\n\n"
          "If you'd like, I can share general evidence-informed ways to support day-to-day stress or sleep alongside professional care, or explain how to prepare questions for your clinician.";
    }

    // Follow-up in an ongoing emotional conversation where the user wrote a
    // short statement that didn't trigger emotion keywords.
    if (priorHistory.isNotEmpty) {
      final lastUser = _lastUserMessage(priorHistory);
      if (lastUser != null) {
        return "I want to make sure I'm following you properly. Could you tell me a little more about how that connects to what you're experiencing right now?";
      }
    }

    return "I don't have verified information on that topic in my built-in wellness and NeuroShift reference notes. I'm designed to help with emotional support, stress and grounding exercises, understanding your EEG and HRV readings, and questions about how NeuroShift works.\n\n"
        "Would you like to explore one of those areas, or tell me how you're feeling today?";
  }

  // ===========================================================================
  // HISTORY & SOURCE HELPERS
  // ===========================================================================

  static List<AiChatMessage> _extractPriorHistory(
    List<AiChatMessage> history,
    String currentPrompt,
  ) {
    if (history.isEmpty) return const [];
    var end = history.length;

    // If the caller already appended the current user message to `history`,
    // exclude it from `priorHistory` so it is never sent twice.
    if (history.last.isUser && history.last.text.trim() == currentPrompt) {
      end = history.length - 1;
    }

    final filtered = <AiChatMessage>[];
    for (var i = 0; i < end; i++) {
      final m = history[i];
      if (m.id == 'welcome') continue;
      filtered.add(m);
    }
    return filtered;
  }

  static AiChatMessage? _lastAssistantMessage(List<AiChatMessage> history) {
    for (var i = history.length - 1; i >= 0; i--) {
      if (!history[i].isUser) return history[i];
    }
    return null;
  }

  static AiChatMessage? _lastUserMessage(List<AiChatMessage> history) {
    for (var i = history.length - 1; i >= 0; i--) {
      if (history[i].isUser) return history[i];
    }
    return null;
  }

  static List<KnowledgeSource> _deduplicateSources(List<KnowledgeSource> input) {
    final seen = <String>{};
    final out = <KnowledgeSource>[];
    for (final s in input) {
      final key = '${s.title}|${s.publisher}';
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  static List<String> _suggestedChipsFor(
    NovaIntent intent,
    RagRetrievalResult ragResult,
  ) {
    final top = ragResult.top;
    if (top != null && top.followUpQuestions.isNotEmpty) {
      return top.followUpQuestions;
    }
    switch (intent) {
      case NovaIntent.telemetryQuestion:
        return const [
          'Why is delta often high?',
          'What is HRV?',
          'Guide me through slow breathing',
        ];
      case NovaIntent.emotionalSupport:
        return const [
          'Guide me through a calming exercise',
          'Help me ground racing thoughts',
        ];
      default:
        return const [
          'What is HRV?',
          'Guide me through slow breathing',
          'Explain my brainwaves',
        ];
    }
  }
}
