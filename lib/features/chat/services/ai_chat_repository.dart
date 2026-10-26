import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_chat_message.dart';

class AiChatRepository {
  final FirebaseFirestore? firestore;

  AiChatRepository({this.firestore});

  FirebaseFirestore? get _instance {
    if (firestore != null) return firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _chatsCol =>
      _instance?.collection('ai_chat_messages');

  Future<void> saveMessage({
    required String userId,
    required AiChatMessage message,
  }) async {
    try {
      final col = _chatsCol;
      if (col == null) return;
      await col.doc(message.id).set(message.toFirestore(userId));
    } catch (e) {
      // Best-effort online sync; log so any network or permission errors are diagnosed
      // ignore: avoid_print
      print('AiChatRepository.saveMessage error: $e');
    }
  }

  Stream<List<AiChatMessage>> streamUserChat(String userId) {
    final col = _chatsCol;
    if (col == null) return const Stream.empty();
    return col
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AiChatMessage.fromFirestore(doc.data()))
          .toList();
    });
  }

  Future<List<AiChatMessage>> getRecentChat(
    String userId, {
    int limit = 60,
  }) async {
    try {
      final col = _chatsCol;
      if (col == null) return [];
      final query = await col
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final messages = query.docs
          .map((doc) => AiChatMessage.fromFirestore(doc.data()))
          .toList();
      // Return in chronological order
      return messages.reversed.toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearHistory(String userId) async {
    try {
      final instance = _instance;
      final col = _chatsCol;
      if (instance == null || col == null) return;
      final query = await col.where('userId', isEqualTo: userId).get();
      final batch = instance.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // Best-effort online deletion
    }
  }
}

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository();
});

final userAiChatStreamProvider =
    StreamProvider.family<List<AiChatMessage>, String>((ref, userId) {
  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.streamUserChat(userId);
});
