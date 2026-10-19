import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import '../../../models/sensor_status.dart';
import '../../../models/signal_reading.dart';
import '../../connect/screens/headband_connect_screen.dart';
import '../models/resource_item.dart';
import 'resource_results_screen.dart';

class ResourcePracticeScreen extends ConsumerStatefulWidget {
  final ResourceItem resource;
  final bool isPrescription;
  final String? therapistName;
  final String? prescriptionId;

  const ResourcePracticeScreen({
    super.key,
    required this.resource,
    this.isPrescription = false,
    this.therapistName,
    this.prescriptionId,
  });

  @override
  ConsumerState<ResourcePracticeScreen> createState() => _ResourcePracticeScreenState();
}

class _ResourcePracticeScreenState extends ConsumerState<ResourcePracticeScreen>
    with SingleTickerProviderStateMixin {
  late final YoutubePlayerController _playerController;
  late final AnimationController _waveAnimController;

  Timer? _sessionTimer;
  int _elapsedSeconds = 0;

  // Session accumulator metrics
  int _calmSamples = 0;
  int _neutralSamples = 0;
  int _activeSamples = 0;
  final List<int> _bpmSamples = [];
  final List<double> _stillnessSamples = [];
  final List<MindState> _stateTimeline = [];
  double _sumAlpha = 0.0;
  double _sumBeta = 0.0;
  double _sumTheta = 0.0;

  @override
  void initState() {
    super.initState();

    _playerController = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        enableCaption: false,
      ),
    );

    _playerController.loadVideoById(videoId: widget.resource.youtubeVideoId);

    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startTimer();
  }

  void _startTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _waveAnimController.dispose();
    _playerController.close();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _completePractice({required bool usedHeadband}) {
    _playerController.stopVideo();
    _sessionTimer?.cancel();

    final totalSamples = _calmSamples + _neutralSamples + _activeSamples;
    final actuallyUsedHeadband = usedHeadband && totalSamples > 0;

    double calmPercent = 0.0;
    double neutralPercent = 0.0;
    double activePercent = 0.0;
    double? initialCalm;
    double? finalCalm;
    String? dominantBand;

    if (actuallyUsedHeadband) {
      calmPercent = (_calmSamples / totalSamples) * 100.0;
      neutralPercent = (_neutralSamples / totalSamples) * 100.0;
      activePercent = (_activeSamples / totalSamples) * 100.0;

      if (_stateTimeline.length >= 6) {
        final windowSize = (_stateTimeline.length * 0.3).ceil().clamp(2, 30);
        final initialSlice = _stateTimeline.sublist(0, windowSize);
        final finalSlice = _stateTimeline.sublist(_stateTimeline.length - windowSize);

        final initialCalmCount = initialSlice.where((s) => s == MindState.calm).length;
        final finalCalmCount = finalSlice.where((s) => s == MindState.calm).length;

        initialCalm = (initialCalmCount / windowSize) * 100.0;
        finalCalm = (finalCalmCount / windowSize) * 100.0;
      }

      if (_sumAlpha >= _sumBeta && _sumAlpha >= _sumTheta) {
        dominantBand = 'Alpha';
      } else if (_sumBeta >= _sumAlpha && _sumBeta >= _sumTheta) {
        dominantBand = 'Beta';
      } else {
        dominantBand = 'Theta';
      }
    }

    double? avgBpm;
    if (_bpmSamples.isNotEmpty) {
      avgBpm = _bpmSamples.reduce((a, b) => a + b) / _bpmSamples.length;
    }

    double avgStillness = 100.0;
    if (_stillnessSamples.isNotEmpty) {
      avgStillness = _stillnessSamples.reduce((a, b) => a + b) / _stillnessSamples.length;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResourceResultsScreen(
          resource: widget.resource,
          durationSeconds: _elapsedSeconds > 0 ? _elapsedSeconds : 1,
          calmPercent: calmPercent,
          neutralPercent: neutralPercent,
          activePercent: activePercent,
          averageBpm: avgBpm,
          averageStillness: avgStillness,
          usedHeadband: actuallyUsedHeadband,
          initialCalmPercent: initialCalm,
          finalCalmPercent: finalCalm,
          dominantBand: dominantBand,
          isPrescription: widget.isPrescription,
          therapistName: widget.therapistName,
          prescriptionId: widget.prescriptionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(headbandStatusProvider);
    final status = statusAsync.value ?? const HeadbandStatus();
    final isConnected = status.isConnected;

    // Listen to real-time signal telemetry
    ref.listen<AsyncValue<SignalReading>>(signalReadingProvider, (prev, next) {
      final reading = next.value;
      if (reading != null && isConnected) {
        switch (reading.mindState) {
          case MindState.calm:
            _calmSamples++;
            break;
          case MindState.neutral:
            _neutralSamples++;
            break;
          case MindState.active:
            _activeSamples++;
            break;
        }

        _stateTimeline.add(reading.mindState);
        _sumAlpha += reading.alpha;
        _sumBeta += reading.beta;
        _sumTheta += reading.theta;

        if (reading.heartRateBpm != null && reading.heartRateBpm! > 0) {
          _bpmSamples.add(reading.heartRateBpm!);
        }
        _stillnessSamples.add(reading.stillnessScore);
      }
    });

    final signalAsync = ref.watch(signalReadingProvider);
    final signal = signalAsync.value ?? SignalReading.idle();

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.resource.category.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: MuseColors.textSecondary,
          ),
        ),
        actions: [
          // Connection pill indicator in AppBar
          Padding(
            padding: const EdgeInsets.only(right: MuseSpacing.md),
            child: Center(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HeadbandConnectScreen(
                        returnLabel: widget.isPrescription ? 'Go Back to Practitioner' : null,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? MuseColors.mindCyan.withValues(alpha: 0.15)
                        : MuseColors.bodyAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConnected ? MuseColors.mindCyan : MuseColors.bodyAmber,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? MuseColors.mindCyan : MuseColors.bodyAmber,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'MUSE 2 LIVE' : 'CONNECT MUSE',
                        style: TextStyle(
                          color: isConnected ? MuseColors.mindCyan : MuseColors.bodyAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MuseSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isPrescription) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: MuseSpacing.md),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MuseColors.cyanGlow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MuseColors.cyanGlow.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, color: MuseColors.cyanGlow, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CLINICAL RECOMMENDATION • From ${widget.therapistName ?? "Practitioner"}',
                          style: const TextStyle(
                            color: MuseColors.cyanGlow,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. YouTube In-App Player
              ClipRRect(
                borderRadius: BorderRadius.circular(MuseSpacing.radiusLg),
                child: Container(
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(controller: _playerController),
                  ),
                ),
              ),

              const SizedBox(height: MuseSpacing.md),

              // 2. Resource Title & Metadata
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.resource.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: MuseColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.resource.author} • ${widget.resource.durationLabel}',
                          style: const TextStyle(
                            color: MuseColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: MuseColors.cardSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MuseColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: MuseColors.mindCyan),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(_elapsedSeconds),
                          style: const TextStyle(
                            color: MuseColors.mindCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: MuseSpacing.lg),

              // 3. Headband Status Card or Connection Prompt
              if (!isConnected)
                _buildConnectPromptCard(context)
              else
                _buildLiveTelemetrySection(signal, status),

              const SizedBox(height: MuseSpacing.xl),

              // 4. Complete Practice Button
              MuseButton(
                label: 'End Practice & View Report',
                icon: Icons.check_circle_outline,
                width: double.infinity,
                onPressed: () => _completePractice(usedHeadband: isConnected),
              ),

              const SizedBox(height: MuseSpacing.sm),

              const Center(
                child: Text(
                  'Completing the session records your EEG metrics and updates your personalized recommendations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MuseColors.textTertiary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Prompt card shown when the headband is not yet connected
  Widget _buildConnectPromptCard(BuildContext context) {
    return MuseCard(
      borderColor: MuseColors.bodyAmber.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MuseColors.bodyAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset, color: MuseColors.bodyAmber, size: 20),
              ),
              const SizedBox(width: MuseSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muse 2 Headband Not Connected',
                      style: TextStyle(
                        color: MuseColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Connect to track live EEG brainwaves, heart rate & stillness.',
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
          const SizedBox(height: MuseSpacing.md),
          const Text(
            'Experience real-time neurofeedback: see your Alpha, Beta, Theta, Delta and Gamma waves animate as you listen to this resource.',
            style: TextStyle(
              color: MuseColors.textTertiary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: MuseSpacing.md),
          MuseButton(
            label: 'Connect Muse 2 Headband',
            icon: Icons.bluetooth_searching,
            variant: MuseButtonVariant.secondary,
            width: double.infinity,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HeadbandConnectScreen(
                    returnLabel: widget.isPrescription ? 'Go Back to Practitioner' : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Real-time live brainwave spectrum and biometrics when headband is connected
  Widget _buildLiveTelemetrySection(SignalReading signal, HeadbandStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Biometric summary bar: Mind State, Heart Rate BPM, Stillness
        Row(
          children: [
            // Mind state pill
            Expanded(
              child: _buildBiometricBadge(
                label: 'MIND STATE',
                value: signal.mindState.name.toUpperCase(),
                icon: Icons.psychology,
                color: _getMindStateColor(signal.mindState),
              ),
            ),
            const SizedBox(width: MuseSpacing.sm),
            // Heart rate BPM
            Expanded(
              child: _buildBiometricBadge(
                label: 'HEART RATE',
                value: (signal.heartRateBpm != null && signal.heartRateBpm! > 0)
                    ? '${signal.heartRateBpm} BPM'
                    : (status.heartRateBpm != null && status.heartRateBpm! > 0)
                        ? '${status.heartRateBpm} BPM'
                        : '-- BPM',
                icon: Icons.favorite,
                color: MuseColors.roseGlow,
              ),
            ),
            const SizedBox(width: MuseSpacing.sm),
            // Stillness Score
            Expanded(
              child: _buildBiometricBadge(
                label: 'STILLNESS',
                value: '${signal.stillnessScore.toStringAsFixed(0)}%',
                icon: Icons.accessibility_new,
                color: MuseColors.breathMint,
              ),
            ),
          ],
        ),

        const SizedBox(height: MuseSpacing.md),

        // 5-Band Live EEG Spectrum Visualizer Card
        MuseCard(
          borderColor: MuseColors.mindCyan.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.waves, color: MuseColors.mindCyan, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE BRAINWAVE SPECTRUM',
                    style: TextStyle(
                      color: MuseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MuseColors.mindCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MUSE 2 SENSORS ACTIVE',
                      style: TextStyle(
                        color: MuseColors.mindCyan,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MuseSpacing.md),

              // Animated multi-colored brainwave oscilloscope
              SizedBox(
                height: 110,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _waveAnimController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _BrainwaveSpectrumPainter(
                        progress: _waveAnimController.value,
                        alpha: signal.alpha,
                        beta: signal.beta,
                        theta: signal.theta,
                        delta: signal.delta,
                        gamma: signal.gamma,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),

              const SizedBox(height: MuseSpacing.md),
              const Divider(color: MuseColors.cardBorder, height: 1),
              const SizedBox(height: MuseSpacing.md),

              // 5 Individual Wave Bands with distinct colors and live microvolt powers
              _buildWaveBandRow(
                band: 'ALPHA',
                range: '8–13 Hz',
                meaning: 'Calm & Relaxation',
                power: signal.alpha,
                color: const Color(0xFF00E5FF), // Cyan
              ),
              const SizedBox(height: 8),
              _buildWaveBandRow(
                band: 'BETA',
                range: '13–30 Hz',
                meaning: 'Active Focus & Thinking',
                power: signal.beta,
                color: const Color(0xFF9D4EDD), // Purple
              ),
              const SizedBox(height: 8),
              _buildWaveBandRow(
                band: 'THETA',
                range: '4–8 Hz',
                meaning: 'Deep Meditation & Flow',
                power: signal.theta,
                color: const Color(0xFFFFB703), // Amber / Gold
              ),
              const SizedBox(height: 8),
              _buildWaveBandRow(
                band: 'DELTA',
                range: '0.5–4 Hz',
                meaning: 'Rest & Deep Stillness',
                power: signal.delta,
                color: const Color(0xFF3B82F6), // Deep Blue
              ),
              const SizedBox(height: 8),
              _buildWaveBandRow(
                band: 'GAMMA',
                range: '30–50 Hz',
                meaning: 'Insight & Heightened Perception',
                power: signal.gamma,
                color: const Color(0xFFEC4899), // Pink
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getMindStateColor(MindState state) {
    switch (state) {
      case MindState.calm:
        return MuseColors.mindCyan;
      case MindState.neutral:
        return MuseColors.textSecondary;
      case MindState.active:
        return MuseColors.roseGlow;
    }
  }

  Widget _buildBiometricBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: MuseColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveBandRow({
    required String band,
    required String range,
    required String meaning,
    required double power,
    required Color color,
  }) {
    // Normalization for visual progress bar (microvolts typical scale: 0 - 30 uV)
    final clampedProgress = (power / 25.0).clamp(0.05, 1.0);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(
            band,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    meaning,
                    style: const TextStyle(
                      color: MuseColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${power.toStringAsFixed(1)} µV',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: clampedProgress,
                  backgroundColor: MuseColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering multi-colored live sine waves representing
/// Alpha, Beta, Theta, Delta, and Gamma brainwave frequencies in real time.
class _BrainwaveSpectrumPainter extends CustomPainter {
  final double progress;
  final double alpha;
  final double beta;
  final double theta;
  final double delta;
  final double gamma;

  _BrainwaveSpectrumPainter({
    required this.progress,
    required this.alpha,
    required this.beta,
    required this.theta,
    required this.delta,
    required this.gamma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    // Draw baseline grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), gridPaint);

    // 1. Delta (Slow, smooth, deep - Blue)
    _drawWave(
      canvas: canvas,
      size: size,
      color: const Color(0xFF3B82F6).withValues(alpha: 0.8),
      amplitude: 14.0 + (delta.clamp(0, 30) * 0.5),
      frequency: 1.5,
      phase: progress * 2 * math.pi * 0.5,
      strokeWidth: 2.0,
    );

    // 2. Theta (Meditative - Amber)
    _drawWave(
      canvas: canvas,
      size: size,
      color: const Color(0xFFFFB703).withValues(alpha: 0.85),
      amplitude: 11.0 + (theta.clamp(0, 30) * 0.6),
      frequency: 2.8,
      phase: progress * 2 * math.pi * 0.8,
      strokeWidth: 2.0,
    );

    // 3. Alpha (Calm awareness - Cyan, brightest)
    _drawWave(
      canvas: canvas,
      size: size,
      color: const Color(0xFF00E5FF),
      amplitude: 16.0 + (alpha.clamp(0, 30) * 0.8),
      frequency: 4.5,
      phase: progress * 2 * math.pi * 1.2,
      strokeWidth: 2.5,
    );

    // 4. Beta (Active thinking - Purple)
    _drawWave(
      canvas: canvas,
      size: size,
      color: const Color(0xFF9D4EDD).withValues(alpha: 0.85),
      amplitude: 8.0 + (beta.clamp(0, 30) * 0.4),
      frequency: 7.0,
      phase: progress * 2 * math.pi * 1.8,
      strokeWidth: 1.8,
    );

    // 5. Gamma (Fast cognition - Pink)
    _drawWave(
      canvas: canvas,
      size: size,
      color: const Color(0xFFEC4899).withValues(alpha: 0.75),
      amplitude: 5.0 + (gamma.clamp(0, 30) * 0.3),
      frequency: 11.0,
      phase: progress * 2 * math.pi * 2.4,
      strokeWidth: 1.5,
    );
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required Color color,
    required double amplitude,
    required double frequency,
    required double phase,
    required double strokeWidth,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;

    for (double x = 0; x <= size.width; x += 2.0) {
      final normalizedX = x / size.width;
      // Window function to taper off at left and right edges nicely
      final window = math.sin(normalizedX * math.pi);
      final y = midY + math.sin(normalizedX * frequency * 2 * math.pi + phase) * amplitude * window;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BrainwaveSpectrumPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.alpha != alpha ||
        oldDelegate.beta != beta ||
        oldDelegate.theta != theta ||
        oldDelegate.delta != delta ||
        oldDelegate.gamma != gamma;
  }
}
