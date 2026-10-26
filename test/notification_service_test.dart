import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/models/app_notification.dart';
import 'package:neuroshift_mobile/models/therapist_access_grant.dart';
import 'package:neuroshift_mobile/models/therapist_message.dart';
import 'package:neuroshift_mobile/models/therapist_prescription.dart';
import 'package:neuroshift_mobile/services/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationService.buildNotifications', () {
    final baseTime = DateTime(2026, 10, 25, 12, 0);

    final activeGrant = TherapistAccessGrant(
      id: 'grant_client1_drsmith',
      clientId: 'client_1',
      clientEmail: 'patient@neuroshift.app',
      therapistId: 'therapist_1',
      therapistEmail: 'drsmith@clinic.org',
      status: GrantStatus.active,
      grantedAt: baseTime.subtract(const Duration(days: 1)),
      expiresAt: baseTime.add(const Duration(days: 89)),
    );

    final pendingGrant = TherapistAccessGrant(
      id: 'grant_client2_drsmith',
      clientId: 'client_2',
      clientEmail: 'newpatient@neuroshift.app',
      therapistId: 'therapist_1',
      therapistEmail: 'drsmith@clinic.org',
      status: GrantStatus.pending,
      grantedAt: baseTime.subtract(const Duration(minutes: 30)),
      expiresAt: baseTime.add(const Duration(days: 90)),
    );

    test('client receives notification when therapist sends a chat message', () {
      final messages = [
        // Client's own outgoing message (should be ignored for client)
        TherapistMessage(
          id: 'msg_1',
          senderId: 'client_1',
          senderName: 'patient',
          senderRole: 'client',
          recipientId: 'therapist_1',
          grantId: activeGrant.id,
          text: 'Hi Dr. Smith, I completed my session.',
          sentAt: baseTime.subtract(const Duration(minutes: 10)),
        ),
        // Therapist's reply (should notify client)
        TherapistMessage(
          id: 'msg_2',
          senderId: 'therapist_1',
          senderName: 'Dr. Smith',
          senderRole: 'therapist',
          recipientId: 'client_1',
          grantId: activeGrant.id,
          text: 'Great progress on your alpha calm score today!',
          sentAt: baseTime.subtract(const Duration(minutes: 5)),
        ),
      ];

      final notifications = NotificationService.buildNotifications(
        currentUserId: 'client_1',
        isTherapist: false,
        clientGrants: [activeGrant],
        therapistGrants: const [],
        messages: messages,
        clientPrescriptions: const [],
        therapistPrescriptions: const [],
        readIds: const {},
      );

      final chatNotifs = notifications
          .where((n) => n.type == AppNotificationType.chatMessage)
          .toList();
      expect(chatNotifs, hasLength(1));
      expect(chatNotifs.first.id, 'notif_msg_msg_2');
      expect(chatNotifs.first.title, contains('Dr. Smith'));
      expect(chatNotifs.first.body, contains('Great progress'));
      expect(chatNotifs.first.grant?.id, activeGrant.id);
      expect(chatNotifs.first.isRead, isFalse);
    });

    test('therapist receives notification when client sends a chat message', () {
      final messages = [
        // Client message to therapist
        TherapistMessage(
          id: 'msg_10',
          senderId: 'client_1',
          senderName: 'Alex',
          senderRole: 'client',
          recipientId: 'therapist_1',
          grantId: activeGrant.id,
          text: 'Dr. Smith, should I try the 4-7-8 breathing before sleep?',
          sentAt: baseTime.subtract(const Duration(minutes: 2)),
        ),
        // Therapist's own message (should NOT notify therapist)
        TherapistMessage(
          id: 'msg_11',
          senderId: 'therapist_1',
          senderName: 'Dr. Smith',
          senderRole: 'therapist',
          recipientId: 'client_1',
          grantId: activeGrant.id,
          text: 'Yes, start with 4 cycles.',
          sentAt: baseTime.subtract(const Duration(minutes: 1)),
        ),
      ];

      final notifications = NotificationService.buildNotifications(
        currentUserId: 'therapist_1',
        isTherapist: true,
        clientGrants: const [],
        therapistGrants: [activeGrant],
        messages: messages,
        clientPrescriptions: const [],
        therapistPrescriptions: const [],
        readIds: const {},
      );

      final chatNotifs = notifications
          .where((n) => n.type == AppNotificationType.chatMessage)
          .toList();
      expect(chatNotifs, hasLength(1));
      expect(chatNotifs.first.id, 'notif_msg_msg_10');
      expect(chatNotifs.first.title, contains('patient@neuroshift.app'));
      expect(chatNotifs.first.body, contains('4-7-8 breathing'));
      expect(chatNotifs.first.grant?.clientId, 'client_1');
    });

    test('notifies client on new prescription and therapist on completed prescription & pending invite', () {
      final recommendedRx = TherapistPrescription(
        id: 'rx_1',
        therapistId: 'therapist_1',
        therapistName: 'Dr. Smith',
        clientId: 'client_1',
        clientEmail: 'patient@neuroshift.app',
        resourceId: 'res_breath_1',
        resourceTitle: 'Resonance Frequency Breathing',
        resourceCategory: 'Breathwork',
        instructions: 'Practice 5 minutes each evening.',
        prescribedAt: baseTime.subtract(const Duration(hours: 2)),
        status: PrescriptionStatus.recommended,
      );

      final completedRx = TherapistPrescription(
        id: 'rx_2',
        therapistId: 'therapist_1',
        therapistName: 'Dr. Smith',
        clientId: 'client_1',
        clientEmail: 'patient@neuroshift.app',
        resourceId: 'res_mind_1',
        resourceTitle: 'Alpha Recovery Soundscape',
        resourceCategory: 'Soundscape',
        prescribedAt: baseTime.subtract(const Duration(hours: 5)),
        status: PrescriptionStatus.completed,
        patientCalmScore: 84.0,
        completedAt: baseTime.subtract(const Duration(minutes: 15)),
      );

      final clientNotifs = NotificationService.buildNotifications(
        currentUserId: 'client_1',
        isTherapist: false,
        clientGrants: [activeGrant],
        therapistGrants: const [],
        messages: const [],
        clientPrescriptions: [recommendedRx],
        therapistPrescriptions: const [],
        readIds: const {},
      );

      expect(
        clientNotifs.any((n) =>
            n.type == AppNotificationType.newPrescription &&
            n.id == 'notif_rx_rx_1'),
        isTrue,
      );

      final therapistNotifs = NotificationService.buildNotifications(
        currentUserId: 'therapist_1',
        isTherapist: true,
        clientGrants: const [],
        therapistGrants: [activeGrant, pendingGrant],
        messages: const [],
        clientPrescriptions: const [],
        therapistPrescriptions: [completedRx],
        readIds: const {},
      );

      expect(
        therapistNotifs.any((n) =>
            n.type == AppNotificationType.grantInvitation &&
            n.grant?.id == pendingGrant.id),
        isTrue,
      );
      expect(
        therapistNotifs.any((n) =>
            n.type == AppNotificationType.prescriptionCompleted &&
            n.id == 'notif_rx_done_rx_2' &&
            n.body.contains('84%')),
        isTrue,
      );
    });

    test('NotificationReadNotifier marks single, grant, and all notifications as read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(notificationReadProvider.notifier);
      final grantA = activeGrant;
      final grantB = pendingGrant;

      final sampleNotifs = [
        AppNotification(
          id: 'notif_msg_1',
          type: AppNotificationType.chatMessage,
          title: 'Message 1',
          body: 'Hello',
          senderName: 'Dr. Smith',
          timestamp: baseTime,
          grant: grantA,
        ),
        AppNotification(
          id: 'notif_msg_2',
          type: AppNotificationType.chatMessage,
          title: 'Message 2',
          body: 'Follow up',
          senderName: 'Dr. Smith',
          timestamp: baseTime,
          grant: grantB,
        ),
      ];

      notifier.markGrantNotificationsRead('client_1', grantA.id, sampleNotifs);
      expect(
        notifier.readIdsFor('client_1').contains('notif_msg_1'),
        isTrue,
      );
      expect(
        notifier.readIdsFor('client_1').contains('notif_msg_2'),
        isFalse,
      );

      notifier.markAllAsRead('client_1', sampleNotifs.map((n) => n.id));
      expect(
        notifier.readIdsFor('client_1').contains('notif_msg_2'),
        isTrue,
      );
    });

    test('NotificationReadNotifier persists and reloads read IDs across app restarts', () async {
      SharedPreferences.setMockInitialValues({
        'notif_read_client_test': ['notif_persisted_1', 'notif_persisted_2'],
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(notificationReadProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.readIdsFor('client_test').contains('notif_persisted_1'), isTrue);
      expect(notifier.readIdsFor('client_test').contains('notif_persisted_2'), isTrue);

      notifier.markAsRead('client_test', 'notif_persisted_3');
      expect(notifier.readIdsFor('client_test').contains('notif_persisted_3'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      final storedList = prefs.getStringList('notif_read_client_test');
      expect(storedList, contains('notif_persisted_3'));
    });

    test('AppNotification toFirestore and fromFirestore serialize and deserialize correctly', () {
      final now = DateTime(2026, 10, 26, 10, 0);
      final notif = AppNotification(
        id: 'notif_cloud_123',
        type: AppNotificationType.chatMessage,
        title: 'New Therapist Message',
        body: 'How are your morning Alpha sessions feeling?',
        senderName: 'Dr. Sarah Smith',
        timestamp: now,
        recipientId: 'client_xyz',
        senderId: 'therapist_abc',
        grantId: 'grant_123',
        targetRoute: '/chat',
        isRead: false,
      );

      final firestoreMap = notif.toFirestore();

      expect(firestoreMap['id'], equals('notif_cloud_123'));
      expect(firestoreMap['recipientId'], equals('client_xyz'));
      expect(firestoreMap['senderId'], equals('therapist_abc'));
      expect(firestoreMap['senderName'], equals('Dr. Sarah Smith'));
      expect(firestoreMap['type'], equals('chatMessage'));
      expect(firestoreMap['title'], equals('New Therapist Message'));
      expect(firestoreMap['body'], equals('How are your morning Alpha sessions feeling?'));
      expect(firestoreMap['isRead'], isFalse);
      expect(firestoreMap['createdAt'], equals(now.toIso8601String()));
      expect(firestoreMap['grantId'], equals('grant_123'));
      expect(firestoreMap['targetRoute'], equals('/chat'));

      final parsed = AppNotification.fromFirestore(firestoreMap, 'notif_cloud_123');
      expect(parsed.id, equals('notif_cloud_123'));
      expect(parsed.recipientId, equals('client_xyz'));
      expect(parsed.senderId, equals('therapist_abc'));
      expect(parsed.senderName, equals('Dr. Sarah Smith'));
      expect(parsed.type, equals(AppNotificationType.chatMessage));
      expect(parsed.title, equals('New Therapist Message'));
      expect(parsed.body, equals('How are your morning Alpha sessions feeling?'));
      expect(parsed.isRead, isFalse);
      expect(parsed.timestamp, equals(now));
      expect(parsed.grantId, equals('grant_123'));
      expect(parsed.targetRoute, equals('/chat'));
    });
  });
}
