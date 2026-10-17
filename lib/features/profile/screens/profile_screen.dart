import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/meditation_session.dart';
import '../../../models/therapist_access_grant.dart';
import '../../../models/therapist_prescription.dart';
import '../../resources/models/resource_item.dart';
import '../../resources/screens/resource_practice_screen.dart';
import '../../therapist/screens/therapist_dashboard_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedPeriod = 'Week'; // 'Day', 'Week', 'Month'
  final TextEditingController _therapistEmailController = TextEditingController();
  bool _isGrantingAccess = false;

  @override
  void dispose() {
    _therapistEmailController.dispose();
    super.dispose();
  }

  List<MeditationSession> _filterSessions(List<MeditationSession> sessions) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
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

  Future<void> _grantTherapistAccess() async {
    final email = _therapistEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid therapist email address')),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Must be signed in to grant access')),
      );
      return;
    }

    setState(() => _isGrantingAccess = true);
    try {
      await ref.read(therapistRepositoryProvider).grantTherapistAccess(
            clientId: user.uid,
            clientEmail: user.email!,
            therapistEmail: email,
          );
      _therapistEmailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: MuseColors.surfaceElevated,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: MuseColors.breathMint, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Access invitation sent to $email')),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to grant access: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGrantingAccess = false);
    }
  }

  void _showTherapistEnrollDialog() {
    final orgController = TextEditingController(text: 'NeuroShift Clinical Center');
    final licController = TextEditingController(text: 'LMFT-98421');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MuseColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.medical_services, color: MuseColors.mysticPurple),
              SizedBox(width: 8),
              Text(
                'Enroll as Therapist',
                style: TextStyle(color: MuseColors.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Activate practitioner status to manage patients, review EEG telemetry, prescribe resources, and chat.',
                style: TextStyle(color: MuseColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: MuseSpacing.md),
              TextField(
                controller: orgController,
                style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Organization / Clinic Name',
                  labelStyle: TextStyle(color: MuseColors.textSecondary),
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              TextField(
                controller: licController,
                style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'License or Practitioner ID',
                  labelStyle: TextStyle(color: MuseColors.textSecondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: MuseColors.textSecondary)),
            ),
            MuseButton(
              label: 'Activate Portal',
              variant: MuseButtonVariant.primary,
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await ref.read(authServiceProvider).enrollCurrentAsTherapist(
                        organization: orgController.text.trim(),
                        licenseNumber: licController.text.trim(),
                      );
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: MuseColors.surfaceElevated,
                        content: Text('Therapist status activated! Dashboard is now available.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Enrollment failed: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    final authUser = ref.watch(authStateProvider).value;
    final therapistAsync = ref.watch(currentTherapistProfileProvider);
    final therapist = therapistAsync.value;
    final sessionsAsync = ref.watch(userSessionsProvider);
    final grantsAsync = ref.watch(clientGrantsProvider);
    final prescriptionsAsync = ref.watch(clientPrescriptionsProvider);

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text('PROFILE & NEURO-ANALYTICS'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MuseSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Account Header Card
              MuseCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: therapist != null
                            ? MuseColors.mysticPurple.withValues(alpha: 0.2)
                            : MuseColors.cardBorder,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: therapist != null ? MuseColors.mysticPurple : MuseColors.cyanGlow,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          therapist != null ? Icons.medical_services_outlined : Icons.person,
                          color: therapist != null ? MuseColors.mysticPurple : MuseColors.cyanGlow,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: MuseSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            therapist?.displayName ?? user?.displayName ?? authUser?.displayName ?? 'NeuroShift Meditator',
                            style: const TextStyle(
                              color: MuseColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            therapist?.email ?? user?.email ?? authUser?.email ?? 'meditator@neuroshift.app',
                            style: const TextStyle(
                              color: MuseColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (therapist != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: MuseColors.mysticPurple.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'REGISTERED PRACTITIONER',
                                style: TextStyle(
                                  color: MuseColors.mysticPurple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Clinician Workspace Banner
              if (therapist != null) ...[
                const SizedBox(height: MuseSpacing.md),
                MuseCard(
                  borderColor: MuseColors.mysticPurple.withValues(alpha: 0.5),
                  backgroundColor: const Color(0xFF221133),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dashboard_customize, color: MuseColors.mysticPurple, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'CLINICAL WORKSPACE',
                              style: TextStyle(
                                color: MuseColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: MuseColors.breathMint.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Verified', style: TextStyle(color: MuseColors.breathMint, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Org: ${therapist.organization} • Lic: ${therapist.licenseNumber}',
                        style: const TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      MuseButton(
                        label: 'Open Clinical Workspace',
                        variant: MuseButtonVariant.primary,
                        width: double.infinity,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TherapistDashboardScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: MuseSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.medical_services_outlined, size: 14, color: MuseColors.cyanGlow),
                    label: const Text(
                      'Clinician Portal Setup',
                      style: TextStyle(color: MuseColors.cyanGlow, fontSize: 12),
                    ),
                    onPressed: _showTherapistEnrollDialog,
                  ),
                ),
              ],

              const SizedBox(height: MuseSpacing.xl),

              // ==================== 1. COMPREHENSIVE WAVE REPORT ====================
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text(
                    'BRAINWAVE ANALYTICS',
                    style: TextStyle(
                      color: MuseColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  // Day / Week / Month Segmented Chips
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['Day', 'Week', 'Month'].map((p) {
                      final isSelected = _selectedPeriod == p;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ChoiceChip(
                          label: Text(p),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedPeriod = p);
                          },
                          backgroundColor: MuseColors.cardSurface,
                          selectedColor: MuseColors.cyanGlow.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSelected ? MuseColors.cyanGlow : MuseColors.textSecondary,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? MuseColors.cyanGlow : MuseColors.cardBorder,
                              width: 0.8,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: MuseSpacing.sm),

              // Telemetry Data Box
              sessionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(MuseSpacing.lg),
                    child: CircularProgressIndicator(color: MuseColors.cyanGlow),
                  ),
                ),
                error: (e, _) => MuseCard(
                  child: Text('Error loading session data: $e', style: const TextStyle(color: MuseColors.roseGlow)),
                ),
                data: (allSessions) {
                  final filtered = _filterSessions(allSessions);

                  if (filtered.isEmpty) {
                    return MuseCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: MuseSpacing.lg),
                          child: Column(
                            children: [
                              const Icon(Icons.waves, color: MuseColors.textTertiary, size: 36),
                              const SizedBox(height: 10),
                              Text(
                                'No sessions recorded for $_selectedPeriod window',
                                style: const TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Complete a meditation or soundscape session wearing your Muse 2 headband to populate genuine EEG wave analytics.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: MuseColors.textSecondary, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Calculate aggregate statistics
                  double totalCalm = 0;
                  double totalNeutral = 0;
                  double totalActive = 0;
                  double totalBpm = 0;
                  double totalStillness = 0;
                  int validBpmCount = 0;
                  int practiceSeconds = 0;

                  for (final s in filtered) {
                    totalCalm += s.calmPercent;
                    totalNeutral += s.neutralPercent;
                    totalActive += s.activePercent;
                    if (s.averageBpm > 0) {
                      totalBpm += s.averageBpm;
                      validBpmCount++;
                    }
                    totalStillness += s.averageStillness;
                    practiceSeconds += s.durationSeconds;
                  }

                  final avgCalm = totalCalm / filtered.length;
                  final avgNeutral = totalNeutral / filtered.length;
                  final avgActive = totalActive / filtered.length;
                  final avgBpm = validBpmCount > 0 ? totalBpm / validBpmCount : 0.0;
                  final avgStillness = totalStillness / filtered.length;
                  final totalMinutes = (practiceSeconds / 60).round();

                  return Column(
                    children: [
                      // Metric Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatTile(
                              label: 'Calm (Alpha)',
                              value: '${avgCalm.toStringAsFixed(1)}%',
                              color: MuseColors.cyanGlow,
                              icon: Icons.waves,
                            ),
                          ),
                          const SizedBox(width: MuseSpacing.md),
                          Expanded(
                            child: _buildStatTile(
                              label: 'Active (Beta)',
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
                            child: _buildStatTile(
                              label: 'Avg Heart Rate',
                              value: avgBpm > 0 ? '${avgBpm.toStringAsFixed(0)} BPM' : '--',
                              color: MuseColors.heartRed,
                              icon: Icons.favorite,
                            ),
                          ),
                          const SizedBox(width: MuseSpacing.md),
                          Expanded(
                            child: _buildStatTile(
                              label: 'Body Stillness',
                              value: '${avgStillness.toStringAsFixed(0)}%',
                              color: MuseColors.bodyAmber,
                              icon: Icons.accessibility_new,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuseSpacing.md),

                      // Wave Balance Bar
                      MuseCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_selectedPeriod Brainwave Balance',
                                  style: const TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '$totalMinutes min across ${filtered.length} sessions',
                                  style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 14,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: (avgCalm * 10).round().clamp(1, 1000),
                                      child: Container(color: MuseColors.cyanGlow),
                                    ),
                                    Expanded(
                                      flex: (avgNeutral * 10).round().clamp(1, 1000),
                                      child: Container(color: MuseColors.mindCyan.withValues(alpha: 0.35)),
                                    ),
                                    Expanded(
                                      flex: (avgActive * 10).round().clamp(1, 1000),
                                      child: Container(color: MuseColors.roseGlow),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLegend('Alpha Calm', '${avgCalm.toStringAsFixed(0)}%', MuseColors.cyanGlow),
                                _buildLegend('Neutral', '${avgNeutral.toStringAsFixed(0)}%', MuseColors.mindCyan.withValues(alpha: 0.6)),
                                _buildLegend('Beta Active', '${avgActive.toStringAsFixed(0)}%', MuseColors.roseGlow),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MuseSpacing.md),

                      // Dynamic Interpretation Box
                      _buildPersonalizedInterpretationCard(avgCalm, avgActive, filtered.length),
                    ],
                  );
                },
              ),

              const SizedBox(height: MuseSpacing.xl),

              // ==================== 2. NEUROLOGICAL INTERPRETATION GUIDE ====================
              const Text(
                'NEUROLOGICAL INTERPRETATION GUIDE',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              _buildWaveInterpretationGuide(),

              const SizedBox(height: MuseSpacing.xl),

              // ==================== 3. BEST-RESPONDED RESOURCES ====================
              const Text(
                'BEST-RESPONDED RESOURCES',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              sessionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (allSessions) => _buildBestRespondedResources(allSessions),
              ),

              const SizedBox(height: MuseSpacing.xl),

              // ==================== 4. PRESCRIBED TOOLS FROM THERAPIST ====================
              prescriptionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (prescriptions) {
                  final activePrescriptions = prescriptions
                      .where((p) => p.status == PrescriptionStatus.recommended)
                      .toList();

                  if (activePrescriptions.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_services_outlined, color: MuseColors.cyanGlow, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'RECOMMENDED BY YOUR THERAPIST',
                            style: TextStyle(
                              color: MuseColors.cyanGlow,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuseSpacing.sm),
                      ...activePrescriptions.map((presc) => _buildPrescriptionCard(presc)),
                      const SizedBox(height: MuseSpacing.xl),
                    ],
                  );
                },
              ),

              // ==================== 5. CARE TEAM & THERAPIST ACCESS ====================
              const Text(
                'CARE TEAM & THERAPIST ACCESS',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              MuseCard(
                borderColor: MuseColors.cyanGlow.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.share, color: MuseColors.cyanGlow, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Grant Access to Your Therapist',
                          style: TextStyle(
                            color: MuseColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Provide your therapist\'s email address. Once accepted, they can review your EEG wave telemetry, track how recommended practices help you, and send personalized resources.',
                      style: TextStyle(color: MuseColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: MuseSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _therapistEmailController,
                            style: const TextStyle(color: MuseColors.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'therapist@clinic.com',
                              hintStyle: const TextStyle(color: MuseColors.textTertiary, fontSize: 13),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.flash_on, color: MuseColors.cyanGlow, size: 16),
                                tooltip: 'Sample Therapist Email',
                                onPressed: () {
                                  setState(() {
                                    final currentEmail = user?.email ?? 'njorogenancy840@gmail.com';
                                    if (_therapistEmailController.text != currentEmail) {
                                      _therapistEmailController.text = currentEmail;
                                    } else {
                                      _therapistEmailController.text = 'dr.smith@neuroclinic.com';
                                    }
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: MuseColors.spaceBackground,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: MuseColors.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: MuseColors.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: MuseColors.cyanGlow),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: MuseSpacing.sm),
                        _isGrantingAccess
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: MuseColors.cyanGlow),
                                ),
                              )
                            : MuseButton(
                                label: 'Grant Access',
                                variant: MuseButtonVariant.primary,
                                onPressed: _grantTherapistAccess,
                              ),
                      ],
                    ),
                    const SizedBox(height: MuseSpacing.md),

                    // Active Grants List
                    grantsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: MuseColors.roseGlow, fontSize: 11)),
                      data: (grants) {
                        if (grants.isEmpty) {
                          return const Text(
                            'No care team access currently active.',
                            style: TextStyle(color: MuseColors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: MuseColors.cardBorder, height: 20),
                            const Text(
                              'ACTIVE & PENDING CARE GRANTS',
                              style: TextStyle(color: MuseColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 6),
                            ...grants.map((grant) => _buildGrantTile(grant)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: MuseSpacing.xl),

              // Non-Clinical Disclaimer
              MuseCard(
                backgroundColor: MuseColors.cardSurface.withValues(alpha: 0.5),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: MuseColors.cyanGlow, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Wellness Notice',
                          style: TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      AppConstants.nonClinicalDisclaimer,
                      style: TextStyle(color: MuseColors.textSecondary, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: MuseSpacing.xl),

              // Sign Out Button
              MuseButton(
                label: 'Sign Out',
                variant: MuseButtonVariant.outline,
                width: double.infinity,
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
              const SizedBox(height: MuseSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildStatTile({
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
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, String value, Color color) {
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

  Widget _buildPersonalizedInterpretationCard(double calm, double active, int sessionCount) {
    String stateTitle;
    String description;
    Color accentColor;

    if (calm >= 60) {
      stateTitle = 'Predominant Alpha Calm (Relaxed & Mindful)';
      description =
          'Your brainwaves reflect sustained parasympathetic activation. High alpha rhythm (8–12 Hz) correlates with calm alertness, stress reduction, and emotional balance. You have been unwinding effectively.';
      accentColor = MuseColors.cyanGlow;
    } else if (active >= 45) {
      stateTitle = 'Elevated Beta Activity (Active Cognition & Strain)';
      description =
          'Higher beta waves (13–30 Hz) indicate active cognitive processing, mental exertion, or potential stress. Consider prioritizing rainfall soundscapes or slow box breathing to facilitate alpha wave restoration.';
      accentColor = MuseColors.roseGlow;
    } else {
      stateTitle = 'Balanced Neurodynamic Equilibrium';
      description =
          'Your telemetry displays an even balance between alertness and composure. Your nervous system is transitioning smoothly without getting stuck in high sympathetic arousal.';
      accentColor = MuseColors.mindCyan;
    }

    return MuseCard(
      borderColor: accentColor.withValues(alpha: 0.4),
      backgroundColor: const Color(0xFF0F1E28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stateTitle,
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: MuseColors.textPrimary, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveInterpretationGuide() {
    final waveTypes = [
      {
        'name': 'Alpha Waves (8 – 12 Hz)',
        'state': 'Calm Alertness & Relaxation',
        'desc': 'Reflects quiet, reflective presence. Prominent when your eyes are closed, during mindfulness, and in states of non-aroused alertness.',
        'color': MuseColors.cyanGlow,
      },
      {
        'name': 'Beta Waves (13 – 30 Hz)',
        'state': 'Active Thinking & Focus',
        'desc': 'Associated with logical problem solving, conversation, and fast decision-making. Over-elevation signals mental fatigue, cognitive rumination, or tension.',
        'color': MuseColors.roseGlow,
      },
      {
        'name': 'Theta Waves (4 – 8 Hz)',
        'state': 'Deep Meditation & Flow',
        'desc': 'Occurs during hypnagogic twilight states, profound meditative trances, creative visualization, and subconscious integration.',
        'color': MuseColors.mysticPurple,
      },
      {
        'name': 'Delta Waves (0.5 – 4 Hz)',
        'state': 'Deep Sleep & Healing',
        'desc': 'Slowest brain rhythms characteristic of deep dreamless sleep, autonomic healing, and cellular restorative processes.',
        'color': MuseColors.bodyAmber,
      },
      {
        'name': 'Gamma Waves (30 – 50 Hz)',
        'state': 'Peak Insight & Binding',
        'desc': 'High-frequency synchronization involved in multi-sensory processing, simultaneous binding of disparate information, and epiphanies.',
        'color': MuseColors.breathMint,
      },
    ];

    return Column(
      children: waveTypes.map((w) {
        final color = w['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: MuseSpacing.sm),
          child: MuseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w['name'] as String,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        w['state'] as String,
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  w['desc'] as String,
                  style: const TextStyle(color: MuseColors.textSecondary, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBestRespondedResources(List<MeditationSession> sessions) {
    // Group sessions by resource title and compute average calm percent
    final Map<String, List<double>> resourceCalmScores = {};

    for (final s in sessions) {
      if (s.notes != null && s.notes!.contains('Resource: ')) {
        final parts = s.notes!.split('|');
        final firstPart = parts.first.replaceAll('Resource: ', '').trim();
        if (firstPart.isNotEmpty) {
          resourceCalmScores.putIfAbsent(firstPart, () => []).add(s.calmPercent);
        }
      }
    }

    if (resourceCalmScores.isEmpty) {
      return MuseCard(
        child: Padding(
          padding: const EdgeInsets.all(MuseSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.spa, color: MuseColors.cyanGlow, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'No Resource Practices Yet',
                    style: TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore the Resources library (guided meditations, rain sounds, piano) to discover which soundscapes produce the strongest Alpha calm response for you.',
                style: TextStyle(color: MuseColors.textSecondary, fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = resourceCalmScores.entries.toList()
      ..sort((a, b) {
        final avgA = a.value.reduce((x, y) => x + y) / a.value.length;
        final avgB = b.value.reduce((x, y) => x + y) / b.value.length;
        return avgB.compareTo(avgA);
      });

    final topResources = sorted.take(3).toList();

    return Column(
      children: topResources.map((entry) {
        final avgScore = entry.value.reduce((x, y) => x + y) / entry.value.length;
        final count = entry.value.length;

        // Find matching catalog resource
        final catalogMatch = ResourceItem.catalog.firstWhere(
          (r) => r.title == entry.key,
          orElse: () => ResourceItem.catalog.first,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: MuseSpacing.sm),
          child: MuseCard(
            borderColor: MuseColors.breathMint.withValues(alpha: 0.3),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MuseColors.breathMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(catalogMatch.category.icon, color: MuseColors.breathMint, size: 20),
                  ),
                ),
                const SizedBox(width: MuseSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Avg Calm: ${avgScore.toStringAsFixed(0)}%  •  $count sessions',
                        style: const TextStyle(color: MuseColors.breathMint, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: MuseColors.cyanGlow, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ResourcePracticeScreen(resource: catalogMatch)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrescriptionCard(TherapistPrescription presc) {
    final catalogMatch = ResourceItem.catalog.firstWhere(
      (r) => r.id == presc.resourceId,
      orElse: () => ResourceItem.catalog.first,
    );

    return MuseCard(
      borderColor: MuseColors.cyanGlow.withValues(alpha: 0.4),
      backgroundColor: const Color(0xFF0F2228),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MuseColors.cyanGlow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('CLINICAL RECOMMENDATION', style: TextStyle(color: MuseColors.cyanGlow, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('From ${presc.therapistName}', style: const TextStyle(color: MuseColors.textTertiary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            presc.resourceTitle,
            style: const TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (presc.instructions != null && presc.instructions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Therapist notes: "${presc.instructions}"',
              style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 10),
          MuseButton(
            label: 'Start Prescribed Practice with Muse 2',
            variant: MuseButtonVariant.primary,
            width: double.infinity,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ResourcePracticeScreen(resource: catalogMatch)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrantTile(TherapistAccessGrant grant) {
    final isActive = grant.status == GrantStatus.active;
    final isPending = grant.status == GrantStatus.pending;
    final isRevoked = grant.status == GrantStatus.revoked;

    Color statusColor;
    String statusLabel;
    if (isActive) {
      statusColor = MuseColors.breathMint;
      statusLabel = 'Active Care Access';
    } else if (isPending) {
      statusColor = MuseColors.amberGlow;
      statusLabel = 'Pending Acceptance';
    } else {
      statusColor = MuseColors.roseGlow;
      statusLabel = 'Access Revoked';
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MuseColors.spaceBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MuseColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grant.therapistEmail,
                  style: const TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isRevoked)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: MuseColors.cardSurface,
                    title: const Text('Revoke Therapist Access?'),
                    content: Text('Are you sure you want to revoke access for ${grant.therapistEmail}? They will no longer be able to see your session telemetry.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke', style: TextStyle(color: MuseColors.roseGlow))),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(therapistRepositoryProvider).revokeGrant(grant.id);
                }
              },
              child: const Text('Revoke', style: TextStyle(color: MuseColors.roseGlow, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
