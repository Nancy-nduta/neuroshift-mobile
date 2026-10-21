import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroshift_mobile/core/providers/app_providers.dart';
import 'package:neuroshift_mobile/core/theme/muse_colors.dart';
import 'package:neuroshift_mobile/core/theme/muse_spacing.dart';
import 'package:neuroshift_mobile/core/widgets/bioluminescent_neural_orb.dart';
import 'package:neuroshift_mobile/core/widgets/muse_button.dart';
import 'package:neuroshift_mobile/features/meditate/screens/session_results_screen.dart';
import 'package:neuroshift_mobile/models/experience_mode.dart';
import 'package:neuroshift_mobile/models/meditation_session.dart';
import 'package:neuroshift_mobile/models/signal_reading.dart';

class LiveMeditationScreen extends ConsumerStatefulWidget {
  final ExperienceMode mode;
  final int durationMinutes;

  const LiveMeditationScreen({
    super.key,
    required this.mode,
    required this.durationMinutes,
  });

  @override
  ConsumerState<LiveMeditationScreen> createState() => _LiveMeditationScreenState();
}

class _LiveMeditationScreenState extends ConsumerState<LiveMeditationScreen> {
  Timer? _sessionTimer;
  int _secondsRemaining = 0;
  int _secondsElapsed = 0;
  final List<SessionEpoch> _timeline = [];

  // Aggregation counters
  int _calmSeconds = 0;
  int _neutralSeconds = 0;
  int _activeSeconds = 0;
  int _birdsEarned = 0;
  int _recoveries = 0;
  MindState _lastState = MindState.neutral;
  final List<double> _bpmSamples = [];
  final List<double> _stillnessSamples = [];

  StreamSubscription<SignalReading>? _readingSub;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationMinutes * 60;

    // Start Muse 2 stream
    final muse = ref.read(museServiceProvider);
    muse.startSession();

    // Listen to real-time telemetry
    _readingSub = muse.readingStream.listen((reading) {
      if (_lastState == MindState.active && reading.mindState == MindState.calm) {
        _recoveries++;
      }
      _lastState = reading.mindState;
      if (reading.heartRateBpm != null) {
        _bpmSamples.add(reading.heartRateBpm!.toDouble());
      }
      _stillnessSamples.add(reading.stillnessScore);
      _birdsEarned = reading.calmPoints;
    });

    // 1-second session clock
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        _secondsRemaining--;

        // Track state time
        if (_lastState == MindState.calm) {
          _calmSeconds++;
        } else if (_lastState == MindState.active) {
          _activeSeconds++;
        } else {
          _neutralSeconds++;
        }

        // Record epoch
        _timeline.add(SessionEpoch(
          secondOffset: _secondsElapsed,
          state: _lastState,
          bpm: _bpmSamples.isNotEmpty ? _bpmSamples.last : 0.0,
          stillness: _stillnessSamples.isNotEmpty ? _stillnessSamples.last : 100.0,
        ));
      });

      if (_secondsRemaining <= 0) {
        _completeSession();
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _readingSub?.cancel();
    ref.read(museServiceProvider).stopSession();
    super.dispose();
  }

  void _completeSession() {
    _sessionTimer?.cancel();
    _readingSub?.cancel();

    final totalSec = _secondsElapsed > 0 ? _secondsElapsed : 1;
    final calmPct = (_calmSeconds / totalSec) * 100.0;
    final neutralPct = (_neutralSeconds / totalSec) * 100.0;
    final activePct = (_activeSeconds / totalSec) * 100.0;

    final avgBpm = _bpmSamples.isNotEmpty
        ? _bpmSamples.reduce((a, b) => a + b) / _bpmSamples.length
        : 0.0;
    final avgStillness = _stillnessSamples.isNotEmpty
        ? _stillnessSamples.reduce((a, b) => a + b) / _stillnessSamples.length
        : 100.0;

    final user = ref.read(authStateProvider).value;

    final session = MeditationSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.uid ?? 'anonymous',
      mode: widget.mode,
      startedAt: DateTime.now().subtract(Duration(seconds: _secondsElapsed)),
      completedAt: DateTime.now(),
      durationSeconds: _secondsElapsed,
      calmPercent: calmPct,
      neutralPercent: neutralPct,
      activePercent: activePct,
      calmPoints: _birdsEarned * 10,
      birdsAwarded: _birdsEarned,
      recoveries: _recoveries,
      averageBpm: avgBpm,
      averageRmssd: 0.0,
      averageStillness: avgStillness,
      timeline: _timeline,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SessionResultsScreen(session: session)),
    );
  }

  String _formatTimer(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final readingAsync = ref.watch(signalReadingProvider);
    final reading = readingAsync.value ?? SignalReading.idle();

    // Responsive Aura Color based on real Muse mind state
    Color auraColor = MuseColors.neutralGlow;
    String stateLabel = 'NEUTRAL';

    switch (reading.mindState) {
      case MindState.calm:
        auraColor = MuseColors.calmGlow;
        stateLabel = 'CALM';
        break;
      case MindState.neutral:
        auraColor = MuseColors.neutralGlow;
        stateLabel = 'NEUTRAL';
        break;
      case MindState.active:
        auraColor = MuseColors.activeGlow;
        stateLabel = 'ACTIVE';
        break;
    }

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.lg, vertical: MuseSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.mode.displayName.toUpperCase(),
                    style: const TextStyle(
                      color: MuseColors.cyanGlow,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MuseColors.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatTimer(_secondsRemaining),
                      style: const TextStyle(
                        color: MuseColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Central Bioluminescent Neural Orb / Biofeedback Core with Atmospheric Glow
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: auraColor.withValues(alpha: 0.12),
                      blurRadius: 70,
                      spreadRadius: 25,
                    ),
                  ],
                ),
                child: BioluminescentNeuralOrb(
                  mindState: reading.mindState,
                  alphaPower: reading.alpha,
                  betaPower: reading.beta,
                  heartRateBpm: reading.heartRateBpm,
                  size: 240,
                  centerLabel: stateLabel,
                  subLabel: 'BREATHE',
                  showTelemetryRings: true,
                ),
              ),
            ),

            const Spacer(),

            // Real-time Telemetry HUD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _HudItem(
                    icon: Icons.flutter_dash,
                    color: MuseColors.cyanGlow,
                    value: '$_birdsEarned',
                    label: 'Birds Landed',
                  ),
                  _HudItem(
                    icon: Icons.favorite,
                    color: MuseColors.roseGlow,
                    value: reading.heartRateBpm != null ? '${reading.heartRateBpm}' : '--',
                    label: 'BPM',
                  ),
                  _HudItem(
                    icon: Icons.accessibility_new,
                    color: MuseColors.fitGood,
                    value: '${reading.stillnessScore.toInt()}%',
                    label: 'Stillness',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MuseSpacing.xxl),

            // End Session Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.xl, vertical: MuseSpacing.md),
              child: MuseButton(
                label: 'End Session',
                variant: MuseButtonVariant.outline,
                width: double.infinity,
                onPressed: _completeSession,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _HudItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: MuseColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: MuseColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
