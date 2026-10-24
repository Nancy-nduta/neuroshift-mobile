import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/features/chat/screens/ai_wellness_chat_screen.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('AiWellnessChatScreen Widget Tests', () {
    testWidgets('Renders Nova AI chat interface with Bio-RAG badges and offline strip', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AiWellnessChatScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('NOVA AI'), findsAtLeastNWidgets(1));
      expect(find.text('BIO-RAG'), findsOneWidget);
      expect(find.textContaining('Muse 2 Headband Offline'), findsOneWidget);
      expect(find.textContaining('NeuroShift AI Mental Health'), findsOneWidget);
      expect(find.text('🧠 Analyze My Brainwaves'), findsAtLeastNWidgets(1));
      expect(find.text('⚡ Calm Anxiety Now'), findsAtLeastNWidgets(1));
    });

    testWidgets('Typing "Hi Nova" replies naturally without rendering a resource card', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AiWellnessChatScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Hi Nova');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Hi Nova'), findsOneWidget);
      expect(
        find.textContaining("Hi there! I'm Nova. How are you feeling today"),
        findsOneWidget,
      );
      expect(find.text('Start ➔'), findsNothing);
    });

    testWidgets('Tapping quick topic chip sends exercise request and renders grounded response with resource card', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AiWellnessChatScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final chip = find.text('⚡ Calm Anxiety Now').first;
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('Acute anxiety, stress and panic'),
        findsOneWidget,
      );
      expect(find.text('EVIDENCE REFERENCE'), findsOneWidget);
      expect(find.textContaining('Sources:'), findsOneWidget);
      expect(find.text('Start ➔'), findsOneWidget);
    });

    testWidgets('Isolates chat session per authenticated user and clears messages when user UID changes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatSessionUserIdProvider.overrideWithValue('user_alpha'),
          ],
          child: const MaterialApp(
            home: AiWellnessChatScreen(),
          ),
        ),
      );
      await tester.pump();

      // User Alpha sends a private emotional message
      await tester.enterText(
        find.byType(TextField),
        'My private message from user alpha',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('My private message from user alpha'), findsOneWidget);

      // Switch account to User Beta
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatSessionUserIdProvider.overrideWithValue('user_beta'),
          ],
          child: const MaterialApp(
            home: AiWellnessChatScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // User Alpha's message must no longer be visible
      expect(find.text('My private message from user alpha'), findsNothing);
      expect(find.textContaining('NeuroShift AI Mental Health'), findsOneWidget);
    });
  });
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return null;
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];
