import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/muse_colors.dart';
import '../../models/sensor_status.dart';

class HeadbandStatusPill extends ConsumerWidget {
  final VoidCallback? onTap;

  const HeadbandStatusPill({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(headbandStatusProvider);
    final status = statusAsync.value ?? const HeadbandStatus();

    final isConnected = status.isConnected;
    final isStreaming = status.isStreaming;
    final isScanning = status.connectionState == ConnectionStateEnum.scanning;
    final isConnecting = status.connectionState == ConnectionStateEnum.connecting;

    Color pillBorderColor = MuseColors.cardBorder;
    Color dotColor = MuseColors.textMuted;
    String text = 'Connect Muse';

    if (isStreaming) {
      pillBorderColor = MuseColors.cyanGlow;
      dotColor = MuseColors.cyanGlow;
      text = 'Streaming';
    } else if (isConnected) {
      pillBorderColor = MuseColors.fitGood;
      dotColor = MuseColors.fitGood;
      text = status.batteryPercent != null ? '${status.batteryPercent}%' : 'Connected';
    } else if (isScanning || isConnecting) {
      pillBorderColor = MuseColors.amberGlow;
      dotColor = MuseColors.amberGlow;
      text = isScanning ? 'Scanning...' : 'Pairing...';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: MuseColors.cardSurface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pillBorderColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isConnected || isStreaming)
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isConnected ? MuseColors.textPrimary : MuseColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (status.batteryPercent != null) ...[
              const SizedBox(width: 4),
              Icon(
                status.batteryPercent! > 20 ? Icons.battery_full : Icons.battery_alert,
                size: 14,
                color: status.batteryPercent! > 20 ? MuseColors.fitGood : MuseColors.roseGlow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
