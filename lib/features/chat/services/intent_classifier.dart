import '../models/ai_chat_message.dart';

enum NovaIntent {
  /// "Hi", "hello nova", "how are you".
  greeting,

  /// "thanks", "bye".
  thanksOrFarewell,

  /// A first-person feeling or hard experience.
  emotionalSupport,

  /// A factual wellness, biosignal or EEG/HRV question.
  wellnessQuestion,

  /// Questions about the user's own live readings.
  telemetryQuestion,

  /// A request to be guided through something (breathing, grounding...).
  exerciseRequest,

  /// Questions about NeuroShift, privacy, Nova itself.
  appQuestion,

  /// Anything else.
  general,
}

/// Lightweight, deterministic intent detection. It decides which pipeline
/// steps run (retrieval, telemetry, resources); it does NOT write replies.
class IntentClassifier {
  const IntentClassifier();

  static String _norm(String s) {
    var t = s.toLowerCase();
    t = t.replaceAll('\u2019', "'").replaceAll('\u2018', "'");
    t = t.replaceAll(RegExp(r"[^a-z0-9'\s\-]"), ' ');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static final _greetingWords = RegExp(
    r"^(hi|hello|hey|hiya|heya|yo|howdy|sup|greetings|good (morning|afternoon|evening)|hey there|hi there|hello there)\b",
  );
  static const _greetingFiller = {
    'nova', 'there', 'how', 'are', 'you', 'doing', 'today', 'again', 'is', 'it',
    'going', "what's", 'whats', 'up', 'hi', 'hello', 'hey', 'good', 'morning',
    'afternoon', 'evening', 'my', 'friend', 'buddy', 'so', 'much',
  };
  static final _howAreYou = RegExp(r"^(how are you|how are you doing|how's it going|hows it going|how r u|what's up|whats up)( nova| today)?$");
  static final _thanks = RegExp(r"^(thanks|thank you|thx|ty|cheers|much appreciated|thanks a lot|thank you so much|appreciate it)( nova| so much| a lot)?$");
  static final _farewell = RegExp(r"^(bye|goodbye|good night|goodnight|see you|see you later|talk later|talk to you later|take care|cya)( nova| soon)?$");

  static final _telemetryTopic = RegExp(
    r"\b(brainwaves?|brain waves?|eeg|alpha|beta|theta|delta|gamma|heart rate|hrv|rmssd|pulse|bpm|readings?|mind state|headband data|stillness|signal)\b",
  );
  static final _myOrLive = RegExp(r"\b(my|mine|current|currently|live|right now|at the moment|now|just now|these|this reading)\b");
  static final _telemetryDirect = RegExp(
    r"\b(analy[sz]e my|interpret my|explain my (reading|brainwave|eeg|heart|hrv|result)|what do my (brainwaves?|readings?|numbers?|eeg|results?) mean|am i (calm|relaxed|stressed|anxious|focused|active)( right now)?|how (calm|relaxed|stressed) am i|what('?s| is) my (heart rate|hrv|mind state|state|reading))\b",
  );

  static final _exercisePatterns = <RegExp>[
    RegExp(r"\b(guide|walk|lead|talk|coach|take) me (through|into)\b"),
    RegExp(r"\b(teach|show) me (how to |a |an |some )?(breath|breathing|ground|grounding|meditat|relax|exercise|technique|sigh|box breathing|body scan)"),
    RegExp(r"\b(start|begin|do|try|give me|need|want|can we do|can you give me|let'?s do)( a| an| some| the)? ?(quick |short |simple |breathing |grounding |relaxation |calming )*(exercise|meditation|breathing|grounding|technique|body scan|session|practice)\b"),
    RegExp(r"\bhelp me (to )?(calm|relax|breathe|slow|ground|sleep|focus|unwind|settle|wind down|de-?stress)\b"),
    RegExp(r"\bcalm (me|myself) down\b"),
    RegExp(r"\b(can you |could you |please )?help me calm\b"),
    RegExp(r"\bi (need|want) to (calm down|relax|breathe|unwind|ground myself)\b"),
    RegExp(r"\bcalm (my )?(anxiety|nerves|mind|down)( now| down)?\b"),
    RegExp(r"\bbox breathing guide\b"),
    RegExp(r"\b(breathing|grounding|sleep|focus) (guide|protocol|exercise|reset)\b"),
    RegExp(r"\bplay (some |a |an )?(music|sounds?|soundscape|meditation|rain|piano|audio)\b"),
  ];

  static final _appPatterns = <RegExp>[
    RegExp(r"\b(neuroshift|neuro shift|this app|the app|your app|(what|who) (is|are) nova)\b"),
    RegExp(r"\b(my data|my privacy|privacy|is it private|stored|storing|saved|save my|chat history|delete (my |the )?(recording|data|session|account|chat)|recordings?|who can see|who sees|share my|gdpr)\b"),
    RegExp(r"\b(connect|pair|pairing) (my |the )?(muse|headband|device)\b"),
    RegExp(r"\b(what can you do|what do you do|who are you|what are you|are you (a |an )?(real|human|bot|ai|robot|therapist|doctor|person)|can i trust you|can you diagnose)\b"),
    RegExp(r"\b(therapist portal|link my therapist|invite (a |my )?therapist|therapist (see|access|portal))\b"),
  ];

  static final _emotionLexicon = RegExp(
    r"\b(anxious|anxiety|stressed|stress|sad|down|low|depressed|tired|exhausted|drained|overwhelmed|lonely|alone|angry|upset|difficult|hard|rough|tough|terrible|awful|bad|worried|worry|scared|afraid|nervous|hopeless|burnt out|burned out|struggling|miserable|frustrated|hurt|cry|crying|numb|empty|panicking|panic|lost|stuck|ashamed|guilty|jealous|irritated|annoyed|restless|on edge|can'?t cope|not okay|not ok|not coping|failing)\b",
  );
  static final _firstPerson = RegExp(r"\b(i|i'm|im|i've|ive|i am|i was|i feel|feeling|my|me|we)\b");
  static final _hardDay = RegExp(r"\b(bad|hard|rough|tough|difficult|long|terrible|awful|stressful|exhausting|horrible) (day|week|night|morning|month|time|year)\b");

  static final _questionStart = RegExp(
    r"^(what|why|how|does|do|is|are|can|could|should|when|which|who|explain|tell me|define|whats|what's|hows|how's|any tips|tips|is it)\b",
  );
  static final _offerInPrevious = RegExp(
    r"(guide you|walk you through|would you like to try|want to try|shall we try|i can guide|i can walk|want me to guide|like me to guide)",
  );
  static final _simpleYes = RegExp(r"^(yes|yeah|yep|yup|sure|ok|okay|please|yes please|sounds good|let'?s do it|let'?s try|go ahead|i'?d like that|alright)( please| nova)?$");

  /// Classify [message]. [previousAssistantText] lets short replies such as
  /// "yes please" continue the thread.
  NovaIntent classify(String message, {String? previousAssistantText}) {
    final t = _norm(message);
    if (t.isEmpty) return NovaIntent.general;

    // Short "yes please" after Nova offered to guide an exercise.
    if (_simpleYes.hasMatch(t) &&
        previousAssistantText != null &&
        _offerInPrevious.hasMatch(previousAssistantText.toLowerCase())) {
      return NovaIntent.exerciseRequest;
    }

    if (_howAreYou.hasMatch(t) || _isPureGreeting(t)) return NovaIntent.greeting;
    if (_thanks.hasMatch(t) || _farewell.hasMatch(t)) return NovaIntent.thanksOrFarewell;

    // Telemetry about the user's own readings.
    if (_telemetryDirect.hasMatch(t) ||
        (_telemetryTopic.hasMatch(t) && _myOrLive.hasMatch(t) && !_appPatterns[1].hasMatch(t))) {
      return NovaIntent.telemetryQuestion;
    }

    if (_appPatterns.any((re) => re.hasMatch(t))) return NovaIntent.appQuestion;

    if (_exercisePatterns.any((re) => re.hasMatch(t))) return NovaIntent.exerciseRequest;

    final isQuestion = _questionStart.hasMatch(t) || message.trim().endsWith('?');
    final hasEmotion = _emotionLexicon.hasMatch(t) || _hardDay.hasMatch(t);
    final firstPerson = _firstPerson.hasMatch(t);

    // Personal disclosure (statement, or "why do I feel...") wins over facts.
    if (hasEmotion && firstPerson && !_isPureFactQuestion(t)) {
      return NovaIntent.emotionalSupport;
    }

    if (isQuestion) return NovaIntent.wellnessQuestion;

    // Ordinary statement in an ongoing conversation (e.g. "I'm scared I'll
    // forget everything") is treated as a continuation of support.
    if (firstPerson && t.split(' ').length >= 3 && previousAssistantText != null) {
      return NovaIntent.emotionalSupport;
    }
    return NovaIntent.general;
  }

  bool _isPureGreeting(String t) {
    if (!_greetingWords.hasMatch(t)) return false;
    final words = t.split(' ');
    if (words.length > 7) return false;
    return words.every(_greetingFiller.contains);
  }

  // "what is anxiety" is a fact question; "why do I feel anxious" is personal.
  bool _isPureFactQuestion(String t) {
    return RegExp(r"^(what is|what are|what does|define|explain|how does|how do)\b").hasMatch(t) &&
        !RegExp(r"\b(i|i'm|im|my|me)\b").hasMatch(t);
  }

  /// Panic-style statements where offering a calming exercise is appropriate.
  static bool isAcuteStress(String message) {
    return RegExp(r"\b(panic attack|panicking|can'?t breathe|cannot breathe|heart (is )?(pounding|racing)|freaking out|hyperventilat\w*|chest (is )?tight)\b")
        .hasMatch(_norm(message));
  }

  /// Whether the user's text asks for audio/music specifically (used to allow
  /// a resource card outside explicit exercise requests).
  static bool asksForAudio(String message) {
    return RegExp(r"\b(play|listen|music|sounds?|soundscape|audio|rain|piano|playlist)\b")
        .hasMatch(_norm(message));
  }

  /// Short acknowledgement kinds.
  static bool isFarewell(String message) => _farewell.hasMatch(_norm(message));
  static bool isHowAreYou(String message) => _howAreYou.hasMatch(_norm(message));

  // Exposed for tests and for the context-aware engine.
  static SafetyStatus lastSafety(List<AiChatMessage> history) {
    for (var i = history.length - 1; i >= 0; i--) {
      final m = history[i];
      if (!m.isUser) return m.safetyStatus;
    }
    return SafetyStatus.none;
  }
}
