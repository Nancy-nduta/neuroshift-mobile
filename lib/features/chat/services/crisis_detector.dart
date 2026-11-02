import '../models/ai_chat_message.dart';
import '../models/crisis_helpline.dart';

/// Result of a safety assessment of one user message in context.
class SafetyAssessment {
  final SafetyStatus status;

  /// Short machine-readable reason (never contains user text).
  final String reason;

  const SafetyAssessment(this.status, this.reason);

  static const none = SafetyAssessment(SafetyStatus.none, 'none');

  bool get needsProtocol => status != SafetyStatus.none;
}

/// Deterministic, model-independent safety screening.
///
/// This runs BEFORE any retrieval or generation and its outcome cannot be
/// overridden by a model reply. It uses word-boundary patterns (so "diet" or
/// "studied" never match "die"), handles negation, indirect statements, and
/// the context of the previous Nova turn.
class CrisisDetector {
  const CrisisDetector();

  static String _normalize(String input) {
    var t = input.toLowerCase();
    t = t.replaceAll('\u2019', "'").replaceAll('\u2018', "'").replaceAll('`', "'");
    t = t.replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  // Phrases that make the statement about someone/something else or
  // informational rather than first-person distress.
  static final _negated = RegExp(
    r"\b(i'?m not|i am not|im not|not feeling|no longer|never been|don'?t feel|do not feel|i don'?t have|i do not have|i have no|no thoughts of|nothing like)\b[^.]{0,30}\b(suicidal|suicide|want to die|kill myself|harm myself|hurt myself|self harm)\b",
  );

  static final List<RegExp> _imminent = [
    RegExp(r"\b(going to|gonna|about to|am going to|i'?ll|i will|planning to|plan to|decided to)\b[^.]{0,25}\b(kill myself|end my life|take my own life|end it all|overdose|hang myself|jump off|shoot myself|cut my wrists)\b"),
    RegExp(r"\b(tonight|right now|today|this evening)\b[^.]{0,30}\b(kill myself|end my life|end it all|commit suicide|take my own life)\b"),
    RegExp(r"\b(kill myself|end my life|end it all|commit suicide)\b[^.]{0,30}\b(tonight|right now|today|this evening)\b"),
    RegExp(r"\bi have (the |a |my )?(pills|gun|rope|knife|razor|blade)\b[^.]{0,30}\b(ready|here|with me|in front of me|next to me|in my hand)\b"),
    RegExp(r"\b(i'?ve|i have|i already|already) (taken|swallowed|took) (too many|a lot of|all (of )?(the|my))\b"),
    RegExp(r"\bwrote (a |my )?(suicide note|goodbye note)\b"),
  ];

  static final List<RegExp> _high = [
    RegExp(r"\b(kill myself|killing myself|end my life|ending my life|take my own life|taking my own life|commit suicide|committing suicide)\b"),
    RegExp(r"\bi (want|wanna|need|would like) to die\b"),
    RegExp(r"\bi (wish|hope) (i )?(was|were) (dead|gone forever)\b"),
    RegExp(r"\bi (wish|hope) i (would not|wouldn'?t|didn'?t|did not) wake up\b"),
    RegExp(r"\b(better off dead|rather be dead|want to be dead)\b"),
    RegExp(r"\b(i am|i'?m|im|feeling|feel|been feeling|have been feeling) suicidal\b"),
    RegExp(r"\b(suicidal thoughts|thoughts of suicide|thinking (about|of) suicide|thinking (about|of) killing myself)\b"),
    RegExp(r"\b(hurt|harm|cut|injure|punish|burn) myself\b"),
    RegExp(r"\b(cutting|hurting|harming) myself\b"),
    RegExp(r"\bself[ -]?harm(ing)?\b"),
  ];

  static final List<RegExp> _ambiguous = [
    RegExp(r"\b(everyone|everybody|they|my family|my friends|people)\b[^.]{0,20}\b(would be|are|is|'?d be) better off without me\b"),
    RegExp(r"\bbetter off without me\b"),
    RegExp(r"\b(no|not any) (point|reason) (in )?(going on|living|continuing|carrying on|anything)\b"),
    RegExp(r"\bi (just )?(can'?t|cannot|can not) (do this|go on|take (it|this)|keep going|carry on|cope) (any ?more|any longer)\b"),
    RegExp(r"\bi (don'?t|do not) want to (be here|wake up|exist|live|go on)\b"),
    RegExp(r"\bi wish i (could )?(disappear|vanish|not exist|never existed|was never born)\b"),
    RegExp(r"\b(want|wanna|going) to disappear( forever)?\b"),
    RegExp(r"\b(end it all|ending it all|ending things for good)\b"),
    RegExp(r"\b(i am|i'?m|im) (a )?(burden|a burden to everyone)\b"),
    RegExp(r"\bnothing matters (any ?more|anymore)\b"),
    RegExp(r"\b(life|living) (isn'?t|is not) worth\b"),
    RegExp(r"\b(can'?t|cannot|don'?t) see (a|any) way out\b"),
    RegExp(r"\bno way out\b"),
    RegExp(r"\bgive up on (life|everything)\b"),
    RegExp(r"\bi'?m done with (life|everything|all of it)\b"),
  ];

  static final _affirmative = RegExp(
    r"^(yes|yeah|yep|yup|ya|i am|i do|i have|i think so|kind of|kinda|sort of|sometimes|a little|a bit|sort of yes|yes i am|yes i do|yes i have|maybe|i guess|i guess so|probably)\b",
  );
  static final _negative = RegExp(
    r"^(no|nope|nah|not really|not at all|i'?m (safe|ok|okay|fine)|i am (safe|ok|okay|fine)|no i'?m (safe|ok|okay|fine)|no i am (safe|ok|okay|fine)|i would never|i wouldn'?t)\b",
  );

  /// Assess [message] in the context of the previous assistant turn.
  SafetyAssessment assess(
    String message, {
    SafetyStatus previousAssistantStatus = SafetyStatus.none,
  }) {
    final t = _normalize(message);
    if (t.isEmpty) return SafetyAssessment.none;

    final negated = _negated.hasMatch(t);

    if (!negated) {
      for (final re in _imminent) {
        if (re.hasMatch(t)) {
          return const SafetyAssessment(SafetyStatus.imminent, 'imminent_pattern');
        }
      }
      for (final re in _high) {
        if (re.hasMatch(t)) {
          return const SafetyAssessment(SafetyStatus.high, 'explicit_pattern');
        }
      }
    }

    // Follow-up to a direct safety question.
    if (previousAssistantStatus != SafetyStatus.none) {
      final short = t.split(' ').length <= 12;
      if (short && _negative.hasMatch(t)) {
        return SafetyAssessment.none;
      }
      if (short && _affirmative.hasMatch(t)) {
        return const SafetyAssessment(SafetyStatus.high, 'affirmed_after_check');
      }
      if (previousAssistantStatus == SafetyStatus.imminent ||
          previousAssistantStatus == SafetyStatus.high) {
        // Stay in the safety posture for short, unclear replies right after
        // a high-risk exchange instead of switching to routine chat.
        if (short && !negated) {
          return SafetyAssessment(previousAssistantStatus, 'continuation');
        }
      }
    }

    if (!negated) {
      for (final re in _ambiguous) {
        if (re.hasMatch(t)) {
          return const SafetyAssessment(SafetyStatus.ambiguous, 'indirect_pattern');
        }
      }
    }
    return SafetyAssessment.none;
  }
}

/// Region-aware crisis guidance. Only numbers that are well established are
/// listed; for every other region the user is pointed to directories and to
/// local emergency services without inventing numbers.
class CrisisResources {
  /// ISO country code such as 'US', or null when unknown.
  final String? countryCode;
  const CrisisResources(this.countryCode);

  String get emergencyLine {
    switch (countryCode?.toUpperCase()) {
      case 'US':
      case 'CA':
        return 'If you might act on these thoughts, call 911 now.';
      case 'GB':
        return 'If you might act on these thoughts, call 999 now.';
      case 'IE':
        return 'If you might act on these thoughts, call 112 or 999 now.';
      case 'KE':
      default:
        return 'If you might act on these thoughts, call 1199 (Kenya Red Cross, toll-free 24/7), your local emergency number (112 or 999 in Kenya) now, or go to the nearest emergency department.';
    }
  }

  List<String> get helplineLines {
    final lines = <String>[];
    switch (countryCode?.toUpperCase()) {
      case 'US':
        lines.add('In the US you can call or text 988 (Suicide & Crisis Lifeline), or text HOME to 741741 (Crisis Text Line).');
        break;
      case 'CA':
        lines.add('In Canada you can call or text 988 (Suicide Crisis Helpline).');
        break;
      case 'GB':
      case 'IE':
        lines.add('In the UK and Ireland you can call Samaritans free on 116 123.');
        break;
      case 'KE':
      default:
        lines.add('Kenya Red Cross: Call 1199 (Toll-Free 24/7 Crisis Support).');
        lines.add('LVCT Health Counselling Support: Call 1190 (Toll-Free 24/7 Counselling).');
        lines.add('Childline Kenya: Call 116 (Toll-Free 24-Hour Child & Youth Support).');
        lines.add('National Emergency Services: Call 112 or 999 (Toll-Free, zero credit needed).');
        break;
    }
    lines.add('Free, confidential helplines in many countries are listed at findahelpline.com and at iasp.info/crisis-centres-helplines.');
    return lines;
  }

  /// Ordered cascade of verified toll-free and emergency helplines for the region.
  /// If one does not answer, the one-tap trigger automatically cascades to the next.
  List<CrisisHelpline> get helplines {
    switch (countryCode?.toUpperCase()) {
      case 'US':
        return const [
          CrisisHelpline(
            id: 'us_988',
            name: 'Suicide & Crisis Lifeline',
            phoneNumber: '988',
            formattedDisplayNumber: '988',
            description: '24/7 free and confidential emotional crisis and suicide prevention.',
            isTollFree: true,
            priorityBadge: 'Priority 1 (Toll-Free)',
          ),
          CrisisHelpline(
            id: 'us_911',
            name: 'Emergency Services (Police / Medical)',
            phoneNumber: '911',
            formattedDisplayNumber: '911',
            description: 'Immediate dispatch for acute medical or physical emergencies.',
            isTollFree: true,
            priorityBadge: 'Emergency Dispatch',
          ),
          CrisisHelpline(
            id: 'us_trevor',
            name: 'The Trevor Project (LGBTQ+ Youth)',
            phoneNumber: '18664887386',
            formattedDisplayNumber: '1-866-488-7386',
            description: '24/7 free and confidential crisis intervention for young people.',
            isTollFree: true,
            priorityBadge: 'Youth Support',
          ),
        ];
      case 'GB':
      case 'IE':
        return const [
          CrisisHelpline(
            id: 'uk_samaritans',
            name: 'Samaritans Crisis Helpline',
            phoneNumber: '116123',
            formattedDisplayNumber: '116 123',
            description: '24/7 confidential emotional support for anyone in distress.',
            isTollFree: true,
            priorityBadge: 'Priority 1 (Free)',
          ),
          CrisisHelpline(
            id: 'uk_emergency',
            name: 'Emergency Services',
            phoneNumber: '999',
            formattedDisplayNumber: '999',
            description: 'Emergency police, ambulance, and medical dispatch.',
            isTollFree: true,
            priorityBadge: 'Emergency Dispatch',
          ),
          CrisisHelpline(
            id: 'uk_nhs',
            name: 'NHS Urgent Mental Health',
            phoneNumber: '111',
            formattedDisplayNumber: '111',
            description: '24/7 NHS psychiatric triage and mental health support.',
            isTollFree: true,
            priorityBadge: 'NHS Support',
          ),
        ];
      case 'KE':
      default:
        return const [
          CrisisHelpline(
            id: 'ke_redcross',
            name: 'Kenya Red Cross Crisis Helpline',
            phoneNumber: '1199',
            formattedDisplayNumber: '1199',
            description: '24/7 National Psychological First Aid & Suicide Crisis Support.',
            isTollFree: true,
            priorityBadge: 'Priority 1 (Toll-Free)',
          ),
          CrisisHelpline(
            id: 'ke_lvct',
            name: 'LVCT Health Counselling Support',
            phoneNumber: '1190',
            formattedDisplayNumber: '1190',
            description: 'Toll-free 24/7 confidential psychological counselling & crisis support.',
            isTollFree: true,
            priorityBadge: 'Priority 2 (Toll-Free)',
          ),
          CrisisHelpline(
            id: 'ke_childline',
            name: 'Childline Kenya (24-Hour Support)',
            phoneNumber: '116',
            formattedDisplayNumber: '116',
            description: '24-hour toll-free support, child & youth helpline.',
            isTollFree: true,
            priorityBadge: 'Priority 3 (Toll-Free)',
          ),
          CrisisHelpline(
            id: 'ke_emergency_112',
            name: 'Emergency Services (All Networks)',
            phoneNumber: '112',
            formattedDisplayNumber: '112',
            description: 'Toll-free emergency dispatch (Works with 0.00 credit on all SIMs).',
            isTollFree: true,
            priorityBadge: 'Priority 4 (Toll-Free)',
          ),
          CrisisHelpline(
            id: 'ke_emergency_999',
            name: 'National Police & Ambulance Dispatch',
            phoneNumber: '999',
            formattedDisplayNumber: '999',
            description: 'Toll-free emergency dispatch (Zero airtime required).',
            isTollFree: true,
            priorityBadge: 'Priority 5 (Toll-Free)',
          ),
        ];
    }
  }
}

/// Fixed safety replies (never model-generated).
class CrisisResponses {
  static String build(SafetyStatus status, {String? countryCode, bool followUp = false}) {
    final res = CrisisResources(countryCode);
    switch (status) {
      case SafetyStatus.ambiguous:
        return "I'm really sorry things feel this heavy, and I'm glad you told me. I want to make sure I understand you: "
            'are you having thoughts of ending your life or hurting yourself? You can answer in your own words. '
            "I'm here, and I'm not going anywhere.";
      case SafetyStatus.imminent:
        return "I'm really glad you told me, and I'm worried about your safety right now. Please act on this straight away:\n\n"
            "\u2022 ${res.emergencyLine}\n"
            "\u2022 If you can, move away from anything you could use to hurt yourself.\n"
            "\u2022 Reach out to someone near you right now, a family member, friend or neighbour, and ask them to stay with you.\n"
            '\u2022 ${res.helplineLines.join('\n\u2022 ')}\n\n'
            "You don't have to go through this moment alone. Are you safe right now, and is someone with you?";
      case SafetyStatus.high:
        if (followUp) {
          return "Thank you for telling me. I'm taking this seriously, and I'm still here with you. "
              'Is there someone you trust who could be with you, or whom you could contact right now? '
              'It would also help to talk to a doctor, therapist or a helpline today.\n\n'
              '\u2022 ${res.emergencyLine}\n'
              '\u2022 ${res.helplineLines.join('\n\u2022 ')}\n\n'
              'Are you safe right now?';
        }
        return "I'm so sorry you're in this much pain, and I'm glad you reached out. What you're feeling matters, and you deserve support from a person right now.\n\n"
            'Are you safe at the moment? If you are thinking of acting on these thoughts:\n\n'
            '\u2022 ${res.emergencyLine}\n'
            '\u2022 ${res.helplineLines.join('\n\u2022 ')}\n'
            '\u2022 Consider contacting a trusted person, or a doctor or therapist, today.\n\n'
            "I'm not a therapist or an emergency service, but I'm here to keep talking with you for as long as you like.";
      case SafetyStatus.none:
        return '';
    }
  }
}
