import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/resources/models/resource_evaluation.dart';
import '../../models/meditation_session.dart';

class SessionRepository {
  final FirebaseFirestore _firestore;

  static const String _localCachePrefix = 'cached_meditation_sessions_';

  SessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection('meditation_sessions');

  CollectionReference<Map<String, dynamic>> get _activitySessionsCol =>
      _firestore.collection('activity_sessions');

  Future<void> _cacheSessionLocally(MeditationSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_localCachePrefix${session.userId}';
      final existingJson = prefs.getStringList(key) ?? [];
      final existingSessions = existingJson.map((str) {
        try {
          return MeditationSession.fromJson(jsonDecode(str) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<MeditationSession>().toList();

      existingSessions.removeWhere((s) => s.id == session.id);
      existingSessions.insert(0, session);
      existingSessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      final encodedList = existingSessions
          .take(50)
          .map((s) => jsonEncode(s.toJson()))
          .toList();
      await prefs.setStringList(key, encodedList);

      // Also mirror into anonymous cache so sessions remain visible across sign-in state transitions
      final fallbackKey = '${_localCachePrefix}anonymous';
      if (key != fallbackKey) {
        final fallbackExisting = prefs.getStringList(fallbackKey) ?? [];
        final fallbackSessions = fallbackExisting.map((str) {
          try {
            return MeditationSession.fromJson(jsonDecode(str) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        }).whereType<MeditationSession>().toList();
        fallbackSessions.removeWhere((s) => s.id == session.id);
        fallbackSessions.insert(0, session);
        await prefs.setStringList(
          fallbackKey,
          fallbackSessions.take(50).map((s) => jsonEncode(s.toJson())).toList(),
        );
      }
    } catch (_) {
      // Local caching is best effort
    }
  }

  Future<List<MeditationSession>> getLocalCachedSessions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_localCachePrefix$userId';
      var existingJson = prefs.getStringList(key) ?? [];
      if (existingJson.isEmpty) {
        existingJson = prefs.getStringList('${_localCachePrefix}anonymous') ?? [];
      }
      final list = existingJson.map((str) {
        try {
          return MeditationSession.fromJson(jsonDecode(str) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<MeditationSession>().toList();
      list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(MeditationSession session) async {
    // 1. Instantly write to local persistent disk cache
    await _cacheSessionLocally(session);

    // 2. Persist to Cloud Firestore
    try {
      await _sessionsCol.doc(session.id).set(session.toFirestore());

      // Update user streak and total minutes
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
      // Best-effort Firestore write; local cache preserves session if offline
    }
  }

  /// Saves structured Reinforcement Learning (RL) state-action-reward feedback
  /// to `activity_sessions/{sessionId}` in strict compliance with `firestore.rules`.
  Future<void> saveActivityEvaluation({
    required String sessionId,
    required String userId,
    required DateTime startedAt,
    required DateTime completedAt,
    required ResourceEvaluation evaluation,
  }) async {
    final safeTitle = evaluation.resourceTitle.isEmpty
        ? 'Guided Session'
        : (evaluation.resourceTitle.length > 150
            ? evaluation.resourceTitle.substring(0, 150)
            : evaluation.resourceTitle);
    final safeCategory = evaluation.category.isEmpty
        ? 'Guided Practice'
        : (evaluation.category.length > 50
            ? evaluation.category.substring(0, 50)
            : evaluation.category);

    try {
      await _activitySessionsCol.doc(sessionId).set({
        'id': sessionId,
        'userId': userId,
        'activityId': evaluation.resourceId.isEmpty ? 'meditation' : evaluation.resourceId,
        'activityTitle': safeTitle,
        'category': safeCategory,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': evaluation.durationSeconds < 0 ? 0 : evaluation.durationSeconds,
        'preValence': evaluation.preValence.clamp(1, 5),
        'postValence': evaluation.postValence.clamp(1, 5),
        'helpfulnessRating': evaluation.starRating.clamp(1, 5),
        'wouldUseAgain': evaluation.wouldUseAgain,
        'feedbackComments': evaluation.toCompactFeedbackComments(),
        'completedSuccessfully': true,
      });
    } catch (_) {
      // Best-effort RL evaluation record
    }
  }

  Stream<List<ResourceEvaluation>> streamUserActivityEvaluations(String userId) {
    return _activitySessionsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ResourceEvaluation.fromActivitySessionDoc(doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<MeditationSession>> streamUserSessions(String userId) async* {
    // 1. Immediately emit locally cached sessions so UI never shows a blank screen
    final cached = await getLocalCachedSessions(userId);
    if (cached.isNotEmpty) {
      yield cached;
    }

    // 2. Stream from Firestore (without requiring a compound index)
    try {
      final firestoreStream = _sessionsCol
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final sessions = snapshot.docs
            .map((doc) => MeditationSession.fromFirestore(doc.data(), doc.id))
            .toList();
        sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return sessions;
      });

      await for (final remoteSessions in firestoreStream) {
        final merged = <String, MeditationSession>{};
        for (final s in cached) {
          merged[s.id] = s;
        }
        for (final s in remoteSessions) {
          merged[s.id] = s;
        }
        final result = merged.values.toList();
        result.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        yield result;
      }
    } catch (_) {
      if (cached.isNotEmpty) {
        yield cached;
      }
    }
  }

  Future<List<MeditationSession>> getUserSessions(String userId) async {
    final cached = await getLocalCachedSessions(userId);
    try {
      final query = await _sessionsCol
          .where('userId', isEqualTo: userId)
          .get();

      final remote = query.docs
          .map((doc) => MeditationSession.fromFirestore(doc.data(), doc.id))
          .toList();
      final merged = <String, MeditationSession>{};
      for (final s in cached) {
        merged[s.id] = s;
      }
      for (final s in remote) {
        merged[s.id] = s;
      }
      final result = merged.values.toList();
      result.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return result;
    } catch (_) {
      return cached;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _sessionsCol.doc(sessionId).delete();
    } catch (_) {}
  }
}

