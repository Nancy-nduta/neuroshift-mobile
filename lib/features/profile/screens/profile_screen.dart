import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/meditation_session.dart';
import '../../../models/therapist_access_grant.dart';
import '../../../models/therapist_prescription.dart';
import '../../../services/notifications/notification_service.dart';
import '../../onboarding/screens/onboarding_consent_screen.dart';
import '../../resources/models/resource_item.dart';
import '../../resources/screens/resource_practice_screen.dart';
import '../../therapist/screens/therapist_dashboard_screen.dart';
import 'client_therapist_chat_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedPeriod = 'Week';
  final TextEditingController _therapistEmailController =
      TextEditingController();
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
        const SnackBar(
            content: Text('Please enter a valid therapist email address')),
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
                const Icon(Icons.check_circle,
                    color: MuseColors.breathMint, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Invitation sent to $email')),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send invitation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGrantingAccess = false);
    }
  }

  void _showTherapistEnrollDialog() {
    final orgController =
        TextEditingController(text: 'NeuroShift Wellness Clinic');
    final licController = TextEditingController(text: 'LMFT-98421');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MuseColors.cardSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.medical_services_outlined,
                  color: MuseColors.mysticPurple),
              SizedBox(width: 8),
              Text(
                'Practitioner Portal',
                style: TextStyle(color: MuseColors.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enable practitioner mode to support clients, share resources, and chat.',
                style:
                    TextStyle(color: MuseColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: MuseSpacing.md),
              TextField(
                controller: orgController,
                style: const TextStyle(
                    color: MuseColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Clinic or Organization',
                  labelStyle: TextStyle(color: MuseColors.textSecondary),
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              TextField(
                controller: licController,
                style: const TextStyle(
                    color: MuseColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'License / Practitioner ID',
                  labelStyle: TextStyle(color: MuseColors.textSecondary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: MuseColors.textSecondary)),
            ),
            MuseButton(
              label: 'Activate',
              variant: MuseButtonVariant.primary,
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await ref
                      .read(authServiceProvider)
                      .enrollCurrentAsTherapist(
                        organization: orgController.text.trim(),
                        licenseNumber: licController.text.trim(),
                      );
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: MuseColors.surfaceElevated,
                        content: Text('Practitioner workspace enabled.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Setup failed: $e')),
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
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MuseColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          NotificationBellButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MuseSpacing.lg,
            vertical: MuseSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Clean User Account Card
              MuseCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: (therapist != null
                                    ? MuseColors.mysticPurple
                                    : MuseColors.cyanGlow)
                                .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            therapist != null
                                ? Icons.medical_services_outlined
                                : Icons.person_outline,
                            color: therapist != null
                                ? MuseColors.mysticPurple
                                : MuseColors.cyanGlow,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: MuseSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                therapist?.displayName ??
                                    user?.displayName ??
                                    authUser?.displayName ??
                                    'Member',
                                style: const TextStyle(
                                  color: MuseColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                therapist?.email ??
                                    user?.email ??
                                    authUser?.email ??
                                    '',
                                style: const TextStyle(
                                  color: MuseColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (therapist != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: MuseColors.mysticPurple
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Practitioner',
                              style: TextStyle(
                                color: MuseColors.mysticPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (therapist != null) ...[
                      const SizedBox(height: MuseSpacing.md),
                      MuseButton(
                        label: 'Open Clinical Workspace',
                        variant: MuseButtonVariant.outline,
                        width: double.infinity,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const TherapistDashboardScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.lg),

              // 2. Therapist Recommended Practices (if any)
              prescriptionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (prescriptions) {
                  final activePrescriptions = prescriptions
                      .where((p) => p.status == PrescriptionStatus.recommended)
                      .toList();

                  if (activePrescriptions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From Your Therapist',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: MuseSpacing.sm),
                      ...activePrescriptions.map(
                        (presc) => _buildPrescriptionCard(
                          presc,
                          grantsAsync.value ?? [],
                        ),
                      ),
                      const SizedBox(height: MuseSpacing.lg),
                    ],
                  );
                },
              ),

              // 3. Wellness Summary Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Wellness Summary',
                    style: TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: ['Day', 'Week', 'Month'].map((p) {
                      final isSelected = _selectedPeriod == p;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MuseColors.cyanGlow.withValues(alpha: 0.18)
                                  : MuseColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? MuseColors.cyanGlow
                                    : MuseColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                color: isSelected
                                    ? MuseColors.cyanGlow
                                    : MuseColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: MuseSpacing.sm),

              sessionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(MuseSpacing.lg),
                    child: CircularProgressIndicator(
                        color: MuseColors.cyanGlow),
                  ),
                ),
                error: (e, _) => MuseCard(
                  child: Text('Unable to load stats: $e',
                      style: const TextStyle(color: MuseColors.roseGlow)),
                ),
                data: (allSessions) {
                  final filtered = _filterSessions(allSessions);

                  if (filtered.isEmpty) {
                    return MuseCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: MuseSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    MuseColors.cyanGlow.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.self_improvement,
                                  color: MuseColors.cyanGlow, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No sessions this ${_selectedPeriod.toLowerCase()}',
                                    style: const TextStyle(
                                      color: MuseColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Complete a practice session to view your calm score and heart rate trends.',
                                    style: TextStyle(
                                      color: MuseColors.textSecondary,
                                      fontSize: 12,
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
                  final avgBpm =
                      validBpmCount > 0 ? totalBpm / validBpmCount : 0.0;
                  final avgStillness = totalStillness / filtered.length;
                  final totalMinutes = (practiceSeconds / 60).round();

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatTile(
                              label: 'Calm Score',
                              value: '${avgCalm.toStringAsFixed(0)}%',
                              color: MuseColors.cyanGlow,
                              icon: Icons.spa_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatTile(
                              label: 'Active Mind',
                              value: '${avgActive.toStringAsFixed(0)}%',
                              color: MuseColors.roseGlow,
                              icon: Icons.bolt_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatTile(
                              label: 'Heart Rate',
                              value: avgBpm > 0
                                  ? '${avgBpm.toStringAsFixed(0)} bpm'
                                  : '--',
                              color: MuseColors.heartRed,
                              icon: Icons.favorite_outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatTile(
                              label: 'Stillness',
                              value: '${avgStillness.toStringAsFixed(0)}%',
                              color: MuseColors.bodyAmber,
                              icon: Icons.accessibility_new,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      MuseCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Mind State Balance',
                                  style: TextStyle(
                                    color: MuseColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$totalMinutes min • ${filtered.length} sessions',
                                  style: const TextStyle(
                                    color: MuseColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 10,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex:
                                          (avgCalm * 10).round().clamp(1, 1000),
                                      child:
                                          Container(color: MuseColors.cyanGlow),
                                    ),
                                    Expanded(
                                      flex: (avgNeutral * 10)
                                          .round()
                                          .clamp(1, 1000),
                                      child: Container(
                                        color: MuseColors.mindCyan
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    Expanded(
                                      flex: (avgActive * 10)
                                          .round()
                                          .clamp(1, 1000),
                                      child:
                                          Container(color: MuseColors.roseGlow),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLegend('Calm',
                                    '${avgCalm.toStringAsFixed(0)}%', MuseColors.cyanGlow),
                                _buildLegend('Neutral',
                                    '${avgNeutral.toStringAsFixed(0)}%', MuseColors.mindCyan.withValues(alpha: 0.7)),
                                _buildLegend('Active',
                                    '${avgActive.toStringAsFixed(0)}%', MuseColors.roseGlow),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: MuseSpacing.xl),

              // 4. Care Team & Therapist Access
              const Text(
                'Care Team',
                style: TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              MuseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect with Your Therapist',
                      style: TextStyle(
                        color: MuseColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Share your progress and chat directly with your therapist.',
                      style: TextStyle(
                          color: MuseColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: MuseSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _therapistEmailController,
                            style: const TextStyle(
                                color: MuseColors.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'therapist@clinic.com',
                              hintStyle: const TextStyle(
                                  color: MuseColors.textTertiary, fontSize: 13),
                              filled: true,
                              fillColor: MuseColors.spaceBackground,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: MuseColors.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: MuseColors.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: MuseColors.cyanGlow),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: MuseSpacing.sm),
                        _isGrantingAccess
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: MuseColors.cyanGlow),
                              )
                            : MuseButton(
                                label: 'Invite',
                                variant: MuseButtonVariant.primary,
                                onPressed: _grantTherapistAccess,
                              ),
                      ],
                    ),
                    grantsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (grants) {
                        if (grants.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(
                                color: MuseColors.cardBorder, height: 24),
                            ...grants.map((grant) => _buildGrantTile(grant)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.xl),

              // 5. Privacy, Practitioner Setup & Account Actions
              const Text(
                'Settings & Privacy',
                style: TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              Builder(
                builder: (context) {
                  final consentRecord =
                      ref.watch(userConsentRecordProvider).value;
                  return MuseCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.verified_user_outlined,
                              color: MuseColors.cyanGlow, size: 20),
                          title: const Text(
                            'Privacy & Consent Preferences',
                            style: TextStyle(
                              color: MuseColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Manage biofeedback, mood & AI permissions',
                            style: TextStyle(
                                color: MuseColors.textSecondary, fontSize: 11.5),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: MuseColors.textSecondary, size: 18),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OnboardingConsentScreen(
                                  isReviewMode: true,
                                  existingRecord: consentRecord,
                                ),
                              ),
                            );
                          },
                        ),
                        if (therapist == null) ...[
                          const Divider(
                              color: MuseColors.cardBorder, height: 1),
                          ListTile(
                            leading: const Icon(
                                Icons.medical_services_outlined,
                                color: MuseColors.mysticPurple,
                                size: 20),
                            title: const Text(
                              'Practitioner Portal Setup',
                              style: TextStyle(
                                color: MuseColors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Enroll as a clinician to support patients',
                              style: TextStyle(
                                  color: MuseColors.textSecondary,
                                  fontSize: 11.5),
                            ),
                            trailing: const Icon(Icons.chevron_right,
                                color: MuseColors.textSecondary, size: 18),
                            onTap: _showTherapistEnrollDialog,
                          ),
                        ],
                        const Divider(color: MuseColors.cardBorder, height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout,
                              color: MuseColors.roseGlow, size: 20),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(
                              color: MuseColors.roseGlow,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => ref.read(authServiceProvider).signOut(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: MuseSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return MuseCard(
      padding: const EdgeInsets.all(14),
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
                    color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style:
                const TextStyle(color: MuseColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ',
            style: const TextStyle(
                color: MuseColors.textSecondary, fontSize: 11.5)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPrescriptionCard(
    TherapistPrescription presc,
    List<TherapistAccessGrant> grants,
  ) {
    final resource = ResourceItem.catalog.firstWhere(
      (r) => r.id == presc.resourceId || r.title == presc.resourceTitle,
      orElse: () => ResourceItem.catalog.first,
    );

    final activeGrant = grants
        .where(
            (g) => g.therapistId == presc.therapistId && g.status == GrantStatus.active)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: MuseSpacing.sm),
      child: MuseCard(
        borderColor: MuseColors.cyanGlow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(resource.category.icon,
                    color: MuseColors.cyanGlow, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presc.resourceTitle,
                        style: const TextStyle(
                          color: MuseColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Recommended by ${presc.therapistName}',
                        style: const TextStyle(
                          color: MuseColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (presc.instructions != null &&
                presc.instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                presc.instructions!,
                style: const TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MuseButton(
                    label: 'Start Session',
                    icon: Icons.play_arrow_rounded,
                    height: 38,
                    variant: MuseButtonVariant.primary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResourcePracticeScreen(
                            resource: resource,
                            isPrescription: true,
                            therapistName: presc.therapistName,
                            prescriptionId: presc.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (activeGrant != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ClientTherapistChatScreen(grant: activeGrant),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline,
                        size: 15, color: MuseColors.cyanGlow),
                    label: const Text('Chat',
                        style: TextStyle(
                            color: MuseColors.cyanGlow, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrantTile(TherapistAccessGrant grant) {
    final isActive = grant.status == GrantStatus.active;
    final isPending = grant.status == GrantStatus.pending;
    final isRevoked = grant.status == GrantStatus.revoked;

    final Color statusColor = isActive
        ? MuseColors.breathMint
        : (isPending ? MuseColors.amberGlow : MuseColors.roseGlow);
    final String statusLabel = isActive
        ? 'Connected'
        : (isPending ? 'Invite Pending' : 'Revoked');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grant.therapistEmail,
                  style: const TextStyle(
                    color: MuseColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isActive)
            TextButton.icon(
              icon: const Icon(Icons.chat_bubble_outline,
                  size: 14, color: MuseColors.cyanGlow),
              label: const Text('Chat',
                  style: TextStyle(
                      color: MuseColors.cyanGlow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientTherapistChatScreen(grant: grant),
                  ),
                );
              },
            ),
          if (!isRevoked)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: MuseColors.cardSurface,
                    title: const Text('Remove Therapist Access?'),
                    content: Text(
                        'Stop sharing your session history with ${grant.therapistEmail}?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove',
                            style: TextStyle(color: MuseColors.roseGlow)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref
                      .read(therapistRepositoryProvider)
                      .revokeGrant(grant.id);
                }
              },
              child: const Text('Remove',
                  style: TextStyle(color: MuseColors.roseGlow, fontSize: 11.5)),
            ),
        ],
      ),
    );
  }
}
