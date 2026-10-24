import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../models/signal_reading.dart';
import '../data/clinical_knowledge_base.dart';
import '../models/ai_chat_message.dart';
import 'rag_retrieval_service.dart';

class AiWellnessService {
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Generate an empathetic, scientifically grounded clinical response using Bio-RAG
  static Future<AiChatMessage> getResponse(
    String userPrompt,
    List<AiChatMessage> history, {
    SignalReading? currentTelemetry,
    bool isConnected = false,
  }) async {
    final lower = userPrompt.toLowerCase().trim();

    // 1. Retrieve most relevant clinical knowledge chunks using RAG retrieval engine
    final ragResult = RagRetrievalService.retrieve(lower);

    // 2. Format live biometric context
    final biometricContext = _formatBiometricContext(currentTelemetry, isConnected);

    // 3. Check for emergency crisis containment query
    if (ragResult.isCrisisQuery) {
      return _generateCrisisResponse(ragResult.topChunk);
    }

    // 4. Check if external Gemini API key is configured
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isNotEmpty) {
      try {
        final geminiResponse = await _queryGeminiWithRag(
          apiKey,
          userPrompt,
          history,
          ragResult,
          biometricContext,
        );
        if (geminiResponse != null && geminiResponse.isNotEmpty) {
          return AiChatMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            suggestedChips: ragResult.suggestedChips,
            recommendedResource: ragResult.recommendedResource,
          );
        }
      } catch (_) {
        // Fallback to offline Bio-RAG synthesis smoothly
      }
    }

    // 5. Offline Clinical Bio-RAG Synthesis Engine (Real-Time, Zero-Latency, Zero-Hallucination)
    await Future.delayed(const Duration(milliseconds: 400));
    return _synthesizeBioRagResponse(
      lower,
      ragResult,
      currentTelemetry,
      isConnected,
    );
  }

  static String _formatBiometricContext(SignalReading? telemetry, bool isConnected) {
    if (!isConnected || telemetry == null) {
      return 'Headband Status: Offline / Awaiting Hardware Connection';
    }

    final stateStr = telemetry.mindState.name.toUpperCase();
    final bpmStr = telemetry.heartRateBpm != null ? '${telemetry.heartRateBpm} BPM' : 'Measuring...';
    final hrvStr = telemetry.hrvRmssd != null ? '${telemetry.hrvRmssd!.toStringAsFixed(1)} ms' : 'Measuring...';
    final alphaStr = '${telemetry.alpha.toStringAsFixed(1)} µV';
    final betaStr = '${telemetry.beta.toStringAsFixed(1)} µV';
    final stillnessStr = '${telemetry.stillnessScore.toStringAsFixed(0)}%';

    return 'Headband Status: Connected (Muse 2)\n'
        '• Current MindState: $stateStr\n'
        '• Alpha Wave Power: $alphaStr\n'
        '• Beta Wave Power: $betaStr\n'
        '• Heart Rate: $bpmStr\n'
        '• HRV (RMSSD): $hrvStr\n'
        '• Physical Stillness: $stillnessStr\n'
        '• Accumulated Calm Points: ${telemetry.calmPoints}';
  }

  static Future<String?> _queryGeminiWithRag(
    String apiKey,
    String prompt,
    List<AiChatMessage> history,
    RagRetrievalResult ragResult,
    String biometricContext,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_geminiEndpoint?key=$apiKey');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final systemInstruction =
          'You are Nova, an empathetic, supportive, and scientifically grounded NeuroShift AI Mental Health & Mindfulness Guide.\n'
          'You synthesize clinical neuro-psychology with live EEG brainwave and heart rate biofeedback.\n'
          'CRITICAL CLINICAL CONTEXT FROM RETRIEVED KNOWLEDGE BASE:\n'
          'Topic: ${ragResult.topChunk.title}\n'
          'Summary: ${ragResult.topChunk.clinicalSummary}\n'
          'Key Protocols: ${ragResult.topChunk.actionableProtocols.join(' | ')}\n\n'
          'CURRENT LIVE USER BIOMETRIC TELEMETRY:\n$biometricContext\n\n'
          'INSTRUCTIONS:\n'
          '1. Warm, compassionate, concise tone.\n'
          '2. When the user asks about their mental state or brainwaves, interpret their live telemetry directly.\n'
          '3. Provide actionable steps formatted with bullet points.\n'
          '4. Remind gently that you are an AI wellness guide, not an emergency medical service.';

      final contents = [
        {
          'role': 'user',
          'parts': [
            {'text': '$systemInstruction\n\nUser Question: $prompt'}
          ]
        }
      ];

      request.write(jsonEncode({'contents': contents}));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String?;
          }
        }
      }
    } finally {
      client.close();
    }
    return null;
  }

  static AiChatMessage _generateCrisisResponse(KnowledgeChunk chunk) {
    final text = '🚨 **${chunk.title}**\n\n'
        '${chunk.clinicalSummary}\n\n'
        '**Immediate Emergency Resources (Available 24/7)**:\n'
        '• 📞 **988 Suicide & Crisis Lifeline**: Call or text **988** (Free, confidential, 24/7 in US & Canada).\n'
        '• 💬 **Crisis Text Line**: Text **HOME** to **741741** to message a trained crisis counselor.\n'
        '• 🌍 **International Support**: Visit **[findahelpline.com](https://findahelpline.com)** or call local emergency services.\n\n'
        'You matter, and there is compassionate human support ready for you right this second.';

    return AiChatMessage(
      id: 'crisis_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedChips: chunk.followUpQuestions,
    );
  }

  static AiChatMessage _synthesizeBioRagResponse(
    String prompt,
    RagRetrievalResult ragResult,
    SignalReading? telemetry,
    bool isConnected,
  ) {
    final buffer = StringBuffer();
    final chunk = ragResult.topChunk;

    // Check if user is asking specifically about their live biometric state
    final isAskingForLiveBioAnalysis = prompt.contains('current') ||
        prompt.contains('analyze') ||
        prompt.contains('my brainwave') ||
        prompt.contains('my mind') ||
        prompt.contains('am i calm') ||
        prompt.contains('my heart rate') ||
        prompt.contains('active state');

    if (isAskingForLiveBioAnalysis) {
      if (isConnected && telemetry != null) {
        final stateName = telemetry.mindState.name.toUpperCase();
        buffer.writeln('🧠 **Live Neural Telemetry Analysis**:\n');
        buffer.writeln('Your headband reports you are currently in the **$stateName** mental state.');

        if (telemetry.mindState == MindState.calm) {
          buffer.writeln(
            '• **Alpha Synchrony (${telemetry.alpha.toStringAsFixed(1)} µV)**: Dominating your cognitive spectrum over Beta (${telemetry.beta.toStringAsFixed(1)} µV). This indicates active parasympathetic calming and cortical gating.',
          );
        } else if (telemetry.mindState == MindState.active) {
          buffer.writeln(
            '• **Beta Arousal (${telemetry.beta.toStringAsFixed(1)} µV)**: High-frequency cortical desynchronization exceeds Alpha (${telemetry.alpha.toStringAsFixed(1)} µV). This reflects active thought processing, analytical focus, or stress.',
          );
        } else {
          buffer.writeln(
            '• **Equilibrium State**: Alpha (${telemetry.alpha.toStringAsFixed(1)} µV) and Beta (${telemetry.beta.toStringAsFixed(1)} µV) are balanced in alert wakeful equilibrium.',
          );
        }

        if (telemetry.heartRateBpm != null && telemetry.heartRateBpm! > 0) {
          buffer.writeln('• **Pulse**: ${telemetry.heartRateBpm} BPM.');
        }
        if (telemetry.hrvRmssd != null && telemetry.hrvRmssd! > 0) {
          buffer.writeln('• **HRV Vagal Tone (RMSSD)**: ${telemetry.hrvRmssd!.toStringAsFixed(1)} ms.');
        }

        buffer.writeln('\n---\n');
      } else {
        buffer.writeln('💡 *Note: Your Muse 2 headband is currently disconnected. Connect it anytime to view real-time neural readouts.*\n');
      }
    }

    // Embed Clinical RAG Knowledge
    buffer.writeln('✨ **${chunk.title}**\n');
    buffer.writeln('${chunk.clinicalSummary}\n');

    buffer.writeln('🎯 **Evidence-Based Action Steps**:');
    for (int i = 0; i < chunk.actionableProtocols.length; i++) {
      buffer.writeln('• ${chunk.actionableProtocols[i]}');
    }

    if (ragResult.recommendedResource != null) {
      buffer.writeln('\n🎧 *Recommended In-App Practice*: **${ragResult.recommendedResource!.title}**');
    }

    return AiChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: buffer.toString().trim(),
      isUser: false,
      timestamp: DateTime.now(),
      suggestedChips: ragResult.suggestedChips,
      recommendedResource: ragResult.recommendedResource,
    );
  }
}
