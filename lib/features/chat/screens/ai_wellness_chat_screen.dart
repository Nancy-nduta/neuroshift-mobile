import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/bioluminescent_neural_orb.dart';
import '../../../models/signal_reading.dart';
import '../../connect/screens/headband_connect_screen.dart';
import '../../resources/models/resource_item.dart';
import '../../resources/screens/resource_practice_screen.dart';
import '../models/ai_chat_message.dart';
import '../services/ai_chat_repository.dart';
import '../services/ai_wellness_service.dart';
import '../widgets/one_tap_sos_trigger_card.dart';

/// Tracks the currently signed-in user's UID for chat session isolation.
/// Wrapped in a try/catch so widget tests that do not initialize Firebase
/// continue to work seamlessly while production builds isolate chat state per UID.
final chatSessionUserIdProvider = Provider<String?>((ref) {
  try {
    return ref.watch(authStateProvider).value?.uid;
  } catch (_) {
    return null;
  }
});

class AiWellnessChatScreen extends ConsumerStatefulWidget {
  const AiWellnessChatScreen({super.key});

  @override
  ConsumerState<AiWellnessChatScreen> createState() =>
      _AiWellnessChatScreenState();
}

class _AiWellnessChatScreenState extends ConsumerState<AiWellnessChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoadingHistory = false;

  final List<String> _quickTopics = [
    '🧠 Analyze My Brainwaves',
    '⚡ Calm Anxiety Now',
    '💓 What is HRV & Vagal Tone?',
    '🫁 Box Breathing Guide',
    '💤 Deep Sleep Protocol',
    '🎯 Focus & ADHD Reset',
    '🌱 Coping with Low Energy',
  ];

  @override
  void initState() {
    super.initState();
    _resetConversationToWelcome();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedChatHistory();
    });
  }

  Future<void> _loadSavedChatHistory() async {
    final userId = ref.read(chatSessionUserIdProvider);
    if (userId == null) return;
    setState(() => _isLoadingHistory = true);
    try {
      final history = await ref.read(aiChatRepositoryProvider).getRecentChat(userId);
      if (history.isNotEmpty && mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(history);
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading saved Nova chat history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _resetConversationToWelcome() {
    _messages
      ..clear()
      ..add(
        AiChatMessage(
          id: 'welcome',
          text:
              'Hello, I am **Nova**, your NeuroShift AI Mental Health & Mindfulness Guide. 🧠✨\n\n'
              'I am here to listen, answer questions about your EEG brainwaves and HRV, or walk you through a calming exercise whenever you want one.\n\n'
              'How are you feeling right now? Tap a topic below or say hello.',
          isUser: false,
          timestamp: DateTime.now(),
          responseMode: NovaResponseMode.deterministic,
          suggestedChips: const [
            '🧠 Analyze My Brainwaves',
            'Calm Anxiety Now',
            'Teach me Box Breathing',
            'Help Me Sleep',
          ],
        ),
      );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmClearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1523),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MuseSpacing.radiusLg),
          side: const BorderSide(color: Color(0x334DF0FF), width: 1.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: MuseColors.heartRose, size: 22),
            SizedBox(width: 8),
            Text(
              'Clear Conversation?',
              style: TextStyle(
                color: MuseColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete your stored conversation history with Nova from your private cloud vault. This action cannot be undone.',
          style: TextStyle(
            color: MuseColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: MuseColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: MuseColors.heartRose,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = ref.read(chatSessionUserIdProvider);
      if (userId != null) {
        await ref.read(aiChatRepositoryProvider).clearHistory(userId);
      }
      if (mounted) {
        setState(_resetConversationToWelcome);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat history cleared from your private vault.'),
            backgroundColor: MuseColors.surfaceElevated,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _textController.clear();

    final userMessage = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      responseMode: NovaResponseMode.user,
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    final userId = ref.read(chatSessionUserIdProvider);
    if (userId != null) {
      ref.read(aiChatRepositoryProvider).saveMessage(
            userId: userId,
            message: userMessage,
          );
    }

    final signal = ref.read(signalReadingProvider).value;
    final status = ref.read(headbandStatusProvider).value;
    final isConnected = status?.isConnected ?? false;
    try {
      final aiMessage = await AiWellnessService.getResponse(
        trimmed,
        List<AiChatMessage>.unmodifiable(_messages),
        currentTelemetry: signal,
        isConnected: isConnected,
        countryCode: 'KE',
      );
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });
      _scrollToBottom();

      if (userId != null) {
        ref.read(aiChatRepositoryProvider).saveMessage(
              userId: userId,
              message: aiMessage,
            );
      }
    } catch (_) {
      if (!mounted) return;
      final fallbackMessage = AiChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'I ran into an unexpected error while preparing a reply. Please try sending your message again.',
        isUser: false,
        timestamp: DateTime.now(),
        responseMode: NovaResponseMode.offlineFallback,
        fallbackReason: 'Unexpected local error while handling message.',
      );
      setState(() {
        _isTyping = false;
        _messages.add(fallbackMessage);
      });
      _scrollToBottom();

      if (userId != null) {
        ref.read(aiChatRepositoryProvider).saveMessage(
              userId: userId,
              message: fallbackMessage,
            );
      }
    }
  }

  void _showSafetyInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1523),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MuseSpacing.radiusLg),
          side: const BorderSide(color: Color(0x334DF0FF), width: 1.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: MuseColors.cyanGlow, size: 22),
            SizedBox(width: 8),
            Text(
              'Nova Clinical Safety',
              style: TextStyle(
                color: MuseColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Nova is an evidence-informed AI wellness and biofeedback guide designed to support everyday stress reflection, grounding exercises, and EEG/HRV literacy.\n\n'
          '⚠️ Nova is not a licensed therapist, physician, or emergency service, and cannot diagnose conditions or give medication advice.\n\n'
          'If you are in acute distress or need support, contact verified toll-free helplines immediately: Kenya Red Cross (1199 - Free), LVCT Health Counselling (1190 - Free), Childline Kenya (116 - Free), or National Emergency Services (112 or 999 - Free, no credit needed).',
          style: TextStyle(
            color: MuseColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.crisis_alert, color: Color(0xFFEF4444), size: 16),
            onPressed: () {
              Navigator.pop(context);
              _showEmergencySosModal(context);
            },
            label: const Text(
              'Open SOS Hotlines',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'I Understand',
              style: TextStyle(
                color: MuseColors.cyanGlow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencySosModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D121F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0x33EF4444), width: 1.2),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              OneTapSosTriggerCard(
                countryCode: 'KE',
                isModal: true,
                onDismiss: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Isolate conversation history per user account: if the signed-in UID
    // changes (sign-out or account switch), clear the in-memory messages.
    ref.listen<String?>(chatSessionUserIdProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          _isTyping = false;
          _resetConversationToWelcome();
        });
      }
    });

    final status = ref.watch(headbandStatusProvider).value;
    final signal = ref.watch(signalReadingProvider).value;
    final isConnected = status?.isConnected ?? false;

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        titleSpacing: Navigator.canPop(context) ? 0 : 14,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: MuseColors.textPrimary,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BioluminescentNeuralOrb(
              mindState: MindState.calm,
              size: 26,
              showTelemetryRings: false,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'NOVA AI',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: MuseColors.cyanGlow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BIO-RAG',
                          style: TextStyle(
                            color: MuseColors.cyanGlow,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MuseColors.calmGlow,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Wellness Guide',
                          style: TextStyle(
                            color: MuseColors.textSecondary,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isLoadingHistory)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(MuseColors.cyanGlow),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: MuseColors.textSecondary,
                size: 19,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _confirmClearChatHistory,
              tooltip: 'Clear Chat History',
            ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(minWidth: 38, minHeight: 32),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x33EF4444),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x99EF4444), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.crisis_alert, color: Color(0xFFFF4D4D), size: 12),
                  SizedBox(width: 2.5),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            onPressed: () => _showEmergencySosModal(context),
            tooltip: 'Toll-Free Crisis SOS Helplines',
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: MuseColors.textSecondary,
              size: 18,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _showSafetyInfoDialog,
            tooltip: 'Safety Disclaimer',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0x334DF0FF),
            height: 0.8,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildBiometricTelemetryHUD(isConnected, signal),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0xFF090D16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md),
                itemCount: _quickTopics.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final topic = _quickTopics[index];
                  return ActionChip(
                    label: Text(
                      topic,
                      style: const TextStyle(
                        color: MuseColors.cyanGlow,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: const Color(0xFF131B2E),
                    side: const BorderSide(
                      color: Color(0x3300E5FF),
                      width: 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () => _sendMessage(topic),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(MuseSpacing.md),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageItem(msg);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MuseSpacing.md,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0x3300E5FF),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: MuseColors.cyanGlow,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Nova is thinking...',
                            style: TextStyle(
                              color: MuseColors.cyanGlow,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MuseSpacing.md,
                vertical: MuseSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E1A),
                border: const Border(
                  top: BorderSide(color: Color(0x334DF0FF), width: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: MuseColors.cyanGlow.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF263554),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 13,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText:
                              'Say hi, share how you feel, or ask about EEG & HRV...',
                          hintStyle: TextStyle(
                            color: MuseColors.textSecondary,
                            fontSize: 12,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00B4D8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricTelemetryHUD(bool isConnected, SignalReading? signal) {
    if (!isConnected || signal == null) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HeadbandConnectScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: MuseSpacing.md,
            vertical: 7,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1523),
            border: Border(
              bottom: BorderSide(color: Color(0x334DF0FF), width: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFB703),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Muse 2 Headband Offline • Tap to connect for live Bio-RAG insights',
                  style: TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: MuseColors.cyanGlow,
              ),
            ],
          ),
        ),
      );
    }

    Color stateColor = MuseColors.cyanGlow;
    if (signal.mindState == MindState.active) {
      stateColor = const Color(0xFFEC4899);
    } else if (signal.mindState == MindState.neutral) {
      stateColor = const Color(0xFFFFB703);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: MuseSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        border: Border(
          bottom: BorderSide(
            color: stateColor.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: stateColor, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stateColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    signal.mindState.name.toUpperCase(),
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'α: ${signal.alpha.toStringAsFixed(1)} µV  β: ${signal.beta.toStringAsFixed(1)} µV',
              style: const TextStyle(
                color: MuseColors.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 10),
            if (signal.heartRateBpm != null && signal.heartRateBpm! > 0) ...[
              const Icon(Icons.favorite, size: 12, color: Color(0xFFEC4899)),
              const SizedBox(width: 3),
              Text(
                '${signal.heartRateBpm} BPM',
                style: const TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
            ],
            InkWell(
              onTap: () =>
                  _sendMessage('Analyze my current brainwaves and mind state'),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x3300E5FF), width: 0.6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Analyze',
                      style: TextStyle(
                        color: MuseColors.cyanGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.auto_awesome,
                      size: 10,
                      color: MuseColors.cyanGlow,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _modeBadgeLabel(NovaResponseMode mode) {
    switch (mode) {
      case NovaResponseMode.gemini:
        return 'AI GENERATED';
      case NovaResponseMode.offlineKnowledge:
        return 'EVIDENCE REFERENCE';
      case NovaResponseMode.offlineFallback:
        return 'OFFLINE MODE';
      case NovaResponseMode.safetyProtocol:
        return 'SAFETY SUPPORT';
      case NovaResponseMode.deterministic:
      case NovaResponseMode.user:
        return '';
    }
  }

  Widget _buildMessageItem(AiChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: MuseSpacing.md, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF16233B),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(
              color: MuseColors.cyanGlow.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: MuseColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    final badgeLabel = _modeBadgeLabel(msg.responseMode);
    final isSafety = msg.responseMode == NovaResponseMode.safetyProtocol;

    return Container(
      margin: const EdgeInsets.only(bottom: MuseSpacing.md, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSafety
                      ? const Color(0xFFFFB703)
                      : MuseColors.cyanGlow,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'NOVA AI',
                style: TextStyle(
                  color: MuseColors.cyanGlow,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              if (badgeLabel.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0x334DF0FF),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: MuseColors.textSecondary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1523),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isSafety
                    ? const Color(0x66FFB703)
                    : const Color(0x334DF0FF),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: MuseColors.cyanGlow.withValues(alpha: 0.04),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: const TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (msg.fallbackReason != null &&
                    msg.fallbackReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ℹ️ ${msg.fallbackReason!}',
                    style: const TextStyle(
                      color: MuseColors.textSecondary,
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (msg.sourceReferences.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildSourcesFooter(msg.sourceReferences),
                ],
                if (msg.recommendedResource != null) ...[
                  const SizedBox(height: MuseSpacing.md),
                  _buildResourceCard(msg.recommendedResource!),
                ],
                if (isSafety &&
                    (msg.safetyStatus == SafetyStatus.imminent ||
                        msg.safetyStatus == SafetyStatus.high)) ...[
                  const SizedBox(height: 12),
                  const OneTapSosTriggerCard(
                    countryCode: 'KE',
                  ),
                ],
              ],
            ),
          ),
          if (msg.suggestedChips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: msg.suggestedChips.map((chipText) {
                return ActionChip(
                  label: Text(
                    chipText,
                    style: const TextStyle(
                      color: MuseColors.cyanGlow,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: const Color(0xFF131B2E),
                  side: const BorderSide(
                    color: Color(0x3300E5FF),
                    width: 0.8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onPressed: () => _sendMessage(chipText),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourcesFooter(List<KnowledgeSource> sources) {
    final labels = sources.take(2).map((s) {
      final year = s.published != null ? ' (${s.published})' : '';
      return '${s.publisher}$year — ${s.title}';
    }).join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x224DF0FF), width: 0.6),
      ),
      child: Text(
        'Sources: $labels',
        style: const TextStyle(
          color: MuseColors.textSecondary,
          fontSize: 10,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildResourceCard(ResourceItem resource) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4D00E5FF), width: 1.0),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              resource.thumbnailUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 54,
                height: 54,
                color: const Color(0xFF1E293B),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: MuseColors.cyanGlow,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${resource.category.label} • ${resource.durationLabel}',
                  style: const TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResourcePracticeScreen(resource: resource),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Start ➔',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
