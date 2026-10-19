import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../models/therapist_access_grant.dart';
import '../../../models/therapist_message.dart';
import '../../resources/models/resource_item.dart';
import '../../resources/screens/resource_practice_screen.dart';

class ClientTherapistChatScreen extends ConsumerStatefulWidget {
  final TherapistAccessGrant grant;

  const ClientTherapistChatScreen({
    super.key,
    required this.grant,
  });

  @override
  ConsumerState<ClientTherapistChatScreen> createState() => _ClientTherapistChatScreenState();
}

class _ClientTherapistChatScreenState extends ConsumerState<ClientTherapistChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final user = ref.read(authStateProvider).value;

    final msg = TherapistMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: user?.uid ?? 'client',
      senderName: user?.displayName ?? (user?.email?.split('@').first ?? 'Patient'),
      senderRole: 'client',
      recipientId: widget.grant.therapistId.isNotEmpty ? widget.grant.therapistId : widget.grant.therapistEmail,
      grantId: widget.grant.id,
      text: text,
      sentAt: DateTime.now(),
    );

    try {
      await ref.read(therapistRepositoryProvider).sendMessage(msg);
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _openPrescribedResource(String resourceId, String resourceTitle, String practitionerName) {
    final catalogMatch = ResourceItem.catalog.firstWhere(
      (r) => r.id == resourceId || r.title == resourceTitle,
      orElse: () => ResourceItem.catalog.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResourcePracticeScreen(
          resource: catalogMatch,
          isPrescription: true,
          therapistName: practitionerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = ref.watch(therapistRepositoryProvider).streamMessages(widget.grant.id);

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        backgroundColor: MuseColors.surfaceElevated,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.grant.therapistEmail,
              style: const TextStyle(
                color: MuseColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Row(
              children: [
                Icon(Icons.verified, size: 12, color: MuseColors.breathMint),
                SizedBox(width: 4),
                Text(
                  'Licensed Practitioner • Active Clinical Channel',
                  style: TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Clinical Session Status Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: 8),
              decoration: BoxDecoration(
                color: MuseColors.cardSurface,
                border: const Border(bottom: BorderSide(color: MuseColors.cardBorder, width: 0.8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: MuseColors.cyanGlow, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EEG wave telemetry and session outcomes from prescribed practices are securely shared with your practitioner.',
                      style: const TextStyle(color: MuseColors.textTertiary, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            // Messages Stream List
            Expanded(
              child: StreamBuilder<List<TherapistMessage>>(
                stream: messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: MuseColors.cyanGlow));
                  }

                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(MuseSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: MuseColors.cyanGlow.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline, size: 40, color: MuseColors.cyanGlow),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Practitioner Care Channel',
                              style: TextStyle(
                                color: MuseColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Send a message to your therapist at ${widget.grant.therapistEmail}. You will also see resources and practice recommendations sent directly to you here.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: MuseColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(MuseSpacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final isClient = m.senderRole == 'client';

                      return Align(
                        alignment: isClient ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: MuseSpacing.sm),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isClient
                                ? MuseColors.cyanGlow.withValues(alpha: 0.18)
                                : MuseColors.cardSurface,
                            border: Border.all(
                              color: isClient
                                  ? MuseColors.cyanGlow.withValues(alpha: 0.5)
                                  : MuseColors.cardBorder,
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: isClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Sender Header
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isClient) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: MuseColors.breathMint.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'PRACTITIONER',
                                        style: TextStyle(
                                          color: MuseColors.breathMint,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    isClient ? 'You' : m.senderName,
                                    style: TextStyle(
                                      color: isClient ? MuseColors.cyanGlow : MuseColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: MuseColors.textTertiary, fontSize: 9),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Message Text
                              Text(
                                m.text,
                                style: const TextStyle(
                                  color: MuseColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),

                              // Attached Resource Action Card
                              if (m.resourceAttachmentTitle != null) ...[
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () => _openPrescribedResource(
                                    m.resourceAttachmentId ?? '',
                                    m.resourceAttachmentTitle!,
                                    m.senderName,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: MuseColors.spaceBackground,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: MuseColors.cyanGlow.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: MuseColors.cyanGlow.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.play_arrow, color: MuseColors.cyanGlow, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.resourceAttachmentTitle!,
                                                style: const TextStyle(
                                                  color: MuseColors.textPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Prescribed Practice • Tap to Start with Muse 2',
                                                style: TextStyle(
                                                  color: MuseColors.cyanGlow,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: MuseColors.cyanGlow, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Message Composer Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: MuseSpacing.sm),
              decoration: const BoxDecoration(
                color: MuseColors.spaceBackground,
                border: Border(top: BorderSide(color: MuseColors.cardBorder, width: 0.8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.grant.therapistEmail}...',
                        hintStyle: const TextStyle(color: MuseColors.textTertiary, fontSize: 13),
                        filled: true,
                        fillColor: MuseColors.cardSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: MuseColors.cyanGlow),
                          )
                        : const Icon(Icons.send, color: MuseColors.cyanGlow),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
