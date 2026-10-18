import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/experience_mode.dart';
import '../../../models/meditation_session.dart';
import '../../../models/therapist_access_grant.dart';
import '../../../models/therapist_message.dart';
import '../../../models/therapist_prescription.dart';
import '../../resources/models/resource_item.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final TherapistAccessGrant grant;

  const PatientDetailScreen({super.key, required this.grant});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  String _timeframe = 'All'; // 'Day', 'Week', 'Month', 'All'
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  List<MeditationSession> _filterSessionsByTimeframe(List<MeditationSession> sessions) {
    final now = DateTime.now();
    switch (_timeframe) {
      case 'Day':
        final cutoff = now.subtract(const Duration(hours: 24));
        return sessions.where((s) => s.startedAt.isAfter(cutoff)).toList();
      case 'Week':
        final cutoff = now.subtract(const Duration(days: 7));
        return sessions.where((s) => s.startedAt.isAfter(cutoff)).toList();
      case 'Month':
        final cutoff = now.subtract(const Duration(days: 30));
        return sessions.where((s) => s.startedAt.isAfter(cutoff)).toList();
      default:
        return sessions;
    }
  }

  Future<void> _sendMessage({ResourceItem? attachedResource}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && attachedResource == null) return;

    setState(() => _isSending = true);
    final user = ref.read(authStateProvider).value;
    final therapist = ref.read(currentTherapistProfileProvider).value;

    final msg = TherapistMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: user?.uid ?? 'therapist',
      senderName: therapist?.displayName ?? 'Therapist',
      senderRole: 'therapist',
      recipientId: widget.grant.clientId,
      grantId: widget.grant.id,
      text: text.isNotEmpty ? text : 'Recommended: ${attachedResource?.title}',
      resourceAttachmentId: attachedResource?.id,
      resourceAttachmentTitle: attachedResource?.title,
      sentAt: DateTime.now(),
    );

    try {
      await ref.read(therapistRepositoryProvider).sendMessage(msg);
      _messageController.clear();
      // Scroll to bottom
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

  void _showPrescribeDialog() {
    ResourceItem selectedItem = ResourceItem.catalog.first;
    final instructionsController = TextEditingController(
      text: 'Practice with your Muse 2 headband connected. Aim for gentle, steady breathing.',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: MuseColors.cardSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: MuseSpacing.lg,
                right: MuseSpacing.lg,
                top: MuseSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + MuseSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medication_liquid_outlined, color: MuseColors.cyanGlow, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'PRESCRIBE RESOURCE',
                          style: TextStyle(
                            color: MuseColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: MuseColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuseSpacing.sm),
                    Text(
                      'Select a soundscape, meditation, or auditory tool to prescribe to ${widget.grant.clientEmail}. Objective Muse 2 EEG telemetry will record the session impact.',
                      style: const TextStyle(color: MuseColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: MuseSpacing.md),
                    const Text(
                      'RESOURCE SELECTION',
                      style: TextStyle(
                        color: MuseColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: MuseColors.spaceBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: MuseColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ResourceItem>(
                          value: selectedItem,
                          isExpanded: true,
                          dropdownColor: MuseColors.spaceBackground,
                          items: ResourceItem.catalog.map((item) {
                            return DropdownMenuItem<ResourceItem>(
                              value: item,
                              child: Row(
                                children: [
                                  Icon(item.category.icon, size: 16, color: item.category.color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedItem = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.md),
                    const Text(
                      'CLINICAL INSTRUCTIONS / NOTES',
                      style: TextStyle(
                        color: MuseColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: instructionsController,
                      maxLines: 3,
                      style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter clinical guidance or recommended frequency...',
                        hintStyle: const TextStyle(color: MuseColors.textTertiary, fontSize: 13),
                        filled: true,
                        fillColor: MuseColors.spaceBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: MuseColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: MuseColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: MuseColors.cyanGlow),
                        ),
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.lg),
                    MuseButton(
                      label: 'Send Prescription to Patient',
                      variant: MuseButtonVariant.primary,
                      width: double.infinity,
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        final therapist = ref.read(currentTherapistProfileProvider).value;
                        final user = ref.read(authStateProvider).value;

                        final prescription = TherapistPrescription(
                          id: 'presc_${DateTime.now().millisecondsSinceEpoch}',
                          therapistId: user?.uid ?? 'therapist',
                          therapistName: therapist?.displayName ?? 'Licensed Practitioner',
                          clientId: widget.grant.clientId,
                          clientEmail: widget.grant.clientEmail,
                          resourceId: selectedItem.id,
                          resourceTitle: selectedItem.title,
                          resourceCategory: selectedItem.category.label,
                          instructions: instructionsController.text.trim(),
                          prescribedAt: DateTime.now(),
                          status: PrescriptionStatus.recommended,
                        );

                        await ref.read(therapistRepositoryProvider).prescribeResource(prescription);

                        // Also send a chat notification
                        await _sendMessage(attachedResource: selectedItem);

                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              backgroundColor: MuseColors.surfaceElevated,
                              content: Text('Prescribed "${selectedItem.title}" to ${widget.grant.clientEmail}'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.grant.clientEmail,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Patient Clinical Workspace',
              style: TextStyle(fontSize: 11, color: MuseColors.cyanGlow),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MuseColors.cyanGlow,
          labelColor: MuseColors.cyanGlow,
          unselectedLabelColor: MuseColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined, size: 20), text: 'INSIGHTS'),
            Tab(icon: Icon(Icons.medication_outlined, size: 20), text: 'PRESCRIPTIONS'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 20), text: 'COMMUNICATION'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInsightsTab(),
          _buildPrescriptionsTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  // ==================== 1. INSIGHT REPORTS & TELEMETRY ====================
  Widget _buildInsightsTab() {
    final sessionsStream = ref.watch(therapistRepositoryProvider).streamClientSessions(widget.grant.clientId);

    return StreamBuilder<List<MeditationSession>>(
      stream: sessionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: MuseColors.cyanGlow));
        }

        final allSessions = snapshot.data ?? [];
        final filteredSessions = _filterSessionsByTimeframe(allSessions);

        // Compute aggregated metrics
        double avgCalm = 0;
        double avgNeutral = 0;
        double avgActive = 0;
        double avgBpm = 0;
        double avgStillness = 0;
        int totalMinutes = 0;

        if (filteredSessions.isNotEmpty) {
          for (final s in filteredSessions) {
            avgCalm += s.calmPercent;
            avgNeutral += s.neutralPercent;
            avgActive += s.activePercent;
            avgBpm += s.averageBpm;
            avgStillness += s.averageStillness;
            totalMinutes += (s.durationSeconds / 60).round();
          }
          avgCalm /= filteredSessions.length;
          avgNeutral /= filteredSessions.length;
          avgActive /= filteredSessions.length;
          avgBpm /= filteredSessions.length;
          avgStillness /= filteredSessions.length;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(MuseSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe Filter Bar
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text(
                    'TELEMETRY WINDOW',
                    style: TextStyle(
                      color: MuseColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: ['Day', 'Week', 'Month', 'All'].map((t) {
                      final isSelected = _timeframe == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _timeframe = t);
                        },
                        backgroundColor: MuseColors.cardSurface,
                        selectedColor: MuseColors.cyanGlow.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? MuseColors.cyanGlow : MuseColors.textSecondary,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? MuseColors.cyanGlow : MuseColors.cardBorder,
                            width: 0.8,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: MuseSpacing.md),

              if (filteredSessions.isEmpty)
                MuseCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: MuseSpacing.lg),
                      child: Column(
                        children: [
                          const Icon(Icons.show_chart, color: MuseColors.textTertiary, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No sessions recorded in "$_timeframe" window.',
                            style: const TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'When the patient completes meditation practices wearing their Muse 2, objective brainwave analytics will display here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Metric Overview Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Calm Alpha %',
                        value: '${avgCalm.toStringAsFixed(1)}%',
                        color: MuseColors.cyanGlow,
                        icon: Icons.waves,
                      ),
                    ),
                    const SizedBox(width: MuseSpacing.md),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Active Beta %',
                        value: '${avgActive.toStringAsFixed(1)}%',
                        color: MuseColors.roseGlow,
                        icon: Icons.bolt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuseSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Avg Heart Rate',
                        value: avgBpm > 0 ? '${avgBpm.toStringAsFixed(0)} BPM' : '--',
                        color: MuseColors.heartRed,
                        icon: Icons.favorite,
                      ),
                    ),
                    const SizedBox(width: MuseSpacing.md),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Body Stillness',
                        value: '${avgStillness.toStringAsFixed(0)}%',
                        color: MuseColors.bodyAmber,
                        icon: Icons.accessibility_new,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuseSpacing.lg),

                // Clinical Wave Distribution Bar
                MuseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AGGREGATE EEG BAND POWER DISTRIBUTION',
                        style: TextStyle(
                          color: MuseColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: MuseSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 16,
                          child: Row(
                            children: [
                              Expanded(
                                flex: (avgCalm * 10).round().clamp(1, 1000),
                                child: Container(color: MuseColors.cyanGlow),
                              ),
                              Expanded(
                                flex: (avgNeutral * 10).round().clamp(1, 1000),
                                child: Container(color: MuseColors.mindCyan.withValues(alpha: 0.4)),
                              ),
                              Expanded(
                                flex: (avgActive * 10).round().clamp(1, 1000),
                                child: Container(color: MuseColors.roseGlow),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildLegendItem('Alpha (Calm)', '${avgCalm.toStringAsFixed(0)}%', MuseColors.cyanGlow),
                          _buildLegendItem('Neutral', '${avgNeutral.toStringAsFixed(0)}%', MuseColors.mindCyan.withValues(alpha: 0.6)),
                          _buildLegendItem('Beta (Active)', '${avgActive.toStringAsFixed(0)}%', MuseColors.roseGlow),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuseSpacing.lg),

                // Clinical Neurological Interpretation
                MuseCard(
                  borderColor: MuseColors.cyanGlow.withValues(alpha: 0.3),
                  backgroundColor: const Color(0xFF0F1B2B),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology, color: MuseColors.cyanGlow, size: 22),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CLINICAL NEUROLOGICAL ASSESSMENT',
                              style: TextStyle(
                                color: MuseColors.cyanGlow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _generateClinicalAssessment(avgCalm, avgActive, filteredSessions.length),
                        style: const TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: MuseColors.cardBorder, height: 1),
                      const SizedBox(height: 8),
                      Text(
                        'Total Sessions Analyzed: ${filteredSessions.length} | Cumulative Practice: $totalMinutes min',
                        style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuseSpacing.lg),

                // Session History Log
                const Text(
                  'INDIVIDUAL SESSION LOGS',
                  style: TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: MuseSpacing.sm),
                ...filteredSessions.map((s) => _buildSessionLogCard(s)),
              ],
            ],
          ),
        );
      },
    );
  }

  String _generateClinicalAssessment(double calm, double active, int sessionCount) {
    if (calm >= 60.0) {
      return 'The patient demonstrates robust parasympathetic activation and sustained Alpha wave dominance (${calm.toStringAsFixed(0)}%). This indicates high attentional stability, low neurovegetative distress, and positive responsiveness to mindfulness practices.';
    } else if (active >= 45.0) {
      return 'Elevated Beta brainwave activity (${active.toStringAsFixed(0)}%) detected. This pattern corresponds with heightened cognitive rumination, autonomic arousal, or anxiety. Prescribing soothing acoustic soundscapes (e.g. rain sounds, brown noise) or guided breath resets is recommended.';
    } else {
      return 'Balanced neurodynamic profile with consistent neutral states. The patient shifts smoothly between cognitive alertness and relaxation. Recommend maintaining steady daily 10-minute sessions to reinforce neuroplastic calm retention.';
    }
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return MuseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSessionLogCard(MeditationSession s) {
    final dateStr = '${s.startedAt.month}/${s.startedAt.day} ${s.startedAt.hour.toString().padLeft(2, '0')}:${s.startedAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: MuseSpacing.sm),
      child: MuseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  s.mode == ExperienceMode.soundscape ? Icons.spa : Icons.self_improvement,
                  size: 16,
                  color: MuseColors.cyanGlow,
                ),
                const SizedBox(width: 8),
                Text(
                  '${s.mode.displayName} Session',
                  style: const TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(color: MuseColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text('Duration: ${(s.durationSeconds / 60).toStringAsFixed(1)} min', style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11)),
                Text('Calm: ${s.calmPercent.toStringAsFixed(0)}%', style: const TextStyle(color: MuseColors.cyanGlow, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('Active: ${s.activePercent.toStringAsFixed(0)}%', style: const TextStyle(color: MuseColors.roseGlow, fontSize: 11)),
                if (s.averageBpm > 0)
                  Text('HR: ${s.averageBpm.toStringAsFixed(0)} bpm', style: const TextStyle(color: MuseColors.heartRed, fontSize: 11)),
              ],
            ),
            if (s.notes != null && s.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                s.notes!,
                style: const TextStyle(color: MuseColors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== 2. PRESCRIPTIONS & ADHERENCE ====================
  Widget _buildPrescriptionsTab() {
    final prescriptionsStream = ref.watch(therapistRepositoryProvider).streamPrescriptionsForClient(widget.grant.clientId);

    return Column(
      children: [
        // Prescribe Button Banner
        Padding(
          padding: const EdgeInsets.all(MuseSpacing.lg),
          child: MuseButton(
            label: '+ Prescribe Resource / Soundscape',
            variant: MuseButtonVariant.primary,
            width: double.infinity,
            onPressed: _showPrescribeDialog,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TherapistPrescription>>(
            stream: prescriptionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: MuseColors.cyanGlow));
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(MuseSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.medication_outlined, size: 48, color: MuseColors.textTertiary),
                        const SizedBox(height: 12),
                        const Text(
                          'No Prescriptions Yet',
                          style: TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap above to recommend a guided meditation, rain sound, or piano soundscape to this patient.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: MuseColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.lg),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final p = list[index];
                  final isCompleted = p.status == PrescriptionStatus.completed;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: MuseSpacing.md),
                    child: MuseCard(
                      borderColor: isCompleted ? MuseColors.breathMint.withValues(alpha: 0.4) : MuseColors.cardBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? MuseColors.breathMint.withValues(alpha: 0.2)
                                      : MuseColors.bodyAmber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCompleted ? Icons.check_circle : Icons.schedule,
                                      size: 13,
                                      color: isCompleted ? MuseColors.breathMint : MuseColors.bodyAmber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isCompleted ? 'COMPLETED WITH MUSE 2' : 'RECOMMENDED',
                                      style: TextStyle(
                                        color: isCompleted ? MuseColors.breathMint : MuseColors.bodyAmber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${p.prescribedAt.month}/${p.prescribedAt.day}',
                                style: const TextStyle(color: MuseColors.textTertiary, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.resourceTitle,
                            style: const TextStyle(
                              color: MuseColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Category: ${p.resourceCategory}',
                            style: const TextStyle(color: MuseColors.cyanGlow, fontSize: 11),
                          ),
                          if (p.instructions != null && p.instructions!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: MuseColors.spaceBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.notes, color: MuseColors.textSecondary, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.instructions!,
                                      style: const TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),

                          // BIOFEEDBACK OUTCOME INSIGHT
                          if (isCompleted) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F2624),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: MuseColors.breathMint.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.verified, color: MuseColors.breathMint, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'OBJECTIVE BIOFEEDBACK VERDICT',
                                        style: TextStyle(
                                          color: MuseColors.breathMint,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (p.patientCalmScore != null)
                                        Text(
                                          'Calm Score: ${p.patientCalmScore!.toStringAsFixed(0)}%  •  ',
                                          style: const TextStyle(color: MuseColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      if (p.patientHelpfulnessRating != null)
                                        Text(
                                          'Rating: ${p.patientHelpfulnessRating}/5 ★',
                                          style: const TextStyle(color: MuseColors.amberGlow, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  if (p.patientFeedback != null && p.patientFeedback!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Patient response: "${p.patientFeedback}"',
                                      style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    (p.patientCalmScore ?? 0) >= 60
                                        ? '✓ Clinically Effective: Patient achieved significant Alpha calm state using this tool.'
                                        : '• Moderate Effect: Patient maintained neutral focus.',
                                    style: TextStyle(
                                      color: (p.patientCalmScore ?? 0) >= 60 ? MuseColors.breathMint : MuseColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: MuseColors.textTertiary, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Awaiting patient session with Muse 2 headband',
                                  style: TextStyle(color: MuseColors.textTertiary, fontSize: 11),
                                ),
                              ],
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
      ],
    );
  }

  // ==================== 3. IN-APP MESSAGING & CHAT ====================
  Widget _buildChatTab() {
    final messagesStream = ref.watch(therapistRepositoryProvider).streamMessages(widget.grant.id);

    return Column(
      children: [
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
                        const Icon(Icons.chat_bubble_outline, size: 48, color: MuseColors.textTertiary),
                        const SizedBox(height: 12),
                        const Text(
                          'Direct Clinical Communication',
                          style: TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Send clinical guidance or attach resources to ${widget.grant.clientEmail}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: MuseColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(MuseSpacing.lg),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final isTherapist = m.senderRole == 'therapist';

                  return Align(
                    alignment: isTherapist ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: MuseSpacing.sm),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isTherapist
                            ? MuseColors.cyanGlow.withValues(alpha: 0.18)
                            : MuseColors.cardSurface,
                        border: Border.all(
                          color: isTherapist
                              ? MuseColors.cyanGlow.withValues(alpha: 0.5)
                              : MuseColors.cardBorder,
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: isTherapist ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m.senderName,
                                style: TextStyle(
                                  color: isTherapist ? MuseColors.cyanGlow : MuseColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: MuseColors.textTertiary, fontSize: 9),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.text,
                            style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13, height: 1.35),
                          ),
                          if (m.resourceAttachmentTitle != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: MuseColors.spaceBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: MuseColors.cyanGlow.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_circle_fill, color: MuseColors.cyanGlow, size: 16),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      m.resourceAttachmentTitle!,
                                      style: const TextStyle(color: MuseColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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

        // Message Input Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: MuseSpacing.sm),
          decoration: const BoxDecoration(
            color: MuseColors.spaceBackground,
            border: Border(top: BorderSide(color: MuseColors.cardBorder, width: 0.8)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: MuseColors.cyanGlow),
                  tooltip: 'Attach Resource',
                  onPressed: _showPrescribeDialog,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Message ${widget.grant.clientEmail}...',
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
                  onPressed: _isSending ? null : () => _sendMessage(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
