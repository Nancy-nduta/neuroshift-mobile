import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/muse_colors.dart';
import '../../models/sensor_status.dart';

/// Accurate 5-sensor Muse 2 Horseshoe Fit & Stability Indicator Widget.
///
/// Reflects the 5 physical sensor contact regions on the Muse 2 headband:
/// 1. TP9: Left Ear (Mastoid clip)
/// 2. AF7: Left Forehead (Frontal EEG)
/// 3. FPz: Center Forehead (Reference EEG & Optical Pulse/PPG)
/// 4. AF8: Right Forehead (Frontal EEG)
/// 5. TP10: Right Ear (Mastoid clip)
///
/// Sensors illuminate solid VIBRANT GREEN when good skin contact is established,
/// and require continuous stability before unlocking clean readings.
class HorseshoeFitWidget extends StatelessWidget {
  final HorseshoeFit fit;
  final double size;
  final bool showLabels;

  const HorseshoeFitWidget({
    super.key,
    required this.fit,
    this.size = 220,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 0.78,
          child: CustomPaint(
            painter: _Muse2HorseshoePainter(fit: fit),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: size * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fit.isStable) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        color: MuseColors.fitGood,
                        size: size * 0.16,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '100%',
                        style: TextStyle(
                          color: MuseColors.fitGood,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.11,
                        ),
                      ),
                      Text(
                        'SIGNAL STABLE',
                        style: TextStyle(
                          color: MuseColors.fitGood,
                          fontSize: size * 0.052,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'READY',
                        style: TextStyle(
                          color: MuseColors.fitGood.withValues(alpha: 0.8),
                          fontSize: size * 0.042,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (fit.isAllGood) ...[
                      SizedBox(
                        width: size * 0.14,
                        height: size * 0.14,
                        child: CircularProgressIndicator(
                          value: fit.stabilityScore > 0 ? fit.stabilityScore : null,
                          strokeWidth: 3.5,
                          backgroundColor: MuseColors.cardBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(MuseColors.fitGood),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(fit.stabilityScore * 100).toInt()}%',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.09,
                        ),
                      ),
                      Text(
                        'STABILIZING',
                        style: TextStyle(
                          color: MuseColors.amberGlow,
                          fontSize: size * 0.05,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'HOLD STILL',
                        style: TextStyle(
                          color: MuseColors.textSecondary,
                          fontSize: size * 0.04,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        fit.overallFitPercentage > 0 ? Icons.sensors : Icons.sensors_off,
                        color: fit.overallFitPercentage > 0 ? MuseColors.amberGlow : MuseColors.textMuted,
                        size: size * 0.15,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${fit.overallFitPercentage.toInt()}%',
                        style: TextStyle(
                          color: MuseColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.10,
                        ),
                      ),
                      Text(
                        'FITTING',
                        style: TextStyle(
                          color: MuseColors.textSecondary,
                          fontSize: size * 0.052,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _SensorLabel(label: 'TP9 (L Ear)', quality: fit.tp9),
              _SensorLabel(label: 'AF7 (L Front)', quality: fit.af7),
              _SensorLabel(label: 'FPz (Center/Pulse)', quality: fit.fpz),
              _SensorLabel(label: 'AF8 (R Front)', quality: fit.af8),
              _SensorLabel(label: 'TP10 (R Ear)', quality: fit.tp10),
            ],
          ),
        ],
      ],
    );
  }
}

class _SensorLabel extends StatelessWidget {
  final String label;
  final FitQuality quality;

  const _SensorLabel({required this.label, required this.quality});

  @override
  Widget build(BuildContext context) {
    final isGood = quality == FitQuality.good;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: quality.color.withValues(alpha: isGood ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: quality.color.withValues(alpha: isGood ? 0.7 : 0.35),
          width: isGood ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: quality.color,
              shape: BoxShape.circle,
              boxShadow: [
                if (isGood)
                  BoxShadow(
                    color: quality.color.withValues(alpha: 0.8),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isGood ? MuseColors.textPrimary : quality.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Muse2HorseshoePainter extends CustomPainter {
  final HorseshoeFit fit;

  _Muse2HorseshoePainter({required this.fit});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radiusX = size.width * 0.42;
    final radiusY = size.height * 0.68;
    final rect = Rect.fromCenter(center: center, width: radiusX * 2, height: radiusY * 2);

    const startAngle = -math.pi / 2 - 1.35; // ~ -167°
    const sweepAngle = 2.70;               // ~ 154°

    // 1. Draw base headband track
    final bgPaint = Paint()
      ..color = MuseColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    // 2. Draw glow on track when all sensors are good / stable
    if (fit.isAllGood) {
      final glowTrackPaint = Paint()
        ..color = MuseColors.fitGood.withValues(alpha: fit.isStable ? 0.35 : 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(rect, startAngle, sweepAngle, false, glowTrackPaint);

      final activeTrackPaint = Paint()
        ..color = MuseColors.fitGood.withValues(alpha: fit.isStable ? 0.9 : 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, activeTrackPaint);
    }

    // 3. Draw the 5 physical Muse 2 sensors along the arch
    // Angles around the ellipse:
    // Left Ear (TP9)
    _drawSensor(canvas, center, radiusX, radiusY, -math.pi / 2 - 1.25, fit.tp9, 'TP9');
    // Left Forehead (AF7)
    _drawSensor(canvas, center, radiusX, radiusY, -math.pi / 2 - 0.55, fit.af7, 'AF7');
    // Center Forehead (FPz - Reference & PPG Optical Pulse)
    _drawSensor(canvas, center, radiusX, radiusY, -math.pi / 2, fit.fpz, 'FPz');
    // Right Forehead (AF8)
    _drawSensor(canvas, center, radiusX, radiusY, -math.pi / 2 + 0.55, fit.af8, 'AF8');
    // Right Ear (TP10)
    _drawSensor(canvas, center, radiusX, radiusY, -math.pi / 2 + 1.25, fit.tp10, 'TP10');
  }

  void _drawSensor(
    Canvas canvas,
    Offset center,
    double radiusX,
    double radiusY,
    double angle,
    FitQuality quality,
    String label,
  ) {
    final cx = center.dx + radiusX * math.cos(angle);
    final cy = center.dy + radiusY * math.sin(angle);
    final nodeCenter = Offset(cx, cy);

    final isGood = quality == FitQuality.good;

    // Outer Glow
    if (isGood) {
      final glowPaint = Paint()
        ..color = MuseColors.fitGood.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(nodeCenter, 15, glowPaint);
    } else if (quality == FitQuality.adjust) {
      final glowPaint = Paint()
        ..color = MuseColors.fitAdjust.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(nodeCenter, 13, glowPaint);
    }

    // Metallic Sensor Housing Ring
    final housingPaint = Paint()
      ..color = MuseColors.cardSurface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(nodeCenter, 11, housingPaint);

    final housingBorderPaint = Paint()
      ..color = isGood ? MuseColors.fitGood : MuseColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = isGood ? 2.0 : 1.5;
    canvas.drawCircle(nodeCenter, 11, housingBorderPaint);

    // Inner Active Electrode Core Dot
    final corePaint = Paint()
      ..color = quality.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(nodeCenter, 7.5, corePaint);

    // Specular Reflection highlight when green/good
    if (isGood) {
      final specPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - 2.2, cy - 2.2), 2.0, specPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Muse2HorseshoePainter oldDelegate) => true;
}
