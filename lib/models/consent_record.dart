enum ConsentStatus {
  granted,
  partial,
  withdrawn;

  String get value => name;

  static ConsentStatus fromString(String? val) {
    switch (val) {
      case 'granted':
        return ConsentStatus.granted;
      case 'partial':
        return ConsentStatus.partial;
      case 'withdrawn':
        return ConsentStatus.withdrawn;
      default:
        return ConsentStatus.granted;
    }
  }
}

/// Represents a user's informed consent document in `consent_records/{userId}`.
/// Matches the strict schema enforced by `firestore.rules`.
class ConsentRecord {
  static const String currentPolicyVersion = '1.0.0';

  final String userId;
  final String policyVersion;
  final ConsentStatus status;
  final bool moodTrackingConsent;
  final bool physiologicalDataConsent;
  final bool adaptiveRecommendationsConsent;
  final bool anonymizedResearchConsent;
  final DateTime consentedAt;
  final String? rawConsentedAt;
  final DateTime lastUpdatedAt;
  final DateTime? withdrawnAt;

  const ConsentRecord({
    required this.userId,
    this.policyVersion = currentPolicyVersion,
    required this.status,
    required this.moodTrackingConsent,
    required this.physiologicalDataConsent,
    required this.adaptiveRecommendationsConsent,
    required this.anonymizedResearchConsent,
    required this.consentedAt,
    this.rawConsentedAt,
    required this.lastUpdatedAt,
    this.withdrawnAt,
  });

  /// Computes whether the consent is full (`granted`), selective (`partial`),
  /// or `withdrawn` based on the boolean flags.
  static ConsentStatus computeStatus({
    required bool moodTrackingConsent,
    required bool physiologicalDataConsent,
    required bool adaptiveRecommendationsConsent,
    required bool anonymizedResearchConsent,
  }) {
    if (!moodTrackingConsent &&
        !physiologicalDataConsent &&
        !adaptiveRecommendationsConsent &&
        !anonymizedResearchConsent) {
      return ConsentStatus.withdrawn;
    }
    if (moodTrackingConsent &&
        physiologicalDataConsent &&
        adaptiveRecommendationsConsent &&
        anonymizedResearchConsent) {
      return ConsentStatus.granted;
    }
    return ConsentStatus.partial;
  }

  /// Whether this consent record allows the user to access the main app.
  bool get isActive =>
      status != ConsentStatus.withdrawn &&
      physiologicalDataConsent &&
      moodTrackingConsent;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'policyVersion': policyVersion,
      'status': status.value,
      'moodTrackingConsent': moodTrackingConsent,
      'physiologicalDataConsent': physiologicalDataConsent,
      'adaptiveRecommendationsConsent': adaptiveRecommendationsConsent,
      'anonymizedResearchConsent': anonymizedResearchConsent,
      'consentedAt': rawConsentedAt ?? consentedAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'withdrawnAt': withdrawnAt?.toIso8601String(),
    };
  }

  factory ConsentRecord.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is String) {
        return DateTime.tryParse(val) ?? fallback;
      }
      return fallback;
    }

    final now = DateTime.now();
    final rawConsented =
        map['consentedAt'] is String ? map['consentedAt'] as String : null;
    final rawWithdrawn = map['withdrawnAt'];

    return ConsentRecord(
      userId: (map['userId'] as String?) ?? docId,
      policyVersion: (map['policyVersion'] as String?) ?? currentPolicyVersion,
      status: ConsentStatus.fromString(map['status'] as String?),
      moodTrackingConsent: (map['moodTrackingConsent'] as bool?) ?? false,
      physiologicalDataConsent:
          (map['physiologicalDataConsent'] as bool?) ?? false,
      adaptiveRecommendationsConsent:
          (map['adaptiveRecommendationsConsent'] as bool?) ?? false,
      anonymizedResearchConsent:
          (map['anonymizedResearchConsent'] as bool?) ?? false,
      consentedAt: parseDate(map['consentedAt'], now),
      rawConsentedAt: rawConsented,
      lastUpdatedAt: parseDate(map['lastUpdatedAt'], now),
      withdrawnAt: rawWithdrawn is String ? DateTime.tryParse(rawWithdrawn) : null,
    );
  }

  ConsentRecord copyWith({
    String? userId,
    String? policyVersion,
    ConsentStatus? status,
    bool? moodTrackingConsent,
    bool? physiologicalDataConsent,
    bool? adaptiveRecommendationsConsent,
    bool? anonymizedResearchConsent,
    DateTime? consentedAt,
    String? rawConsentedAt,
    DateTime? lastUpdatedAt,
    DateTime? withdrawnAt,
    bool clearWithdrawnAt = false,
  }) {
    return ConsentRecord(
      userId: userId ?? this.userId,
      policyVersion: policyVersion ?? this.policyVersion,
      status: status ?? this.status,
      moodTrackingConsent: moodTrackingConsent ?? this.moodTrackingConsent,
      physiologicalDataConsent:
          physiologicalDataConsent ?? this.physiologicalDataConsent,
      adaptiveRecommendationsConsent:
          adaptiveRecommendationsConsent ?? this.adaptiveRecommendationsConsent,
      anonymizedResearchConsent:
          anonymizedResearchConsent ?? this.anonymizedResearchConsent,
      consentedAt: consentedAt ?? this.consentedAt,
      rawConsentedAt: rawConsentedAt ?? this.rawConsentedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      withdrawnAt: clearWithdrawnAt ? null : (withdrawnAt ?? this.withdrawnAt),
    );
  }
}
