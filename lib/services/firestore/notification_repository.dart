import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../models/app_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  /// Creates a notification document in Cloud Firestore Collection 13.
  Future<void> createNotification(AppNotification notification) async {
    await _notificationsCol.doc(notification.id).set(notification.toFirestore());
  }

  /// Streams notifications addressed to [recipientId], sorted from newest to oldest.
  Stream<List<AppNotification>> streamNotifications(String recipientId) {
    if (recipientId.isEmpty) {
      return Stream.value(const []);
    }

    return _notificationsCol
        .where('recipientId', isEqualTo: recipientId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  /// Marks a specific notification document as read by the recipient.
  Future<void> markAsRead(String notificationId, {DateTime? readAt}) async {
    try {
      await _notificationsCol.doc(notificationId).update({
        'isRead': true,
        'readAt': (readAt ?? DateTime.now()).toIso8601String(),
      });
    } catch (_) {
      // Best-effort in offline/disconnected environments
    }
  }

  /// Marks multiple notification documents as read.
  Future<void> markAllAsRead(Iterable<String> notificationIds) async {
    final futures = notificationIds.map((id) => markAsRead(id));
    await Future.wait(futures);
  }

  /// Deletes a notification document (user right to dismissal / erasure).
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsCol.doc(notificationId).delete();
  }
}

/// Repository provider for Firestore notifications.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Streams real-time notifications from Firestore for the currently signed-in user.
final firestoreNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);

  return ref
      .watch(notificationRepositoryProvider)
      .streamNotifications(user.uid);
});
