import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/core/providers/app_providers.dart';
import 'package:neuroshift_mobile/features/onboarding/screens/onboarding_consent_screen.dart';
import 'package:neuroshift_mobile/models/consent_record.dart';
import 'package:neuroshift_mobile/services/firestore/consent_repository.dart';

class _FakeConsentRepository implements ConsentRepository {
  ConsentRecord? savedRecord;
  Map<String, dynamic>? savedMoodCheckin;
  String? withdrawnUserId;

  @override
  Stream<ConsentRecord?> streamConsentRecord(String userId) =>
      Stream.value(savedRecord);

  @override
  Future<ConsentRecord?> getConsentRecord(String userId) async => savedRecord;

  @override
  Future<ConsentRecord> saveConsentRecord(ConsentRecord record) async {
    savedRecord = record;
    return record;
  }

  @override
  Future<ConsentRecord> withdrawConsent(String userId) async {
    withdrawnUserId = userId;
    final now = DateTime.now();
    savedRecord = ConsentRecord(
      userId: userId,
      status: ConsentStatus.withdrawn,
      moodTrackingConsent: false,
      physiologicalDataConsent: false,
      adaptiveRecommendationsConsent: false,
      anonymizedResearchConsent: false,
      consentedAt: now,
      lastUpdatedAt: now,
      withdrawnAt: now,
    );
    return savedRecord!;
  }

  @override
  Future<void> saveOnboardingMoodCheckin({
    required String userId,
    required int valence,
    required String moodLabel,
    String? notes,
    List<String> tags = const [],
  }) async {
    savedMoodCheckin = {
      'userId': userId,
      'valence': valence,
      'moodLabel': moodLabel,
      'tags': tags,
      'isOnboardingCheckin': true,
    };
  }
}

void main() {
  group('ConsentRecord & Firestore Schema Compliance Tests', () {
    test('toFirestoreMap contains exact 10 fields required by firestore.rules and preserves rawConsentedAt', () {
      final now = DateTime(2026, 10, 25, 18, 30);
      final record = ConsentRecord(
        userId: 'user_abc123',
        policyVersion: '1.0.0',
        status: ConsentStatus.partial,
        moodTrackingConsent: true,
        physiologicalDataConsent: true,
        adaptiveRecommendationsConsent: true,
        anonymizedResearchConsent: false,
        consentedAt: now,
        rawConsentedAt: '2026-10-20T10:00:00.000Z',
        lastUpdatedAt: now,
        withdrawnAt: null,
      );

      final map = record.toFirestoreMap();
      expect(
        map.keys.toSet(),
        equals({
          'userId',
          'policyVersion',
          'status',
          'moodTrackingConsent',
          'physiologicalDataConsent',
          'adaptiveRecommendationsConsent',
          'anonymizedResearchConsent',
          'consentedAt',
          'lastUpdatedAt',
          'withdrawnAt',
        }),
      );
      expect(map['consentedAt'], '2026-10-20T10:00:00.000Z');
      expect(map['status'], 'partial');
      expect(record.isActive, isTrue);
    });

    test('computeStatus classifies granted, partial, and withdrawn accurately', () {
      expect(
        ConsentRecord.computeStatus(
          moodTrackingConsent: true,
          physiologicalDataConsent: true,
          adaptiveRecommendationsConsent: true,
          anonymizedResearchConsent: true,
        ),
        ConsentStatus.granted,
      );

      expect(
        ConsentRecord.computeStatus(
          moodTrackingConsent: true,
          physiologicalDataConsent: true,
          adaptiveRecommendationsConsent: true,
          anonymizedResearchConsent: false,
        ),
        ConsentStatus.partial,
      );

      expect(
        ConsentRecord.computeStatus(
          moodTrackingConsent: false,
          physiologicalDataConsent: false,
          adaptiveRecommendationsConsent: false,
          anonymizedResearchConsent: false,
        ),
        ConsentStatus.withdrawn,
      );
    });
  });

  group('OnboardingConsentScreen Widget Tests', () {
    testWidgets('Renders consent clauses, switches, and saves ConsentRecord + onboarding mood check-in on submit',
        (tester) async {
      final fakeRepo = _FakeConsentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consentRepositoryProvider.overrideWithValue(fakeRepo),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: OnboardingConsentScreen(
              overrideUserId: 'uid_test_patient',
              overrideUserEmail: 'patient@neuroshift.app',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NeuroShift Participant Informed Consent'), findsOneWidget);
      expect(find.text('Purpose & Non-Medical Wellness Disclaimer'), findsOneWidget);
      expect(find.text('Data Collection, Cloud Firestore Storage & Security'), findsOneWidget);

      // Scroll down to affirmation checkbox & submit button
      final checkboxFinder = find.byKey(const Key('consent_acknowledge_checkbox'));
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('consent_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(fakeRepo.savedRecord, isNotNull);
      expect(fakeRepo.savedRecord!.userId, 'uid_test_patient');
      expect(fakeRepo.savedRecord!.physiologicalDataConsent, isTrue);
      expect(fakeRepo.savedRecord!.moodTrackingConsent, isTrue);
      expect(fakeRepo.savedRecord!.adaptiveRecommendationsConsent, isTrue);
      expect(fakeRepo.savedRecord!.anonymizedResearchConsent, isFalse);
      expect(fakeRepo.savedRecord!.status, ConsentStatus.partial);

      expect(fakeRepo.savedMoodCheckin, isNotNull);
      expect(fakeRepo.savedMoodCheckin!['userId'], 'uid_test_patient');
      expect(fakeRepo.savedMoodCheckin!['isOnboardingCheckin'], isTrue);
    });
  });
}
