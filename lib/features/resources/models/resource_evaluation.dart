class ResourceEvaluation {
  final String resourceId;
  final String resourceTitle;
  final double calmPercent;
  final double neutralPercent;
  final double activePercent;
  final int durationSeconds;
  final double? averageBpm;
  final double averageStillness;
  final int starRating; // 1 to 5
  final String moodShift; // 'Significantly Calmer', 'Slightly Better', 'Neutral / Same', 'Distracting / Restless'
  final bool wouldRecommend; // Computed automatically by the system
  final bool usedHeadband;
  final double? initialCalmPercent;
  final double? finalCalmPercent;
  final String? dominantBand;
  final String? notes;
  final DateTime timestamp;

  const ResourceEvaluation({
    required this.resourceId,
    required this.resourceTitle,
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
  });

  /// Relaxation shift gradient from session start to session end
  double get deltaCalmShift {
    if (initialCalmPercent != null && finalCalmPercent != null) {
      return finalCalmPercent! - initialCalmPercent!;
    }
    return 0.0;
  }

  /// System-computed recommendation score (0 to 100) combining genuine sensor trajectory and user rating.
  double get performanceScore {
    if (usedHeadband && calmPercent > 0) {
      // 1. Star rating: 0 - 40 points
      final starScore = (starRating / 5.0) * 40.0;

      // 2. Objective calm percentage: 0 - 30 points
      final calmScore = (calmPercent / 100.0) * 30.0;

      // 3. Relaxation trajectory bonus (tense-to-calm shift): up to +15 points
      double trajectoryBonus = 0.0;
      if (deltaCalmShift > 10.0) {
        trajectoryBonus = 15.0; // Significant shift into calm
      } else if (deltaCalmShift > 0.0) {
        trajectoryBonus = 8.0;
      } else if (deltaCalmShift < -15.0) {
        trajectoryBonus = -10.0; // Became noticeably more restless
      }

      // 4. Mood shift feedback: -15 to +15 points
      double moodBonus = 0.0;
      if (moodShift == 'Significantly Calmer') moodBonus = 15.0;
      if (moodShift == 'Slightly Better') moodBonus = 8.0;
      if (moodShift == 'Distracting / Restless') moodBonus = -15.0;

      return (starScore + calmScore + trajectoryBonus + moodBonus).clamp(0.0, 100.0);
    } else {
      // Self-guided session without headband
      final starScore = (starRating / 5.0) * 60.0;
      double moodBonus = 15.0;
      if (moodShift == 'Significantly Calmer') moodBonus = 40.0;
      if (moodShift == 'Slightly Better') moodBonus = 25.0;
      if (moodShift == 'Neutral / Same') moodBonus = 10.0;
      if (moodShift == 'Distracting / Restless') moodBonus = -20.0;

      return (starScore + moodBonus).clamp(0.0, 100.0);
    }
  }

  /// Psychophysiological mood state derived from authentic Muse 2 EEG frequencies or user response
  String get inferredMood {
    if (!usedHeadband || (calmPercent == 0 && activePercent == 0)) {
      return 'Self-Reported ($moodShift)';
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

  Map<String, dynamic> toMap() {
    return {
      'resourceId': resourceId,
      'resourceTitle': resourceTitle,
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
    };
  }

  factory ResourceEvaluation.fromMap(Map<String, dynamic> map) {
    return ResourceEvaluation(
      resourceId: map['resourceId'] as String? ?? '',
      resourceTitle: map['resourceTitle'] as String? ?? '',
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
    );
  }
}
