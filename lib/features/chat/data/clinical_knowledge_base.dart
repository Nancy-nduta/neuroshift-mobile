import '../models/ai_chat_message.dart';

/// Strength of the evidence behind a chunk's claims.
enum EvidenceQuality {
  /// Guidance from a national health body or a systematic review.
  established,

  /// Some supporting studies, but small, short or mixed.
  limited,

  /// Common practice with little or no formal trial evidence.
  practiceBased,

  /// Describes how NeuroShift itself works (taken from the app's code).
  appDesign,
}

/// A small, single-topic unit of reference knowledge for Nova's RAG layer.
class KnowledgeChunk {
  final String id;

  /// wellness | eeg | hrv | audio | sleep | focus | mood | support | app | crisis
  final String category;
  final String title;
  final List<String> tags;

  /// Phrases people actually use when asking about this topic.
  final List<String> keywords;

  /// 2-4 sentence plain-language explanation.
  final String summary;

  /// Practical steps / key points (kept short).
  final List<String> keyPoints;

  /// Question types this chunk answers: definition, howto, why, exercise,
  /// privacy, scope, safety.
  final List<String> questionTypes;
  final String? safetyNotes;
  final String limitations;
  final EvidenceQuality evidence;
  final List<KnowledgeSource> sources;

  /// ISO date the content was last reviewed.
  final String reviewedOn;

  /// Optional in-app resource that suits this topic (must exist in catalog).
  final String? recommendedResourceId;
  final List<String> followUpQuestions;

  /// True when this chunk can be turned into a guided exercise.
  final bool isExercise;

  const KnowledgeChunk({
    required this.id,
    required this.category,
    required this.title,
    required this.tags,
    required this.keywords,
    required this.summary,
    this.keyPoints = const [],
    this.questionTypes = const [],
    this.safetyNotes,
    required this.limitations,
    required this.evidence,
    this.sources = const [],
    required this.reviewedOn,
    this.recommendedResourceId,
    this.followUpQuestions = const [],
    this.isExercise = false,
  });

  bool get isAppFact => category == 'app';

  /// Text used by the retriever (not shown to users).
  String get searchText => [
        title,
        title,
        tags.join(' '),
        tags.join(' '),
        keywords.join(' '),
        summary,
        keyPoints.join(' '),
      ].join(' ');
}

const String _kReviewed = '2026-10-24';

// ---------------------------------------------------------------------------
// Verified sources. Every URL/DOI below was checked on 2026-10-24
// (HTTP 200, or DOI title confirmed through Crossref). Sources that block
// automated checks are not listed.
// ---------------------------------------------------------------------------
const _nhsBreathing = KnowledgeSource(
  title: 'Breathing exercises for stress',
  publisher: 'NHS (UK)',
  url: 'https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/',
  limitation: 'General self-help guidance; not a treatment for anxiety disorders.',
);
const _nimhAnxiety = KnowledgeSource(
  title: 'Anxiety Disorders',
  publisher: 'National Institute of Mental Health (US)',
  url: 'https://www.nimh.nih.gov/health/topics/anxiety-disorders',
  limitation: 'Overview for the public; individual care needs a clinician.',
);
const _balban = KnowledgeSource(
  title: 'Brief structured respiration practices enhance mood and reduce physiological arousal',
  publisher: 'Cell Reports Medicine (Balban et al.)',
  url: 'https://doi.org/10.1016/j.xcrm.2022.100895',
  published: '2023',
  limitation: 'Randomised study in non-clinical volunteers; short daily practice; self-reported mood.',
);
const _zaccaro = KnowledgeSource(
  title: 'How Breath-Control Can Change Your Life: A Systematic Review on Psycho-Physiological Correlates of Slow Breathing',
  publisher: 'Frontiers in Human Neuroscience (Zaccaro et al.)',
  url: 'https://doi.org/10.3389/fnhum.2018.00353',
  published: '2018',
  limitation: 'Review of small, varied studies; mostly healthy participants.',
);
const _shaffer = KnowledgeSource(
  title: 'An Overview of Heart Rate Variability Metrics and Norms',
  publisher: 'Frontiers in Public Health (Shaffer & Ginsberg)',
  url: 'https://doi.org/10.3389/fpubh.2017.00258',
  published: '2017',
  limitation: 'Norms vary widely with age, fitness and measurement conditions.',
);
const _klimesch = KnowledgeSource(
  title: 'EEG alpha and theta oscillations reflect cognitive and memory performance: a review and analysis',
  publisher: 'Brain Research Reviews (Klimesch)',
  url: 'https://doi.org/10.1016/S0165-0173(98)00056-3',
  published: '1999',
  limitation: 'Describes cognition-related rhythms, not everyday mood states.',
);
const _krigolson = KnowledgeSource(
  title: 'Choosing MUSE: Validation of a Low-Cost, Portable EEG System for ERP Research',
  publisher: 'Frontiers in Neuroscience (Krigolson et al.)',
  url: 'https://doi.org/10.3389/fnins.2017.00109',
  published: '2017',
  limitation: 'Validated for event-related potentials in research tasks, not for emotion or mental-health assessment.',
);
const _arns = KnowledgeSource(
  title: 'A Decade of EEG Theta/Beta Ratio Research in ADHD',
  publisher: 'Journal of Attention Disorders (Arns et al.)',
  url: 'https://doi.org/10.1177/1087054712460087',
  published: '2012',
  limitation: 'Group-level differences only; not a diagnostic test for an individual.',
);
const _uriguen = KnowledgeSource(
  title: 'EEG artifact removal - state-of-the-art and guidelines',
  publisher: 'Journal of Neural Engineering (Uriguen & Garcia-Zapirain)',
  url: 'https://doi.org/10.1088/1741-2560/12/3/031001',
  published: '2015',
);
const _nice222 = KnowledgeSource(
  title: 'Depression in adults: treatment and management (NG222)',
  publisher: 'NICE (UK)',
  url: 'https://www.nice.org.uk/guidance/ng222',
  limitation: 'UK clinical guideline for clinicians; summarised here in general terms.',
);
const _nimhDepression = KnowledgeSource(
  title: 'Depression',
  publisher: 'National Institute of Mental Health (US)',
  url: 'https://www.nimh.nih.gov/health/topics/depression',
);
const _nhsInsomnia = KnowledgeSource(
  title: 'Insomnia',
  publisher: 'NHS (UK)',
  url: 'https://www.nhs.uk/conditions/insomnia/',
  limitation: 'General sleep advice; persistent insomnia needs individual assessment.',
);
const _riedy = KnowledgeSource(
  title: 'Noise as a sleep aid: A systematic review',
  publisher: 'Sleep Medicine Reviews (Riedy et al.)',
  url: 'https://doi.org/10.1016/j.smrv.2020.101385',
  published: '2021',
  limitation: 'Evidence quality reported as low; studies are few and varied.',
);
const _deWitte = KnowledgeSource(
  title: 'Effects of music interventions on stress-related outcomes: a systematic review and two meta-analyses',
  publisher: 'Health Psychology Review (de Witte et al.)',
  url: 'https://doi.org/10.1080/17437199.2019.1627897',
  published: '2019',
  limitation: 'Mostly structured music interventions, not YouTube ambience; results vary between studies.',
);
const _soderlund = KnowledgeSource(
  title: 'Listen to the noise: noise is beneficial for cognitive performance in ADHD',
  publisher: 'Journal of Child Psychology and Psychiatry (SÃ¶derlund et al.)',
  url: 'https://doi.org/10.1111/j.1469-7610.2007.01749.x',
  published: '2007',
  limitation: 'Small laboratory study in children; not shown to carry over to everyday life.',
);
const _nimhAdhd = KnowledgeSource(
  title: 'Attention-Deficit/Hyperactivity Disorder',
  publisher: 'National Institute of Mental Health (US)',
  url: 'https://www.nimh.nih.gov/health/topics/attention-deficit-hyperactivity-disorder-adhd',
);
const _nimhHelp = KnowledgeSource(
  title: 'Help for Mental Illnesses / Find help',
  publisher: 'National Institute of Mental Health (US)',
  url: 'https://www.nimh.nih.gov/health/find-help',
);
const _findAHelpline = KnowledgeSource(
  title: 'Find a Helpline',
  publisher: 'ThroughLine',
  url: 'https://findahelpline.com',
  limitation: 'Directory of helplines by country; availability and hours vary.',
);
const _iasp = KnowledgeSource(
  title: 'Crisis Centres and Helplines',
  publisher: 'International Association for Suicide Prevention',
  url: 'https://www.iasp.info/crisis-centres-helplines/',
);

class ClinicalKnowledgeBase {
  /// All chunks, including the crisis chunk (never returned by retrieval).
  static const List<KnowledgeChunk> chunks = [
    // ------------------------------------------------------------------ WELLNESS
    KnowledgeChunk(
      id: 'anx_acute',
      category: 'wellness',
      title: 'Acute anxiety, stress and panic: what helps in the moment',
      tags: ['anxiety', 'panic', 'stress', 'calm', 'overwhelmed', 'racing heart'],
      keywords: [
        'panic attack', 'anxious', 'anxiety', 'calm down', 'freaking out',
        'chest tight', 'heart pounding', 'on edge', 'stressed', 'overwhelmed',
        'nervous', 'scared', 'shaking',
      ],
      summary:
          'Anxiety and panic are driven by the body\'s stress response: a faster heartbeat, quick shallow '
          'breathing, a tight chest or trembling. These sensations are very uncomfortable, but they are usually '
          'not dangerous and tend to ease. Slowing the breath and anchoring attention in the present are common '
          'first steps people can use on their own.',
      keyPoints: [
        'Breathe in gently through your nose, then let the breath out slowly through your mouth. Make the out-breath a little longer than the in-breath, and keep going for a few minutes.',
        'Physiological sigh: two short breaths in through the nose (a full one, then a small top-up), then one long, slow breath out. Repeat a few times.',
        'Let your shoulders drop and unclench your jaw and hands.',
        'If you feel light-headed, stop and breathe normally.',
      ],
      questionTypes: ['exercise', 'howto', 'definition'],
      safetyNotes:
          'Seek urgent medical help for chest pain that is new, severe or unusual, fainting, or trouble breathing. '
          'If panic attacks are frequent or get in the way of daily life, talk to a doctor or therapist.',
      limitations:
          'Breathing techniques are self-help for stress. They are not a treatment for an anxiety disorder, and '
          'the cyclic-sighing study involved non-clinical volunteers.',
      evidence: EvidenceQuality.limited,
      sources: [_nhsBreathing, _nimhAnxiety, _balban],
      reviewedOn: _kReviewed,
      recommendedResourceId: 'med_03',
      followUpQuestions: ['Guide me through a breathing exercise', 'Why does my heart race when I\'m anxious?', 'When should I get professional help?'],
      isExercise: true,
    ),
    KnowledgeChunk(
      id: 'grounding',
      category: 'wellness',
      title: 'Grounding when your mind is spiralling',
      tags: ['grounding', 'overthinking', 'rumination', 'racing thoughts', 'mindfulness', 'present moment'],
      keywords: [
        '5-4-3-2-1', 'grounding technique', 'spiralling', 'spiraling', 'overthinking',
        'racing thoughts', 'get out of my head', 'stop my thoughts', 'cannot stop thinking',
        'mind wont shut off',
      ],
      summary:
          'Grounding techniques shift attention from worrying thoughts to what your senses can notice right now. '
          'They are widely used in therapy and self-help, although there is little formal trial evidence for any '
          'single technique.',
      keyPoints: [
        '5-4-3-2-1: name 5 things you can see, 4 you can feel or touch, 3 you can hear, 2 you can smell and 1 you can taste.',
        'Press your feet into the floor and notice the support under you.',
        'Describe your surroundings out loud in plain words, like a commentator.',
        'Slow your out-breath while you do it.',
      ],
      questionTypes: ['exercise', 'howto', 'definition'],
      safetyNotes: 'If grounding makes you feel more distressed, stop and choose something gentler, such as slow breathing.',
      limitations: 'Practice-based. No single source is cited here because I do not hold a verified trial for this technique.',
      evidence: EvidenceQuality.practiceBased,
      sources: [],
      reviewedOn: _kReviewed,
      recommendedResourceId: 'med_05',
      followUpQuestions: ['Walk me through 5-4-3-2-1', 'Help me slow my breathing', 'Why do thoughts spiral?'],
      isExercise: true,
    ),
    KnowledgeChunk(
      id: 'slow_breathing',
      category: 'wellness',
      title: 'Slow breathing and the body',
      tags: ['breathing', 'slow breathing', 'relaxation', 'vagus', 'parasympathetic'],
      keywords: [
        'slow breathing', 'does breathing help', 'breathing exercise', 'box breathing',
        '4-7-8', 'deep breathing', 'breath work', 'breathwork', 'how breathing affects',
      ],
      summary:
          'Slow, relaxed breathing is associated with changes in heart rhythm, brain activity and self-reported '
          'relaxation. A systematic review of small studies found these links, and a randomised study of short '
          'daily breathing practices found mood benefits in volunteers. Evidence is encouraging but modest, and '
          'results differ between people.',
      keyPoints: [
        'Pick a pace that feels easy; forcing long holds can make you feel worse.',
        'A slightly longer out-breath than in-breath is a common approach.',
        'A few minutes once or twice a day is a reasonable trial.',
      ],
      questionTypes: ['definition', 'why', 'howto', 'exercise'],
      safetyNotes: 'Stop if you feel dizzy or tingly. Breath-holding exercises may not suit people with some heart, lung or pregnancy-related conditions; check with a clinician.',
      limitations: 'Studies are small and varied and often involve healthy people; it is not a substitute for treatment.',
      evidence: EvidenceQuality.limited,
      sources: [_zaccaro, _balban, _nhsBreathing],
      reviewedOn: _kReviewed,
      recommendedResourceId: 'med_01',
      followUpQuestions: ['Guide me through slow breathing', 'How does breathing relate to HRV?'],
      isExercise: true,
    ),

    // -------------------------------------------------------------------- MOOD
    KnowledgeChunk(
      id: 'low_mood_ba',
      category: 'mood',
      title: 'Low mood and behavioural activation',
      tags: ['low mood', 'depression', 'sadness', 'motivation', 'behavioural activation'],
      keywords: [
        'feel down', 'feeling down', 'unmotivated', 'no energy', 'feeling blue', 'low mood',
        'depressed', 'sad', 'hopeless', 'empty', 'numb', 'behavioural activation',
        'behavioral activation', 'lonely',
      ],
      summary:
          'Low mood can make everything feel heavy, and doing less often makes mood lower still. Behavioural '
          'activation means gently scheduling small, achievable activities, especially ones that give a sense of '
          'pleasure, connection or accomplishment, even when motivation is low. It is one of the psychological '
          'treatments recommended for depression in UK guidance, usually delivered with a therapist.',
      keyPoints: [
        'Choose one very small activity today, such as a short walk, a shower, or a message to a friend.',
        'Do it even if you do not feel like it, then notice how you feel afterwards.',
        'Build up gradually rather than trying to fix everything at once.',
      ],
      questionTypes: ['definition', 'howto', 'exercise'],
      safetyNotes:
          'If low mood lasts most days for two weeks or more, or you have thoughts of harming yourself, please talk to a doctor, '
          'a therapist or a crisis service.',
      limitations: 'Self-guided steps are a gentle starting point and not a replacement for professional assessment or treatment.',
      evidence: EvidenceQuality.established,
      sources: [_nice222, _nimhDepression],
      reviewedOn: _kReviewed,
      recommendedResourceId: 'piano_01',
      followUpQuestions: ['Help me choose a small step for today', 'When should I see someone about this?'],
      isExercise: true,
    ),

    // ------------------------------------------------------------------- SLEEP
    KnowledgeChunk(
      id: 'sleep_wind_down',
      category: 'sleep',
      title: 'Sleep and winding down',
      tags: ['sleep', 'insomnia', 'bedtime', 'night', 'rest'],
      keywords: [
        'cant sleep', 'cannot sleep', 'cant fall asleep', 'insomnia', 'waking up at night',
        'wake up at 3am', 'sleep better', 'better sleep', 'bedtime routine', 'tired but wired',
        'cant get back to sleep', 'mind wont shut off in bed', 'sleep tips',
      ],
      summary:
          'Common advice for sleeping better is to keep regular sleep and wake times, wind down before bed, keep the '
          'bedroom dark, quiet and comfortably cool, and limit caffeine, alcohol, big late meals and screens close to '
          'bedtime. If you cannot sleep, getting up and doing something calm until you feel sleepy can help.',
      keyPoints: [
        'Keep the same wake-up time, even after a poor night.',
        'Create a 30-60 minute wind-down: dim lights, no work or doom-scrolling.',
        'Try a slow body scan or slow breathing in bed.',
        'Park worries earlier in the evening by writing them down with a next step.',
      ],
      questionTypes: ['howto', 'exercise', 'definition'],
      safetyNotes: 'If sleep problems last for several weeks or hurt your daytime functioning, talk to a doctor. CBT for insomnia is an evidence-based treatment.',
      limitations: 'General advice; the benefit of each individual habit varies between people.',
      evidence: EvidenceQuality.established,
      sources: [_nhsInsomnia],
      reviewedOn: _kReviewed,
      recommendedResourceId: 'rain_01',
      followUpQuestions: ['Guide me through a body scan', 'Does white noise help sleep?'],
      isExercise: true,
    ),

    // ------------------------------------------------------------------- AUDIO
    KnowledgeChunk(
      id: 'audio_relaxation',
      category: 'audio',
      title: 'Audio for relaxation: rain, noise, music and binaural beats',
      tags: ['audio', 'music', 'rain sounds', 'white noise', 'binaural beats', 'soundscape'],
      keywords: [
        'rain sounds', 'white noise', 'brown noise', 'binaural beats', 'binaural', 'soundscape',
        'relaxing music', 'ambient sound', 'do sounds help', 'nature sounds', 'does music help',
        'isochronic', '10 hz',
      ],
      summary:
          'Calming music has been linked with lower stress in a review of structured music interventions, and some '
          'people find rain or steady noise soothing. For noise as a sleep aid, a systematic review judged the '
          'evidence to be low quality and mixed. The claim that specific frequencies such as binaural beats reliably '
          'change brain state or mood is not firmly established.',
      keyPoints: [
        'Treat sounds as a comfort tool: use what you personally find soothing.',
        'Keep the volume moderate, especially for sleep.',
        'Judge by how you feel afterwards, not by the frequency on the label.',
      ],
      questionTypes: ['definition', 'why'],
      safetyNotes: 'Keep volume low enough to talk over comfortably; loud audio for long periods can damage hearing.',
      limitations:
          'The reviews cited are about music interventions and noise generally, not the specific YouTube tracks in this app. '
          'No verified review is cited for binaural beats.',
      evidence: EvidenceQuality.limited,
      sources: [_deWitte, _riedy],
      reviewedOn: _kReviewed,
      recommendedResourceId: 'rain_01',
      followUpQuestions: ['What helps me sleep?', 'Which sounds does the app have?'],
    ),

    // ------------------------------------------------------------------- FOCUS
    KnowledgeChunk(
      id: 'focus_environment',
      category: 'focus',
      title: 'Focus, distraction and your environment',
      tags: ['focus', 'concentration', 'distraction', 'studying', 'adhd', 'attention'],
      keywords: [
        'cant concentrate', 'cannot concentrate', 'cant focus', 'distracted', 'distraction',
        'studying', 'study', 'procrastinating', 'adhd', 'background noise', 'attention',
        'stop getting distracted', 'keep my focus',
      ],
      summary:
          'Focus is easier when the environment asks less of your attention: notifications off, one task at a time, '
          'short work blocks with breaks, and a place to jot down stray thoughts. Some people concentrate better with '
          'steady background sound; one small lab study found it helped children with ADHD on a memory task, but that '
          'has not been shown to carry over reliably to everyday life. ADHD is diagnosed by clinicians, not by '
          'headband readings.',
      keyPoints: [
        'Silence notifications and keep only one task visible.',
        'Work in short blocks (for example 25 minutes) with a real break.',
        'Keep a scrap of paper for intrusive thoughts and return to the task.',
        'Try steady, low-lyric sound and keep it only if it helps you.',
      ],
      questionTypes: ['howto', 'exercise', 'why'],
      safetyNotes: 'If concentration problems are long-standing or affect work, school or relationships, consider an assessment with a clinician.',
      limitations: 'Evidence for noise and focus is limited. Headband EEG cannot diagnose ADHD.',
      evidence: EvidenceQuality.limited,
      sources: [_soderlund, _nimhAdhd],
      reviewedOn: _kReviewed,
      recommendedResourceId: 'noise_03',
      followUpQuestions: ['Help me plan a focus block', 'Does sound help me concentrate?'],
      isExercise: true,
    ),

    // --------------------------------------------------------------------- EEG
    KnowledgeChunk(
      id: 'eeg_bands',
      category: 'eeg',
      title: 'EEG frequency bands: what alpha, beta, theta and delta mean',
      tags: ['eeg', 'brainwaves', 'alpha', 'beta', 'theta', 'delta', 'gamma', 'frequency bands'],
      keywords: [
        'alpha waves', 'beta waves', 'theta waves', 'delta waves', 'gamma waves', 'brainwaves',
        'brain waves', 'eeg bands', 'frequency bands', 'what is alpha', 'what is beta',
        'what is theta', 'what is delta', 'frequencies mean',
      ],
      summary:
          'EEG measures tiny electrical rhythms from the scalp, grouped by frequency: delta (about 0.5-4 Hz), theta '
          '(4-8 Hz), alpha (8-13 Hz), beta (13-30 Hz) and gamma (30 Hz and above). Alpha tends to be stronger in '
          'relaxed, awake states, especially with the eyes closed, and beta tends to be associated with active '
          'thinking and alertness. The bands describe brain rhythms, not feelings, and the link between a band and '
          'a mood or emotion is indirect and varies between people.',
      keyPoints: [
        'Delta: slowest rhythm; large in deep sleep but also picks up blinks and slow drift.',
        'Theta: linked with drowsiness and some memory/meditative states.',
        'Alpha: stronger in relaxed wakefulness.',
        'Beta: more active thinking and alertness.',
      ],
      questionTypes: ['definition', 'why'],
      limitations:
          'A Muse headband is a low-cost consumer device. It has been validated for research-style tasks (event-related '
          'potentials) but not for diagnosing emotions or mental-health conditions. Group-level EEG differences, such as '
          'theta/beta ratios in ADHD, cannot diagnose an individual.',
      evidence: EvidenceQuality.established,
      sources: [_klimesch, _krigolson, _arns],
      reviewedOn: _kReviewed,
      followUpQuestions: ['Why is my delta so high?', 'How does the app decide calm vs active?'],
    ),
    KnowledgeChunk(
      id: 'eeg_artifacts',
      category: 'eeg',
      title: 'Why delta looks high on a forehead headband',
      tags: ['eeg', 'delta', 'artifact', 'blink', 'signal quality', 'muscle'],
      keywords: [
        'delta always high', 'why is delta', 'delta highest', 'delta dominant', 'blink',
        'blinking', 'eye movement', 'artifact', 'artefact', 'jaw clench', 'noisy signal',
        'signal quality', 'bad reading', 'inaccurate',
      ],
      summary:
          'EEG power is naturally larger at low frequencies and falls off as frequency rises, so slow bands often look '
          'biggest. On a forehead headband, eye blinks, eye movements, slow drift from a loose fit and sweat add large '
          'low-frequency signal, while jaw and facial muscle tension add high-frequency noise. A large delta reading '
          'therefore often reflects these effects rather than deep relaxation.',
      keyPoints: [
        'Keep the headband snug and the sensors on clean, dry skin.',
        'Sit still and relax your jaw and forehead.',
        'Compare readings with your own baseline instead of a single number.',
      ],
      questionTypes: ['why', 'howto'],
      limitations: 'Artefacts cannot be completely removed from consumer devices, and I cannot tell from one reading what caused it.',
      evidence: EvidenceQuality.established,
      sources: [_uriguen, _krigolson],
      reviewedOn: _kReviewed,
      followUpQuestions: ['How does the app classify my state?', 'How can I get a cleaner signal?'],
    ),

    // --------------------------------------------------------------------- HRV
    KnowledgeChunk(
      id: 'hrv_basics',
      category: 'hrv',
      title: 'Heart rate and heart rate variability (HRV)',
      tags: ['hrv', 'rmssd', 'heart rate', 'variability', 'vagal', 'pulse'],
      keywords: [
        'what is hrv', 'heart rate variability', 'rmssd', 'low hrv', 'high hrv', 'good hrv',
        'hrv number', 'vagal tone', 'vagus nerve', 'resting heart rate', 'bpm', 'pulse',
        'heart rate',
      ],
      summary:
          'Heart rate is how many times your heart beats per minute. Heart rate variability (HRV) is the small '
          'variation in the time between beats. RMSSD is a common short-term HRV measure that mainly reflects the '
          'parasympathetic ("rest and digest") influence on the heart. HRV differs a lot with age, fitness, sleep, '
          'illness, caffeine and time of day, so there is no single "good" number; changes against your own baseline '
          'are more informative than comparing with other people.',
      keyPoints: [
        'Measure under similar conditions (for example, seated and at rest) to compare readings.',
        'A single low reading is not a diagnosis; stress, poor sleep or movement can all lower it.',
        'Slow breathing can transiently raise HRV.',
      ],
      questionTypes: ['definition', 'why'],
      limitations:
          'Optical heart sensors on a headband are less accurate than an ECG, and short or movement-affected windows '
          'give noisy HRV estimates. HRV cannot diagnose a medical or mental-health condition.',
      evidence: EvidenceQuality.established,
      sources: [_shaffer],
      reviewedOn: _kReviewed,
      recommendedResourceId: 'nature_01',
      followUpQuestions: ['Explain my current reading', 'Does breathing change HRV?'],
    ),

    // ----------------------------------------------------------------- SUPPORT
    KnowledgeChunk(
      id: 'professional_support',
      category: 'support',
      title: 'When to seek professional support',
      tags: ['therapy', 'therapist', 'doctor', 'professional help', 'treatment', 'diagnosis'],
      keywords: [
        'see a therapist', 'need therapy', 'professional help', 'see a doctor', 'counsellor',
        'counselor', 'psychiatrist', 'psychologist', 'should i get help', 'do i need help',
        'is this normal', 'how do i know',
      ],
      summary:
          'It is worth talking to a doctor or mental-health professional if distress lasts for weeks, keeps coming back, '
          'affects sleep, work, study or relationships, or you are using alcohol or other substances to cope. Early help '
          'often makes recovery easier. A professional can assess what is going on and discuss options; self-help tools like '
          'this app can sit alongside care but do not replace it.',
      keyPoints: [
        'Start with a doctor, GP or a licensed therapist or counsellor you trust.',
        'Do not stop or change prescribed medication without speaking to the prescriber.',
        'If you are in danger or thinking of harming yourself, use urgent help rather than waiting for an appointment.',
      ],
      questionTypes: ['howto', 'definition', 'safety'],
      limitations: 'Services differ by country. Nova cannot diagnose or assess you.',
      evidence: EvidenceQuality.established,
      sources: [_nimhHelp],
      reviewedOn: _kReviewed,
      followUpQuestions: ['What does the therapist feature in the app do?', 'What if I feel unsafe?'],
    ),

    // --------------------------------------------------------- NEUROSHIFT APP
    KnowledgeChunk(
      id: 'app_overview',
      category: 'app',
      title: 'What NeuroShift does',
      tags: ['neuroshift', 'app', 'features', 'muse', 'headband', 'sessions', 'resources'],
      keywords: [
        'what can neuroshift do', 'what does the app do', 'features', 'how does the app work',
        'connect my muse', 'connect my headband', 'pair headband', 'pair muse', 'bluetooth',
        'meditation modes', 'what can you do', 'calm points', 'birds',
      ],
      summary:
          'NeuroShift connects to a Muse 2 headband over Bluetooth and shows live EEG band activity, an optical heart-rate '
          'estimate and HRV, plus a neural-orb visual. You can run timed meditation sessions in several modes (Mind, Heart, '
          'Body, Breath, Soundscape), browse a resource library (guided meditations, rain and storm, white and brown noise, '
          'piano, nature sounds), review your session history, and chat with Nova. There is also a therapist portal. Use the '
          'Connect tab to pair the headband.',
      keyPoints: ['Pair the headband from the Connect tab.', 'Sessions record summary results such as time spent calm, neutral and active.'],
      questionTypes: ['definition', 'howto'],
      limitations: 'Describes the current build. Features not mentioned here may not exist.',
      evidence: EvidenceQuality.appDesign,
      reviewedOn: _kReviewed,
      followUpQuestions: ['How does the app decide calm vs active?', 'What data does the app store?'],
    ),
    KnowledgeChunk(
      id: 'app_state_classification',
      category: 'app',
      title: 'How NeuroShift labels Calm, Neutral and Active',
      tags: ['calm', 'neutral', 'active', 'classification', 'mind state', 'alpha beta'],
      keywords: [
        'how does the app decide', 'calm or active', 'calm neutral active', 'how is calm measured',
        'what counts as calm', 'mind state', 'how does it work out', 'classify',
        'why does it say active', 'why does it say calm',
      ],
      summary:
          'The app takes a short window of signal from one forehead sensor (AF7), turns it into band powers with a Fourier '
          'transform, and compares alpha with beta (ignoring delta). If alpha is clearly higher than beta it shows Calm; if beta '
          'is clearly higher it shows Active; otherwise Neutral. This is a simple rule of thumb. It has not been validated as '
          'a measure of emotions or mental health, and movement, blinks and a loose fit can change it.',
      keyPoints: ['Calm, Neutral and Active are the app\'s own labels, not clinical states.'],
      questionTypes: ['why', 'definition'],
      limitations: 'Uses a single frontal channel and a heuristic threshold; not a clinical tool.',
      evidence: EvidenceQuality.appDesign,
      sources: [_krigolson],
      reviewedOn: _kReviewed,
      followUpQuestions: ['Why is delta so high?', 'Explain my current reading'],
    ),
    KnowledgeChunk(
      id: 'app_privacy_data',
      category: 'app',
      title: 'Data, privacy, recordings and deleting',
      tags: ['privacy', 'data', 'storage', 'delete', 'recording', 'chat history'],
      keywords: [
        'what happens to my data', 'my data', 'privacy', 'is it private', 'does the app save',
        'save my chats', 'chat history', 'delete my recording', 'delete recording', 'delete my data',
        'delete my session', 'audio recording', 'who can see', 'is it stored',
      ],
      summary:
          'You sign in with a Firebase account. When you finish a session, a summary (mode, duration, time spent calm, neutral '
          'and active, average heart rate and HRV and similar totals) is saved to your account in the app\'s cloud database; raw EEG '
          'waveforms are not saved. Nova conversations are kept only in memory on the chat screen and are not saved by the app. '
          'When the online AI is enabled, your messages (and, only when you ask about your readings, a short summary of them) are '
          'sent to Google\'s Gemini service to generate a reply. I do not find any audio-recording feature in this version of the app. '
          'The data layer can delete a saved session record, but I have not confirmed that a delete button is available in the '
          'current screens, so I cannot promise how to do it. I also cannot give you a complete guarantee of who can read stored '
          'records.',
      keyPoints: ['Avoid sharing names, addresses or other identifying details in chat.'],
      questionTypes: ['privacy'],
      limitations: 'Based on how the current build is written; policies may change.',
      evidence: EvidenceQuality.appDesign,
      reviewedOn: _kReviewed,
      followUpQuestions: ['What does the therapist portal share?', 'What can NeuroShift do?'],
    ),
    KnowledgeChunk(
      id: 'app_therapist',
      category: 'app',
      title: 'Therapist portal',
      tags: ['therapist', 'portal', 'prescription', 'access', 'sharing'],
      keywords: [
        'taherapist portal', 'share with my therapist', 'therapist access', 'therapist see',
        'prescribe', 'prescription', 'link my therapist', 'who can see my sessions',
        'practitioner', 'invite therapist',
      ],
      summary:
          'The app has a therapist side. A client can invite a therapist by email to link with them, and the therapist can accept. '
          'A linked therapist can see the client\'s session results, exchange messages and recommend resources from the library, which '
          'the client can then practise with the headband. The exact controls available may change between versions.',
      keyPoints: [],
      questionTypes: ['definition', 'howto', 'privacy'],
      limitations: 'Describes intended behaviour from the app\'s design; I cannot verify the access rules in detail.',
      evidence: EvidenceQuality.appDesign,
      reviewedOn: _kReviewed,
      followUpQuestions: ['What data does the app store?'],
    ),
    KnowledgeChunk(
      id: 'app_nova_scope',
      category: 'app',
      title: 'About Nova',
      tags: ['nova', 'ai', 'chatbot', 'scope', 'limits', 'therapist'],
      keywords: [
        'who are you', 'what are you', 'are you a therapist', 'are you a real therapist',
        'are you human', 'are you real', 'are you a bot', 'are you ai', 'can you diagnose',
        'can i trust you', 'are you a doctor', 'what is nova',
      ],
      summary:
          'I am Nova, an AI wellness guide inside NeuroShift. I am not a therapist, doctor or emergency service, I cannot '
          'diagnose anything, and I can make mistakes. I can chat, explain wellness and biosignal concepts in plain language, '
          'guide simple calming exercises and help you make sense of your readings. For personal medical or mental-health '
          'decisions, please talk to a qualified professional.',
      keyPoints: [],
      questionTypes: ['scope', 'definition'],
      limitations: 'Offline mode is much simpler than online mode.',
      evidence: EvidenceQuality.appDesign,
      reviewedOn: _kReviewed,
      followUpQuestions: ['What can you help me with?', 'What data does the app store?'],
    ),

    // ------------------------------------------------------------------ CRISIS
    // Used only by the safety module; never returned by normal retrieval.
    KnowledgeChunk(
      id: 'crisis_support',
      category: 'crisis',
      title: 'Crisis support and emergency guidance',
      tags: ['crisis', 'suicide', 'self harm', 'emergency'],
      keywords: [],
      summary:
          'If you may be in immediate danger, contact your local emergency number. Free, confidential helplines exist in many '
          'countries; the directories below list them by country.',
      limitations: 'Numbers and hours differ by country. Nova does not hold a complete verified list.',
      evidence: EvidenceQuality.established,
      sources: [_findAHelpline, _iasp],
      reviewedOn: _kReviewed,
    ),
  ];

  static KnowledgeChunk? byId(String id) {
    for (final c in chunks) {
      if (c.id == id) return c;
    }
    return null;
  }
}

