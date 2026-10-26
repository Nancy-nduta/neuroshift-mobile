import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_notification.dart';
import '../../models/meditation_session.dart';
import '../../models/therapist_access_grant.dart';
import '../../models/therapist_message.dart';
import '../../models/therapist_prescription.dart';

class TherapistRepository {
  final FirebaseFirestore _firestore;

  TherapistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _grantsCol =>
      _firestore.collection('therapist_access_grants');

  CollectionReference<Map<String, dynamic>> get _messagesCol =>
      _firestore.collection('therapist_messages');

  CollectionReference<Map<String, dynamic>> get _prescriptionsCol =>
      _firestore.collection('therapist_prescriptions');

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection('meditation_sessions');

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  // ==================== 1. GRANTS & INVITATIONS ====================

  /// Patient grants access to a therapist by email
  Future<TherapistAccessGrant> grantTherapistAccess({
    required String clientId,
    required String clientEmail,
    required String therapistEmail,
  }) async {
    final cleanEmail = therapistEmail.trim().toLowerCase();
    final grantId = 'grant_${clientId}_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    // Look up if therapist profile already exists
    String therapistId = 'pending_$cleanEmail';
    try {
      final query = await _firestore
          .collection('therapist_profiles')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        therapistId = query.docs.first.id;
      }
    } catch (_) {}

    final grant = TherapistAccessGrant(
      id: grantId,
      clientId: clientId,
      clientEmail: clientEmail,
      therapistId: therapistId,
      therapistEmail: cleanEmail,
      status: GrantStatus.pending,
      scopes: const ['session_reports', 'eeg_telemetry', 'recommendations'],
      grantedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );

    await _grantsCol.doc(grantId).set(grant.toFirestore());
    return grant;
  }

  /// Stream grants initiated by this client
  Stream<List<TherapistAccessGrant>> streamClientGrants(String clientId) {
    return _grantsCol
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TherapistAccessGrant.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.grantedAt.compareTo(a.grantedAt));
          return list;
        });
  }

  /// Stream invitations/grants received by therapist (by email or UID)
  Stream<List<TherapistAccessGrant>> streamTherapistGrants({
    required String therapistId,
    required String therapistEmail,
  }) {
    final cleanEmail = therapistEmail.trim().toLowerCase();
    return _grantsCol
        .where('therapistEmail', isEqualTo: cleanEmail)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TherapistAccessGrant.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.grantedAt.compareTo(a.grantedAt));
          return list;
        });
  }

  /// Therapist accepts patient invitation
  Future<void> acceptGrant({
    required String grantId,
    required String therapistId,
  }) async {
    await _grantsCol.doc(grantId).update({
      'status': 'active',
      'therapistId': therapistId,
    });
  }

  /// Client revokes access
  Future<void> revokeGrant(String grantId) async {
    await _grantsCol.doc(grantId).update({
      'status': 'revoked',
      'revokedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ==================== 2. PATIENT INSIGHTS ====================

  /// Fetch client session telemetry (used by therapist dashboard)
  Future<List<MeditationSession>> getClientSessions(String clientId) async {
    final query = await _sessionsCol
        .where('userId', isEqualTo: clientId)
        .limit(50)
        .get();

    final list = query.docs
        .map((doc) => MeditationSession.fromFirestore(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  Stream<List<MeditationSession>> streamClientSessions(String clientId) {
    return _sessionsCol
        .where('userId', isEqualTo: clientId)
        .limit(50)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => MeditationSession.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
          return list;
        });
  }

  // ==================== 3. MESSAGING & CHAT ====================

  Stream<List<TherapistMessage>> streamMessages(String grantId) {
    return _messagesCol
        .where('grantId', isEqualTo: grantId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TherapistMessage.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
          return list;
        });
  }

  /// Stream messages across multiple clinical grants (up to 10 for Firestore `whereIn`).
  Stream<List<TherapistMessage>> streamMessagesForGrants(List<String> grantIds) {
    final cleanIds = grantIds.where((id) => id.isNotEmpty).take(10).toList();
    if (cleanIds.isEmpty) {
      return Stream.value(const []);
    }
    return _messagesCol
        .where('grantId', whereIn: cleanIds)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TherapistMessage.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          return list;
        });
  }

  Future<void> sendMessage(TherapistMessage message) async {
    await _messagesCol.doc(message.id).set(message.toFirestore());
    try {
      final notifId = 'notif_msg_${message.id}';
      final isFromTherapist = message.senderRole == 'therapist';
      final notif = AppNotification(
        id: notifId,
        type: AppNotificationType.chatMessage,
        title: isFromTherapist
            ? 'Message from ${message.senderName.isNotEmpty ? message.senderName : "Your Therapist"}'
            : 'New Patient Message • ${message.senderName}',
        body: message.text,
        senderName: message.senderName.isNotEmpty ? message.senderName : 'NeuroShift User',
        timestamp: message.sentAt,
        recipientId: message.recipientId,
        senderId: message.senderId,
        grantId: message.grantId,
        isRead: false,
      );
      await _notificationsCol.doc(notifId).set(notif.toFirestore());
    } catch (_) {}
  }

  /// Edit an existing message sent by the user
  Future<void> updateMessage({
    required String messageId,
    required String newText,
  }) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;
    await _messagesCol.doc(messageId).update({
      'text': trimmed,
      'isEdited': true,
      'editedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete an existing message sent by the user
  Future<void> deleteMessage(String messageId) async {
    await _messagesCol.doc(messageId).delete();
  }

  // ==================== 4. PRESCRIPTIONS & RECOMMENDED TOOLS ====================

  Future<void> prescribeResource(TherapistPrescription prescription) async {
    await _prescriptionsCol.doc(prescription.id).set(prescription.toFirestore());
    try {
      final notifId = 'notif_rx_${prescription.id}';
      final notif = AppNotification(
        id: notifId,
        type: AppNotificationType.newPrescription,
        title: 'New Prescribed Practice from ${prescription.therapistName}',
        body: prescription.instructions != null && prescription.instructions!.trim().isNotEmpty
            ? '${prescription.resourceTitle} — "${prescription.instructions!.trim()}"'
            : 'Recommended practice: ${prescription.resourceTitle}',
        senderName: prescription.therapistName,
        timestamp: prescription.prescribedAt,
        recipientId: prescription.clientId,
        senderId: prescription.therapistId,
        isRead: false,
      );
      await _notificationsCol.doc(notifId).set(notif.toFirestore());
    } catch (_) {}
  }

  Stream<List<TherapistPrescription>> streamPrescriptionsForClient(String clientId) {
    return _prescriptionsCol
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TherapistPrescription.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.prescribedAt.compareTo(a.prescribedAt));
          return list;
        });
  }

  Stream<List<TherapistPrescription>> streamPrescriptionsForTherapist(String therapistId) {
    return _prescriptionsCol
        .where('therapistId', isEqualTo: therapistId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TherapistPrescription.fromFirestore(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.prescribedAt.compareTo(a.prescribedAt));
          return list;
        });
  }

  /// Patient completes practice for a prescribed tool, recording their Muse 2 outcome
  Future<void> recordPrescriptionOutcome({
    required String prescriptionId,
    required String completedSessionId,
    required double patientCalmScore,
    required int patientHelpfulnessRating,
    String? patientFeedback,
  }) async {
    await _prescriptionsCol.doc(prescriptionId).update({
      'status': 'completed',
      'completedSessionId': completedSessionId,
      'patientCalmScore': patientCalmScore,
      'patientHelpfulnessRating': patientHelpfulnessRating,
      'patientFeedback': patientFeedback,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
    try {
      final rxDoc = await _prescriptionsCol.doc(prescriptionId).get();
      if (rxDoc.exists && rxDoc.data() != null) {
        final rx = TherapistPrescription.fromFirestore(rxDoc.data()!, rxDoc.id);
        final notifId = 'notif_rx_done_${rx.id}';
        final notif = AppNotification(
          id: notifId,
          type: AppNotificationType.prescriptionCompleted,
          title: 'Practice Completed by ${rx.clientEmail}',
          body: 'Completed "${rx.resourceTitle}" • Calm: ${patientCalmScore.toStringAsFixed(0)}%',
          senderName: rx.clientEmail,
          timestamp: DateTime.now(),
          recipientId: rx.therapistId,
          senderId: rx.clientId,
          isRead: false,
        );
        await _notificationsCol.doc(notifId).set(notif.toFirestore());
      }
    } catch (_) {}
  }
}
