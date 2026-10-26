import 'dart:convert';

class ResourceEvaluation {
  final String resourceId;
  final String resourceTitle;
  final String category;
  final double calmPercent;
  final double neutralPercent;
  final double activePercent;
  final int durationSeconds;
  final double? averageBpm;
  final double averageStillness;
  final int starRating; // 1 to 5 (helpfulnessRating)
  final String moodShift; // 'Significantly Calmer', 'Slightly Better', 'Neutral / Same', 'Distracting / Restless'
  final bool wouldRecommend; // Computed automatically by the system
  final bool usedHeadband;
  final double? initialCalmPercent;
  final double? finalCalmPercent;
  final String? dominantBand;
  final String? notes;
  final DateTime timestamp;

  // Comprehensive Reinforcement Learning (RL) State-Action-Reward signals
  final int preValence; // 1 (Very Stressed) to 5 (Deeply Calm)
  final int postValence; // 1 (Very Stressed) to 5 (Deeply Calm)
  final int mentalCalmScore; // 1 to 5
  final int bodyRelaxationScore; // 1 to 5
  final int focusClarityScore; // 1 to 5
  final String pacingFit; // 'Just Right', 'Too Short', 'Too Long', 'Audio Distracting'
  final List<String> outcomeTags; // e.g. ['Eased Anxiety', 'Slowed Thoughts', ...]
  final bool wouldUseAgain;

  const ResourceEvaluation({
    required this.resourceId,
    required this.resourceTitle,
    this.category = 'Guided Practice',
    required this.calmPercent,
    required this.neutralPercent,
    required this.activePercent,
    required this.durationSeconds,
    this.averageBpm,
    required this.averageStillness,
    required this.starRating,
    required this.moodShift,
    required this.wouldRecommend,
    required this.usedHeadband,
    this.initialCalmPercent,
    this.finalCalmPercent,
    this.dominantBand,
    this.notes,
    required this.timestamp,
    this.preValence = 2,
    this.postValence = 4,
    this.mentalCalmScore = 4,
    this.bodyRelaxationScore = 4,
    this.focusClarityScore = 4,
    this.pacingFit = 'Just Right',
    this.outcomeTags = const [],
    this.wouldUseAgain = true,
  });

  /// State transition delta: positive values indicate stress reduction / mood elevation.
  int get valenceDelta => postValence - preValence;

  /// Average across the 3 multi-dimensional subjective outcome axes (1.0 to 5.0).
  double get multiDimensionalOutcomeAvg =>
      (mentalCalmScore + bodyRelaxationScore + focusClarityScore) / 3.0;

  /// Relaxation shift gradient from session start to session end (EEG).
  double get deltaCalmShift {
    if (initialCalmPercent != null && finalCalmPercent != null) {
      return finalCalmPercent! - initialCalmPercent!;
    }
    return 0.0;
  }

  /// Effective calm percentage that works both WITH and WITHOUT hardware sensors.
  /// When no sensor is connected, derives a calibrated calm score from the RL feedback signals.
  double get effectiveCalmPercent {
    if (usedHeadband && (calmPercent > 0 || neutralPercent > 0 || activePercent > 0)) {
      return calmPercent.clamp(0.0, 100.0);
    }
    final weighted = (postValence * 0.35 +
            mentalCalmScore * 0.30 +
            bodyRelaxationScore * 0.20 +
            focusClarityScore * 0.15) /
        5.0 *
        100.0;
    final deltaBoost = valenceDelta * 4.0;
    final pacingPenalty = pacingFit == 'Audio Distracting' ? -10.0 : 0.0;
    return (weighted + deltaBoost + pacingPenalty).clamp(12.0, 94.0);
  }

  /// Effective active/restless percentage (hardware or RL-inferred when sensor-free).
  double get effectiveActivePercent {
    if (usedHeadband && (calmPercent > 0 || neutralPercent > 0 || activePercent > 0)) {
      return activePercent.clamp(0.0, 100.0);
    }
    final calm = effectiveCalmPercent;
    final restlessness = ((5 - mentalCalmScore) * 5.5 +
            (5 - postValence) * 5.0 +
            (pacingFit == 'Audio Distracting' ? 12.0 : 0.0))
        .clamp(4.0, 100.0 - calm - 6.0);
    return restlessness;
  }

  /// Effective neutral percentage (hardware or RL-inferred when sensor-free).
  double get effectiveNeutralPercent {
    if (usedHeadband && (calmPercent > 0 || neutralPercent > 0 || activePercent > 0)) {
      return neutralPercent.clamp(0.0, 100.0);
    }
    return (100.0 - effectiveCalmPercent - effectiveActivePercent).clamp(0.0, 100.0);
  }

  /// Subjective RL reward component (0 to 100) computed purely from the comprehensive feedback form.
  double get subjectiveRlReward {
    // 1. State transition & post-state valence (up to 30 pts)
    final postStateScore = (postValence / 5.0) * 18.0;
    final transitionBonus = (valenceDelta * 4.0).clamp(-10.0, 12.0);

    // 2. Multi-dimensional impact: Mental Calm, Body Relaxation, Focus Clarity (up to 30 pts)
    final multiDimScore = (multiDimensionalOutcomeAvg / 5.0) * 30.0;

    // 3. Helpfulness star rating (up to 25 pts)
    final ratingScore = (starRating / 5.0) * 25.0;

    // 4. Retention & Pacing Fit signals (-25 to +15 pts)
    double fitBonus = 0.0;
    if (wouldUseAgain) {
      fitBonus += 8.0;
    } else {
      fitBonus -= 18.0;
    }

    if (pacingFit == 'Just Right') {
      fitBonus += 5.0;
    } else if (pacingFit == 'Audio Distracting') {
      fitBonus -= 12.0;
    } else {
      fitBonus -= 2.0; // Too Short / Too Long
    }

    // 5. Outcome tags bonus (up to +2 pts for rich positive signals)
    final tagBonus = (outcomeTags.length * 0.7).clamp(0.0, 2.0);

    return (postStateScore + transitionBonus + multiDimScore + ratingScore + fitBonus + tagBonus)
        .clamp(0.0, 100.0);
  }

  /// System-computed RL reward score (0 to 100) combining genuine sensor trajectory (when available)
  /// and comprehensive subjective state-action-reward feedback.
  double get performanceScore {
    final subjReward = subjectiveRlReward;

    if (usedHeadband && (calmPercent > 0 || activePercent > 0)) {
      // Objective EEG + PPG score (0 to 100)
      double trajectoryBonus = 0.0;
      if (deltaCalmShift > 10.0) {
        trajectoryBonus = 18.0;
      } else if (deltaCalmShift > 0.0) {
        trajectoryBonus = 10.0;
      } else if (deltaCalmShift < -15.0) {
        trajectoryBonus = -12.0;
      }

      final stillnessComponent = (averageStillness / 100.0) * 15.0;
      final calmComponent = (calmPercent / 100.0) * 67.0;
      final objectiveScore = (calmComponent + stillnessComponent + trajectoryBonus).clamp(0.0, 100.0);

      // 45% Objective Biosignal Reward + 55% Subjective RL Reward
      return (objectiveScore * 0.45 + subjReward * 0.55).clamp(0.0, 100.0);
    } else {
      // Sensor-free session: 100% powered by the multi-dimensional RL feedback model
      return subjReward;
    }
  }

  /// Psychophysiological mood state derived from authentic Muse 2 EEG frequencies or comprehensive RL feedback.
  String get inferredMood {
    if (!usedHeadband || (calmPercent == 0 && activePercent == 0)) {
      if (valenceDelta >= 2 && postValence >= 4) {
        return 'Strong Stress Relief (+$valenceDelta State Shift)';
      }
      if (postValence == 5) {
        return 'Deeply Restored & Grounded';
      }
      if (postValence == 4) {
        return 'Calm & Centered ($moodShift)';
      }
      if (postValence == 3) {
        return 'Balanced / Neutral State';
      }
      return 'Elevated Tension — Alternative Modality Advised';
    }

    if (deltaCalmShift >= 20.0) {
      return 'Tension Released into Deep Calm';
    }
    if (calmPercent >= 70.0) {
      return 'Deep Calm & Inner Peace';
    }
    if (calmPercent >= 50.0) {
      return 'Relaxed & Grounded';
    }
    if (activePercent >= 50.0) {
      return 'Restless / Active Mind';
    }
    return 'Balanced Mind State';
  }

  /// Encodes structured RL metadata + user notes into a compact string (<= 500 chars)
  /// for Firestore `activity_sessions.feedbackComments`.
  String toCompactFeedbackComments() {
    final cleanNotes = (notes ?? '').trim();
    final meta = {
      'mc': mentalCalmScore,
      'br': bodyRelaxationScore,
      'fc': focusClarityScore,
      'pf': pacingFit,
      'tags': outcomeTags,
      'ms': moodShift,
      'hb': usedHeadband,
      if (cleanNotes.isNotEmpty) 'n': cleanNotes.length > 220 ? cleanNotes.substring(0, 220) : cleanNotes,
    };
    final encoded = jsonEncode(meta);
    return encoded.length <= 500 ? encoded : encoded.substring(0, 500);
  }

  Map<String, dynamic> toMap() {
    return {
      'resourceId': resourceId,
      'resourceTitle': resourceTitle,
      'category': category,
      'calmPercent': calmPercent,
      'neutralPercent': neutralPercent,
      'activePercent': activePercent,
      'durationSeconds': durationSeconds,
      'averageBpm': averageBpm,
      'averageStillness': averageStillness,
      'starRating': starRating,
      'moodShift': moodShift,
      'wouldRecommend': wouldRecommend,
      'usedHeadband': usedHeadband,
      'initialCalmPercent': initialCalmPercent,
      'finalCalmPercent': finalCalmPercent,
      'dominantBand': dominantBand,
      'deltaCalmShift': deltaCalmShift,
      'performanceScore': performanceScore,
      'inferredMood': inferredMood,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'preValence': preValence,
      'postValence': postValence,
      'mentalCalmScore': mentalCalmScore,
      'bodyRelaxationScore': bodyRelaxationScore,
      'focusClarityScore': focusClarityScore,
      'pacingFit': pacingFit,
      'outcomeTags': outcomeTags,
      'wouldUseAgain': wouldUseAgain,
    };
  }

  factory ResourceEvaluation.fromMap(Map<String, dynamic> map) {
    return ResourceEvaluation(
      resourceId: map['resourceId'] as String? ?? '',
      resourceTitle: map['resourceTitle'] as String? ?? '',
      category: map['category'] as String? ?? 'Guided Practice',
      calmPercent: (map['calmPercent'] as num?)?.toDouble() ?? 0.0,
      neutralPercent: (map['neutralPercent'] as num?)?.toDouble() ?? 0.0,
      activePercent: (map['activePercent'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (map['durationSeconds'] as int?) ?? 0,
      averageBpm: (map['averageBpm'] as num?)?.toDouble(),
      averageStillness: (map['averageStillness'] as num?)?.toDouble() ?? 100.0,
      starRating: (map['starRating'] as int?) ?? 5,
      moodShift: map['moodShift'] as String? ?? 'Significantly Calmer',
      wouldRecommend: (map['wouldRecommend'] as bool?) ?? true,
      usedHeadband: (map['usedHeadband'] as bool?) ?? false,
      initialCalmPercent: (map['initialCalmPercent'] as num?)?.toDouble(),
      finalCalmPercent: (map['finalCalmPercent'] as num?)?.toDouble(),
      dominantBand: map['dominantBand'] as String?,
      notes: map['notes'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      preValence: (map['preValence'] as int?) ?? 2,
      postValence: (map['postValence'] as int?) ?? 4,
      mentalCalmScore: (map['mentalCalmScore'] as int?) ?? 4,
      bodyRelaxationScore: (map['bodyRelaxationScore'] as int?) ?? 4,
      focusClarityScore: (map['focusClarityScore'] as int?) ?? 4,
      pacingFit: map['pacingFit'] as String? ?? 'Just Right',
      outcomeTags: (map['outcomeTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      wouldUseAgain: (map['wouldUseAgain'] as bool?) ?? true,
    );
  }

  /// Reconstructs a [ResourceEvaluation] from a Firestore `activity_sessions` document.
  factory ResourceEvaluation.fromActivitySessionDoc(Map<String, dynamic> data) {
    int mc = 4;
    int br = 4;
    int fc = 4;
    String pf = 'Just Right';
    List<String> tags = const [];
    String ms = 'Slightly Better';
    bool hb = false;
    String? userNotes;

    final rawComments = data['feedbackComments'] as String?;
    if (rawComments != null && rawComments.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(rawComments) as Map<String, dynamic>;
        mc = (decoded['mc'] as num?)?.toInt() ?? 4;
        br = (decoded['br'] as num?)?.toInt() ?? 4;
        fc = (decoded['fc'] as num?)?.toInt() ?? 4;
        pf = decoded['pf'] as String? ?? 'Just Right';
        tags = (decoded['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [];
        ms = decoded['ms'] as String? ?? 'Slightly Better';
        hb = (decoded['hb'] as bool?) ?? false;
        userNotes = decoded['n'] as String?;
      } catch (_) {
        userNotes = rawComments;
      }
    } else {
      userNotes = rawComments;
    }

    final preV = (data['preValence'] as num?)?.toInt() ?? 2;
    final postV = (data['postValence'] as num?)?.toInt() ?? 4;
    final rating = (data['helpfulnessRating'] as num?)?.toInt() ?? 4;
    final useAgain = (data['wouldUseAgain'] as bool?) ?? true;

    DateTime completed = DateTime.now();
    final rawCompleted = data['completedAt'];
    if (rawCompleted is String) {
      completed = DateTime.tryParse(rawCompleted) ?? DateTime.now();
    }

    return ResourceEvaluation(
      resourceId: data['activityId'] as String? ?? '',
      resourceTitle: data['activityTitle'] as String? ?? '',
      category: data['category'] as String? ?? 'Guided Practice',
      calmPercent: 0.0,
      neutralPercent: 0.0,
      activePercent: 0.0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      averageStillness: 100.0,
      starRating: rating,
      moodShift: ms,
      wouldRecommend: useAgain && rating >= 4,
      usedHeadband: hb,
      notes: userNotes,
      timestamp: completed,
      preValence: preV,
      postValence: postV,
      mentalCalmScore: mc,
      bodyRelaxationScore: br,
      focusClarityScore: fc,
      pacingFit: pf,
      outcomeTags: tags,
      wouldUseAgain: useAgain,
    );
  }
}

