import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/bioluminescent_neural_orb.dart';
import '../../../core/widgets/cybernetic_heart_rate_visualizer.dart';
import '../../../core/widgets/holographic_brainwave_visualizer.dart';
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

class _ResourcePracticeScreenState extends ConsumerState<ResourcePracticeScreen> {
  late final YoutubePlayerController _playerController;

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

    _playerController = YoutubePlayerController.fromVideoId(
      videoId: widget.resource.youtubeVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        enableCaption: false,
        showVideoAnnotations: false,
      ),
    );

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

              // YouTube External App Fallback
              Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: MuseSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(
                          'https://www.youtube.com/watch?v=${widget.resource.youtubeVideoId}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.open_in_new, size: 12, color: MuseColors.cyanGlow),
                            SizedBox(width: 4),
                            Text(
                              'Open in YouTube App',
                              style: TextStyle(
                                color: MuseColors.cyanGlow,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: MuseSpacing.xs),
              child: BioluminescentNeuralOrb(
                mindState: MindState.neutral,
                size: 140,
                centerLabel: 'STANDBY',
                subLabel: 'MUSE 2 READY',
                showTelemetryRings: true,
              ),
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

  /// Real-time live brainwave spectrum, ECG cardio dynamics, and biometrics when headband is connected
  Widget _buildLiveTelemetrySection(SignalReading signal, HeadbandStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Central Bioluminescent Neural Reactor Hero
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: MuseSpacing.md),
            child: BioluminescentNeuralOrb(
              mindState: (!status.isConnected || status.packetsReceived < 15)
                  ? MindState.neutral
                  : signal.mindState,
              alphaPower: signal.alpha,
              betaPower: signal.beta,
              heartRateBpm: signal.heartRateBpm ?? status.heartRateBpm,
              size: 200,
              centerLabel: (!status.isConnected || status.packetsReceived < 15)
                  ? 'CALIBRATING'
                  : signal.mindState.name.toUpperCase(),
              subLabel: status.isConnected
                  ? 'NEURAL CORE • ${status.packetsReceived} PKTS'
                  : 'AWAITING HARDWARE',
              showTelemetryRings: true,
            ),
          ),
        ),

        // 2. High-Fidelity Cybernetic ECG Heart Rate & Autonomic Coherence HUD
        CyberneticHeartRateVisualizer(
          heartRateBpm: signal.heartRateBpm ?? status.heartRateBpm,
          hrvRmssd: signal.hrvRmssd,
          isConnected: status.isConnected,
        ),

        const SizedBox(height: MuseSpacing.md),

        // 3. Multi-Channel Quantum Brainwave Oscilloscope & Spectral Power Visualizer
        HolographicBrainwaveVisualizer(
          alpha: signal.alpha,
          beta: signal.beta,
          theta: signal.theta,
          delta: signal.delta,
          gamma: signal.gamma,
          isConnected: status.isConnected,
          packetsReceived: status.packetsReceived,
        ),
      ],
    );
  }
}
