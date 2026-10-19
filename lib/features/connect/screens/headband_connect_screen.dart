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
  ConsumerState<HeadbandConnectScreen> createState() => _HeadbandConnectScreenState();
}

class _HeadbandConnectScreenState extends ConsumerState<HeadbandConnectScreen> {
  @override
  Widget build(BuildContext context) {
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
        title: const Text('MUSE 2 HEADBAND'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.link_off, color: MuseColors.roseGlow),
              tooltip: 'Disconnect Headband',
              onPressed: () => museService.disconnect(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MuseSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Live 5-Sensor Muse 2 Horseshoe Fit & Stability Indicator
              Center(
                child: HorseshoeFitWidget(
                  fit: fit,
                  size: 230,
                  showLabels: true,
                ),
              ),
              const SizedBox(height: MuseSpacing.lg),

              // 2. Real-Time Hardware Signal & Stability Feedback Card
              if (isConnected) ...[
                if (fit.isStable) ...[
                  MuseCard(
                    borderColor: MuseColors.fitGood,
                    backgroundColor: MuseColors.fitGood.withValues(alpha: 0.12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified, color: MuseColors.fitGood, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'All 5 Sensors Green & Stable',
                                style: TextStyle(
                                  color: MuseColors.fitGood,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Electrode impedance is calibrated and noise-free. Brainwave (EEG) and heart pulse (PPG) signals are streaming cleanly.',
                          style: TextStyle(
                            color: MuseColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: MuseSpacing.md),
                        MuseButton(
                          label: widget.returnLabel != null
                              ? 'Headband Ready • ${widget.returnLabel}'
                              : 'Headband Ready • Go to Resources',
                          icon: widget.returnLabel != null ? Icons.check : Icons.spa,
                          width: double.infinity,
                          onPressed: () {
                            if (widget.returnLabel != null) {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            } else {
                              final isTherapist = ref.read(isTherapistProvider);
                              final resourcesIndex = isTherapist ? 3 : 2;
                              ref.read(mainNavIndexProvider.notifier).setIndex(resourcesIndex);
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ] else if (fit.isAllGood) ...[
                  MuseCard(
                    borderColor: MuseColors.amberGlow,
                    backgroundColor: MuseColors.amberGlow.withValues(alpha: 0.10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            value: fit.stabilityScore > 0 ? fit.stabilityScore : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(MuseColors.fitGood),
                            backgroundColor: MuseColors.cardBorder,
                          ),
                        ),
                        const SizedBox(width: MuseSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stabilizing Signal (${(fit.stabilityScore * 100).toInt()}%)...',
                                style: const TextStyle(
                                  color: MuseColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'All 5 sensors green. Hold your head still for 2.5s to establish clean baseline readings.',
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
                ] else ...[
                  MuseCard(
                    borderColor: MuseColors.amberGlow.withValues(alpha: 0.6),
                    backgroundColor: MuseColors.cardSurface,
                    child: Row(
                      children: [
                        const Icon(Icons.tune, color: MuseColors.amberGlow, size: 24),
                        const SizedBox(width: MuseSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Adjusting Sensor Contact',
                                style: TextStyle(
                                  color: MuseColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getFitGuidanceText(fit),
                                style: const TextStyle(
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
                ],
                const SizedBox(height: MuseSpacing.md),
              ],

              // 3. Live Hardware Telemetry Diagnostics Card
              MuseCard(
                borderColor: isConnected ? MuseColors.fitGood : MuseColors.cardBorder,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (isConnected ? MuseColors.fitGood : MuseColors.textMuted).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                            color: isConnected ? MuseColors.fitGood : MuseColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: MuseSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected ? (status.deviceName ?? 'Muse 2 Headband') : 'Not Connected',
                                style: const TextStyle(
                                  color: MuseColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isConnected
                                    ? (status.batteryPercent != null
                                        ? 'Battery: ${status.batteryPercent}% • BLE Active'
                                        : 'Connected • Awaiting Telemetry')
                                    : (isScanning ? 'Scanning for nearby headbands...' : 'Turn on your Muse 2 to pair'),
                                style: const TextStyle(
                                  color: MuseColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isConnected) ...[
                      const Divider(color: MuseColors.cardBorder, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TelemetryStat(
                            label: 'Battery',
                            value: status.batteryPercent != null ? '${status.batteryPercent}%' : '--',
                            icon: Icons.battery_charging_full,
                            color: status.batteryPercent != null ? MuseColors.fitGood : MuseColors.textMuted,
                          ),
                          _TelemetryStat(
                            label: 'Signal',
                            value: fit.isStable
                                ? 'Stable'
                                : (fit.isAllGood ? 'Stabilizing' : '${fit.overallFitPercentage.toInt()}%'),
                            icon: fit.isStable ? Icons.verified : Icons.sensors,
                            color: fit.isStable ? MuseColors.fitGood : MuseColors.cyanGlow,
                          ),
                          _TelemetryStat(
                            label: 'Stillness',
                            value: '${status.stillnessScore.toInt()}%',
                            icon: Icons.accessibility_new,
                            color: MuseColors.bodyAmber,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MuseSpacing.lg),

              if (status.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(MuseSpacing.md),
                  decoration: BoxDecoration(
                    color: MuseColors.roseGlow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                    border: Border.all(color: MuseColors.roseGlow.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: MuseColors.roseGlow),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status.errorMessage!,
                          style: const TextStyle(color: MuseColors.roseGlow, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuseSpacing.lg),
              ],

              // 4. Scan BLE Action Button
              MuseButton(
                label: isScanning ? 'Searching...' : (isConnected ? 'Rescan Devices' : 'Scan for Muse 2'),
                icon: isScanning ? null : Icons.search,
                isLoading: isScanning,
                width: double.infinity,
                variant: isConnected ? MuseButtonVariant.outline : MuseButtonVariant.primary,
                onPressed: () {
                  if (isScanning) {
                    museService.stopScan();
                  } else {
                    museService.startScan();
                  }
                },
              ),
              const SizedBox(height: MuseSpacing.xl),

              // 5. Discovered Headbands List
              if (devices.isNotEmpty && !isConnected) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DISCOVERED HEADBANDS (${devices.length})',
                    style: const TextStyle(
                      color: MuseColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.sm),
                ...devices.map((res) {
                  final name = res.device.platformName.isNotEmpty
                      ? res.device.platformName
                      : (res.advertisementData.advName.isNotEmpty ? res.advertisementData.advName : 'Muse Headband');
                  final rssi = res.rssi;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: MuseSpacing.sm),
                    child: MuseCard(
                      padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: MuseSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(Icons.headset, color: MuseColors.cyanGlow),
                          const SizedBox(width: MuseSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: MuseColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Signal: $rssi dBm • ${res.device.remoteId.str}',
                                  style: const TextStyle(
                                    color: MuseColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MuseButton(
                            label: 'Connect',
                            height: 36,
                            onPressed: () => museService.connectToDevice(res.device),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: MuseSpacing.xl),
              ],

              // 6. Fitting Tips Card
              MuseCard(
                backgroundColor: MuseColors.cardSurface.withValues(alpha: 0.5),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: MuseColors.amberGlow, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Fitting Tips for Best Signal',
                          style: TextStyle(
                            color: MuseColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Ear Sensors (TP9, TP10): Tuck hair completely behind your ears so the conductive rubber ear clips touch bare skin.\n'
                      '• Forehead Sensors (AF7, FPz, AF8): Position flat and snug midway above your eyebrows.\n'
                      '• Center Pulse/Ref (FPz): Must make flush contact with forehead skin to measure heart rate pulse and ground EEG.\n'
                      '• If contact is stubborn, moisten sensors slightly with a damp cloth or water.',
                      style: TextStyle(
                        color: MuseColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
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

  String _getFitGuidanceText(HorseshoeFit fit) {
    final needed = <String>[];
    if (fit.tp9 != FitQuality.good) needed.add('Left Ear');
    if (fit.af7 != FitQuality.good) needed.add('Left Forehead');
    if (fit.fpz != FitQuality.good) needed.add('Center Forehead');
    if (fit.af8 != FitQuality.good) needed.add('Right Forehead');
    if (fit.tp10 != FitQuality.good) needed.add('Right Ear');

    if (needed.isEmpty) return 'Hold still to complete stability calibration.';
    return 'Adjust ${needed.join(', ')}: ensure firm contact with bare skin.';
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
