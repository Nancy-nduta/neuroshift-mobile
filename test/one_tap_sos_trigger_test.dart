import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/features/chat/models/crisis_helpline.dart';
import 'package:neuroshift_mobile/features/chat/services/crisis_detector.dart';
import 'package:neuroshift_mobile/features/chat/widgets/one_tap_sos_trigger_card.dart';

void main() {
  group('One-Tap Cascading Crisis SOS Trigger Tests', () {
    test('CrisisResources returns prioritized Kenyan and international toll-free helplines', () {
      final keRes = CrisisResources('KE');
      expect(keRes.helplines.isNotEmpty, isTrue);
      expect(keRes.helplines.first.phoneNumber, equals('1199'));
      expect(keRes.helplines.first.name, contains('Kenya Red Cross'));
      expect(keRes.helplines[1].phoneNumber, equals('1190'));
      expect(keRes.helplines[1].name, contains('LVCT Health'));
      expect(keRes.helplines[2].phoneNumber, equals('116'));
      expect(keRes.helplines[3].phoneNumber, equals('112'));

      final usRes = CrisisResources('US');
      expect(usRes.helplines.first.phoneNumber, equals('988'));

      final gbRes = CrisisResources('GB');
      expect(gbRes.helplines.first.phoneNumber, equals('116123'));
    });

    testWidgets('Renders OneTapSosTriggerCard with primary toll-free helpline and cascade buttons',
        (tester) async {
      const mockHelplines = [
        CrisisHelpline(
          id: 'test_1',
          name: 'Kenya Red Cross',
          phoneNumber: '1199',
          formattedDisplayNumber: '1199',
          description: '24/7 National Psychological First Aid & Suicide Crisis',
          isTollFree: true,
          priorityBadge: 'Priority 1 (Toll-Free)',
        ),
        CrisisHelpline(
          id: 'test_2',
          name: 'Chiromo Hospital Helpline',
          phoneNumber: '0800220000',
          formattedDisplayNumber: '0800 220 000',
          description: '24/7 Psychiatric & Crisis Triage',
          isTollFree: true,
          priorityBadge: 'Priority 2 (Toll-Free)',
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OneTapSosTriggerCard(
                helplines: mockHelplines,
              ),
            ),
          ),
        ),
      );

      // Verify header and primary call button
      expect(find.text('ONE-TAP CRISIS SOS HELPLINE'), findsOneWidget);
      expect(find.text('LINE 1 OF 2'), findsOneWidget);
      expect(find.text('Kenya Red Cross'), findsOneWidget);
      expect(find.textContaining('ONE-TAP CALL: 1199 (FREE)'), findsOneWidget);

      // Tap directory expansion
      final expandButton = find.textContaining('View all 2 verified emergency lines');
      expect(expandButton, findsOneWidget);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      expect(find.text('Chiromo Hospital Helpline'), findsOneWidget);
      expect(find.text('0800 220 000'), findsOneWidget);
    });
  });
}
