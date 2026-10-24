import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/muse_colors.dart';
import '../theme/muse_spacing.dart';

/// Futuristic Multi-Band Holographic Brainwave Oscilloscope & Spectral HUD
/// Features prominent stacked channels, quantum synthesis waves, and spectral power modes.
class HolographicBrainwaveVisualizer extends StatefulWidget {
  final double alpha;
  final double beta;
  final double theta;
  final double delta;
  final double gamma;
  final bool isConnected;
  final int packetsReceived;
  final double height;

  const HolographicBrainwaveVisualizer({
    super.key,
    required this.alpha,
    required this.beta,
    required this.theta,
    required this.delta,
    required this.gamma,
    this.isConnected = true,
    this.packetsReceived = 0,
    this.height = 280,
  });

  @override
  State<HolographicBrainwaveVisualizer> createState() =>
      _HolographicBrainwaveVisualizerState();
}

class _HolographicBrainwaveVisualizerState
    extends State<HolographicBrainwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;
  int _selectedView = 0; // 0: STACKED CHANNELS, 1: QUANTUM SYNTHESIS, 2: SPECTRAL POWER

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
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
          color: dominantColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: dominantColor.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Futuristic Telemetry Badges & View Selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MuseSpacing.md,
              vertical: MuseSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dominantColor,
                    boxShadow: [
                      BoxShadow(
                        color: dominantColor.withValues(alpha: 0.9),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'EEG QUANTUM SPECTRUM',
                  style: TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                // View Selector Toggle (CHANNELS / SYNTHESIS / POWER)
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
                        label: 'CHANNELS',
                        isSelected: _selectedView == 0,
                        onTap: () => setState(() => _selectedView = 0),
                      ),
                      _buildToggleButton(
                        label: 'SYNTHESIS',
                        isSelected: _selectedView == 1,
                        onTap: () => setState(() => _selectedView = 1),
                      ),
                      _buildToggleButton(
                        label: 'POWER',
                        isSelected: _selectedView == 2,
                        onTap: () => setState(() => _selectedView = 2),
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
            padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: 7),
            decoration: BoxDecoration(
              color: dominantColor.withValues(alpha: 0.12),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: dominantColor.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.radar, color: dominantColor, size: 15),
                const SizedBox(width: 6),
                Text(
                  'DOMINANT: ',
                  style: TextStyle(
                    color: dominantColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Expanded(
                  child: Text(
                    dominantText.toUpperCase(),
                    style: const TextStyle(
                      color: MuseColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (widget.isConnected ? MuseColors.calmGlow : MuseColors.bodyAmber)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.isConnected
                        ? '60 FPS LIVE'
                        : 'STANDBY',
                    style: TextStyle(
                      color: widget.isConnected
                          ? MuseColors.calmGlow
                          : MuseColors.bodyAmber,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Body (Stacked Channels / Quantum Synthesis / Spectral Bars)
          Padding(
            padding: const EdgeInsets.all(MuseSpacing.md),
            child: _buildBodyView(dominantColor),
          ),

          // Microvolt Legend Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MuseSpacing.md,
              0,
              MuseSpacing.md,
              MuseSpacing.sm + 2,
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

  Widget _buildBodyView(Color dominantColor) {
    switch (_selectedView) {
      case 0:
        return _buildStackedChannelsView();
      case 1:
        return _buildSynthesisOscilloscope(dominantColor);
      case 2:
      default:
        return _buildSpectralBars();
    }
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00E5FF) : MuseColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  /// 1. STACKED CHANNELS VIEW: Distinct, prominently separated lanes for each frequency band
  Widget _buildStackedChannelsView() {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _sweepController,
        builder: (context, child) {
          return CustomPaint(
            painter: _StackedEegChannelsPainter(
              progress: _sweepController.value,
              gamma: widget.gamma,
              beta: widget.beta,
              alpha: widget.alpha,
              theta: widget.theta,
              delta: widget.delta,
              isConnected: widget.isConnected,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  /// 2. QUANTUM SYNTHESIS VIEW: Massive, expansive overlapping oscilloscope wave
  Widget _buildSynthesisOscilloscope(Color dominantColor) {
    return SizedBox(
      height: widget.height,
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

  /// 3. SPECTRAL POWER VIEW: Neon gradient power bars with microvolt readouts
  Widget _buildSpectralBars() {
    final total = (widget.gamma + widget.beta + widget.alpha + widget.theta + widget.delta);
    final safeTotal = total > 0 ? total : 1.0;

    return Column(
      children: [
        _buildSpectralBandRow(
          band: 'γ GAMMA (30–100 Hz)',
          role: 'Peak Cognition & Neural Binding',
          power: widget.gamma,
          percent: (widget.gamma / safeTotal) * 100,
          color: const Color(0xFFEC4899),
        ),
        const SizedBox(height: 10),
        _buildSpectralBandRow(
          band: 'β BETA (13–30 Hz)',
          role: 'Active Focus & Analytical Thought',
          power: widget.beta,
          percent: (widget.beta / safeTotal) * 100,
          color: const Color(0xFF9D4EDD),
        ),
        const SizedBox(height: 10),
        _buildSpectralBandRow(
          band: 'α ALPHA (8–13 Hz)',
          role: 'Calm Mindfulness & Relaxation',
          power: widget.alpha,
          percent: (widget.alpha / safeTotal) * 100,
          color: const Color(0xFF00E5FF),
        ),
        const SizedBox(height: 10),
        _buildSpectralBandRow(
          band: 'θ THETA (4–8 Hz)',
          role: 'Deep Meditation & Creative Flow',
          power: widget.theta,
          percent: (widget.theta / safeTotal) * 100,
          color: const Color(0xFFFFB703),
        ),
        const SizedBox(height: 10),
        _buildSpectralBandRow(
          band: 'δ DELTA (0.5–4 Hz)',
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
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              '${power.toStringAsFixed(1)} μV (${percent.toStringAsFixed(0)}%)',
              style: const TextStyle(
                color: MuseColors.textPrimary,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          role,
          style: const TextStyle(
            color: MuseColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (percent / 100).clamp(0.04, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: 8,
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
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${val > 0 ? val.toStringAsFixed(1) : '--'} μV',
          style: const TextStyle(
            color: MuseColors.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// 1. Painter that renders 5 distinctly separated EEG channel lanes with custom badges and live waves
class _StackedEegChannelsPainter extends CustomPainter {
  final double progress;
  final double gamma;
  final double beta;
  final double alpha;
  final double theta;
  final double delta;
  final bool isConnected;

  _StackedEegChannelsPainter({
    required this.progress,
    required this.gamma,
    required this.beta,
    required this.alpha,
    required this.theta,
    required this.delta,
    required this.isConnected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final channelCount = 5;
    final channelHeight = size.height / channelCount;

    // Background medical grid
    _drawMedicalGrid(canvas, size, channelCount);

    final channels = [
      _ChannelData(
        label: 'γ GAMMA',
        freqRange: '30–100 Hz',
        power: gamma,
        color: const Color(0xFFEC4899),
        freq: 12.0,
        baseAmp: 12.0,
        scale: (gamma.clamp(1.0, 30.0) / 30.0),
        phase: progress * 2 * math.pi * 2.2,
      ),
      _ChannelData(
        label: 'β BETA',
        freqRange: '13–30 Hz',
        power: beta,
        color: const Color(0xFF9D4EDD),
        freq: 8.0,
        baseAmp: 16.0,
        scale: (beta.clamp(2.0, 40.0) / 40.0),
        phase: progress * 2 * math.pi * 1.6,
      ),
      _ChannelData(
        label: 'α ALPHA',
        freqRange: '8–13 Hz',
        power: alpha,
        color: const Color(0xFF00E5FF),
        freq: 5.0,
        baseAmp: 22.0,
        scale: (alpha.clamp(3.0, 45.0) / 45.0),
        phase: progress * 2 * math.pi * 1.1,
      ),
      _ChannelData(
        label: 'θ THETA',
        freqRange: '4–8 Hz',
        power: theta,
        color: const Color(0xFFFFB703),
        freq: 2.8,
        baseAmp: 18.0,
        scale: (theta.clamp(2.0, 40.0) / 40.0),
        phase: progress * 2 * math.pi * 0.7,
      ),
      _ChannelData(
        label: 'δ DELTA',
        freqRange: '0.5–4 Hz',
        power: delta,
        color: const Color(0xFF3B82F6),
        freq: 1.4,
        baseAmp: 20.0,
        scale: (delta.clamp(2.0, 45.0) / 45.0),
        phase: progress * 2 * math.pi * 0.4,
      ),
    ];

    for (int i = 0; i < channelCount; i++) {
      final ch = channels[i];
      final laneMidY = (i * channelHeight) + (channelHeight / 2);

      // Draw Channel Label & Microvolt Text on Left
      _drawChannelText(
        canvas: canvas,
        ch: ch,
        y: laneMidY - 14,
      );

      // Draw Lane Waveform
      final laneAmp = (isConnected ? ch.baseAmp * (ch.scale > 0 ? ch.scale : 0.6) : ch.baseAmp * 0.5)
          .clamp(4.0, channelHeight * 0.42);

      _drawSingleLaneWave(
        canvas: canvas,
        startX: 85.0,
        width: size.width - 85.0,
        midY: laneMidY,
        ch: ch,
        amplitude: laneAmp,
      );
    }

    // Vertical sweep tracer line
    final sweepX = 85.0 + (progress * (size.width - 85.0));
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(sweepX - 2, 0, 4, size.height))
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(sweepX, 0), Offset(sweepX, size.height), sweepPaint);
  }

  void _drawChannelText({
    required Canvas canvas,
    required _ChannelData ch,
    required double y,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${ch.label}\n',
            style: TextStyle(
              color: ch.color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          TextSpan(
            text: '${ch.power > 0 ? ch.power.toStringAsFixed(1) : '--'} μV',
            style: const TextStyle(
              color: MuseColors.textPrimary,
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(4, y));
  }

  void _drawSingleLaneWave({
    required Canvas canvas,
    required double startX,
    required double width,
    required double midY,
    required _ChannelData ch,
    required double amplitude,
  }) {
    final path = Path();
    final glowPath = Path();

    for (double x = 0; x <= width; x += 1.5) {
      final normX = x / width;
      final window = math.sin(normX * math.pi);
      final harmonic = math.sin(normX * ch.freq * 2 * math.pi + ch.phase) +
          0.2 * math.sin(normX * ch.freq * 4 * math.pi + ch.phase * 1.5);
      final y = midY + harmonic * amplitude * window;

      if (x == 0) {
        path.moveTo(startX + x, y);
        glowPath.moveTo(startX + x, y);
      } else {
        path.lineTo(startX + x, y);
        glowPath.lineTo(startX + x, y);
      }
    }

    // Outer glow bloom
    final glowPaint = Paint()
      ..color = ch.color.withValues(alpha: 0.3)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(glowPath, glowPaint);

    // Sharp neon beam
    final linePaint = Paint()
      ..color = ch.color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  void _drawMedicalGrid(Canvas canvas, Size size, int channelCount) {
    final gridPaint = Paint()
      ..color = const Color(0xFF16233B).withValues(alpha: 0.45)
      ..strokeWidth = 0.6;

    final laneHeight = size.height / channelCount;

    // Horizontal lane dividers
    for (int i = 0; i <= channelCount; i++) {
      final y = i * laneHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Left channel label partition line
    final partitionPaint = Paint()
      ..color = const Color(0xFF263D66)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(80, 0), Offset(80, size.height), partitionPaint);

    // Vertical time grid ticks
    final stepsX = 8;
    for (int i = 1; i < stepsX; i++) {
      final x = 80 + (size.width - 80) * (i / stepsX);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StackedEegChannelsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gamma != gamma ||
        oldDelegate.beta != beta ||
        oldDelegate.alpha != alpha ||
        oldDelegate.theta != theta ||
        oldDelegate.delta != delta;
  }
}

class _ChannelData {
  final String label;
  final String freqRange;
  final double power;
  final Color color;
  final double freq;
  final double baseAmp;
  final double scale;
  final double phase;

  _ChannelData({
    required this.label,
    required this.freqRange,
    required this.power,
    required this.color,
    required this.freq,
    required this.baseAmp,
    required this.scale,
    required this.phase,
  });
}

/// 2. Custom Painter that renders an expansive quantum multi-channel EEG composite oscilloscope
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

    // Baseline amplitude scaling (scaled for expansive prominence up to 45px amplitude)
    final hasRealSignal = isConnected && (alpha + beta + theta + delta + gamma > 0.5);
    final aScale = hasRealSignal ? (alpha.clamp(4.0, 50.0) / 50.0) : 0.75;
    final bScale = hasRealSignal ? (beta.clamp(3.0, 45.0) / 45.0) : 0.55;
    final tScale = hasRealSignal ? (theta.clamp(3.0, 45.0) / 45.0) : 0.65;
    final dScale = hasRealSignal ? (delta.clamp(2.0, 40.0) / 40.0) : 0.80;
    final gScale = hasRealSignal ? (gamma.clamp(1.0, 30.0) / 30.0) : 0.45;

    // 1. Delta (Deep Blue, slow 1.5 Hz swell)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFF3B82F6),
      frequency: 1.4,
      amplitude: 28.0 * dScale,
      phaseOffset: progress * 2 * math.pi * 0.4,
      strokeWidth: 2.2,
      opacity: 0.8,
    );

    // 2. Theta (Amber Gold, gentle 3.2 Hz wave)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFFFFB703),
      frequency: 2.8,
      amplitude: 32.0 * tScale,
      phaseOffset: progress * 2 * math.pi * 0.7,
      strokeWidth: 2.5,
      opacity: 0.85,
    );

    // 3. Alpha (Electric Cyan, primary bioluminescent mindfulness ribbon)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFF00E5FF),
      frequency: 5.2,
      amplitude: 44.0 * aScale,
      phaseOffset: progress * 2 * math.pi * 1.1,
      strokeWidth: 3.2,
      opacity: 1.0,
      withGlow: true,
    );

    // 4. Beta (Violet Purple, crisp fast active spikes)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFF9D4EDD),
      frequency: 8.6,
      amplitude: 24.0 * bScale,
      phaseOffset: progress * 2 * math.pi * 1.6,
      strokeWidth: 2.4,
      opacity: 0.85,
    );

    // 5. Gamma (Electric Rose, fast cognitive bursts)
    _drawOscilloscopeChannel(
      canvas: canvas,
      size: size,
      color: const Color(0xFFEC4899),
      frequency: 13.5,
      amplitude: 18.0 * gScale,
      phaseOffset: progress * 2 * math.pi * 2.2,
      strokeWidth: 1.8,
      opacity: 0.8,
    );

    // 6. Draw futuristic vertical sweep tracer line
    final scanX = progress * size.width;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(scanX - 2, 0, 4, size.height))
      ..strokeWidth = 2.4;

    canvas.drawLine(Offset(scanX, 0), Offset(scanX, size.height), sweepPaint);
  }

  void _drawCyberGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF16233B).withValues(alpha: 0.5)
      ..strokeWidth = 0.6;

    // Horizontal baseline grid
    final stepsY = 6;
    for (int i = 1; i < stepsY; i++) {
      final y = size.height * (i / stepsY);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid ticks
    final stepsX = 10;
    for (int i = 1; i < stepsX; i++) {
      final x = size.width * (i / stepsX);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Center voltage zero-axis
    final zeroPaint = Paint()
      ..color = const Color(0xFF263D66)
      ..strokeWidth = 1.2;
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
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = strokeWidth * 3.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
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
