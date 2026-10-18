import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/meditation_session.dart';

class SessionRepository {
  final FirebaseFirestore _firestore;

  SessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection('meditation_sessions');

  Future<void> saveSession(MeditationSession session) async {
    await _sessionsCol.doc(session.id).set(session.toFirestore());

    // Update user streak and total minutes
    try {
      final userDocRef = _firestore.collection('users').doc(session.userId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(userDocRef);
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          final currentMinutes = (data['totalMeditationMinutes'] as int?) ?? 0;
          final sessionMinutes = (session.durationSeconds / 60).ceil();
          tx.update(userDocRef, {
            'totalMeditationMinutes': currentMinutes + sessionMinutes,
          });
        }
      });
    } catch (_) {
      // Best-effort stats aggregation
    }
  }

  Stream<List<MeditationSession>> streamUserSessions(String userId) {
    return _sessionsCol
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MeditationSession.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<MeditationSession>> getUserSessions(String userId) async {
    final query = await _sessionsCol
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => MeditationSession.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionsCol.doc(sessionId).delete();
  }
}
