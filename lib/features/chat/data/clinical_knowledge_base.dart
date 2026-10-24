/// A discrete, clinically verified chunk of neuro-psychological knowledge
/// used by the Bio-RAG (Retrieval-Augmented Generation) engine.
class KnowledgeChunk {
  final String id;
  final String category; // 'eeg_neuroscience', 'hrv_vagal', 'cbt_somatic', 'sleep', 'adhd_focus', 'crisis'
  final String title;
  final List<String> tags;
  final List<String> keywords;
  final String clinicalSummary;
  final List<String> actionableProtocols;
  final String? recommendedResourceId;
  final List<String> followUpQuestions;

  const KnowledgeChunk({
    required this.id,
    required this.category,
    required this.title,
    required this.tags,
    required this.keywords,
    required this.clinicalSummary,
    required this.actionableProtocols,
    this.recommendedResourceId,
    required this.followUpQuestions,
  });
}

class ClinicalKnowledgeBase {
  static const List<KnowledgeChunk> chunks = [
    // 1. Acute Anxiety & Panic Grounding
    KnowledgeChunk(
      id: 'rag_anxiety_01',
      category: 'cbt_somatic',
      title: 'Acute Autonomic Panic & Somatic Reset',
      tags: ['anxiety', 'panic', 'fear', 'overwhelm', 'racing heart', 'hyperventilation'],
      keywords: [
        'anxious', 'panic', 'scared', 'freaking out', 'calm down', 'can\'t breathe',
        'chest tight', 'shaking', 'nervous', 'terrified', 'overwhelmed', 'attack'
      ],
      clinicalSummary:
          'Panic attacks and acute anxiety represent sudden sympathetic nervous system surges '
          '(fight-or-flight overdrive). The amygdala signals acute threat, prompting rapid shallow breathing, '
          'tachycardia, and cortical vasoconstriction. Cognitive logic cannot immediately override an acute '
          'amygdala surge; physiological downregulation must precede cognitive restructuring.',
      actionableProtocols: [
        'The Physiological Sigh: Two quick inhales through the nose (one deep, one short top-off), followed by a slow, unforced vocalized exhale through the mouth. 3 cycles directly triggers the vagal brake.',
        '5-4-3-2-1 Sensory Orientation: Ground neural processing in the physical present—identify 5 visible objects, 4 touchable textures, 3 distinct sounds, 2 scents, and 1 slow breath.',
        'Peripheral Gaze Dilatation: Soften your focal gaze to view your entire peripheral field. Narrow tunnel vision activates autonomic arousal; dilating visual gaze downregulates sympathetic tone.',
      ],
      recommendedResourceId: 'med_03', // 10-Min Meditation for Anxiety
      followUpQuestions: [
        'Guide me through a 2-minute physiological sigh',
        'Why does my heart beat fast during anxiety?',
        'Start 10-Min Calming Session',
      ],
    ),

    // 2. Alpha Brainwaves & Cortical Calming
    KnowledgeChunk(
      id: 'rag_eeg_alpha',
      category: 'eeg_neuroscience',
      title: 'Alpha Rhythm (8–13 Hz) & Mindful Synchrony',
      tags: ['alpha', 'brainwaves', 'eeg', 'calm', 'meditation', 'relaxation'],
      keywords: [
        'alpha', 'brainwave', 'brainwaves', '8hz', '10hz', '12hz', 'calm state',
        'meditation waves', 'synchrony', 'berger effect', 'calm points', 'birds'
      ],
      clinicalSummary:
          'Alpha waves (8–13 Hz) are generated predominantly in occipital and parietal cortices during '
          'wakeful relaxation with eyes closed (the Berger effect). In neurofeedback, Alpha represents '
          'functional cortical gating—the brain actively suppressing irrelevant sensory input and internal noise. '
          'A higher Alpha/Beta ratio reflects parasympathetic nervous system dominance and mindful presence.',
      actionableProtocols: [
        'Eye-Closure Alpha Surge: Simply closing your eyes and resting your gaze downward behind your eyelids increases occipital alpha power by up to 50%.',
        'Diaphragmatic Rhythmic Pacing: Breathe at 5.5 to 6 breaths per minute. Cardiorespiratory synchronization induces thalamocortical alpha oscillation bursts.',
        'Acoustic Alpha Entrainment: Listening to 10 Hz isochronic or binaural soundscapes reinforces bilateral cortical synchrony.',
      ],
      recommendedResourceId: 'noise_01', // Pure Alpha Wave Resonance
      followUpQuestions: [
        'How do I increase my Alpha waves in real-time?',
        'What is the difference between Alpha and Beta waves?',
        'Start Alpha Wave Soundscape',
      ],
    ),

    // 3. Beta Brainwaves & Stress / Active Cognition
    KnowledgeChunk(
      id: 'rag_eeg_beta',
      category: 'eeg_neuroscience',
      title: 'Beta Rhythm (13–30 Hz) & Cognitive Arousal',
      tags: ['beta', 'brainwaves', 'focus', 'stress', 'overthinking', 'racing mind'],
      keywords: [
        'beta', 'active state', 'overthinking', 'racing thoughts', 'stressed', 'analytical',
        'high beta', 'cortical arousal', 'mental fatigue', 'cannot turn off brain'
      ],
      clinicalSummary:
          'Beta waves (13–30 Hz) represent fast, desynchronized cortical processing. Low Beta (13–18 Hz) '
          'is vital for active focus, problem-solving, and executive functioning. However, High Beta (20–30 Hz) '
          'correlates with hypervigilance, rumination, cognitive stress, and sustained muscular guarding.',
      actionableProtocols: [
        'Cognitive Defusion: Treat thoughts as external sensory events rather than immediate imperatives. Label the process: "I notice my mind is generating problem-solving predictions."',
        'Somatic Release: High Beta is linked to subtle jaw, brow, and neck tension. Deliberately drop your tongue from the roof of your mouth and drop your shoulders.',
        'Acoustic Brown Noise Masking: Deep low-frequency noise dampens high-frequency sensory gating demands on the prefrontal cortex.',
      ],
      recommendedResourceId: 'noise_02', // Deep Brown Noise
      followUpQuestions: [
        'Why is my app showing Active state?',
        'How to transition from Beta to Alpha?',
        'Start Brown Noise Session',
      ],
    ),

    // 4. Theta Brainwaves & Deep Flow vs. Drowsiness
    KnowledgeChunk(
      id: 'rag_eeg_theta',
      category: 'eeg_neuroscience',
      title: 'Theta Rhythm (4–8 Hz) & Twilight Absorption',
      tags: ['theta', 'flow', 'subconscious', 'drowsiness', 'deep meditation'],
      keywords: [
        'theta', 'deep flow', 'hypnagogic', 'daydream', 'creativity', 'drowsy',
        'sleepy during meditation', 'twilight state', 'adhd ratio'
      ],
      clinicalSummary:
          'Theta waves (4–8 Hz) occur in the limbic system, hippocampus, and frontal midline during '
          'hypnagogic transition (between waking and sleeping), memory consolidation, and deep mantra meditation. '
          'In advanced neurofeedback, simultaneous Alpha and Theta elevation signifies the "Alpha-Theta crossover," '
          'a hallmark of creative breakthrough and deep trauma processing.',
      actionableProtocols: [
        'Distinguishing Flow from Drowsiness: If Theta rises while Alpha remains strong and posture is upright, you are in deep meditative flow. If Theta rises while Alpha collapses and head nods, you are falling asleep.',
        'Non-Sleep Deep Rest (NSDR): Use structured body-scan audio to sustain conscious theta states without descending into stage-1 sleep.',
      ],
      recommendedResourceId: 'sound_02', // Tibetan Singing Bowls
      followUpQuestions: [
        'Am I meditating deeply or just getting sleepy?',
        'What is an Alpha-Theta crossover?',
        'Play Deep Flow Soundscape',
      ],
    ),

    // 5. Delta Brainwaves & Restorative Physiology
    KnowledgeChunk(
      id: 'rag_eeg_delta',
      category: 'eeg_neuroscience',
      title: 'Delta Rhythm (0.5–4 Hz) & The 1/f Power Law',
      tags: ['delta', 'sleep', 'deep sleep', 'artifacts', '1/f law', 'blinking'],
      keywords: [
        'delta', 'dominant wave', 'why delta so high', 'sleep waves', 'slow wave',
        'eog', 'blink artifact', '1/f noise', 'pink noise'
      ],
      clinicalSummary:
          'Delta waves (0.5–4 Hz) are large, slow synchronized cortical oscillations characteristic of '
          'Stage 3/4 non-REM deep slow-wave sleep. In awake EEG recordings, Delta power is numerically '
          'dominant due to two factors: 1) The physical 1/f power-law distribution of biological electrodynamics, '
          'and 2) Frontal electro-ocular artifacts (EOG)—every microscopic eye blink or movement creates '
          'a large dipole wave in the 1–3 Hz Delta band. For this reason, wakeful meditation state classification '
          'deliberately isolates the 4–30 Hz cognitive spectrum (Theta, Alpha, Beta).',
      actionableProtocols: [
        'Keep Gaze Steady: To prevent ocular Delta spikes during practice, keep eyelids softly closed without squeezing or rapid eye darting.',
        'Ensure Electrode Adhesion: Loose headband sensors generate low-frequency baseline impedance drift that mimics Delta waves.',
      ],
      recommendedResourceId: 'rain_01', // Soothing Rain for Deep Delta Rest
      followUpQuestions: [
        'Why does my app show Delta as dominant?',
        'How does Muse measure meditation calm?',
        'Explore Sleep Protocols',
      ],
    ),

    // 6. Heart Rate Variability (HRV) & Vagal Tone
    KnowledgeChunk(
      id: 'rag_hrv_vagus',
      category: 'hrv_vagal',
      title: 'Heart Rate Variability (HRV / RMSSD) & Vagal Tone',
      tags: ['hrv', 'rmssd', 'heart rate', 'vagus nerve', 'autonomic', 'bpm'],
      keywords: [
        'hrv', 'heart rate', 'rmssd', 'vagal tone', 'vagus nerve', 'bpm',
        'pulse', 'heart variability', 'autonomic balance', 'polyvagal'
      ],
      clinicalSummary:
          'Heart Rate Variability (HRV) measures the minute, millisecond variations between consecutive heartbeats (R-R intervals). '
          'RMSSD (Root Mean Square of Successive Differences) specifically quantifies parasympathetic vagal activation. '
          'A healthy cardiovascular system is not a rigid metronome; high HRV (>40–70 ms) signals autonomic flexibility, '
          'resilience, and fast recovery from stress. Low HRV (<25–30 ms) signals chronic sympathetic overdrive, fatigue, or illness.',
      actionableProtocols: [
        'Resonance Frequency Breathing: Inhale smoothly for 5.5 seconds, exhale smoothly for 5.5 seconds (~5.5 breaths per minute). This synchronizes heart rate oscillations with breathing (Respiratory Sinus Arrhythmia), maximizing HRV.',
        'Cold Somatic Stimulus: Splashing cold water on your temples and eyes stimulates the mammalian diving reflex, instantly triggering the vagus nerve to slow the pulse.',
        'Post-Meal Rest: Allow 30 minutes after heavy meals before expecting peak HRV, as digestion requires visceral blood flow.',
      ],
      recommendedResourceId: 'nature_01', // Ocean Shore Waves
      followUpQuestions: [
        'What is a good RMSSD number for me?',
        'How does breathing affect my heart rate?',
        'Start 5.5s Coherent Breathing Practice',
      ],
    ),

    // 7. ADHD, Focus & Cognitive Distraction
    KnowledgeChunk(
      id: 'rag_adhd_focus',
      category: 'adhd_focus',
      title: 'ADHD Executive Regulation & Neural Focus Optimization',
      tags: ['adhd', 'focus', 'distraction', 'dopamine', 'studying', 'procrastination'],
      keywords: [
        'adhd', 'focus', 'distracted', 'cannot concentrate', 'study', 'work',
        'procrastinating', 'dopamine', 'executive function', 'task paralysis'
      ],
      clinicalSummary:
          'ADHD and acute distraction represent prefrontal dopamine dysregulation and sensory gating overflow. '
          'When internal or external stimuli continually break attentional salience, the brain struggles to maintain '
          'active task networks. In EEG, individuals with ADHD frequently exhibit elevated frontal Theta relative to Beta '
          '(high Theta/Beta Ratio), indicating cognitive under-arousal that leads to restless seeking behaviors.',
      actionableProtocols: [
        'Binaural Acoustic Sound Blanketing: Continuous Brown or Pink noise suppresses acoustic novelty, shielding working memory from auditory distractions.',
        'The 10-Minute Micro-Agreement: Defeat task paralysis by agreeing to work for only 10 minutes. 80% of executive resistance dissolves once momentum is established.',
        'External Working Memory Buffer: Keep an index card beside your workspace. Every time a tangential thought arrives, write it down in 3 words and immediately return.',
      ],
      recommendedResourceId: 'noise_03', // Gentle Lofi Beats for Study
      followUpQuestions: [
        'Explain the Theta/Beta ADHD ratio',
        'How does acoustic noise help ADHD brains?',
        'Start Focus Audio Session',
      ],
    ),

    // 8. Sleep Hygiene & Insomnia Wind-Down
    KnowledgeChunk(
      id: 'rag_sleep_nsdr',
      category: 'sleep',
      title: 'Circadian Wind-Down & Sleep Architecture',
      tags: ['sleep', 'insomnia', 'night', 'tired', 'rest', 'melatonin'],
      keywords: [
        'sleep', 'insomnia', 'cannot sleep', 'wake up at night', 'bedtime',
        'tired but wired', 'rest', 'sleep protocol', 'night routine'
      ],
      clinicalSummary:
          'Healthy sleep onset requires a dual physiological cascade: 1) Adenosine sleep pressure accumulation, '
          'and 2) Autonomic downshifting marked by a 1°C drop in core body temperature and prefrontal Alpha-to-Theta transition. '
          'Blue-spectrum photons (450–480 nm) and high cognitive Beta activity suppress pineal melatonin release.',
      actionableProtocols: [
        'Non-Sleep Deep Rest (NSDR): Perform a 10-minute guided body scan to release somatic muscular tension in the jaw, trapezius, and hips before attempting sleep.',
        'Temperature Drop: Cool your bedroom to ~18°C (65°F). Taking a warm shower 60 minutes before bed triggers vasodilation, cooling core temperature.',
        'Sensory Safe Haven: Continuous rainfall or forest ambience provides predictable auditory stimulation, reassuring evolutionary vigilance circuits.',
      ],
      recommendedResourceId: 'rain_02', // Gentle Night Rain on Tent
      followUpQuestions: [
        'What is Non-Sleep Deep Rest (NSDR)?',
        'Guide me through a pre-sleep body scan',
        'Play Sleep Ambience',
      ],
    ),

    // 9. Low Energy, Sadness & Behavioral Activation
    KnowledgeChunk(
      id: 'rag_cbt_mood',
      category: 'cbt_somatic',
      title: 'Low Valence, Depressive Fatigue & Behavioral Activation',
      tags: ['depression', 'sadness', 'low energy', 'grief', 'unmotivated', 'empty'],
      keywords: [
        'depressed', 'sad', 'unmotivated', 'hopeless', 'low energy', 'numb',
        'empty', 'lonely', 'exhausted', 'crying', 'heavy heart'
      ],
      clinicalSummary:
          'Low emotional valence and depressive fatigue often create a self-reinforcing somatic feedback loop: '
          'dorsal vagal hypo-arousal leads to behavioral immobilization, which further starves the brain of '
          'dopaminergic and serotonergic reinforcement. In CBT, the frontline intervention is Gentle Behavioral '
          'Activation—engaging in tiny, low-demand physical and sensory inputs to re-engage the nervous system.',
      actionableProtocols: [
        'Micro-Movements: Do not aim for full workouts. Engage in 2 minutes of spinal stretching, stepping outside for natural ocular photons, or drinking cold water.',
        'Compassionate Self-Validation: Radical acceptance—remind yourself: "My nervous system is conserving energy right now. I do not have to fix everything today."',
        'Acoustic Resonance: Listening to peaceful, emotionally coherent acoustic piano or gentle nature sounds supports emotional processing without sensory overwhelm.',
      ],
      recommendedResourceId: 'piano_01', // Peaceful Relaxing Piano
      followUpQuestions: [
        'What is behavioral activation?',
        'Give me 3 gentle micro-actions for today',
        'Play Peaceful Piano',
      ],
    ),

    // 10. Crisis & Psychiatric Safety Protocol
    KnowledgeChunk(
      id: 'rag_crisis_protocol',
      category: 'crisis',
      title: 'Emergency Crisis Safety & Professional Support',
      tags: ['crisis', 'suicide', 'self harm', 'emergency', 'help', 'danger'],
      keywords: [
        'kill myself', 'suicide', 'die', 'end it all', 'hurt myself', 'self-harm',
        'cannot go on', 'want to die', 'harming myself'
      ],
      clinicalSummary:
          'Immediate safety containment is paramount when self-harm or suicidal ideation is expressed. '
          'AI systems are supportive educational guides and must never substitute for acute crisis de-escalation '
          'or professional clinical intervention.',
      actionableProtocols: [
        '988 Suicide & Crisis Lifeline: Call or text 988 (Available 24/7, free, confidential in the US and Canada).',
        'Crisis Text Line: Text HOME to 741741 to connect with a live Crisis Counselor 24/7.',
        'International Resources: Visit https://findahelpline.com or call local emergency dispatch (911 / 112 / 999).',
        'Therapist Connect: If you have an active practitioner linked in NeuroShift, open the Practitioner Portal to send an urgent check-in note.',
      ],
      recommendedResourceId: null,
      followUpQuestions: [
        'Connect with my therapist in NeuroShift',
        'Show emergency hotline numbers',
      ],
    ),
  ];
}
