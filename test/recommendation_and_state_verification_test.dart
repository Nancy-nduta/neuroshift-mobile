import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/models/signal_reading.dart';
import 'package:neuroshift_mobile/services/signal_processing/eeg_band_analyzer.dart';
import 'package:neuroshift_mobile/features/resources/models/resource_evaluation.dart';
import 'package:neuroshift_mobile/features/resources/models/resource_item.dart';
import 'package:neuroshift_mobile/features/resources/providers/resource_ranking_provider.dart';

void main() {
  group('EEG Classification Proof: Confusion Matrix & Performance Metrics', () {
    test('Calculates Confusion Matrix, Precision, Recall, and F1-score across 300 synthetic trials', () {
      const samplingRate = 256.0;
      const windowSamples = 256;
      const analyzer = EegBandAnalyzer(defaultSamplingRate: samplingRate);

      // Classes: 0 = Calm, 1 = Neutral, 2 = Active
      final matrix = List.generate(3, (_) => List.filled(3, 0));
      const classNames = ['Calm', 'Neutral', 'Active'];

      // Helper to generate synthetic signal
      List<double> generateWave({
        required double alphaAmp,
        required double betaAmp,
        required double thetaAmp,
        required double noiseAmp,
        required math.Random rng,
      }) {
        return List<double>.generate(windowSamples, (i) {
          final t = i / samplingRate;
          return alphaAmp * math.sin(2 * math.pi * 10.0 * t + rng.nextDouble()) +
              betaAmp * math.sin(2 * math.pi * 20.0 * t + rng.nextDouble()) +
              thetaAmp * math.sin(2 * math.pi * 6.0 * t + rng.nextDouble()) +
              (rng.nextDouble() - 0.5) * noiseAmp;
        });
      }

      final rng = math.Random(42);
      const trialsPerClass = 100;

      // 1. Generate 100 Ground Truth CALM trials (High Alpha 10 Hz, low Beta)
      for (int i = 0; i < trialsPerClass; i++) {
        final signal = generateWave(
          alphaAmp: 35.0 + rng.nextDouble() * 15.0, // 35 - 50 uV
          betaAmp: 10.0 + rng.nextDouble() * 5.0,   // 10 - 15 uV
          thetaAmp: 8.0 + rng.nextDouble() * 4.0,
          noiseAmp: 3.0,
          rng: rng,
        );
        final result = analyzer.analyzeWindow(signal);
        expect(result, isNotNull);
        final predIdx = result!.state == MindState.calm
            ? 0
            : (result.state == MindState.neutral ? 1 : 2);
        matrix[0][predIdx]++;
      }

      // 2. Generate 100 Ground Truth NEUTRAL trials (Balanced Alpha and Beta)
      for (int i = 0; i < trialsPerClass; i++) {
        final signal = generateWave(
          alphaAmp: 22.0 + rng.nextDouble() * 4.0, // 22 - 26 uV
          betaAmp: 22.0 + rng.nextDouble() * 4.0,  // 22 - 26 uV
          thetaAmp: 12.0 + rng.nextDouble() * 4.0,
          noiseAmp: 4.0,
          rng: rng,
        );
        final result = analyzer.analyzeWindow(signal);
        expect(result, isNotNull);
        final predIdx = result!.state == MindState.calm
            ? 0
            : (result.state == MindState.neutral ? 1 : 2);
        matrix[1][predIdx]++;
      }

      // 3. Generate 100 Ground Truth ACTIVE trials (High Beta 20 Hz, low Alpha)
      for (int i = 0; i < trialsPerClass; i++) {
        final signal = generateWave(
          alphaAmp: 10.0 + rng.nextDouble() * 5.0,  // 10 - 15 uV
          betaAmp: 35.0 + rng.nextDouble() * 15.0,  // 35 - 50 uV
          thetaAmp: 8.0 + rng.nextDouble() * 4.0,
          noiseAmp: 3.0,
          rng: rng,
        );
        final result = analyzer.analyzeWindow(signal);
        expect(result, isNotNull);
        final predIdx = result!.state == MindState.calm
            ? 0
            : (result.state == MindState.neutral ? 1 : 2);
        matrix[2][predIdx]++;
      }

      // Calculate Metrics
      int totalCorrect = matrix[0][0] + matrix[1][1] + matrix[2][2];
      const totalSamples = trialsPerClass * 3;
      final overallAccuracy = (totalCorrect / totalSamples) * 100.0;

      // Print Beautiful Confusion Matrix & Proof Report
      // ignore: avoid_print
      print('\n===============================================================');
      // ignore: avoid_print
      print('          NEUROSHIFT EEG MIND STATE CONFUSION MATRIX           ');
      // ignore: avoid_print
      print('===============================================================');
      // ignore: avoid_print
      print('                   Pred Calm | Pred Neutral | Pred Active | Recall');
      for (int i = 0; i < 3; i++) {
        final totalActual = matrix[i][0] + matrix[i][1] + matrix[i][2];
        final recall = (matrix[i][i] / totalActual) * 100.0;
        final name = classNames[i].padRight(12);
        // ignore: avoid_print
        print(
          'Actual $name :   ${matrix[i][0].toString().padLeft(4)}   |    ${matrix[i][1].toString().padLeft(4)}    |    ${matrix[i][2].toString().padLeft(4)}   | ${recall.toStringAsFixed(1)}%',
        );
      }
      // ignore: avoid_print
      print('---------------------------------------------------------------');
      final precisions = <double>[];
      for (int j = 0; j < 3; j++) {
        final totalPred = matrix[0][j] + matrix[1][j] + matrix[2][j];
        final prec = totalPred > 0 ? (matrix[j][j] / totalPred) * 100.0 : 0.0;
        precisions.add(prec);
      }
      // ignore: avoid_print
      print(
        'Precision   :    ${precisions[0].toStringAsFixed(1)}%   |    ${precisions[1].toStringAsFixed(1)}%   |    ${precisions[2].toStringAsFixed(1)}%',
      );
      // ignore: avoid_print
      print('OVERALL CLASSIFIER ACCURACY: ${overallAccuracy.toStringAsFixed(2)}% ($totalCorrect / $totalSamples correct)');
      // ignore: avoid_print
      print('===============================================================\n');

      // Assert high statistical validity
      expect(overallAccuracy, greaterThanOrEqualTo(95.0));
      expect(matrix[0][0], greaterThanOrEqualTo(90)); // Calm Recall >= 90%
      expect(matrix[2][2], greaterThanOrEqualTo(90)); // Active Recall >= 90%
    });
  });

  group('Recommendation Engine Proof: Reinforcement Learning & Bandit Proofs', () {
    test('RL Model updates Q-value, adapts policies, and demonstrates category affinity transfer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(resourceRankingsProvider.notifier);

      // Step 1: Initial state has baseline bandit priors (62.0)
      final med01 = ResourceItem.catalog.firstWhere((r) => r.id == 'med_01');
      final med02 = ResourceItem.catalog.firstWhere((r) => r.id == 'med_02');
      final nature01 = ResourceItem.catalog.firstWhere((r) => r.id == 'nature_01');

      final initialMed01Score = notifier.expectedBanditScore(med01);
      final initialNature01Score = notifier.expectedBanditScore(nature01);
      expect(initialMed01Score, equals(62.0));
      expect(initialNature01Score, equals(62.0));

      // Step 2: User completes a highly successful Guided Meditation session
      final highRewardEval = ResourceEvaluation(
        resourceId: 'med_01',
        resourceTitle: 'Deep Calm Breathing',
        category: ResourceCategory.guidedMeditation.label,
        calmPercent: 88.0,
        neutralPercent: 10.0,
        activePercent: 2.0,
        durationSeconds: 300,
        averageStillness: 92.0,
        starRating: 5,
        moodShift: 'Significantly Calmer',
        wouldRecommend: true,
        usedHeadband: true,
        timestamp: DateTime.now(),
        preValence: 2,
        postValence: 5, // +3 mood shift
        mentalCalmScore: 5,
        bodyRelaxationScore: 5,
        focusClarityScore: 5,
        pacingFit: 'Just Right',
        wouldUseAgain: true,
      );

      notifier.recordEvaluation(highRewardEval);

      // Verify direct reward boosted med_01
      final updatedMed01Score = notifier.expectedBanditScore(med01);
      expect(updatedMed01Score, greaterThan(80.0));

      // Verify Category Affinity Transfer:
      // Even though med_02 was NEVER played yet, its score rises because user thrives in Guided Practice!
      final transferredMed02Score = notifier.expectedBanditScore(med02);
      expect(transferredMed02Score, greaterThan(initialMed01Score));

      // Step 3: Verify Policy Pivot when session is distracting
      final distractingEval = ResourceEvaluation(
        resourceId: 'nature_01',
        resourceTitle: 'Ocean Waves',
        category: 'Nature Soundscapes',
        calmPercent: 20.0,
        neutralPercent: 30.0,
        activePercent: 50.0,
        durationSeconds: 180,
        averageStillness: 60.0,
        starRating: 1,
        moodShift: 'Distracting / Restless',
        wouldRecommend: false,
        usedHeadband: true,
        timestamp: DateTime.now(),
        preValence: 2,
        postValence: 2,
        mentalCalmScore: 1,
        bodyRelaxationScore: 2,
        focusClarityScore: 2,
        pacingFit: 'Audio Distracting',
        wouldUseAgain: false, // Explicit negative signal
      );

      notifier.recordEvaluation(distractingEval);

      final nextRec = notifier.recommendFromEvaluation(distractingEval);

      // The RL model MUST pivot away from Nature Soundscapes due to negative reward!
      expect(nextRec.resource.category.label, isNot(equals('Nature Soundscapes')));
      expect(nextRec.policyReason, contains('pivoted away'));

      // ignore: avoid_print
      print('\n===============================================================');
      // ignore: avoid_print
      print('       REINFORCEMENT LEARNING RECOMMENDATION VERIFICATION      ');
      // ignore: avoid_print
      print('===============================================================');
      // ignore: avoid_print
      print('Initial Unseen Prior Score      : $initialMed01Score');
      // ignore: avoid_print
      print('Post-Reward Direct Score (med_01): ${updatedMed01Score.toStringAsFixed(1)} (Boosted by RL)');
      // ignore: avoid_print
      print('Category Transfer Score (med_02) : ${transferredMed02Score.toStringAsFixed(1)} (Transfer learning without direct trial!)');
      // ignore: avoid_print
      print('Policy Pivot Triggered           : ${nextRec.resource.title} (${nextRec.resource.category.label})');
      // ignore: avoid_print
      print('Policy Rationale                 : "${nextRec.policyReason}"');
      // ignore: avoid_print
      print('===============================================================\n');
    });
  });
}
