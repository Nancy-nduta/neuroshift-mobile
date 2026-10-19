import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/meditation_session.dart';
import '../../models/sensor_status.dart';
import '../../models/signal_reading.dart';
import '../../models/therapist_access_grant.dart';
import '../../models/therapist_prescription.dart';
import '../../models/therapist_profile.dart';
import '../../services/auth/auth_service.dart';
import '../../services/firestore/session_repository.dart';
import '../../services/firestore/therapist_repository.dart';
import '../../services/sensors/muse_bluetooth_service.dart';

// Services
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

final museServiceProvider = Provider<MuseBluetoothService>((ref) {
  final service = MuseBluetoothService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Auth Streams
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUserProfile(user.uid);
});

final currentTherapistProfileProvider = StreamProvider<TherapistProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('therapist_profiles')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists && doc.data() != null
          ? TherapistProfile.fromFirestore(doc.data()!, doc.id)
          : null);
});

final isTherapistProvider = Provider<bool>((ref) {
  return ref.watch(currentTherapistProfileProvider).value != null;
});

// Telemetry & Hardware Streams
final headbandStatusProvider = StreamProvider<HeadbandStatus>((ref) {
  final muse = ref.watch(museServiceProvider);
  return muse.statusStream;
});

final signalReadingProvider = StreamProvider<SignalReading>((ref) {
  final muse = ref.watch(museServiceProvider);
  return muse.readingStream;
});

final discoveredDevicesProvider = StreamProvider<List<ScanResult>>((ref) {
  final muse = ref.watch(museServiceProvider);
  return muse.discoveredDevicesStream;
});

// Sessions Stream
final userSessionsProvider = StreamProvider<List<MeditationSession>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(sessionRepositoryProvider).streamUserSessions(user.uid);
});

// Therapist & Care Team Providers
final therapistRepositoryProvider = Provider<TherapistRepository>((ref) {
  return TherapistRepository();
});

final clientGrantsProvider = StreamProvider<List<TherapistAccessGrant>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(therapistRepositoryProvider).streamClientGrants(user.uid);
});

final therapistGrantsProvider = StreamProvider<List<TherapistAccessGrant>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || user.email == null) return Stream.value([]);
  return ref.watch(therapistRepositoryProvider).streamTherapistGrants(
        therapistId: user.uid,
        therapistEmail: user.email!,
      );
});

final clientPrescriptionsProvider = StreamProvider<List<TherapistPrescription>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(therapistRepositoryProvider).streamPrescriptionsForClient(user.uid);
});

/// Controls the active bottom navigation bar tab in MainShell across the entire app
class MainNavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final mainNavIndexProvider = NotifierProvider<MainNavNotifier, int>(
  MainNavNotifier.new,
);


