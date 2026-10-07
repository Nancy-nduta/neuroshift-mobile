import 'package:cloud_firestore/cloud_firestore.dart';
import 'experience_mode.dart';
import 'signal_reading.dart';

class MeditationSession {
  final String id;
  final String userId;
  final ExperienceMode mode;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;
  
  // Muse 2 Calm / Neutral / Active breakdown (percentages)
  final double calmPercent;
  final double neutralPercent;
  final double activePercent;
  
  // Muse Gamification & Achievements
  final int calmPoints;
  final int birdsAwarded; // Muse awards birds when calm state is sustained!
  final int recoveries;   // Returning from active to calm
  
  // Physiological summaries
  final double averageBpm;
  final double averageRmssd;
  final double averageStillness; // 0.0 - 100.0%
  
  // Time-series breakdown for the session graph (sampled every second or epoch)
  final List<SessionEpoch> timeline;
  final String? notes;

  const MeditationSession({
    required this.id,
    required this.userId,
    required this.mode,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    required this.calmPercent,
    required this.neutralPercent,
    required this.activePercent,
    required this.calmPoints,
    required this.birdsAwarded,
    required this.recoveries,
    required this.averageBpm,
    required this.averageRmssd,
    required this.averageStillness,
    this.timeline = const [],
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'mode': mode.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': Timestamp.fromDate(completedAt),
      'durationSeconds': durationSeconds,
      'calmPercent': calmPercent,
      'neutralPercent': neutralPercent,
      'activePercent': activePercent,
      'calmPoints': calmPoints,
      'birdsAwarded': birdsAwarded,
      'recoveries': recoveries,
      'averageBpm': averageBpm,
      'averageRmssd': averageRmssd,
      'averageStillness': averageStillness,
      'notes': notes,
    };
  }

  factory MeditationSession.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return MeditationSession(
      id: docId,
      userId: map['userId'] as String? ?? '',
      mode: ExperienceMode.values.firstWhere(
        (e) => e.name == (map['mode'] as String?),
        orElse: () => ExperienceMode.mind,
      ),
      startedAt: parseDate(map['startedAt']),
      completedAt: parseDate(map['completedAt']),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      calmPercent: (map['calmPercent'] as num?)?.toDouble() ?? 0.0,
      neutralPercent: (map['neutralPercent'] as num?)?.toDouble() ?? 0.0,
      activePercent: (map['activePercent'] as num?)?.toDouble() ?? 0.0,
      calmPoints: (map['calmPoints'] as num?)?.toInt() ?? 0,
      birdsAwarded: (map['birdsAwarded'] as num?)?.toInt() ?? 0,
      recoveries: (map['recoveries'] as num?)?.toInt() ?? 0,
      averageBpm: (map['averageBpm'] as num?)?.toDouble() ?? 0.0,
      averageRmssd: (map['averageRmssd'] as num?)?.toDouble() ?? 0.0,
      averageStillness: (map['averageStillness'] as num?)?.toDouble() ?? 100.0,
      notes: map['notes'] as String?,
    );
  }

  MeditationSession copyWith({
    String? id,
    String? userId,
    ExperienceMode? mode,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    double? calmPercent,
    double? neutralPercent,
    double? activePercent,
    int? calmPoints,
    int? birdsAwarded,
    int? recoveries,
    double? averageBpm,
    double? averageRmssd,
    double? averageStillness,
    List<SessionEpoch>? timeline,
    String? notes,
  }) {
    return MeditationSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      calmPercent: calmPercent ?? this.calmPercent,
      neutralPercent: neutralPercent ?? this.neutralPercent,
      activePercent: activePercent ?? this.activePercent,
      calmPoints: calmPoints ?? this.calmPoints,
      birdsAwarded: birdsAwarded ?? this.birdsAwarded,
      recoveries: recoveries ?? this.recoveries,
      averageBpm: averageBpm ?? this.averageBpm,
      averageRmssd: averageRmssd ?? this.averageRmssd,
      averageStillness: averageStillness ?? this.averageStillness,
      timeline: timeline ?? this.timeline,
      notes: notes ?? this.notes,
    );
  }
}

class SessionEpoch {
  final int secondOffset;
  final MindState state;
  final double bpm;
  final double stillness;

  const SessionEpoch({
    required this.secondOffset,
    required this.state,
    required this.bpm,
    required this.stillness,
  });

  Map<String, dynamic> toMap() => {
    'secondOffset': secondOffset,
    'state': state.name,
    'bpm': bpm,
    'stillness': stillness,
  };

  factory SessionEpoch.fromMap(Map<String, dynamic> map) {
    return SessionEpoch(
      secondOffset: (map['secondOffset'] as num?)?.toInt() ?? 0,
      state: MindState.values.firstWhere(
        (s) => s.name == (map['state'] as String?),
        orElse: () => MindState.neutral,
      ),
      bpm: (map['bpm'] as num?)?.toDouble() ?? 0.0,
      stillness: (map['stillness'] as num?)?.toDouble() ?? 100.0,
    );
  }
}
