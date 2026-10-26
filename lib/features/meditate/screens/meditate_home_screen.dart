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
import '../../../services/notifications/notification_service.dart';
import '../../connect/screens/headband_connect_screen.dart';
import '../../resources/models/resource_evaluation.dart';
import '../../resources/models/resource_item.dart';
import '../../resources/providers/resource_ranking_provider.dart';
import '../../resources/screens/resource_practice_screen.dart';
import '../widgets/how_it_works_card.dart';
import 'live_meditation_screen.dart';

class MeditateHomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenConnectTab;

  const MeditateHomeScreen({super.key, this.onOpenConnectTab});

  @override
  ConsumerState<MeditateHomeScreen> createState() => _MeditateHomeScreenState();
}

class _MeditateHomeScreenState extends ConsumerState<MeditateHomeScreen> {
  int _selectedDuration = 5;

  ResourceItem _resourceForMode(ExperienceMode mode, int durationMinutes) {
    final ranked = ref.read(rankedResourcesProvider);
    final evaluations = ref.read(resourceRankingsProvider);

    final defaultId = switch (mode.type) {
      ExperienceType.mind => durationMinutes <= 5 ? 'med_01' : 'med_02',
      ExperienceType.heart => 'med_03',
      ExperienceType.breath => 'med_05',
      ExperienceType.body => 'med_04',
      ExperienceType.soundscape => 'rain_01',
    };

    // If the default item was explicitly disliked or demoted by RL, pick the highest-ranked matching item
    final defaultEval = evaluations[defaultId];
    if (defaultEval != null && (!defaultEval.wouldUseAgain || defaultEval.performanceScore < 55)) {
      final matchingCategory = mode.type == ExperienceType.soundscape
          ? ranked.where((r) => r.category != ResourceCategory.guidedMeditation).toList()
          : ranked.where((r) => r.category == ResourceCategory.guidedMeditation && r.id != defaultId).toList();
      if (matchingCategory.isNotEmpty) {
        return matchingCategory.first;
      }
    }

    if (mode.type == ExperienceType.soundscape && evaluations.isNotEmpty) {
      final bestSoundscape = ranked
          .where((r) => r.category != ResourceCategory.guidedMeditation)
          .toList();
      if (bestSoundscape.isNotEmpty) {
        return bestSoundscape.first;
      }
    }

    return ResourceItem.catalog.firstWhere(
      (r) => r.id == defaultId,
      orElse: () => ranked.first,
    );
  }

  void _startSessionWith({
    required ExperienceMode mode,
    required int durationMinutes,
  }) {
    final status =
        ref.read(headbandStatusProvider).value ?? const HeadbandStatus();

    if (!status.isConnected) {
      final resource = _resourceForMode(mode, durationMinutes);
      showModalBottomSheet(
        context: context,
        backgroundColor: MuseColors.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(MuseSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: MuseSpacing.md),
                    decoration: BoxDecoration(
                      color: MuseColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: MuseColors.bodyAmber.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sensors_rounded,
                      size: 26,
                      color: MuseColors.bodyAmber,
                    ),
                  ),
                  const SizedBox(height: MuseSpacing.md),
                  const Text(
                    'Sensor Required for Live Tracking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'To record your brainwaves, heart rate, and stillness for ${mode.displayName}, please connect your Muse 2 sensor first — or proceed without a sensor to watch "${resource.title}".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: MuseColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: MuseSpacing.lg),
                  MuseButton(
                    label: 'Connect Sensor to Track',
                    icon: Icons.bluetooth_searching_rounded,
                    variant: MuseButtonVariant.primary,
                    width: double.infinity,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (widget.onOpenConnectTab != null) {
                        widget.onOpenConnectTab!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HeadbandConnectScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: MuseSpacing.sm),
                  MuseButton(
                    label: 'Proceed Without Sensor (Watch Resource)',
                    icon: Icons.play_circle_outline_rounded,
                    variant: MuseButtonVariant.outline,
                    width: double.infinity,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResourcePracticeScreen(
                            resource: resource,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    _launchLiveScreen(mode: mode, durationMinutes: durationMinutes);
  }

  void _launchLiveScreen({
    required ExperienceMode mode,
    required int durationMinutes,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveMeditationScreen(
          mode: mode,
          durationMinutes: durationMinutes,
        ),
      ),
    );
  }

  List<ResourceItem> _recommendResourcesForMode(ExperienceMode mode) {
    final ranked = ref.read(rankedResourcesProvider);
    switch (mode.type) {
      case ExperienceType.mind:
        return ranked.where((r) =>
          r.id == 'med_01' ||
          r.id == 'med_02' ||
          r.id == 'med_05' ||
          r.id == 'noise_01' ||
          r.id == 'piano_01'
        ).toList();
      case ExperienceType.heart:
        return ranked.where((r) =>
          r.id == 'med_03' ||
          r.id == 'piano_01' ||
          r.id == 'piano_02' ||
          r.id == 'piano_03' ||
          r.id == 'nature_01'
        ).toList();
      case ExperienceType.body:
        return ranked.where((r) =>
          r.id == 'med_04' ||
          r.id == 'med_03' ||
          r.id == 'rain_03' ||
          r.id == 'nature_04'
        ).toList();
      case ExperienceType.breath:
        return ranked.where((r) =>
          r.id == 'med_02' ||
          r.id == 'med_05' ||
          r.id == 'rain_04' ||
          r.id == 'noise_03'
        ).toList();
      case ExperienceType.soundscape:
        return ranked.where((r) =>
          r.category != ResourceCategory.guidedMeditation
        ).toList();
    }
  }

  void _showPracticeRecommendationsModal(ExperienceMode mode) {
    final recommendations = _recommendResourcesForMode(mode);

    showModalBottomSheet(
      context: context,
      backgroundColor: MuseColors.cardSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: MuseColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: mode.gradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(mode.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: MuseSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.displayName,
                                style: const TextStyle(
                                  color: MuseColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mode.subtitle,
                                style: const TextStyle(
                                  color: MuseColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: MuseColors.textSecondary),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: MuseColors.cardBorder, height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommended Guided Practices',
                          style: TextStyle(
                            color: MuseColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${recommendations.length} sessions',
                          style: const TextStyle(
                            color: MuseColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.lg),
                      itemCount: recommendations.length,
                      itemBuilder: (context, index) {
                        final item = recommendations[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ResourcePracticeScreen(resource: item),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: MuseColors.spaceBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: mode.accentColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.thumbnailUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 60,
                                        height: 60,
                                        color: mode.accentColor.withValues(alpha: 0.15),
                                        child: Icon(mode.icon, color: mode.accentColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: MuseColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              item.durationLabel,
                                              style: TextStyle(
                                                color: mode.accentColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text('•', style: TextStyle(color: MuseColors.textMuted, fontSize: 11)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item.author,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: MuseColors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: mode.accentColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.play_arrow_rounded, color: mode.accentColor, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(MuseSpacing.lg, 8, MuseSpacing.lg, MuseSpacing.md),
                    child: Column(
                      children: [
                        MuseButton(
                          label: 'Or Start Free-Form Timer ($_selectedDuration min)',
                          icon: Icons.timer_outlined,
                          variant: MuseButtonVariant.outline,
                          width: double.infinity,
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _startSessionWith(
                              mode: mode,
                              durationMinutes: _selectedDuration,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  _Recommendation _computeRecommendation(
    List<MeditationSession> sessions,
    Map<String, ResourceEvaluation> evaluations,
  ) {
    // 1. If the user has recent RL feedback evaluations (with or without sensor),
    // use the Contextual Bandit policy directly for personalized recommendations!
    if (evaluations.isNotEmpty) {
      final sortedEvals = evaluations.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestEval = sortedEvals.first;
      final rlRec = ref
          .read(resourceRankingsProvider.notifier)
          .recommendFromEvaluation(latestEval);

      final recommendedMode = switch (rlRec.suggestedPracticeMode.toLowerCase()) {
        'heart' => ExperienceMode.heart,
        'breath' => ExperienceMode.breath,
        'body' => ExperienceMode.body,
        'soundscape' => ExperienceMode.soundscape,
        _ => ExperienceMode.mind,
      };

      return _Recommendation(
        mode: recommendedMode,
        durationMinutes: _selectedDuration,
        tag: latestEval.usedHeadband ? 'RL + Sensor Match' : 'RL Adaptive Pick',
        reason: rlRec.policyReason,
      );
    }

    if (sessions.isEmpty) {
      return const _Recommendation(
        mode: ExperienceMode.mind,
        durationMinutes: 3,
        tag: 'Recommended',
        reason: 'A gentle 3-minute session to settle your thoughts and unwind.',
      );
    }

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
        durationMinutes: _selectedDuration,
        tag: 'Best Match',
        reason:
            'Your previous ${bestSession.mode.displayName} session reached ${maxCalm.toStringAsFixed(0)}% calm.',
      );
    }

    final latest = sessions.first;
    final nextMode = switch (latest.mode.type) {
      ExperienceType.mind => ExperienceMode.heart,
      ExperienceType.heart => ExperienceMode.breath,
      ExperienceType.breath => ExperienceMode.body,
      ExperienceType.body => ExperienceMode.soundscape,
      ExperienceType.soundscape => ExperienceMode.mind,
    };

    return _Recommendation(
      mode: nextMode,
      durationMinutes: _selectedDuration,
      tag: 'Today\'s Pick',
      reason: 'A refreshing shift into ${nextMode.subtitle.toLowerCase()}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    final authUser = ref.watch(authStateProvider).value;
    final sessionsAsync = ref.watch(userSessionsProvider);
    final sessions = sessionsAsync.value ?? [];
    final evaluations = ref.watch(resourceRankingsProvider);

    final displayName = user?.displayName ??
        (authUser?.email != null
            ? authUser!.email!.split('@').first
            : 'Friend');
    final streak = user?.streakDays ?? 0;
    final recommendation = _computeRecommendation(sessions, evaluations);

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text(
          'NeuroShift',
          style: TextStyle(
            letterSpacing: 0.6,
            fontSize: 19,
            fontWeight: FontWeight.w700,
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
                color: MuseColors.amberGlow.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: MuseColors.amberGlow, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '${streak}d',
                    style: const TextStyle(
                      color: MuseColors.amberGlow,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          const NotificationBellButton(),
          Padding(
            padding: const EdgeInsets.only(right: MuseSpacing.md),
            child: HeadbandStatusPill(
              onTap: () {
                if (widget.onOpenConnectTab != null) {
                  widget.onOpenConnectTab!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const HeadbandConnectScreen()),
                  );
                }
              },
            ),
          ),
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
              // Clean Greeting
              Text(
                '${_getTimeGreeting()}, $displayName',
                style: const TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Take a few minutes to reset and recharge.',
                style: TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: MuseSpacing.lg),

              // 1. Hero Recommended Session Card
              MuseCard(
                borderColor: recommendation.mode.accentColor,
                backgroundColor: const Color(0xFF141E30),
                padding: const EdgeInsets.all(MuseSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: recommendation.mode.accentColor
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            recommendation.tag,
                            style: TextStyle(
                              color: recommendation.mode.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Duration Quick Selector Pills
                        Row(
                          children: [3, 5, 10].map((mins) {
                            final selected = _selectedDuration == mins;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedDuration = mins),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? MuseColors.cyanGlow
                                            .withValues(alpha: 0.2)
                                        : MuseColors.spaceBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? MuseColors.cyanGlow
                                          : MuseColors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    '${mins}m',
                                    style: TextStyle(
                                      color: selected
                                          ? MuseColors.cyanGlow
                                          : MuseColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: selected
                                          ? FontWeight.bold
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
                    const SizedBox(height: MuseSpacing.md),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: recommendation.mode.gradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            recommendation.mode.icon,
                            color: Colors.white,
                            size: 26,
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
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                recommendation.reason,
                                style: const TextStyle(
                                  color: MuseColors.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuseSpacing.lg),
                    MuseButton(
                      label: 'Start $_selectedDuration-Min Session',
                      icon: Icons.play_arrow_rounded,
                      width: double.infinity,
                      onPressed: () => _startSessionWith(
                        mode: recommendation.mode,
                        durationMinutes: _selectedDuration,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.xl),

              // 2. Choose a Practice Mode
              const Text(
                'Choose a Practice',
                style: TextStyle(
                  color: MuseColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MuseSpacing.sm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: ExperienceMode.values.map((mode) {
                  return MuseCard(
                    padding: const EdgeInsets.all(14),
                    borderColor: mode.accentColor.withValues(alpha: 0.35),
                    onTap: () => _showPracticeRecommendationsModal(mode),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: mode.accentColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                mode.icon,
                                color: mode.accentColor,
                                size: 18,
                              ),
                            ),
                            Text(
                              '$_selectedDuration min',
                              style: const TextStyle(
                                color: MuseColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mode.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: MuseColors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              mode.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: MuseColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: MuseSpacing.lg),

              // 3. Compact, collapsible Quick Start Guide at bottom
              HowItWorksCard(
                onConnectTapped: () {
                  if (widget.onOpenConnectTab != null) {
                    widget.onOpenConnectTab!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HeadbandConnectScreen()),
                    );
                  }
                },
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
