import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/muse_colors.dart';
import '../../models/signal_reading.dart';

/// Futuristic, bioluminescent 3D-feeling Neural Reactor / Mind Orb.
///
/// Reacts dynamically at 60 FPS to live EEG brainwave telemetry:
/// - In [MindState.calm]: Blooms into electric cyan & ethereal emerald with gentle orbital rings.
/// - In [MindState.neutral]: Smooth rolling cosmic indigo and deep ocean blue laminar waves.
/// - In [MindState.active]: Energetic neon rose & solar magenta with rapid orbital plasma flares.
/// - Heart pulse reactivity: Outer aura expands subtly in sync with incoming BPM.
/// - Wave power scaling: Inner fluid ripples undulate in proportion to live Alpha microvolts.
class BioluminescentNeuralOrb extends StatefulWidget {
  final MindState mindState;
  final double alphaPower;
  final double betaPower;
  final int? heartRateBpm;
  final double size;
  final String? centerLabel;
  final String? subLabel;
  final bool showTelemetryRings;

  const BioluminescentNeuralOrb({
    super.key,
    required this.mindState,
    this.alphaPower = 0.0,
    this.betaPower = 0.0,
    this.heartRateBpm,
    this.size = 220,
    this.centerLabel,
    this.subLabel,
    this.showTelemetryRings = true,
  });

  @override
  State<BioluminescentNeuralOrb> createState() => _BioluminescentNeuralOrbState();
}

class _BioluminescentNeuralOrbState extends State<BioluminescentNeuralOrb>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();

    // 1. Continuous slow 60 FPS orbital rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    // 2. Heartbeat / breathing pulse animation
    final pulseDurationMs = _calculatePulsePeriod(widget.heartRateBpm);
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: pulseDurationMs),
    )..repeat(reverse: true);

    // 3. Fluid plasma ripple wave controller
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  int _calculatePulsePeriod(int? bpm) {
    if (bpm != null && bpm >= 45 && bpm <= 160) {
      return (60000 / bpm).round();
    }
    return 3600; // Default gentle 3.6s breath cycle
  }

  @override
  void didUpdateWidget(covariant BioluminescentNeuralOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heartRateBpm != widget.heartRateBpm) {
      final newPeriod = _calculatePulsePeriod(widget.heartRateBpm);
      _pulseController.duration = Duration(milliseconds: newPeriod);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getAuraColors(widget.mindState);

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController, _rippleController]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _NeuralOrbPainter(
              rotation: _rotationController.value,
              pulse: _pulseController.value,
              ripple: _rippleController.value,
              primaryColor: colors.primary,
              secondaryColor: colors.secondary,
              ambientColor: colors.ambient,
              alphaPower: widget.alphaPower,
              betaPower: widget.betaPower,
              showRings: widget.showTelemetryRings,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.centerLabel != null)
                    Text(
                      widget.centerLabel!,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: widget.size * 0.085,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        shadows: [
                          Shadow(
                            color: colors.primary.withValues(alpha: 0.8),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  if (widget.subLabel != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.subLabel!,
                        style: TextStyle(
                          color: MuseColors.textSecondary,
                          fontSize: widget.size * 0.045,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _AuraPalette _getAuraColors(MindState state) {
    switch (state) {
      case MindState.calm:
        return const _AuraPalette(
          primary: Color(0xFF00F5FF), // Bioluminescent Neon Cyan
          secondary: Color(0xFF06D6A0), // Luminous Mint Emerald
          ambient: Color(0x3300F5FF),
        );
      case MindState.neutral:
        return const _AuraPalette(
          primary: Color(0xFF9D4EDD), // Cosmic Plasma Violet
          secondary: Color(0xFF3B82F6), // Deep Oceanic Blue
          ambient: Color(0x289D4EDD),
        );
      case MindState.active:
        return const _AuraPalette(
          primary: Color(0xFFFF2A6D), // High-Energy Solar Rose
          secondary: Color(0xFFFFB703), // Kinetic Amber
          ambient: Color(0x33FF2A6D),
        );
    }
  }
}

class _AuraPalette {
  final Color primary;
  final Color secondary;
  final Color ambient;

  const _AuraPalette({
    required this.primary,
    required this.secondary,
    required this.ambient,
  });
}

class _NeuralOrbPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final double ripple;
  final Color primaryColor;
  final Color secondaryColor;
  final Color ambientColor;
  final double alphaPower;
  final double betaPower;
  final bool showRings;

  _NeuralOrbPainter({
    required this.rotation,
    required this.pulse,
    required this.ripple,
    required this.primaryColor,
    required this.secondaryColor,
    required this.ambientColor,
    required this.alphaPower,
    required this.betaPower,
    required this.showRings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.32;

    // Pulse breathing dilation (±5% scale)
    final pulseScale = 0.95 + (pulse * 0.10);
    final coreRadius = baseRadius * pulseScale;

    // 1. Deep Atmospheric Outer Bioluminescent Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.35),
          secondaryColor.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.2, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.55));

    canvas.drawCircle(center, baseRadius * 1.55, glowPaint);

    // 2. Dual Counter-Rotating Cybernetic Orbital Telemetry Rings
    if (showRings) {
      _drawOrbitalRings(canvas, center, baseRadius * 1.30);
    }

    // 3. Fluid Internal Plasma Sphere with Shifting Waves
    _drawPlasmaSphere(canvas, center, coreRadius);

    // 4. Floating Synaptic Energy Particle Nodes
    _drawParticleNodes(canvas, center, baseRadius * 1.15);
  }

  void _drawOrbitalRings(Canvas canvas, Offset center, double radius) {
    // Outer telemetry ring
    final ringPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, ringPaint);

    // Rotating segment arcs (Sci-Fi HUD feel)
    final arcPaint1 = Paint()
      ..color = primaryColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    final arcPaint2 = Paint()
      ..color = secondaryColor.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    final startAngle1 = rotation * 2 * math.pi;
    final startAngle2 = -rotation * 2 * math.pi * 1.4;

    // Draw primary rotating arcs
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle1,
      math.pi * 0.6,
      false,
      arcPaint1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle1 + math.pi,
      math.pi * 0.35,
      false,
      arcPaint1,
    );

    // Draw secondary inner counter-rotating arcs
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.90),
      startAngle2,
      math.pi * 0.5,
      false,
      arcPaint2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.90),
      startAngle2 + math.pi * 1.2,
      math.pi * 0.4,
      false,
      arcPaint2,
    );

    // Precision radial degree ticks
    final tickPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * math.pi;
      final isMajor = i % 6 == 0;
      final innerR = radius - (isMajor ? 6.0 : 3.0);
      final outerR = radius + (isMajor ? 6.0 : 3.0);
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * innerR, center.dy + math.sin(angle) * innerR),
        Offset(center.dx + math.cos(angle) * outerR, center.dy + math.sin(angle) * outerR),
        tickPaint,
      );
    }
  }

  void _drawPlasmaSphere(Canvas canvas, Offset center, double radius) {
    // 3D Glass Sphere Base Gradient
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          Colors.white.withValues(alpha: 0.40),
          primaryColor.withValues(alpha: 0.85),
          secondaryColor.withValues(alpha: 0.60),
          const Color(0xFF050811).withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.45, 0.80, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // Internal Fluid Sine Ripples (Microvolt responsive)
    final ripplePath = Path();
    final waveAmplitude = 3.0 + (alphaPower.clamp(0, 30) * 0.25);
    final numPoints = 64;

    for (int i = 0; i <= numPoints; i++) {
      final angle = (i / numPoints) * 2 * math.pi;
      final offsetR = radius * 0.82 +
          math.sin(angle * 4 + ripple * 2 * math.pi) * waveAmplitude +
          math.cos(angle * 3 - rotation * 2 * math.pi) * (waveAmplitude * 0.7);

      final x = center.dx + math.cos(angle) * offsetR;
      final y = center.dy + math.sin(angle) * offsetR;

      if (i == 0) {
        ripplePath.moveTo(x, y);
      } else {
        ripplePath.lineTo(x, y);
      }
    }
    ripplePath.close();

    final fluidPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(ripplePath, fluidPaint);

    // Specular Highlight (High-tech glass sheen)
    final specularPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.45),
        colors: [
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.7],
      ).createShader(Rect.fromCircle(
        center: Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
        radius: radius * 0.45,
      ));

    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
      radius * 0.35,
      specularPaint,
    );
  }

  void _drawParticleNodes(Canvas canvas, Offset center, double radius) {
    final particlePaint = Paint()..style = PaintingStyle.fill;

    const int particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi + (rotation * 2 * math.pi * 0.8);
      final wobbleR = radius + math.sin(angle * 3 + pulse * math.pi) * 4.0;
      final px = center.dx + math.cos(angle) * wobbleR;
      final py = center.dy + math.sin(angle) * wobbleR;

      particlePaint.color = (i % 2 == 0 ? primaryColor : secondaryColor).withValues(alpha: 0.85);
      canvas.drawCircle(Offset(px, py), 2.5, particlePaint);

      // Soft glow around particle
      particlePaint.color = primaryColor.withValues(alpha: 0.25);
      canvas.drawCircle(Offset(px, py), 6.0, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralOrbPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pulse != pulse ||
        oldDelegate.ripple != ripple ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.alphaPower != alphaPower;
  }
}
