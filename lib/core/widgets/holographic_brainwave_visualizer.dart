import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/muse_colors.dart';
import '../theme/muse_spacing.dart';

/// Futuristic Multi-Band Holographic Brainwave Oscilloscope & Spectral HUD
class HolographicBrainwaveVisualizer extends StatefulWidget {
  final double alpha;
  final double beta;
  final double theta;
  final double delta;
  final double gamma;
  final bool isConnected;
  final int packetsReceived;

  const HolographicBrainwaveVisualizer({
    super.key,
    required this.alpha,
    required this.beta,
    required this.theta,
    required this.delta,
    required this.gamma,
    this.isConnected = true,
    this.packetsReceived = 0,
  });

  @override
  State<HolographicBrainwaveVisualizer> createState() =>
      _HolographicBrainwaveVisualizerState();
}

class _HolographicBrainwaveVisualizerState
    extends State<HolographicBrainwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;
  int _selectedView = 0; // 0: Oscilloscope HUD, 1: Spectral Frequency Bars

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  String _getDominantBand() {
    double maxVal = widget.alpha;
    String dominant = 'ALPHA (Calm Mindfulness)';

    if (widget.beta > maxVal) {
      maxVal = widget.beta;
      dominant = 'BETA (Active Focus)';
    }
    if (widget.theta > maxVal) {
      maxVal = widget.theta;
      dominant = 'THETA (Deep Flow)';
    }
    if (widget.delta > maxVal) {
      maxVal = widget.delta;
      dominant = 'DELTA (Restorative Stillness)';
    }
    if (widget.gamma > maxVal) {
      maxVal = widget.gamma;
      dominant = 'GAMMA (Peak Cognition)';
    }

    if (maxVal < 1.0 && (!widget.isConnected || widget.packetsReceived < 15)) {
      return 'SYNTHESIZING BASELINE...';
    }
    return dominant;
  }

  Color _getDominantColor() {
    double maxVal = widget.alpha;
    Color color = const Color(0xFF00E5FF); // Alpha Cyan

    if (widget.beta > maxVal) {
      maxVal = widget.beta;
      color = const Color(0xFF9D4EDD); // Beta Purple
    }
    if (widget.theta > maxVal) {
      maxVal = widget.theta;
      color = const Color(0xFFFFB703); // Theta Amber
    }
    if (widget.delta > maxVal) {
      maxVal = widget.delta;
      color = const Color(0xFF3B82F6); // Delta Blue
    }
    if (widget.gamma > maxVal) {
      maxVal = widget.gamma;
      color = const Color(0xFFEC4899); // Gamma Pink
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final dominantText = _getDominantBand();
    final dominantColor = _getDominantColor();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(MuseSpacing.radiusLg),
        border: Border.all(
          color: dominantColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dominantColor.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Futuristic Telemetry Badges
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MuseSpacing.md,
              vertical: MuseSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dominantColor,
                    boxShadow: [
                      BoxShadow(
                        color: dominantColor.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'EEG QUANTUM SPECTRUM',
                  style: TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                // View Selector Toggle
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF263554),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton(
                        label: 'WAVES',
                        isSelected: _selectedView == 0,
                        onTap: () => setState(() => _selectedView = 0),
                      ),
                      _buildToggleButton(
                        label: 'POWER',
                        isSelected: _selectedView == 1,
                        onTap: () => setState(() => _selectedView = 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dominant Band Status Indicator Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: dominantColor.withValues(alpha: 0.1),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: dominantColor.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.radar, color: dominantColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  'DOMINANT: ',
                  style: TextStyle(
                    color: dominantColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Expanded(
                  child: Text(
                    dominantText.toUpperCase(),
                    style: const TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  widget.isConnected
                      ? 'SYNCED'
                      : 'STANDBY',
                  style: TextStyle(
                    color: widget.isConnected
                        ? MuseColors.calmGlow
                        : MuseColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Body (Wave Oscilloscope or Spectral Frequency Bars)
          Padding(
            padding: const EdgeInsets.all(MuseSpacing.md),
            child: _selectedView == 0
                ? _buildWaveOscilloscope(dominantColor)
                : _buildSpectralBars(),
          ),

          // Microvolt Legend Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MuseSpacing.md,
              0,
              MuseSpacing.md,
              MuseSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendItem('γ GAMMA', const Color(0xFFEC4899), widget.gamma),
                _buildLegendItem('β BETA', const Color(0xFF9D4EDD), widget.beta),
                _buildLegendItem('α ALPHA', const Color(0xFF00E5FF), widget.alpha),
                _buildLegendItem('θ THETA', const Color(0xFFFFB703), widget.theta),
                _buildLegendItem('δ DELTA', const Color(0xFF3B82F6), widget.delta),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E5FF) : MuseColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildWaveOscilloscope(Color dominantColor) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _sweepController,
        builder: (context, child) {
          return CustomPaint(
            painter: _CyberneticEegPainter(
              progress: _sweepController.value,
              alpha: widget.alpha,
              beta: widget.beta,
              theta: widget.theta,
              delta: widget.delta,
              gamma: widget.gamma,
              isConnected: widget.isConnected,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildSpectralBars() {
    final total = (widget.gamma + widget.beta + widget.alpha + widget.theta + widget.delta);
    final safeTotal = total > 0 ? total : 1.0;

    return Column(
      children: [
        _buildSpectralBandRow(
          band: 'GAMMA (30–100 Hz)',
          role: 'Peak Cognition & Neural Binding',
          power: widget.gamma,
          percent: (widget.gamma / safeTotal) * 100,
          color: const Color(0xFFEC4899),
        ),
        const SizedBox(height: 8),
        _buildSpectralBandRow(
          band: 'BETA (13–30 Hz)',
          role: 'Active Focus & Analytical Thought',
          power: widget.beta,
          percent: (widget.beta / safeTotal) * 100,
          color: const Color(0xFF9D4EDD),
        ),
        const SizedBox(height: 8),
        _buildSpectralBandRow(
          band: 'ALPHA (8–13 Hz)',
          role: 'Calm Mindfulness & Relaxation',
          power: widget.alpha,
          percent: (widget.alpha / safeTotal) * 100,
          color: const Color(0xFF00E5FF),
        ),
        const SizedBox(height: 8),
        _buildSpectralBandRow(
          band: 'THETA (4–8 Hz)',
          role: 'Deep Meditation & Creative Flow',
          power: widget.theta,
          percent: (widget.theta / safeTotal) * 100,
          color: const Color(0xFFFFB703),
        ),
        const SizedBox(height: 8),
        _buildSpectralBandRow(
          band: 'DELTA (0.5–4 Hz)',
          role: 'Restorative Stillness & Deep Healing',
          power: widget.delta,
          percent: (widget.delta / safeTotal) * 100,
          color: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildSpectralBandRow({
    required String band,
    required String role,
    required double power,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              band,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              '${power.toStringAsFixed(1)} μV (${percent.toStringAsFixed(0)}%)',
              style: const TextStyle(
                color: MuseColors.textPrimary,
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          role,
          style: const TextStyle(
            color: MuseColors.textSecondary,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (percent / 100).clamp(0.04, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, double val) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${val > 0 ? val.toStringAsFixed(1) : '--'} μV',
          style: const TextStyle(
            color: MuseColors.textSecondary,
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// Custom Painter that renders an authenticated, cybernetic multi-channel EEG oscilloscope
class _CyberneticEegPainter extends CustomPainter {
  final double progress;
  final double alpha;
  final double beta;
  final double theta;
  final double delta;
  final double gamma;
  final bool isConnected;

  _CyberneticEegPainter({
    required this.progress,
    required this.alpha,
    required this.beta,
    required this.theta,
    required this.delta,
    required this.gamma,
    required this.isConnected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawCyberGrid(canvas, size);

    // Baseline amplitude scaling
    final hasRealSignal = isConnected && (alpha + beta + theta + delta + gamma > 0.5);
    final aScale = hasRealSignal ? (alpha.clamp(4.0, 50.0) / 50.0) : 0.65;
    final bScale = hasRealSignal ? (beta.clamp(3.0, 45.0) / 45.0) : 0.45;
    final tScale = hasRealSignal ? (theta.clamp(3.0, 45.0) / 45.0) : 0.55;
    final dScale = hasRealSignal ? (delta.clamp(2.0, 40.0) / 40.0) : 0.70;
    final gScale = hasRealSignal ? (gamma.clamp(1.0, 30.0) / 30.0) : 0.35;

    // 1. Delta (Deep Blue, slow 1.5 Hz swell)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFF3B82F6),
      frequency: 1.4,
      amplitude: 14.0 * dScale,
      phaseOffset: progress * 2 * math.pi * 0.4,
      strokeWidth: 1.6,
      opacity: 0.75,
    );

    // 2. Theta (Amber Gold, gentle 3.2 Hz wave)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFFFFB703),
      frequency: 2.8,
      amplitude: 16.0 * tScale,
      phaseOffset: progress * 2 * math.pi * 0.7,
      strokeWidth: 1.8,
      opacity: 0.85,
    );

    // 3. Alpha (Electric Cyan, primary bioluminescent mindfulness ribbon 5.5 Hz)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFF00E5FF),
      frequency: 5.2,
      amplitude: 22.0 * aScale,
      phaseOffset: progress * 2 * math.pi * 1.1,
      strokeWidth: 2.4,
      opacity: 1.0,
      withGlow: true,
    );

    // 4. Beta (Violet Purple, crisp fast active spikes 8.8 Hz)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFF9D4EDD),
      frequency: 8.6,
      amplitude: 12.0 * bScale,
      phaseOffset: progress * 2 * math.pi * 1.6,
      strokeWidth: 1.7,
      opacity: 0.8,
    );

    // 5. Gamma (Electric Rose, fast cognitive burst 14 Hz)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFFEC4899),
      frequency: 13.5,
      amplitude: 9.0 * gScale,
      phaseOffset: progress * 2 * math.pi * 2.2,
      strokeWidth: 1.4,
      opacity: 0.75,
    );

    // 6. Draw futuristic vertical sweep tracer line
    final scanX = progress * size.width;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(scanX - 2, 0, 4, size.height))
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(scanX, 0), Offset(scanX, size.height), sweepPaint);
  }

  void _drawCyberGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF16233B).withValues(alpha: 0.5)
      ..strokeWidth = 0.6;

    // Horizontal baseline grid
    final stepsY = 4;
    for (int i = 1; i < stepsY; i++) {
      final y = size.height * (i / stepsY);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid ticks
    final stepsX = 8;
    for (int i = 1; i < stepsX; i++) {
      final x = size.width * (i / stepsX);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Center voltage zero-axis
    final zeroPaint = Paint()
      ..color = const Color(0xFF263D66)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      zeroPaint,
    );
  }

  void _drawOscilloscopeChannel({
    required Canvas canvas,
    required Size size,
    required Color color,
    required double frequency,
    required double amplitude,
    required double phaseOffset,
    required double strokeWidth,
    required double opacity,
    bool withGlow = false,
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;

    for (double x = 0; x <= size.width; x += 1.5) {
      final normX = x / size.width;
      // Edge damping window so waves seamlessly stay inside oscilloscope box
      final window = math.sin(normX * math.pi);
      final harmonic = math.sin(normX * frequency * 2 * math.pi + phaseOffset) +
          0.25 * math.sin(normX * frequency * 4 * math.pi + phaseOffset * 1.5);
      final y = midY + harmonic * amplitude * window;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (withGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth * 3.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(path, glowPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CyberneticEegPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.alpha != alpha ||
        oldDelegate.beta != beta ||
        oldDelegate.theta != theta ||
        oldDelegate.delta != delta ||
        oldDelegate.gamma != gamma;
  }
}
