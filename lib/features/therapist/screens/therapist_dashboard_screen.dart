import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/therapist_access_grant.dart';
import 'patient_detail_screen.dart';

class TherapistDashboardScreen extends ConsumerWidget {
  const TherapistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapist = ref.watch(currentTherapistProfileProvider).value;
    final user = ref.watch(authStateProvider).value;
    final grantsAsync = ref.watch(therapistGrantsProvider);

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text(
          'CLINICAL WORKSPACE',
          style: TextStyle(
            color: MuseColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MuseColors.mysticPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MuseColors.mysticPurple.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: MuseColors.breathMint, size: 14),
                SizedBox(width: 4),
                Text(
                  'Practitioner',
                  style: TextStyle(color: MuseColors.breathMint, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MuseSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Practitioner Header Card
              MuseCard(
                borderColor: MuseColors.mysticPurple.withValues(alpha: 0.4),
                backgroundColor: const Color(0xFF1B1429),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: MuseColors.mysticPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.medical_services, color: Colors.white, size: 26),
                      ),
                    ),
                    const SizedBox(width: MuseSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            therapist?.displayName ?? user?.displayName ?? 'Licensed Practitioner',
                            style: const TextStyle(
                              color: MuseColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            therapist?.organization.isNotEmpty == true
                                ? therapist!.organization
                                : 'NeuroShift Clinical Network',
                            style: const TextStyle(color: MuseColors.cyanGlow, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lic: ${therapist?.licenseNumber.isNotEmpty == true ? therapist!.licenseNumber : "VERIFIED-PRACTITIONER"} • ${user?.email ?? ""}',
                            style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.xl),

              // ==================== 1. PENDING INVITATIONS ====================
              grantsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: MuseColors.cyanGlow)),
                error: (e, _) => MuseCard(child: Text('Error loading grants: $e', style: const TextStyle(color: MuseColors.roseGlow))),
                data: (allGrants) {
                  final pendingGrants = allGrants.where((g) => g.status == GrantStatus.pending).toList();
                  final activeGrants = allGrants.where((g) => g.status == GrantStatus.active).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pendingGrants.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: MuseColors.amberGlow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${pendingGrants.length} NEW',
                                style: const TextStyle(color: MuseColors.amberGlow, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'PENDING PATIENT INVITATIONS',
                              style: TextStyle(
                                color: MuseColors.amberGlow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MuseSpacing.sm),
                        ...pendingGrants.map((grant) => _buildPendingGrantCard(context, ref, grant, user?.uid ?? '')),
                        const SizedBox(height: MuseSpacing.xl),
                      ],

                      // ==================== 2. ACTIVE PATIENT ROSTER ====================
                      Row(
                        children: [
                          const Text(
                            'CONNECTED PATIENTS',
                            style: TextStyle(
                              color: MuseColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${activeGrants.length} Active',
                            style: const TextStyle(color: MuseColors.cyanGlow, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuseSpacing.sm),

                      if (activeGrants.isEmpty)
                        MuseCard(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: MuseSpacing.lg),
                              child: Column(
                                children: [
                                  const Icon(Icons.group_outlined, size: 40, color: MuseColors.textTertiary),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Active Patients Connected Yet',
                                    style: TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'When a patient enters your email (${user?.email ?? "therapist email"}) on their profile, their invitation will appear above.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...activeGrants.map((grant) => _buildActivePatientCard(context, grant)),
                    ],
                  );
                },
              ),

              const SizedBox(height: MuseSpacing.xl),

              // ==================== 3. CLINICAL PROTOCOL REFERENCE ====================
              const Text(
                'CLINICAL EEG & NEUROFEEDBACK REFERENCE',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              MuseCard(
                backgroundColor: MuseColors.cardSurface.withValues(alpha: 0.6),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: MuseColors.cyanGlow, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Objective Biomarkers from Muse 2',
                          style: TextStyle(color: MuseColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Alpha Band (8–12 Hz): Reflects restful wakefulness & parasympathetic engagement. Target for mindfulness training.\n'
                      '• Beta Band (13–30 Hz): Reflects active cognition, stress, or sensory processing. Elevated beta indicates mental load.\n'
                      '• HRV RMSSD & Heart Rate: Derived from optical PPG. Higher RMSSD denotes autonomic flexibility and vagal tone.\n'
                      '• Body Stillness: 3-axis accelerometer and gyro detecting physical fidgeting and posture stability.',
                      style: TextStyle(color: MuseColors.textSecondary, fontSize: 12, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingGrantCard(BuildContext context, WidgetRef ref, TherapistAccessGrant grant, String therapistUid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MuseSpacing.sm),
      child: MuseCard(
        borderColor: MuseColors.amberGlow.withValues(alpha: 0.5),
        backgroundColor: const Color(0xFF261E14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mail_outline, color: MuseColors.amberGlow, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    grant.clientEmail,
                    style: const TextStyle(
                      color: MuseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: MuseColors.amberGlow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Pending Invite', style: TextStyle(color: MuseColors.amberGlow, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Patient has granted you access to their Muse 2 EEG session reports, real-time brainwave analytics, and prescription recommendations.',
              style: TextStyle(color: MuseColors.textSecondary, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MuseButton(
                    label: 'Accept Patient',
                    variant: MuseButtonVariant.primary,
                    onPressed: () async {
                      try {
                        await ref.read(therapistRepositoryProvider).acceptGrant(
                              grantId: grant.id,
                              therapistId: therapistUid,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: MuseColors.surfaceElevated,
                              content: Text('Accepted invitation from ${grant.clientEmail}'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error accepting: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: MuseSpacing.sm),
                MuseButton(
                  label: 'Decline',
                  variant: MuseButtonVariant.outline,
                  onPressed: () async {
                    await ref.read(therapistRepositoryProvider).revokeGrant(grant.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePatientCard(BuildContext context, TherapistAccessGrant grant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MuseSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(grant: grant),
            ),
          );
        },
        child: MuseCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MuseColors.cyanGlow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person, color: MuseColors.cyanGlow, size: 24),
                ),
              ),
              const SizedBox(width: MuseSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grant.clientEmail,
                      style: const TextStyle(
                        color: MuseColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Access granted ${grant.grantedAt.month}/${grant.grantedAt.day}/${grant.grantedAt.year}',
                      style: const TextStyle(color: MuseColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: MuseColors.cyanGlow),
            ],
          ),
        ),
      ),
    );
  }
}
