import 'therapist_access_grant.dart';

enum AppNotificationType {
  chatMessage,
  newPrescription,
  prescriptionCompleted,
  grantInvitation,
  grantAccepted,
  systemAlert,
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String senderName;
  final DateTime timestamp;
  final String? recipientId;
  final String? senderId;
  final String? grantId;
  final String? targetRoute;
  final DateTime? readAt;
  final TherapistAccessGrant? grant;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.senderName,
    required this.timestamp,
    this.recipientId,
    this.senderId,
    this.grantId,
    this.targetRoute,
    this.readAt,
    this.grant,
    this.isRead = false,
  });

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
    TherapistAccessGrant? grant,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      senderName: senderName,
      timestamp: timestamp,
      recipientId: recipientId,
      senderId: senderId,
      grantId: grantId,
      targetRoute: targetRoute,
      readAt: readAt ?? this.readAt,
      grant: grant ?? this.grant,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Converts this notification into a Firestore-compliant document map.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'recipientId': recipientId ?? '',
      'senderId': senderId ?? '',
      'senderName': senderName,
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': timestamp.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      if (grantId != null) 'grantId': grantId,
      if (targetRoute != null) 'targetRoute': targetRoute,
    };
  }

  /// Creates an [AppNotification] instance from a Firestore document.
  factory AppNotification.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    TherapistAccessGrant? grant,
  }) {
    final typeStr = data['type'] as String? ?? 'systemAlert';
    final notifType = AppNotificationType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => AppNotificationType.systemAlert,
    );

    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is String
        ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
        : DateTime.now();

    final readAtRaw = data['readAt'];
    final readAt = readAtRaw is String ? DateTime.tryParse(readAtRaw) : null;

    return AppNotification(
      id: id,
      type: notifType,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'NeuroShift',
      timestamp: createdAt,
      recipientId: data['recipientId'] as String?,
      senderId: data['senderId'] as String?,
      grantId: data['grantId'] as String?,
      targetRoute: data['targetRoute'] as String?,
      readAt: readAt,
      grant: grant,
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }
}
