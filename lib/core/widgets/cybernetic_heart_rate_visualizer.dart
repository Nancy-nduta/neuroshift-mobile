import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/muse_colors.dart';
import '../theme/muse_spacing.dart';

/// Futuristic Holographic ECG Cardio Waveform & Heart Telemetry HUD
class CyberneticHeartRateVisualizer extends StatefulWidget {
  final int? heartRateBpm;
  final double? hrvRmssd;
  final bool isConnected;

  const CyberneticHeartRateVisualizer({
    super.key,
    required this.heartRateBpm,
    this.hrvRmssd,
    this.isConnected = true,
  });

  @override
  State<CyberneticHeartRateVisualizer> createState() =>
      _CyberneticHeartRateVisualizerState();
}

class _CyberneticHeartRateVisualizerState
    extends State<CyberneticHeartRateVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _ecgSweepController;
  late final AnimationController _cardioPulseController;

  @override
  void initState() {
    super.initState();

    // ECG trace sweep (takes ~1.8 seconds per sweep cycle)
    _ecgSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Pulse controller synchronized to heart rate (default 72 BPM -> 833ms per beat)
    final bpm = (widget.heartRateBpm != null && widget.heartRateBpm! > 0)
        ? widget.heartRateBpm!
        : 72;
    final beatMs = (60000 / bpm).round().clamp(400, 1500);

    _cardioPulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: beatMs),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CyberneticHeartRateVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heartRateBpm != oldWidget.heartRateBpm &&
        widget.heartRateBpm != null &&
        widget.heartRateBpm! > 0) {
      final beatMs = (60000 / widget.heartRateBpm!).round().clamp(400, 1500);
      _cardioPulseController.duration = Duration(milliseconds: beatMs);
      if (!_cardioPulseController.isAnimating) {
        _cardioPulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ecgSweepController.dispose();
    _cardioPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBpm = widget.heartRateBpm ?? 0;
    final hasValidBpm = widget.isConnected && effectiveBpm > 0;
    final displayBpm = hasValidBpm ? '$effectiveBpm' : '--';

    // RR interval estimation in milliseconds
    final pulseIntervalMs = hasValidBpm ? (60000 / effectiveBpm).round() : 0;

    // Autonomic state determination from RMSSD
    final rmssd = widget.hrvRmssd ?? 45.0;
    final String ansLabel;
    final Color ansColor;
    if (!hasValidBpm) {
      ansLabel = 'MEASURING CARDIAC CADENCE...';
      ansColor = MuseColors.textSecondary;
    } else if (rmssd >= 55.0) {
      ansLabel = 'PARASYMPATHETIC (DEEP VAGAL TONE)';
      ansColor = const Color(0xFF00FFB2); // Emerald Mint
    } else if (rmssd >= 35.0) {
      ansLabel = 'BALANCED AUTONOMIC HOMEOSTASIS';
      ansColor = const Color(0xFF00E5FF); // Electric Cyan
    } else {
      ansLabel = 'SYMPATHETIC ELEVATION (ACTIVE)';
      ansColor = const Color(0xFFFF5252); // Alert Coral
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(MuseSpacing.radiusLg),
        border: Border.all(
          color: const Color(0xFFFF2A6D).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2A6D).withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MuseSpacing.md,
              vertical: MuseSpacing.sm,
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _cardioPulseController,
                  builder: (context, child) {
                    final scale = 0.85 + (_cardioPulseController.value * 0.3);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF2A6D),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A6D).withValues(alpha: 0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'CARDIAC COHERENCE & PPG ECG',
                  style: TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2A6D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hasValidBpm ? 'PPG LOCKED' : 'CALIBRATING',
                    style: TextStyle(
                      color: hasValidBpm ? const Color(0xFFFF2A6D) : MuseColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Autonomic Status Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: ansColor.withValues(alpha: 0.1),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: ansColor.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite_border, color: ansColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  'STATE: ',
                  style: TextStyle(
                    color: ansColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Expanded(
                  child: Text(
                    ansLabel,
                    style: const TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Real-time ECG Trace Oscilloscope Screen
          Padding(
            padding: const EdgeInsets.all(MuseSpacing.md),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _ecgSweepController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CyberneticEcgPainter(
                      progress: _ecgSweepController.value,
                      hasSignal: hasValidBpm,
                      bpm: effectiveBpm,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),

          // Telemetry Readout Grid Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MuseSpacing.md,
              0,
              MuseSpacing.md,
              MuseSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Heart Rate
                _buildTelemetryBox(
                  label: 'HEART RATE',
                  value: displayBpm,
                  unit: 'BPM',
                  icon: Icons.favorite,
                  accentColor: const Color(0xFFFF2A6D),
                ),
                // Pulse Interval
                _buildTelemetryBox(
                  label: 'R-R INTERVAL',
                  value: pulseIntervalMs > 0 ? '$pulseIntervalMs' : '--',
                  unit: 'ms',
                  icon: Icons.timer,
                  accentColor: const Color(0xFF00E5FF),
                ),
                // HRV RMSSD
                _buildTelemetryBox(
                  label: 'HRV RMSSD',
                  value: rmssd > 0 ? rmssd.toStringAsFixed(0) : '--',
                  unit: 'ms',
                  icon: Icons.graphic_eq,
                  accentColor: const Color(0xFF00FFB2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBox({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: 11),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: MuseColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter that renders an authentic P-Q-R-S-T medical cardiac ECG waveform
class _CyberneticEcgPainter extends CustomPainter {
  final double progress;
  final bool hasSignal;
  final int bpm;

  _CyberneticEcgPainter({
    required this.progress,
    required this.hasSignal,
    required this.bpm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawMedicalGrid(canvas, size);

    final midY = size.height * 0.52;
    final sweepX = progress * size.width;

    // Build authentic P-Q-R-S-T cardiac waveform
    final path = Path();
    final glowPath = Path();

    // 2 cardiac cycles across width
    final cycleWidth = size.width / 2.0;

    for (double x = 0; x <= size.width; x += 1.5) {
      final cyclePos = (x % cycleWidth) / cycleWidth; // 0.0 to 1.0 within a heartbeat

      double dy = 0.0;

      // Authentic physiological ECG segments:
      // P wave (atrial depolarization) ~ 0.15 - 0.25
      if (cyclePos >= 0.15 && cyclePos <= 0.25) {
        final pNorm = (cyclePos - 0.15) / 0.10;
        dy = -math.sin(pNorm * math.pi) * 8.0;
      }
      // Q wave (septal depolarization) ~ 0.32 - 0.35
      else if (cyclePos > 0.32 && cyclePos <= 0.35) {
        final qNorm = (cyclePos - 0.32) / 0.03;
        dy = math.sin(qNorm * math.pi) * 6.0;
      }
      // R wave (ventricular depolarization peak) ~ 0.35 - 0.40
      else if (cyclePos > 0.35 && cyclePos <= 0.40) {
        final rNorm = (cyclePos - 0.35) / 0.05;
        dy = -math.sin(rNorm * math.pi) * 44.0;
      }
      // S wave (ventricular late depolarization) ~ 0.40 - 0.44
      else if (cyclePos > 0.40 && cyclePos <= 0.44) {
        final sNorm = (cyclePos - 0.40) / 0.04;
        dy = math.sin(sNorm * math.pi) * 12.0;
      }
      // T wave (ventricular repolarization) ~ 0.52 - 0.68
      else if (cyclePos >= 0.52 && cyclePos <= 0.68) {
        final tNorm = (cyclePos - 0.52) / 0.16;
        dy = -math.sin(tNorm * math.pi) * 14.0;
      }

      // Add slight biological noise / baseline variation
      final noise = math.sin(x * 0.1 + progress * 4.0) * 0.8;
      final y = midY + dy + noise;

      if (x == 0) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    // Phosphor glow behind the trace
    final glowPaint = Paint()
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.25)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(glowPath, glowPaint);

    // Crisp neon foreground line
    final linePaint = Paint()
      ..color = const Color(0xFFFF2A6D)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Glowing tracer head dot at current sweep position
    final tracerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final tracerGlowPaint = Paint()
      ..color = const Color(0xFFFF2A6D)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Sample Y at current sweepX
    final cyclePosSweep = (sweepX % cycleWidth) / cycleWidth;
    double sweepY = midY;
    if (cyclePosSweep >= 0.15 && cyclePosSweep <= 0.25) {
      sweepY -= math.sin(((cyclePosSweep - 0.15) / 0.10) * math.pi) * 8.0;
    } else if (cyclePosSweep > 0.32 && cyclePosSweep <= 0.35) {
      sweepY += math.sin(((cyclePosSweep - 0.32) / 0.03) * math.pi) * 6.0;
    } else if (cyclePosSweep > 0.35 && cyclePosSweep <= 0.40) {
      sweepY -= math.sin(((cyclePosSweep - 0.35) / 0.05) * math.pi) * 44.0;
    } else if (cyclePosSweep > 0.40 && cyclePosSweep <= 0.44) {
      sweepY += math.sin(((cyclePosSweep - 0.40) / 0.04) * math.pi) * 12.0;
    } else if (cyclePosSweep >= 0.52 && cyclePosSweep <= 0.68) {
      sweepY -= math.sin(((cyclePosSweep - 0.52) / 0.16) * math.pi) * 14.0;
    }

    canvas.drawCircle(Offset(sweepX, sweepY), 6.0, tracerGlowPaint);
    canvas.drawCircle(Offset(sweepX, sweepY), 2.8, tracerPaint);

    // Scanning sweep shadow line
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF090D16).withValues(alpha: 0.9),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(sweepX, 0, 30, size.height));
    canvas.drawRect(Rect.fromLTWH(sweepX, 0, 30, size.height), scanPaint);
  }

  void _drawMedicalGrid(Canvas canvas, Size size) {
    final majorGridPaint = Paint()
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.1)
      ..strokeWidth = 0.8;

    final minorGridPaint = Paint()
      ..color = const Color(0xFF1B283E).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Minor grid (every 10px)
    for (double x = 0; x <= size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorGridPaint);
    }
    for (double y = 0; y <= size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorGridPaint);
    }

    // Major grid (every 48px)
    for (double x = 0; x <= size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorGridPaint);
    }
    for (double y = 0; y <= size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorGridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberneticEcgPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hasSignal != hasSignal ||
        oldDelegate.bpm != bpm;
  }
}
