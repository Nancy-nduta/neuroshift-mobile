/// Repeatable retrieval evaluation set for Nova's RAG layer.
///
/// Each case lists which knowledge-chunk ids are acceptable as the top hit
/// for the NEW knowledge base (`acceptNew`) and for the ORIGINAL baseline
/// knowledge base (`acceptOld`). `expectNone` marks queries for which no
/// evidence should be returned (out-of-scope questions).
class RetrievalEvalCase {
  final String query;
  final Set<String> acceptNew;
  final Set<String> acceptOld;
  final bool expectNone;

  const RetrievalEvalCase(
    this.query, {
    this.acceptNew = const {},
    this.acceptOld = const {},
    this.expectNone = false,
  });
}

const List<RetrievalEvalCase> retrievalEvalSet = [
  // --- Anxiety / acute stress ---
  RetrievalEvalCase("I'm having a panic attack and my heart is pounding",
      acceptNew: {'anx_acute'}, acceptOld: {'rag_anxiety_01'}),
  RetrievalEvalCase('how do I calm down when I feel really anxious',
      acceptNew: {'anx_acute', 'slow_breathing'}, acceptOld: {'rag_anxiety_01'}),
  RetrievalEvalCase("I feel so stressed and on edge all the time",
      acceptNew: {'anx_acute', 'professional_support'}, acceptOld: {'rag_anxiety_01'}),
  RetrievalEvalCase("my chest feels tight and I'm freaking out",
      acceptNew: {'anx_acute'}, acceptOld: {'rag_anxiety_01'}),
  RetrievalEvalCase("I'm nervous about tomorrow and my mind is racing",
      acceptNew: {'anx_acute', 'grounding'}, acceptOld: {'rag_anxiety_01', 'rag_eeg_beta'}),

  // --- Grounding / breathing ---
  RetrievalEvalCase("what is the 5-4-3-2-1 grounding technique",
      acceptNew: {'grounding'}, acceptOld: {'rag_anxiety_01'}),
  RetrievalEvalCase("I can't stop my thoughts spiralling, how do I get out of my head",
      acceptNew: {'grounding'}, acceptOld: {'rag_eeg_beta', 'rag_anxiety_01'}),
  RetrievalEvalCase("does breathing slowly actually change anything in your body",
      acceptNew: {'slow_breathing', 'anx_acute'}, acceptOld: {'rag_anxiety_01', 'rag_hrv_vagus'}),

  // --- HRV ---
  RetrievalEvalCase('What is HRV?', acceptNew: {'hrv_basics'}, acceptOld: {'rag_hrv_vagus'}),
  RetrievalEvalCase('what does RMSSD mean', acceptNew: {'hrv_basics'}, acceptOld: {'rag_hrv_vagus'}),
  RetrievalEvalCase('is a low heart rate variability bad',
      acceptNew: {'hrv_basics'}, acceptOld: {'rag_hrv_vagus'}),
  RetrievalEvalCase("what's a good HRV number for me",
      acceptNew: {'hrv_basics'}, acceptOld: {'rag_hrv_vagus'}),

  // --- EEG ---
  RetrievalEvalCase('what are alpha waves',
      acceptNew: {'eeg_bands'},
      acceptOld: {'rag_eeg_alpha', 'rag_eeg_beta', 'rag_eeg_theta', 'rag_eeg_delta'}),
  RetrievalEvalCase('explain theta and beta brainwaves',
      acceptNew: {'eeg_bands'},
      acceptOld: {'rag_eeg_alpha', 'rag_eeg_beta', 'rag_eeg_theta', 'rag_eeg_delta'}),
  RetrievalEvalCase('what do the different brainwave frequencies mean',
      acceptNew: {'eeg_bands'},
      acceptOld: {'rag_eeg_alpha', 'rag_eeg_beta', 'rag_eeg_theta', 'rag_eeg_delta'}),
  RetrievalEvalCase('why is delta always the highest on my headband',
      acceptNew: {'eeg_artifacts'}, acceptOld: {'rag_eeg_delta'}),
  RetrievalEvalCase('does blinking affect my EEG reading',
      acceptNew: {'eeg_artifacts'}, acceptOld: {'rag_eeg_delta'}),
  RetrievalEvalCase('how does the app decide whether I am calm or active',
      acceptNew: {'app_state_classification'}, acceptOld: {}),

  // --- Low mood ---
  RetrievalEvalCase('I feel really down and unmotivated lately',
      acceptNew: {'low_mood_ba', 'professional_support'}, acceptOld: {'rag_cbt_mood'}),
  RetrievalEvalCase('what is behavioural activation',
      acceptNew: {'low_mood_ba'}, acceptOld: {'rag_cbt_mood'}),
  RetrievalEvalCase("I have no energy to do anything and I'm feeling blue",
      acceptNew: {'low_mood_ba'}, acceptOld: {'rag_cbt_mood'}),

  // --- Sleep ---
  RetrievalEvalCase("I can't fall asleep at night", acceptNew: {'sleep_wind_down'}, acceptOld: {'rag_sleep_nsdr'}),
  RetrievalEvalCase('tips for better sleep', acceptNew: {'sleep_wind_down'}, acceptOld: {'rag_sleep_nsdr'}),
  RetrievalEvalCase('I keep waking up at 3am and cannot get back to sleep',
      acceptNew: {'sleep_wind_down'}, acceptOld: {'rag_sleep_nsdr'}),
  RetrievalEvalCase("my mind won't shut off when I get into bed",
      acceptNew: {'sleep_wind_down', 'grounding'}, acceptOld: {'rag_sleep_nsdr'}),

  // --- Audio ---
  RetrievalEvalCase('does listening to rain sounds actually help you relax',
      acceptNew: {'audio_relaxation'}, acceptOld: {}),
  RetrievalEvalCase('do binaural beats work',
      acceptNew: {'audio_relaxation'}, acceptOld: {}),
  RetrievalEvalCase('is white noise good for sleeping',
      acceptNew: {'audio_relaxation', 'sleep_wind_down'}, acceptOld: {'rag_sleep_nsdr'}),

  // --- Focus ---
  RetrievalEvalCase("I can't concentrate when I study",
      acceptNew: {'focus_environment'}, acceptOld: {'rag_adhd_focus'}),
  RetrievalEvalCase('does background noise help ADHD focus',
      acceptNew: {'focus_environment', 'audio_relaxation'}, acceptOld: {'rag_adhd_focus'}),
  RetrievalEvalCase('how do I stop getting distracted while working',
      acceptNew: {'focus_environment'}, acceptOld: {'rag_adhd_focus'}),

  // --- Professional support ---
  RetrievalEvalCase('when should I see a therapist',
      acceptNew: {'professional_support'}, acceptOld: {}),
  RetrievalEvalCase('how do I know if I need professional help',
      acceptNew: {'professional_support'}, acceptOld: {}),

  // --- App / privacy ---
  RetrievalEvalCase('what happens to my data', acceptNew: {'app_privacy_data'}, acceptOld: {}),
  RetrievalEvalCase('does the app save my chats', acceptNew: {'app_privacy_data'}, acceptOld: {}),
  RetrievalEvalCase('what happens if I delete my recording',
      acceptNew: {'app_privacy_data'}, acceptOld: {}),
  RetrievalEvalCase('who can see my meditation sessions',
      acceptNew: {'app_privacy_data', 'app_therapist'}, acceptOld: {}),
  RetrievalEvalCase('what can NeuroShift do', acceptNew: {'app_overview'}, acceptOld: {}),
  RetrievalEvalCase('how do I connect my Muse headband',
      acceptNew: {'app_overview'}, acceptOld: {}),
  RetrievalEvalCase('are you a real therapist',
      acceptNew: {'app_nova_scope'}, acceptOld: {}),

  // --- Out of scope: must NOT return evidence ---
  RetrievalEvalCase('What is the capital of France', expectNone: true),
  RetrievalEvalCase('write me a python function to sort a list', expectNone: true),
  RetrievalEvalCase('who won the world cup', expectNone: true),
  RetrievalEvalCase("what's the weather like in Nairobi", expectNone: true),
  RetrievalEvalCase('tell me a joke', expectNone: true),
  RetrievalEvalCase('best pizza recipe', expectNone: true),
  RetrievalEvalCase('how do I change a flat tyre', expectNone: true),
];
