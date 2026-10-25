import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/consent_record.dart';

class ConsentRepository {
  final FirebaseFirestore _firestore;

  ConsentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _consentCol =>
      _firestore.collection('consent_records');

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _moodCheckinsCol =>
      _firestore.collection('mood_checkins');

  /// Streams the user's live consent record from `consent_records/{userId}`.
  Stream<ConsentRecord?> streamConsentRecord(String userId) {
    return _consentCol.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ConsentRecord.fromFirestore(doc.data()!, doc.id);
    });
  }

  /// Fetches the user's current consent record once.
  Future<ConsentRecord?> getConsentRecord(String userId) async {
    try {
      final doc = await _consentCol.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ConsentRecord.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  /// Creates or updates `consent_records/{userId}` in Firestore, preserving
  /// the immutable `consentedAt` timestamp if a record already exists, and
  /// synchronizes `hasCompletedOnboarding` on `users/{userId}`.
  Future<ConsentRecord> saveConsentRecord(ConsentRecord record) async {
    final docRef = _consentCol.doc(record.userId);
    String? existingConsentedAt = record.rawConsentedAt;

    try {
      final existingSnap = await docRef.get();
      if (existingSnap.exists && existingSnap.data() != null) {
        final raw = existingSnap.data()!['consentedAt'];
        if (raw is String && raw.isNotEmpty) {
          existingConsentedAt = raw;
        }
      }
    } catch (_) {}

    final recordToSave = record.copyWith(
      rawConsentedAt: existingConsentedAt ?? record.consentedAt.toIso8601String(),
      lastUpdatedAt: DateTime.now(),
    );

    await docRef.set(recordToSave.toFirestoreMap());

    // Also update `hasCompletedOnboarding` on `users/{userId}` while preserving immutable fields.
    try {
      final userRef = _usersCol.doc(record.userId);
      final userSnap = await userRef.get();
      if (userSnap.exists && userSnap.data() != null) {
        await userRef.update({
          'hasCompletedOnboarding': recordToSave.isActive,
        });
      }
    } catch (_) {}

    return recordToSave;
  }

  /// Withdraws consent in `consent_records/{userId}` while preserving the
  /// legally required audit trail (`consentedAt` remains unchanged, `delete` is never called).
  Future<ConsentRecord> withdrawConsent(String userId) async {
    final now = DateTime.now();
    final existing = await getConsentRecord(userId);

    final withdrawnRecord = ConsentRecord(
      userId: userId,
      policyVersion: existing?.policyVersion ?? ConsentRecord.currentPolicyVersion,
      status: ConsentStatus.withdrawn,
      moodTrackingConsent: false,
      physiologicalDataConsent: false,
      adaptiveRecommendationsConsent: false,
      anonymizedResearchConsent: false,
      consentedAt: existing?.consentedAt ?? now,
      rawConsentedAt: existing?.rawConsentedAt ?? now.toIso8601String(),
      lastUpdatedAt: now,
      withdrawnAt: now,
    );

    return saveConsentRecord(withdrawnRecord);
  }

  /// Saves an initial onboarding baseline mood check-in to `mood_checkins/{checkinId}`
  /// conforming to `isValidMoodCheckin` in `firestore.rules`.
  Future<void> saveOnboardingMoodCheckin({
    required String userId,
    required int valence,
    required String moodLabel,
    String? notes,
    List<String> tags = const [],
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final checkinId = 'onboarding_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final trimmedNotes = notes?.trim();

    await _moodCheckinsCol.doc(checkinId).set({
      'id': checkinId,
      'userId': userId,
      'timestamp': nowIso,
      'valence': valence.clamp(1, 5),
      'moodLabel': moodLabel.trim().isEmpty ? 'Neutral' : moodLabel.trim(),
      'notes': (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : (trimmedNotes.length > 500 ? trimmedNotes.substring(0, 500) : trimmedNotes),
      'tags': tags.take(10).toList(),
      'isOnboardingCheckin': true,
    });
  }
}
