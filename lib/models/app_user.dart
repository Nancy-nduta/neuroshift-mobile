class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final String? rawCreatedAt;
  final int totalMeditationMinutes;
  final int streakDays;
  final String? pairedHeadbandId;
  final List<String> pairedDevices;
  final double? baselineRestingHr;
  final double? baselineHrvRmssd;
  final bool hasCompletedOnboarding;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.rawCreatedAt,
    this.totalMeditationMinutes = 0,
    this.streakDays = 0,
    this.pairedHeadbandId,
    this.pairedDevices = const [],
    this.baselineRestingHr,
    this.baselineHrvRmssd,
    this.hasCompletedOnboarding = true,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': rawCreatedAt ?? createdAt.toIso8601String(),
      'totalMeditationMinutes': totalMeditationMinutes,
      'streakDays': streakDays,
      'pairedHeadbandId': pairedHeadbandId,
      'pairedDevices': pairedDevices,
      'baselineRestingHr': baselineRestingHr,
      'baselineHrvRmssd': baselineHrvRmssd,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory AppUser.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawDate = map['createdAt'] is String ? map['createdAt'] as String : null;

    return AppUser(
      uid: (map['uid'] as String?) ?? docId,
      email: (map['email'] as String?) ?? '',
      displayName: map['displayName'] as String?,
      createdAt: parseDate(map['createdAt']),
      rawCreatedAt: rawDate,
      totalMeditationMinutes: (map['totalMeditationMinutes'] as int?) ?? 0,
      streakDays: (map['streakDays'] as int?) ?? 0,
      pairedHeadbandId: map['pairedHeadbandId'] as String?,
      pairedDevices: (map['pairedDevices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      baselineRestingHr: (map['baselineRestingHr'] as num?)?.toDouble(),
      baselineHrvRmssd: (map['baselineHrvRmssd'] as num?)?.toDouble(),
      hasCompletedOnboarding: (map['hasCompletedOnboarding'] as bool?) ?? true,
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    String? rawCreatedAt,
    int? totalMeditationMinutes,
    int? streakDays,
    String? pairedHeadbandId,
    List<String>? pairedDevices,
    double? baselineRestingHr,
    double? baselineHrvRmssd,
    bool? hasCompletedOnboarding,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      rawCreatedAt: rawCreatedAt ?? this.rawCreatedAt,
      totalMeditationMinutes: totalMeditationMinutes ?? this.totalMeditationMinutes,
      streakDays: streakDays ?? this.streakDays,
      pairedHeadbandId: pairedHeadbandId ?? this.pairedHeadbandId,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      baselineRestingHr: baselineRestingHr ?? this.baselineRestingHr,
      baselineHrvRmssd: baselineHrvRmssd ?? this.baselineHrvRmssd,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}
