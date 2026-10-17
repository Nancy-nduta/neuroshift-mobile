import 'package:cloud_firestore/cloud_firestore.dart';

class TherapistMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'client' or 'therapist'
  final String recipientId;
  final String grantId;
  final String text;
  final String? resourceAttachmentId;
  final String? resourceAttachmentTitle;
  final DateTime sentAt;

  const TherapistMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.recipientId,
    required this.grantId,
    required this.text,
    this.resourceAttachmentId,
    this.resourceAttachmentTitle,
    required this.sentAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'recipientId': recipientId,
      'grantId': grantId,
      'text': text,
      'resourceAttachmentId': resourceAttachmentId,
      'resourceAttachmentTitle': resourceAttachmentTitle,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory TherapistMessage.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TherapistMessage(
      id: (map['id'] as String?) ?? docId,
      senderId: (map['senderId'] as String?) ?? '',
      senderName: (map['senderName'] as String?) ?? '',
      senderRole: (map['senderRole'] as String?) ?? 'client',
      recipientId: (map['recipientId'] as String?) ?? '',
      grantId: (map['grantId'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      resourceAttachmentId: map['resourceAttachmentId'] as String?,
      resourceAttachmentTitle: map['resourceAttachmentTitle'] as String?,
      sentAt: parseDate(map['sentAt']),
    );
  }
}
