import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/horseshoe_fit_widget.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/sensor_status.dart';

class HeadbandConnectScreen extends ConsumerStatefulWidget {
  final String? returnLabel;

  const HeadbandConnectScreen({
    super.key,
    this.returnLabel,
  });

  @override
  ConsumerState<HeadbandConnectScreen> createState() =>
      _HeadbandConnectScreenState();
}

class _HeadbandConnectScreenState extends ConsumerState<HeadbandConnectScreen> {
  @override
  Widget build(BuildContext context) {
    // Notify user on pairing and fit stabilization without prematurely redirecting
    ref.listen<AsyncValue<HeadbandStatus>>(headbandStatusProvider, (prev, next) {
      final wasConnected = prev?.value?.isConnected ?? false;
      final isNowConnected = next.value?.isConnected ?? false;
      if (!wasConnected && isNowConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Headband connected! Place on your head to check sensor fit.'),
            duration: Duration(seconds: 3),
            backgroundColor: MuseColors.cardSurface,
          ),
        );
      }

      final wasStable = prev?.value?.fit.isStable ?? false;
      final isNowStable = next.value?.fit.isStable ?? false;
      if (!wasStable && isNowStable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Good sensor fit confirmed! You are ready to begin.'),
            duration: Duration(seconds: 2),
            backgroundColor: MuseColors.cardSurface,
          ),
        );
      }
    });

    final statusAsync = ref.watch(headbandStatusProvider);
    final status = statusAsync.value ?? const HeadbandStatus();
    final devicesAsync = ref.watch(discoveredDevicesProvider);
    final devices = devicesAsync.value ?? [];
    final museService = ref.read(museServiceProvider);

    final isConnected = status.isConnected;
    final isScanning = status.connectionState == ConnectionStateEnum.scanning;
    final fit = status.fit;

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text(
          'Headband',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MuseColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.link_off, color: MuseColors.roseGlow),
              tooltip: 'Disconnect',
              onPressed: () => museService.disconnect(),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Sensor Fit Ring
              Center(
                child: HorseshoeFitWidget(
                  fit: fit,
                  size: 210,
                  showLabels: true,
                ),
              ),
              const SizedBox(height: MuseSpacing.lg),

              // 2. Clean Status Card
              MuseCard(
                borderColor:
                    isConnected ? MuseColors.fitGood : MuseColors.cardBorder,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (isConnected
                                    ? MuseColors.fitGood
                                    : MuseColors.textMuted)
                                .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth,
                            color: isConnected
                                ? MuseColors.fitGood
                                : MuseColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: MuseSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected
                                    ? (status.deviceName ?? 'Muse 2 Connected')
                                    : 'No Headband Connected',
                                style: const TextStyle(
                                  color: MuseColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isConnected
                                    ? (fit.isStable
                                        ? 'Good sensor fit • Ready for practice'
                                        : _getFitGuidanceText(fit))
                                    : (isScanning
                                        ? 'Looking for nearby headbands...'
                                        : 'Turn on your Muse 2 headband to pair'),
                                style: const TextStyle(
                                  color: MuseColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isConnected) ...[
                      const Divider(color: MuseColors.cardBorder, height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TelemetryStat(
                            label: 'Battery',
                            value: status.batteryPercent != null
                                ? '${status.batteryPercent}%'
                                : '--',
                            icon: Icons.battery_charging_full,
                            color: MuseColors.fitGood,
                          ),
                          _TelemetryStat(
                            label: 'Fit',
                            value: '${fit.overallFitPercentage.toInt()}%',
                            icon: Icons.sensors,
                            color: fit.isStable
                                ? MuseColors.fitGood
                                : MuseColors.cyanGlow,
                          ),
                          _TelemetryStat(
                            label: 'Stillness',
                            value: '${status.stillnessScore.toInt()}%',
                            icon: Icons.accessibility_new,
                            color: MuseColors.bodyAmber,
                          ),
                        ],
                      ),
                      const SizedBox(height: MuseSpacing.md),
                      MuseButton(
                        label: fit.isStable
                            ? (widget.returnLabel ?? 'Continue to Resources')
                            : 'Place Headband on Head to Continue',
                        icon: fit.isStable
                            ? Icons.check_circle_outline
                            : Icons.sensors,
                        variant: fit.isStable
                            ? MuseButtonVariant.primary
                            : MuseButtonVariant.outline,
                        width: double.infinity,
                        onPressed: fit.isStable ? _proceedToDestination : null,
                      ),
                      if (!fit.isStable) ...[
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _proceedToDestination,
                          child: const Text(
                            'Skip fit check & continue',
                            style: TextStyle(
                              color: MuseColors.textMuted,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.md),

              if (status.errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: MuseSpacing.md),
                  child: Text(
                    status.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: MuseColors.roseGlow, fontSize: 12.5),
                  ),
                ),
              ],

              // 3. Scan Action Button
              MuseButton(
                label: isScanning
                    ? 'Stop Scanning'
                    : (isConnected ? 'Scan Again' : 'Find My Headband'),
                icon: isScanning ? null : Icons.search,
                isLoading: isScanning,
                width: double.infinity,
                variant: isConnected
                    ? MuseButtonVariant.outline
                    : MuseButtonVariant.primary,
                onPressed: () {
                  if (isScanning) {
                    museService.stopScan();
                  } else {
                    museService.startScan();
                  }
                },
              ),
              const SizedBox(height: MuseSpacing.lg),

              // 4. Discovered Headbands List
              if (devices.isNotEmpty && !isConnected) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nearby Headbands',
                    style: TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.sm),
                ...devices.map((res) {
                  final name = res.device.platformName.isNotEmpty
                      ? res.device.platformName
                      : (res.advertisementData.advName.isNotEmpty
                          ? res.advertisementData.advName
                          : 'Muse Headband');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: MuseSpacing.sm),
                    child: MuseCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: MuseSpacing.md, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.headphones,
                              color: MuseColors.cyanGlow, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: MuseColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          MuseButton(
                            label: 'Connect',
                            height: 36,
                            onPressed: () =>
                                museService.connectToDevice(res.device),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: MuseSpacing.md),
              ],

              // 5. Simple Fit Tip Card
              MuseCard(
                padding: const EdgeInsets.all(14),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: MuseColors.amberGlow, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Tuck hair behind your ears and rest the band snug across the middle of your forehead.',
                        style: TextStyle(
                          color: MuseColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
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

  void _proceedToDestination() {
    final isTherapist = ref.read(isTherapistProvider);
    final resourcesTabIndex = isTherapist ? 3 : 2;
    ref.read(mainNavIndexProvider.notifier).setIndex(resourcesTabIndex);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _getFitGuidanceText(HorseshoeFit fit) {
    final needed = <String>[];
    if (fit.tp9 != FitQuality.good) needed.add('left ear');
    if (fit.af7 != FitQuality.good) needed.add('left forehead');
    if (fit.fpz != FitQuality.good) needed.add('center forehead');
    if (fit.af8 != FitQuality.good) needed.add('right forehead');
    if (fit.tp10 != FitQuality.good) needed.add('right ear');

    if (needed.isEmpty) return 'Hold still for a moment to lock signal...';
    return 'Gently adjust ${needed.join(', ')} for clearer contact.';
  }
}

class _TelemetryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TelemetryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: MuseColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
