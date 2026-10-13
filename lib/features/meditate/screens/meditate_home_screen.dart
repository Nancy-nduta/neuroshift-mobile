import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/headband_status_pill.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/experience_mode.dart';
import '../../../models/meditation_session.dart';
import '../../../models/sensor_status.dart';
import '../../connect/screens/headband_connect_screen.dart';
import '../widgets/how_it_works_card.dart';
import 'live_meditation_screen.dart';

class MeditateHomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenConnectTab;

  const MeditateHomeScreen({super.key, this.onOpenConnectTab});

  @override
  ConsumerState<MeditateHomeScreen> createState() => _MeditateHomeScreenState();
}

class _MeditateHomeScreenState extends ConsumerState<MeditateHomeScreen> {
  void _startSessionWith({required ExperienceMode mode, required int durationMinutes}) {
    final status = ref.read(headbandStatusProvider).value ?? const HeadbandStatus();

    if (!status.isConnected) {
      showModalBottomSheet(
        context: context,
        backgroundColor: MuseColors.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(MuseSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sensors_off, size: 48, color: MuseColors.amberGlow),
                const SizedBox(height: MuseSpacing.md),
                const Text(
                  'Headband Not Connected',
                  style: TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: MuseSpacing.xs),
                const Text(
                  'Connect your Muse 2 headband to receive live brainwave, heart rate, and stillness biofeedback.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MuseColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: MuseSpacing.xl),
                MuseButton(
                  label: 'Connect Muse 2',
                  width: double.infinity,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (widget.onOpenConnectTab != null) {
                      widget.onOpenConnectTab!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HeadbandConnectScreen()),
                      );
                    }
                  },
                ),
                const SizedBox(height: MuseSpacing.sm),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _launchLiveScreen(mode: mode, durationMinutes: durationMinutes);
                  },
                  child: const Text(
                    'Practice Without Biofeedback',
                    style: TextStyle(color: MuseColors.textMuted),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    _launchLiveScreen(mode: mode, durationMinutes: durationMinutes);
  }

  void _launchLiveScreen({required ExperienceMode mode, required int durationMinutes}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveMeditationScreen(
          mode: mode,
          durationMinutes: durationMinutes,
        ),
      ),
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  _Recommendation _computeRecommendation(List<MeditationSession> sessions) {
    if (sessions.isEmpty) {
      return _Recommendation(
        mode: ExperienceMode.mind,
        durationMinutes: 3,
        tag: 'STARTER PRACTICE',
        reason:
            'Calibrates your baseline brainwave calm levels and introduces live neurofeedback.',
      );
    }

    // Check recent sessions to determine what was most effective
    MeditationSession? bestSession;
    double maxCalm = -1;
    for (final s in sessions) {
      if (s.calmPercent > maxCalm) {
        maxCalm = s.calmPercent;
        bestSession = s;
      }
    }

    if (bestSession != null && maxCalm >= 60) {
      return _Recommendation(
        mode: bestSession.mode,
        durationMinutes: (bestSession.durationSeconds / 60).round().clamp(3, 15),
        tag: 'WORKED BEST FOR YOU',
        reason:
            'You achieved your highest calm state (${maxCalm.toInt()}%) during ${bestSession.mode.displayName}.',
      );
    }

    // Fallback recommendation
    final lastSession = sessions.first;
    final alternateMode = lastSession.mode == ExperienceMode.mind
        ? ExperienceMode.breath
        : ExperienceMode.mind;

    return _Recommendation(
      mode: alternateMode,
      durationMinutes: 5,
      tag: 'ADAPTIVE ROTATION',
      reason:
          'Rotating modalities stimulates neuro-plastic recovery and parasympathetic balance.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    final authUser = ref.watch(authStateProvider).value;
    final sessionsAsync = ref.watch(userSessionsProvider);
    final sessions = sessionsAsync.value ?? [];

    final displayName = user?.displayName ?? authUser?.displayName?.split(' ').first ?? 'Meditator';
    final streak = user?.streakDays ?? 0;
    final recommendation = _computeRecommendation(sessions);

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text(
          'NEUROSHIFT',
          style: TextStyle(
            letterSpacing: 2.0,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: MuseColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (streak > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MuseColors.amberGlow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MuseColors.amberGlow.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: MuseColors.amberGlow, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$streak d',
                    style: const TextStyle(
                      color: MuseColors.amberGlow,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Padding(
            padding: const EdgeInsets.only(right: MuseSpacing.md),
            child: HeadbandStatusPill(
              onTap: () {
                if (widget.onOpenConnectTab != null) {
                  widget.onOpenConnectTab!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HeadbandConnectScreen()),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.lg, vertical: MuseSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                '${_getTimeGreeting()}, $displayName',
                style: const TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Welcome to your biofeedback practice space.',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: MuseSpacing.lg),

              // 1. INTRODUCTORY SECTION: How NeuroShift Works
              HowItWorksCard(
                onConnectTapped: () {
                  if (widget.onOpenConnectTab != null) {
                    widget.onOpenConnectTab!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HeadbandConnectScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: MuseSpacing.xl),

              // 2. TODAY'S RECOMMENDED SESSION HERO CARD
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: MuseColors.cyanGlow, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'RECOMMENDED FOR YOU',
                    style: TextStyle(
                      color: MuseColors.cyanGlow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: MuseColors.cyanGlow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      recommendation.tag,
                      style: const TextStyle(
                        color: MuseColors.cyanGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MuseSpacing.sm),

              // Hero Card
              MuseCard(
                borderColor: recommendation.mode.accentColor.withValues(alpha: 0.6),
                backgroundColor: const Color(0xFF131D2A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: recommendation.mode.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: recommendation.mode.accentColor.withValues(alpha: 0.35),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              recommendation.mode.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: MuseSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation.mode.displayName,
                                style: const TextStyle(
                                  color: MuseColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 14, color: MuseColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${recommendation.durationMinutes} Minutes • Guided Session',
                                    style: const TextStyle(
                                      color: MuseColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuseSpacing.md),

                    // Explanation Box
                    Container(
                      padding: const EdgeInsets.all(MuseSpacing.sm),
                      decoration: BoxDecoration(
                        color: MuseColors.cardSurface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                        border: Border.all(color: MuseColors.cardBorder.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 16, color: MuseColors.amberGlow),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recommendation.reason,
                              style: const TextStyle(
                                color: MuseColors.textSecondary,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MuseSpacing.lg),

                    // Prominent Start Button
                    MuseButton(
                      label: 'Start ${recommendation.durationMinutes}-Min Practice',
                      icon: Icons.play_arrow,
                      width: double.infinity,
                      onPressed: () => _startSessionWith(
                        mode: recommendation.mode,
                        durationMinutes: recommendation.durationMinutes,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Recommendation {
  final ExperienceMode mode;
  final int durationMinutes;
  final String tag;
  final String reason;

  const _Recommendation({
    required this.mode,
    required this.durationMinutes,
    required this.tag,
    required this.reason,
  });
}
