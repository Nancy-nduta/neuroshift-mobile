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
import '../services/ai_wellness_service.dart';

class AiWellnessChatScreen extends ConsumerStatefulWidget {
  const AiWellnessChatScreen({super.key});

  @override
  ConsumerState<AiWellnessChatScreen> createState() => _AiWellnessChatScreenState();
}

class _AiWellnessChatScreenState extends ConsumerState<AiWellnessChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isTyping = false;

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
    // Welcome message from Nova AI
    _messages.add(
      AiChatMessage(
        id: 'welcome',
        text: 'Hello, I am **Nova**, your NeuroShift AI Mental Health & Mindfulness Guide. 🧠✨\n\n'
            'I am here 24/7 to support you with immediate calming tools, somatic nervous system resets, explaining your EEG brainwaves and HRV, or navigating tough emotional moments.\n\n'
            'How are you feeling right now? Tap a topic below or ask me anything.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedChips: [
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

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _textController.clear();

    final userMessage = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    final signal = ref.read(signalReadingProvider).value;
    final status = ref.read(headbandStatusProvider).value;
    final isConnected = status?.isConnected ?? false;

    try {
      final aiMessage = await AiWellnessService.getResponse(
        trimmed,
        _messages,
        currentTelemetry: signal,
        isConnected: isConnected,
      );
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          AiChatMessage(
            id: 'err_${DateTime.now().millisecondsSinceEpoch}',
            text: 'I am taking a moment to stabilize my neural connection. Please ask again or select one of the core topics below.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
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
        title: Row(
          children: const [
            Icon(Icons.health_and_safety, color: MuseColors.cyanGlow, size: 22),
            SizedBox(width: 8),
            Text(
              'Nova Clinical Safety',
              style: TextStyle(color: MuseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Nova is an automated AI Mental Health & Neuro-Wellness Guide designed to provide evidence-based psychoeducation, breathing protocols, and biometric literacy.\n\n'
          '⚠️ Nova is not a licensed physician or psychiatric crisis service. If you are experiencing acute distress, please contact emergency medical services or call/text the 988 Suicide & Crisis Lifeline.',
          style: TextStyle(color: MuseColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand', style: TextStyle(color: MuseColors.cyanGlow, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(headbandStatusProvider).value;
    final signal = ref.watch(signalReadingProvider).value;
    final isConnected = status?.isConnected ?? false;

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: MuseColors.textPrimary, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            // Miniature glowing orb avatar
            const BioluminescentNeuralOrb(
              mindState: MindState.calm,
              size: 32,
              showTelemetryRings: false,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'NOVA AI',
                      style: TextStyle(
                        color: MuseColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: MuseColors.cyanGlow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BIO-RAG',
                        style: TextStyle(
                          color: MuseColors.cyanGlow,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: MuseColors.calmGlow,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online • Cognitive Bio-Guide',
                      style: TextStyle(color: MuseColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: MuseColors.textSecondary, size: 20),
            onPressed: _showSafetyInfoDialog,
            tooltip: 'Safety Disclaimer',
          ),
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
            // Real-Time Cybernetic Telemetry Strip
            _buildBiometricTelemetryHUD(isConnected, signal),

            // Quick Topic Discovery Chips Ribbon
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
                    side: const BorderSide(color: Color(0x3300E5FF), width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _sendMessage(topic),
                  );
                },
              ),
            ),

            // Chat Messages Feed
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

            // Live Typing Indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x3300E5FF), width: 0.8),
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
                            style: TextStyle(color: MuseColors.cyanGlow, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Message Input Box
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
                        border: Border.all(color: const Color(0xFF263554), width: 1.0),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Ask Nova about anxiety, sleep, brainwaves...',
                          hintStyle: TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
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
          padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: 7),
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
              const Icon(Icons.arrow_forward_ios, size: 10, color: MuseColors.cyanGlow),
            ],
          ),
        ),
      );
    }

    // Connected state HUD
    Color stateColor = MuseColors.cyanGlow;
    if (signal.mindState == MindState.active) {
      stateColor = const Color(0xFFEC4899);
    } else if (signal.mindState == MindState.neutral) {
      stateColor = const Color(0xFFFFB703);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        border: Border(
          bottom: BorderSide(color: stateColor.withValues(alpha: 0.3), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // MindState pill
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

          // Microvolt readouts
          Text(
            'α: ${signal.alpha.toStringAsFixed(1)} µV  β: ${signal.beta.toStringAsFixed(1)} µV',
            style: const TextStyle(
              color: MuseColors.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),

          const Spacer(),

          // Heart Rate badge if present
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
            const SizedBox(width: 8),
          ],

          // Quick analyze button
          InkWell(
            onTap: () => _sendMessage('Analyze my current brainwaves and mind state'),
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
                    style: TextStyle(color: MuseColors.cyanGlow, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.auto_awesome, size: 10, color: MuseColors.cyanGlow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

    // Nova AI Response Bubble
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MuseColors.cyanGlow,
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
                color: const Color(0x334DF0FF),
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

                // In-Chat Recommended Resource Action Card
                if (msg.recommendedResource != null) ...[
                  const SizedBox(height: MuseSpacing.md),
                  _buildResourceCard(msg.recommendedResource!),
                ],
              ],
            ),
          ),

          // Follow-up Suggestion Chips
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
                  side: const BorderSide(color: Color(0x3300E5FF), width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onPressed: () => _sendMessage(chipText),
                );
              }).toList(),
            ),
          ],
        ],
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
                child: const Icon(Icons.play_circle_outline, color: MuseColors.cyanGlow),
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
                  style: const TextStyle(color: MuseColors.textSecondary, fontSize: 10),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Start ➔', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
