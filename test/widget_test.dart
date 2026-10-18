import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/core/widgets/horseshoe_fit_widget.dart';
import 'package:neuroshift_mobile/models/sensor_status.dart';

void main() {
  testWidgets('HorseshoeFitWidget renders fit percentage and electrodes', (WidgetTester tester) async {
    const fit = HorseshoeFit(
      tp9: FitQuality.good,
      af7: FitQuality.good,
      fpz: FitQuality.good,
      af8: FitQuality.good,
      tp10: FitQuality.good,
      stabilityScore: 1.0,
      isStable: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HorseshoeFitWidget(fit: fit, size: 200),
        ),
      ),
    );

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('SIGNAL STABLE'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('TP9 (L Ear)'), findsOneWidget);
    expect(find.text('AF7 (L Front)'), findsOneWidget);
    expect(find.text('FPz (Center/Pulse)'), findsOneWidget);
    expect(find.text('AF8 (R Front)'), findsOneWidget);
    expect(find.text('TP10 (R Ear)'), findsOneWidget);
  });
}
