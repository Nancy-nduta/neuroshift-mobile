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

      // Header branding
      expect(find.text('NOVA AI'), findsAtLeastNWidgets(1));
      expect(find.text('BIO-RAG'), findsOneWidget);

      // Offline telemetry HUD strip
      expect(find.textContaining('Muse 2 Headband Offline'), findsOneWidget);

      // Initial welcome message from Nova
      expect(find.textContaining('NeuroShift AI Mental Health'), findsOneWidget);

      // Quick action chips
      expect(find.text('🧠 Analyze My Brainwaves'), findsAtLeastNWidgets(1));
      expect(find.text('⚡ Calm Anxiety Now'), findsAtLeastNWidgets(1));
    });

    testWidgets('Tapping quick topic chip sends message and synthesizes Bio-RAG response', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AiWellnessChatScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap '⚡ Calm Anxiety Now' chip
      final chip = find.text('⚡ Calm Anxiety Now').first;
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pump();

      // Typing indicator should appear
      expect(find.text('Nova is thinking...'), findsOneWidget);

      // Wait for AI response synthesis (400ms delayed)
      await tester.pump(const Duration(milliseconds: 500));
      // Flush post-frame callback
      await tester.pump();
      // Complete scroll animation (300ms)
      await tester.pump(const Duration(milliseconds: 400));

      // Verify that the response bubble with clinical content was added
      expect(find.textContaining('Autonomic Panic'), findsOneWidget);
      expect(find.textContaining('Physiological Sigh'), findsOneWidget);
      expect(find.text('Start ➔'), findsOneWidget);
    });
  });
}

// Canonical transparent 1x1 image & mock HTTP client for widget tests
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
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];
