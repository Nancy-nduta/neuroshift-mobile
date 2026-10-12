import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/app_user.dart';
import '../../models/therapist_profile.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: '201008218780-q00g8r0016k6fkk50n8p8bnvelhks652.apps.googleusercontent.com',
            );

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        // Auto-provision if missing
        final user = _auth.currentUser;
        if (user != null && user.uid == uid) {
          final now = DateTime.now();
          final newUser = AppUser(
            uid: uid,
            email: user.email ?? '',
            displayName: user.displayName,
            createdAt: now,
            rawCreatedAt: now.toIso8601String(),
          );
          try {
            await _firestore.collection('users').doc(uid).set(newUser.toFirestoreMap());
          } catch (_) {}
          return newUser;
        }
        return null;
      }
      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<TherapistProfile?> getTherapistProfile(String uid) async {
    try {
      final doc = await _firestore.collection('therapist_profiles').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return TherapistProfile.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final profile = await getUserProfile(uid);
    if (profile != null) return profile;

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final newProfile = AppUser(
      uid: uid,
      email: cred.user?.email ?? email.trim(),
      displayName: cred.user?.displayName,
      createdAt: now,
      rawCreatedAt: nowIso,
    );
    try {
      await _firestore.collection('users').doc(uid).set(newProfile.toFirestoreMap());
    } catch (_) {}
    return newProfile;
  }

  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final userDocRef = _firestore.collection('users').doc(uid);
    final existingDoc = await userDocRef.get();
    if (existingDoc.exists && existingDoc.data() != null) {
      final existingCreatedAt = (existingDoc.data()?['createdAt'] as String?) ?? nowIso;
      final newProfile = AppUser(
        uid: uid,
        email: email.trim(),
        displayName: displayName?.trim(),
        createdAt: DateTime.tryParse(existingCreatedAt) ?? now,
        rawCreatedAt: existingCreatedAt,
      );
      await userDocRef.set(newProfile.toFirestoreMap(), SetOptions(merge: true));
      return newProfile;
    } else {
      final newProfile = AppUser(
        uid: uid,
        email: email.trim(),
        displayName: displayName?.trim(),
        createdAt: now,
        rawCreatedAt: nowIso,
      );
      await userDocRef.set(newProfile.toFirestoreMap());
      return newProfile;
    }
  }

  Future<TherapistProfile> registerTherapist({
    required String email,
    required String password,
    required String displayName,
    required String organization,
    required String licenseNumber,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user?.updateDisplayName(displayName.trim());

    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final therapistProfile = TherapistProfile(
      id: uid,
      displayName: displayName.trim(),
      email: email.trim(),
      organization: organization.trim(),
      licenseNumber: licenseNumber.trim(),
      isVerified: false,
      createdAt: now,
      rawCreatedAt: nowIso,
    );

    // Save therapist profile in therapist_profiles/{uid}
    await _firestore
        .collection('therapist_profiles')
        .doc(uid)
        .set(therapistProfile.toFirestoreMap());

    // Safely check and provision user doc: if already created, preserve existing createdAt!
    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final existingDoc = await userDocRef.get();
      if (existingDoc.exists && existingDoc.data() != null) {
        final existingCreatedAt = (existingDoc.data()?['createdAt'] as String?) ?? nowIso;
        final userProfile = AppUser(
          uid: uid,
          email: email.trim(),
          displayName: displayName.trim(),
          createdAt: DateTime.tryParse(existingCreatedAt) ?? now,
          rawCreatedAt: existingCreatedAt,
        );
        await userDocRef.set(userProfile.toFirestoreMap(), SetOptions(merge: true));
      } else {
        final userProfile = AppUser(
          uid: uid,
          email: email.trim(),
          displayName: displayName.trim(),
          createdAt: now,
          rawCreatedAt: nowIso,
        );
        await userDocRef.set(userProfile.toFirestoreMap());
      }
    } catch (_) {
      // User doc provisioning is non-fatal; therapist profile is primary
    }

    return therapistProfile;
  }

  Future<TherapistProfile> enrollCurrentAsTherapist({
    required String organization,
    required String licenseNumber,
    String? displayName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be authenticated');
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final name = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : (user.displayName ?? (user.email?.split('@').first ?? 'Practitioner'));

    final therapistProfile = TherapistProfile(
      id: user.uid,
      displayName: name,
      email: user.email ?? '',
      organization: organization.trim(),
      licenseNumber: licenseNumber.trim(),
      isVerified: true,
      createdAt: now,
      rawCreatedAt: nowIso,
    );

    await _firestore
        .collection('therapist_profiles')
        .doc(user.uid)
        .set(therapistProfile.toFirestoreMap());

    return therapistProfile;
  }

  Future<AppUser?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential cred = await _auth.signInWithCredential(credential);
    final uid = cred.user!.uid;
    final profile = await getUserProfile(uid);
    if (profile != null) return profile;

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final newProfile = AppUser(
      uid: uid,
      email: cred.user?.email ?? googleUser.email,
      displayName: cred.user?.displayName ?? googleUser.displayName,
      createdAt: now,
      rawCreatedAt: nowIso,
    );
    try {
      await _firestore.collection('users').doc(uid).set(newProfile.toFirestoreMap());
    } catch (_) {}
    return newProfile;
  }

  Future<void> updateUserProfile(AppUser user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    String? rawCreatedAt = user.rawCreatedAt;
    try {
      final snap = await userDocRef.get();
      if (snap.exists && snap.data() != null) {
        rawCreatedAt = (snap.data()?['createdAt'] as String?) ?? rawCreatedAt;
      }
    } catch (_) {}

    final userWithCreatedAt = user.copyWith(rawCreatedAt: rawCreatedAt);
    await userDocRef.set(
      userWithCreatedAt.toFirestoreMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
