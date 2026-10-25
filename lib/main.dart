import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/theme/muse_colors.dart';
import 'core/theme/muse_theme.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/navigation/screens/main_shell.dart';
import 'features/onboarding/screens/onboarding_consent_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: NeuroShiftApp(),
    ),
  );
}

class NeuroShiftApp extends ConsumerWidget {
  const NeuroShiftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'NeuroShift',
      debugShowCheckedModeBanner: false,
      theme: MuseTheme.darkTheme,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const AuthScreen();
          }

          final consentState = ref.watch(userConsentRecordProvider);
          return consentState.when(
            data: (consentRecord) {
              if (consentRecord == null || !consentRecord.isActive) {
                return OnboardingConsentScreen(existingRecord: consentRecord);
              }
              return const MainShell();
            },
            loading: () => const Scaffold(
              backgroundColor: MuseColors.spaceBackground,
              body: Center(
                child: CircularProgressIndicator(color: MuseColors.cyanGlow),
              ),
            ),
            error: (_, _) => const OnboardingConsentScreen(),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: MuseColors.spaceBackground,
          body: Center(
            child: CircularProgressIndicator(color: MuseColors.cyanGlow),
          ),
        ),
        error: (err, stack) => Scaffold(
          backgroundColor: MuseColors.spaceBackground,
          body: Center(
            child: Text(
              'Startup Error: $err',
              style: const TextStyle(color: MuseColors.roseGlow),
            ),
          ),
        ),
      ),
    );
  }
}
