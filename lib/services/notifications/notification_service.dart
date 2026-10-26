import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/muse_colors.dart';
import '../../core/theme/muse_spacing.dart';
import '../../features/profile/screens/client_therapist_chat_screen.dart';
import '../../features/therapist/screens/patient_detail_screen.dart';
import '../../models/app_notification.dart';
import '../../models/therapist_access_grant.dart';
import '../../models/therapist_message.dart';
import '../../models/therapist_prescription.dart';
import '../firestore/notification_repository.dart';

/// Tracks read notification IDs per authenticated user UID with persistent storage.
class NotificationReadNotifier extends Notifier<Map<String, Set<String>>> {
  @override
  Map<String, Set<String>> build() {
    _loadFromPrefs();
    return const {};
  }

  Set<String> readIdsFor(String userId) => state[userId] ?? const {};

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('notif_read_'));
      final loaded = <String, Set<String>>{};
      for (final k in keys) {
        final userId = k.substring('notif_read_'.length);
        final list = prefs.getStringList(k) ?? [];
        if (list.isNotEmpty) {
          loaded[userId] = list.toSet();
        }
      }
      if (loaded.isNotEmpty) {
        state = {
          ...state,
          for (final entry in loaded.entries)
            entry.key: {...(state[entry.key] ?? const {}), ...entry.value},
        };
      }
    } catch (_) {
      // Graceful fallback in tests or environments without shared_preferences
    }
  }

  Future<void> _persistForUser(String userId, Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('notif_read_$userId', ids.toList());
    } catch (_) {
      // Best-effort local persistence
    }
  }

  void markAsRead(String userId, String notificationId) {
    final current = state[userId] ?? const {};
    if (!current.contains(notificationId)) {
      final updated = {...current, notificationId};
      state = {
        ...state,
        userId: updated,
      };
      _persistForUser(userId, updated);
    }
    // Also sync read state to Firestore notifications collection
    try {
      ref.read(notificationRepositoryProvider).markAsRead(notificationId);
    } catch (_) {}
  }

  void markAllAsRead(String userId, Iterable<String> notificationIds) {
    final current = state[userId] ?? const {};
    final updated = {...current, ...notificationIds};
    state = {
      ...state,
      userId: updated,
    };
    _persistForUser(userId, updated);
    // Also sync all read states to Firestore notifications collection
    try {
      ref.read(notificationRepositoryProvider).markAllAsRead(notificationIds);
    } catch (_) {}
  }

  void markGrantNotificationsRead(
    String userId,
    String grantId,
    Iterable<AppNotification> notifications,
  ) {
    final matchingIds = notifications
        .where((n) => n.grant?.id == grantId)
        .map((n) => n.id);
    markAllAsRead(userId, matchingIds);
  }
}

final notificationReadProvider =
    NotifierProvider<NotificationReadNotifier, Map<String, Set<String>>>(
  NotificationReadNotifier.new,
);

/// Streams prescriptions created by the currently logged-in therapist.
final therapistPrescriptionsProvider =
    StreamProvider<List<TherapistPrescription>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref
      .watch(therapistRepositoryProvider)
      .streamPrescriptionsForTherapist(user.uid);
});

/// Streams all chat messages belonging to the current user's clinical grants
/// (both client and therapist grants).
final userGrantMessagesProvider = StreamProvider<List<TherapistMessage>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);

  final isTherapist = ref.watch(isTherapistProvider);
  final clientGrants = ref.watch(clientGrantsProvider).value ?? const [];
  final therapistGrants = ref.watch(therapistGrantsProvider).value ?? const [];

  final allGrantIds = <String>{
    for (final g in clientGrants) g.id,
    if (isTherapist)
      for (final g in therapistGrants) g.id,
  }.toList();

  if (allGrantIds.isEmpty) {
    return Stream.value(const []);
  }
  return ref
      .watch(therapistRepositoryProvider)
      .streamMessagesForGrants(allGrantIds);
});

/// Reactive list of notifications for the currently logged-in user.
final userNotificationsProvider = Provider<List<AppNotification>>((ref) {
  try {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const [];

    final isTherapist = ref.watch(isTherapistProvider);
    final clientGrants = ref.watch(clientGrantsProvider).value ?? const [];
    final therapistGrants =
        ref.watch(therapistGrantsProvider).value ?? const [];
    final messages = ref.watch(userGrantMessagesProvider).value ?? const [];
    final clientPrescriptions =
        ref.watch(clientPrescriptionsProvider).value ?? const [];
    final therapistPrescriptions = isTherapist
        ? (ref.watch(therapistPrescriptionsProvider).value ?? const [])
        : const <TherapistPrescription>[];

    final readMap = ref.watch(notificationReadProvider);
    final readIds = readMap[user.uid] ?? const {};

    final synthesized = NotificationService.buildNotifications(
      currentUserId: user.uid,
      isTherapist: isTherapist,
      clientGrants: clientGrants,
      therapistGrants: therapistGrants,
      messages: messages,
      clientPrescriptions: clientPrescriptions,
      therapistPrescriptions: therapistPrescriptions,
      readIds: readIds,
    );

    // Watch real-time notifications stored in Firestore `notifications` collection
    final firestoreNotifs =
        ref.watch(firestoreNotificationsProvider).value ?? const [];

    // Merge Firestore notifications and synthesized notifications seamlessly
    final mergedById = <String, AppNotification>{};
    for (final n in synthesized) {
      mergedById[n.id] = n;
    }
    for (final fn in firestoreNotifs) {
      final effectiveIsRead = fn.isRead || readIds.contains(fn.id);
      final grant = clientGrants.where((g) => g.id == fn.grantId).firstOrNull ??
          therapistGrants.where((g) => g.id == fn.grantId).firstOrNull ??
          fn.grant;
      mergedById[fn.id] = fn.copyWith(
        isRead: effectiveIsRead,
        grant: grant,
      );
    }

    final result = mergedById.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  } catch (_) {
    return const [];
  }
});

/// Reactive count of unread notifications for the currently signed-in user.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(userNotificationsProvider);
  return list.where((n) => !n.isRead).length;
});

class NotificationService {
  const NotificationService._();

  /// Pure builder that synthesizes sorted [AppNotification] items for a user
  /// from their grants, chat messages, and prescriptions.
  static List<AppNotification> buildNotifications({
    required String currentUserId,
    required bool isTherapist,
    required List<TherapistAccessGrant> clientGrants,
    required List<TherapistAccessGrant> therapistGrants,
    required List<TherapistMessage> messages,
    required List<TherapistPrescription> clientPrescriptions,
    required List<TherapistPrescription> therapistPrescriptions,
    required Set<String> readIds,
  }) {
    final items = <AppNotification>[];

    final grantById = <String, TherapistAccessGrant>{
      for (final g in clientGrants) g.id: g,
      for (final g in therapistGrants) g.id: g,
    };

    // 1. Incoming Chat Messages (Client <-> Therapist)
    for (final m in messages) {
      if (m.senderId == currentUserId) continue;

      final grant = grantById[m.grantId];
      final fromTherapist = m.senderRole == 'therapist';

      // Ensure clients see messages from therapists and therapists see messages from clients
      if (!isTherapist && !fromTherapist) continue;

      final id = 'notif_msg_${m.id}';
      final senderLabel = fromTherapist
          ? (m.senderName.isNotEmpty
              ? m.senderName
              : (grant?.therapistEmail ?? 'Your Therapist'))
          : (grant?.clientEmail.isNotEmpty == true
              ? grant!.clientEmail
              : m.senderName);

      items.add(
        AppNotification(
          id: id,
          type: AppNotificationType.chatMessage,
          title: fromTherapist
              ? 'Message from $senderLabel'
              : 'New Patient Message • $senderLabel',
          body: m.text,
          senderName: senderLabel,
          timestamp: m.sentAt,
          grant: grant,
          isRead: readIds.contains(id),
        ),
      );
    }

    // 2. Client-side Prescriptions & Accepted Grants
    for (final rx in clientPrescriptions) {
      if (rx.status == PrescriptionStatus.recommended) {
        final id = 'notif_rx_${rx.id}';
        final matchingGrant = clientGrants
            .where(
              (g) =>
                  g.therapistId == rx.therapistId ||
                  g.status == GrantStatus.active,
            )
            .firstOrNull;

        items.add(
          AppNotification(
            id: id,
            type: AppNotificationType.newPrescription,
            title: 'New Prescribed Practice from ${rx.therapistName}',
            body: rx.instructions != null && rx.instructions!.trim().isNotEmpty
                ? '${rx.resourceTitle} — "${rx.instructions!.trim()}"'
                : 'Recommended practice: ${rx.resourceTitle}',
            senderName: rx.therapistName,
            timestamp: rx.prescribedAt,
            grant: matchingGrant,
            isRead: readIds.contains(id),
          ),
        );
      }
    }

    for (final g in clientGrants) {
      if (g.status == GrantStatus.active) {
        final id = 'notif_grant_active_${g.id}';
        items.add(
          AppNotification(
            id: id,
            type: AppNotificationType.grantAccepted,
            title: 'Therapist Connected',
            body:
                '${g.therapistEmail} accepted your invitation. You can now chat directly.',
            senderName: g.therapistEmail,
            timestamp: g.grantedAt,
            grant: g,
            isRead: readIds.contains(id),
          ),
        );
      }
    }

    // 3. Therapist-side Pending Invitations & Completed Prescriptions
    if (isTherapist) {
      for (final g in therapistGrants) {
        if (g.status == GrantStatus.pending) {
          final id = 'notif_grant_pending_${g.id}';
          items.add(
            AppNotification(
              id: id,
              type: AppNotificationType.grantInvitation,
              title: 'New Patient Invitation',
              body:
                  '${g.clientEmail} invited you to review their telemetry and chat.',
              senderName: g.clientEmail,
              timestamp: g.grantedAt,
              grant: g,
              isRead: readIds.contains(id),
            ),
          );
        }
      }

      for (final rx in therapistPrescriptions) {
        if (rx.status == PrescriptionStatus.completed) {
          final id = 'notif_rx_done_${rx.id}';
          final matchingGrant = therapistGrants
              .where((g) => g.clientId == rx.clientId)
              .firstOrNull;
          final calmStr = rx.patientCalmScore != null
              ? ' • Calm: ${rx.patientCalmScore!.toStringAsFixed(0)}%'
              : '';

          items.add(
            AppNotification(
              id: id,
              type: AppNotificationType.prescriptionCompleted,
              title: 'Practice Completed by ${rx.clientEmail}',
              body: 'Completed "${rx.resourceTitle}"$calmStr',
              senderName: rx.clientEmail,
              timestamp: rx.completedAt ?? rx.prescribedAt,
              grant: matchingGrant,
              isRead: readIds.contains(id),
            ),
          );
        }
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  /// Navigates to the appropriate screen when a user taps a notification.
  static void openNotificationTarget(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref
          .read(notificationReadProvider.notifier)
          .markAsRead(user.uid, notification.id);
    }

    final isTherapist = ref.read(isTherapistProvider);
    final grant = notification.grant;

    if (grant != null) {
      if (user != null) {
        final all = ref.read(userNotificationsProvider);
        ref
            .read(notificationReadProvider.notifier)
            .markGrantNotificationsRead(user.uid, grant.id, all);
      }

      if (isTherapist && grant.clientId != user?.uid) {
        if (grant.status == GrantStatus.pending) {
          // Switch to Clinical Workspace tab so therapist can accept the invite
          ref.read(mainNavIndexProvider.notifier).setIndex(0);
          return;
        }
        final tabIndex =
            notification.type == AppNotificationType.prescriptionCompleted
                ? 1
                : 2;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(
              grant: grant,
              initialTabIndex: tabIndex,
            ),
          ),
        );
        return;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientTherapistChatScreen(grant: grant),
          ),
        );
        return;
      }
    }

    // Fallback: navigate to Profile tab (client) or Clinical tab (therapist)
    ref.read(mainNavIndexProvider.notifier).setIndex(isTherapist ? 0 : 4);
  }

  static String formatRelativeTime(DateTime timestamp, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

/// Glowing notification bell icon button with an unread count badge.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () {
        final user = ref.read(authStateProvider).value;
        if (user != null) {
          final notifs = ref.read(userNotificationsProvider);
          final unreadIds = notifs.where((n) => !n.isRead).map((n) => n.id);
          if (unreadIds.isNotEmpty) {
            ref
                .read(notificationReadProvider.notifier)
                .markAllAsRead(user.uid, unreadIds);
          }
        }
        NotificationCenterSheet.show(context);
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            unreadCount > 0
                ? Icons.notifications_active
                : Icons.notifications_none_rounded,
            color: unreadCount > 0
                ? MuseColors.cyanGlow
                : MuseColors.textSecondary,
            size: 22,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: MuseColors.roseGlow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: MuseColors.spaceBackground,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet displaying all notifications for the logged-in user.
class NotificationCenterSheet extends ConsumerStatefulWidget {
  const NotificationCenterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1422),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.72,
        child: NotificationCenterSheet(),
      ),
    );
  }

  @override
  ConsumerState<NotificationCenterSheet> createState() =>
      _NotificationCenterSheetState();
}

class _NotificationCenterSheetState
    extends ConsumerState<NotificationCenterSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markVisibleRead();
    });
  }

  void _markVisibleRead() {
    if (!mounted) return;
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final notifs = ref.read(userNotificationsProvider);
      final unreadIds = notifs.where((n) => !n.isRead).map((n) => n.id);
      if (unreadIds.isNotEmpty) {
        ref
            .read(notificationReadProvider.notifier)
            .markAllAsRead(user.uid, unreadIds);
      }
    }
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.chatMessage:
        return Icons.chat_bubble_rounded;
      case AppNotificationType.newPrescription:
        return Icons.medication_liquid_rounded;
      case AppNotificationType.prescriptionCompleted:
        return Icons.task_alt_rounded;
      case AppNotificationType.grantInvitation:
        return Icons.person_add_alt_1_rounded;
      case AppNotificationType.grantAccepted:
        return Icons.verified_user_rounded;
      case AppNotificationType.systemAlert:
        return Icons.notifications_active_rounded;
    }
  }

  Color _colorFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.chatMessage:
        return MuseColors.cyanGlow;
      case AppNotificationType.newPrescription:
        return MuseColors.mysticPurple;
      case AppNotificationType.prescriptionCompleted:
        return MuseColors.breathMint;
      case AppNotificationType.grantInvitation:
        return MuseColors.amberGlow;
      case AppNotificationType.grantAccepted:
        return MuseColors.breathMint;
      case AppNotificationType.systemAlert:
        return MuseColors.cyanGlow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(userNotificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final user = ref.watch(authStateProvider).value;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MuseColors.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MuseSpacing.lg,
              MuseSpacing.md,
              MuseSpacing.md,
              MuseSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: MuseColors.cyanGlow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CARE & CHAT NOTIFICATIONS',
                    style: TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                if (unreadCount > 0 && user != null)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(notificationReadProvider.notifier).markAllAsRead(
                            user.uid,
                            notifications.map((n) => n.id),
                          );
                    },
                    icon: const Icon(
                      Icons.done_all_rounded,
                      size: 16,
                      color: MuseColors.cyanGlow,
                    ),
                    label: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: MuseColors.cyanGlow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0x264DF0FF), height: 1),
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MuseSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 44,
                            color: MuseColors.textTertiary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All caught up',
                            style: TextStyle(
                              color: MuseColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'New messages and practice updates between you and your therapist or patients will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: MuseColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(MuseSpacing.md),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final accent = _colorFor(n.type);

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.pop(context);
                          NotificationService.openNotificationTarget(
                            context,
                            ref,
                            n,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? const Color(0xFF12192B)
                                : const Color(0xFF17223B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: n.isRead
                                  ? const Color(0x224DF0FF)
                                  : accent.withValues(alpha: 0.65),
                              width: n.isRead ? 0.8 : 1.2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconFor(n.type),
                                  color: accent,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (!n.isRead) ...[
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: accent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: TextStyle(
                                              color: MuseColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: n.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          NotificationService
                                              .formatRelativeTime(n.timestamp),
                                          style: const TextStyle(
                                            color: MuseColors.textTertiary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body,
                                      style: const TextStyle(
                                        color: MuseColors.textSecondary,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: MuseColors.textTertiary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
