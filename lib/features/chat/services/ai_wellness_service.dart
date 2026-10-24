import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/ai_chat_message.dart';
import '../../resources/models/resource_item.dart';

class AiWellnessService {
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Generate an empathetic, scientifically grounded clinical response
  static Future<AiChatMessage> getResponse(String userPrompt, List<AiChatMessage> history) async {
    final lower = userPrompt.toLowerCase().trim();

    // Check if an external Gemini API key is provided via compile-time environment
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isNotEmpty) {
      try {
        final geminiResponse = await _queryGemini(apiKey, userPrompt, history);
        if (geminiResponse != null && geminiResponse.isNotEmpty) {
          final matchedRes = _findRelevantResource(lower);
          return AiChatMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            suggestedChips: _generateFollowUpChips(lower),
            recommendedResource: matchedRes,
          );
        }
      } catch (_) {
        // Fallback to built-in neuro-clinical engine seamlessly
      }
    }

    // Built-in Neuro-Clinical Intelligence Engine (100% offline & real-time)
    await Future.delayed(const Duration(milliseconds: 650));
    return _generateClinicalResponse(lower);
  }

  static Future<String?> _queryGemini(
    String apiKey,
    String prompt,
    List<AiChatMessage> history,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_geminiEndpoint?key=$apiKey');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final systemInstruction =
          'You are Nova, an empathetic, supportive, and scientifically grounded NeuroShift AI Mental Health & Mindfulness Guide. '
          'You provide compassionate neuro-wellness advice on coping with anxiety, stress, depression, ADHD focus, sleep, and explaining brainwaves (Alpha, Beta, Theta, Delta, Gamma) and HRV. '
          'Keep your tone warm, concise, and structured with bullet points. Always include a gentle reminder that you are an AI companion, not emergency psychiatric services.';

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

  static AiChatMessage _generateClinicalResponse(String prompt) {
    String text;
    ResourceItem? resource;
    List<String> chips;

    // 1. Anxiety / Panic / Stress Attacks
    if (prompt.contains('anxi') || prompt.contains('panic') || prompt.contains('calm down') || prompt.contains('scared') || prompt.contains('overwhelm')) {
      text = 'I hear you, and it is completely okay that you are feeling this way right now. Let’s bring your nervous system back into balance step by step:\n\n'
          '🫁 **1. The Physiological Sigh (Fastest Reset)**:\n'
          '• Take two quick inhales through your nose (deep inhale, then a top-off inhale).\n'
          '• Follow with one long, slow, unforced exhale through your mouth.\n'
          '• Repeating this 3 times immediately triggers the parasympathetic vagal brake, reducing heart rate.\n\n'
          '👁️ **2. The 5-4-3-2-1 Sensory Grounding**:\n'
          '• Notice 5 things you can see.\n'
          '• 4 things you can physically touch.\n'
          '• 3 sounds you can hear.\n'
          '• 2 scents around you.\n'
          '• 1 deep breath of gratitude.\n\n'
          'Your nervous system is just trying to protect you. You are in a safe space.';
      resource = ResourceItem.catalog.firstWhere((r) => r.id == 'med_03'); // 10-Min Meditation for Anxiety
      chips = ['Teach me Box Breathing', 'Explain Alpha brainwaves', 'Start Anxiety Meditation'];
    }
    // 2. Brainwaves & EEG Explanation
    else if (prompt.contains('brainwave') || prompt.contains('alpha') || prompt.contains('beta') || prompt.contains('theta') || prompt.contains('delta') || prompt.contains('gamma') || prompt.contains('eeg')) {
      text = 'Here is how your brain operates across the 5 primary EEG frequency bands:\n\n'
          '• **α Alpha (8–13 Hz) — Calm Presence**:\n'
          'The bridge between conscious thought and subconscious stillness. Surges during light meditation, closed eyes, and serene mindfulness.\n\n'
          '• **β Beta (13–30 Hz) — Active Processing**:\n'
          'Associated with alert focus, problem solving, and analytical thought. If excessive, it can manifest as cognitive anxiety.\n\n'
          '• **θ Theta (4–8 Hz) — Deep Meditation & Flow**:\n'
          'The twilight state seen during deep hypnotic absorption, creative epiphanies, and daydreaming.\n\n'
          '• **δ Delta (0.5–4 Hz) — Restorative Healing**:\n'
          'Slowest high-amplitude waves. Essential for deep stage-3 NREM physical regeneration and memory consolidation.\n\n'
          '• **γ Gamma (30–100 Hz) — Peak Cognition**:\n'
          'Ultra-fast microvolts synchronizing diverse brain regions for high-level insight and sensory binding.';
      resource = ResourceItem.catalog.firstWhere((r) => r.id == 'noise_01'); // Alpha wave resonance
      chips = ['How to increase Alpha waves?', 'What is HRV & Vagal Tone?', 'Practice Alpha entrainment'];
    }
    // 3. Heart Rate & Heart Rate Variability (HRV / RMSSD)
    else if (prompt.contains('hrv') || prompt.contains('heart') || prompt.contains('rmssd') || prompt.contains('vagus') || prompt.contains('bpm')) {
      text = 'Your cardiovascular system is directly wired into your emotional state via the Vagus Nerve:\n\n'
          '💓 **Heart Rate Variability (HRV / RMSSD)**:\n'
          '• Unlike your baseline pulse (BPM), HRV measures the microsecond variations between consecutive heartbeats.\n'
          '• **Higher RMSSD (>40–60 ms)** indicates strong vagal tone, high emotional resilience, and active parasympathetic "Rest & Digest".\n'
          '• **Lower RMSSD (<30 ms)** indicates autonomic stress, fight-or-flight sympathetic dominance, or physical fatigue.\n\n'
          '🌊 **How to Boost Your HRV**:\n'
          '• Resonance frequency breathing at 6 breaths per minute (5.5s inhale, 5.5s exhale).\n'
          '• Cold water face splashes (diving reflex).\n'
          '• Quality sleep and somatic mindfulness practices.';
      resource = ResourceItem.catalog.firstWhere((r) => r.id == 'nature_01'); // Ocean Shore Waves
      chips = ['Show 5.5s Resonance Breathing', 'Explain Alpha brainwaves', 'Calm my Heart Rate'];
    }
    // 4. Focus, ADHD, and Racing Thoughts
    else if (prompt.contains('focus') || prompt.contains('adhd') || prompt.contains('distract') || prompt.contains('study') || prompt.contains('overthink') || prompt.contains('racing')) {
      text = 'When your prefrontal cortex is overloaded with racing thoughts, try these neuro-cognitive strategies:\n\n'
          '🎯 **1. Acoustic Frequency Masking**:\n'
          '• Low-frequency Brown and Pink noise acts as an acoustic sound blanket, suppressing background auditory salience that triggers ADHD task switching.\n\n'
          '🧠 **2. The 20-Minute Focus Sprint**:\n'
          '• Commit to only 20 minutes on a single task with zero notifications.\n'
          '• Keep a "Brain Dump" notepad beside you: whenever a rogue thought enters your head, write it down and return immediately.\n\n'
          '🫁 **3. Box Breathing for Mental Clarity**:\n'
          '• Inhale 4s • Hold 4s • Exhale 4s • Hold 4s.\n'
          '• This stabilizes carbon dioxide levels in the blood and sharpens focal attention.';
      resource = ResourceItem.catalog.firstWhere((r) => r.id == 'noise_03'); // Gentle Lofi Beats
      chips = ['Start Focus Audio', 'Explain Beta vs Alpha waves', 'How to stop overthinking'];
    }
    // 5. Sleep & Insomnia
    else if (prompt.contains('sleep') || prompt.contains('insomnia') || prompt.contains('tired') || prompt.contains('night') || prompt.contains('bed')) {
      text = 'Falling asleep is not an on/off switch; it is a gradual descent into Delta wave synchrony. Here is your evidence-based wind-down protocol:\n\n'
          '💤 **1. Non-Sleep Deep Rest (NSDR)**:\n'
          '• A guided 10–15 minute progressive body scan shifts cortical activity from beta to theta, releasing muscular guarding.\n\n'
          '🌧️ **2. Continuous Low-Frequency Acoustic Ambience**:\n'
          '• Steady rainfall or gentle ocean tides reduce auditory cortices arousal, mimicking the sensory environment of deep safety.\n\n'
          '🌡️ **3. Core Temperature Drop**:\n'
          '• Your body must drop by ~1°C to initiate melatonin release. Keep your bedroom cool (~18°C / 65°F).\n\n'
          'Would you like to start a soothing soundscape now?';
      resource = ResourceItem.catalog.firstWhere((r) => r.id == 'rain_01'); // Rain on window with thunder
      chips = ['Start Sleep Ambience', 'Explain Body Scan Meditation', 'Calm down before bed'];
    }
    // 6. Depression, Sadness, or Low Energy
    else if (prompt.contains('depress') || prompt.contains('sad') || prompt.contains('hopeless') || prompt.contains('empty') || prompt.contains('lonely') || prompt.contains('cry')) {
      text = 'I want to acknowledge how difficult this feels. You don’t have to "fix" or change everything today. Healing happens in very small, gentle moments:\n\n'
          '🌱 **1. Micro-Action (Behavioral Activation)**:\n'
          '• Give yourself permission to do the bare minimum. Drink a glass of water, step outside for 2 minutes of natural light, or stretch your arms.\n\n'
          '🤝 **2. Self-Compassion Break**:\n'
          '• Place one hand over your heart or on your chest. Feel the warmth and the gentle rhythm of your breathing.\n'
          '• Remind yourself: *"This is a painful moment, but suffering is part of being human. May I be gentle with myself."*\n\n'
          '💡 *Important: If you are in crisis, please reach out to trusted friends, family, or call/text 988 (or your local mental health crisis line). You do not have to carry this alone.*';
      resource = ResourceItem.catalog.firstWhere((r) => r.id == 'piano_01'); // Peaceful Relaxing Piano
      chips = ['Play soothing piano music', 'Teach me gentle breathing', 'Connect with my therapist'];
    }
    // 7. Breathing Exercises (Box, 4-7-8, Diaphragmatic)
    else if (prompt.contains('breath') || prompt.contains('technique') || prompt.contains('box') || prompt.contains('exercise')) {
      text = 'Here are the top 3 clinically validated breathing protocols for nervous system regulation:\n\n'
          '🟦 **1. Box Breathing (Navy SEAL Calming Protocol)**:\n'
          '• Inhale for 4 seconds\n'
          '• Hold lungs full for 4 seconds\n'
          '• Exhale smoothly for 4 seconds\n'
          '• Hold lungs empty for 4 seconds\n'
          '• Repeat 4 cycles to reset elevated heart rate.\n\n'
          '🌙 **2. The 4-7-8 Sleep Inducer**:\n'
          '• Inhale through nose for 4s\n'
          '• Gently retain breath for 7s\n'
          '• Slowly whoosh exhale through mouth for 8s.\n\n'
          '🫀 **3. Coherent 5.5s Resonance**:\n'
          '• 5.5s Inhale + 5.5s Exhale = ~5.5 breaths per minute. Maximizes Heart Rate Variability (HRV).';
      resource = ResourceItem.catalog.firstWhere((r) => r.id == 'med_01'); // 5-Min Morning Meditation
      chips = ['Try Box Breathing now', 'Explain HRV benefits', 'Start 5-min Guided Session'];
    }
    // 8. General Greeting & Introduction
    else {
      text = 'Hello! I am **Nova**, your personal NeuroShift AI Mental Health & Neuro-Wellness Guide. 🧠✨\n\n'
          'I am here 24/7 to support you with:\n'
          '• **Immediate Calm & Grounding**: Science-backed breathing and somatic resets for anxiety.\n'
          '• **Deciphering Your Brainwaves**: What your Alpha, Beta, Theta, and Delta telemetry means.\n'
          '• **Cardiovascular Resilience**: Understanding your HRV, RMSSD, and vagal recovery.\n'
          '• **Targeted In-App Practice**: Recommending soothing soundscapes and guided sessions.\n\n'
          'How is your mind feeling right now? Tap a topic below or type anything on your mind.';
      chips = [
        'Calm Anxiety Now',
        'Explain My Brainwaves',
        'Help Me Sleep',
        'Boost My Focus & ADHD',
        'What is HRV & Vagal Tone?'
      ];
    }

    return AiChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedChips: chips,
      recommendedResource: resource,
    );
  }

  static ResourceItem? _findRelevantResource(String query) {
    if (query.contains('anxi') || query.contains('panic') || query.contains('stress')) {
      return ResourceItem.catalog.firstWhere((r) => r.id == 'med_03');
    }
    if (query.contains('alpha') || query.contains('focus') || query.contains('brainwave')) {
      return ResourceItem.catalog.firstWhere((r) => r.id == 'noise_01');
    }
    if (query.contains('sleep') || query.contains('rain') || query.contains('night')) {
      return ResourceItem.catalog.firstWhere((r) => r.id == 'rain_01');
    }
    if (query.contains('piano') || query.contains('sad') || query.contains('calm')) {
      return ResourceItem.catalog.firstWhere((r) => r.id == 'piano_01');
    }
    return null;
  }

  static List<String> _generateFollowUpChips(String query) {
    if (query.contains('anxi') || query.contains('panic')) {
      return ['Teach me Box Breathing', 'Explain Alpha brainwaves', 'Start Anxiety Meditation'];
    }
    if (query.contains('sleep')) {
      return ['Start Sleep Ambience', 'Explain Body Scan Meditation', 'Calm down before bed'];
    }
    return ['Calm Anxiety Now', 'Explain My Brainwaves', 'What is HRV & Vagal Tone?'];
  }
}
