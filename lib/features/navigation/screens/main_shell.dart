import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroshift_mobile/core/providers/app_providers.dart';
import 'package:neuroshift_mobile/core/theme/muse_colors.dart';
import 'package:neuroshift_mobile/features/chat/screens/ai_wellness_chat_screen.dart';
import 'package:neuroshift_mobile/features/connect/screens/headband_connect_screen.dart';
import 'package:neuroshift_mobile/features/meditate/screens/meditate_home_screen.dart';
import 'package:neuroshift_mobile/features/profile/screens/profile_screen.dart';
import 'package:neuroshift_mobile/features/resources/screens/resources_screen.dart';
import 'package:neuroshift_mobile/features/therapist/screens/therapist_dashboard_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  void _onTabSelected(int index) {
    ref.read(mainNavIndexProvider.notifier).setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = ref.watch(isTherapistProvider);

    final List<Widget> screens;
    final List<NavigationDestination> destinations;

    if (isTherapist) {
      screens = [
        const TherapistDashboardScreen(),
        MeditateHomeScreen(onOpenConnectTab: () => _onTabSelected(2)),
        const HeadbandConnectScreen(),
        const ResourcesScreen(),
        const AiWellnessChatScreen(),
        const ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.medical_services_outlined, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.medical_services, color: MuseColors.mysticPurple),
          label: 'Clinical',
        ),
        NavigationDestination(
          icon: Icon(Icons.self_improvement_outlined, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.self_improvement, color: MuseColors.cyanGlow),
          label: 'Meditate',
        ),
        NavigationDestination(
          icon: Icon(Icons.sensors, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.sensors, color: MuseColors.cyanGlow),
          label: 'Connect',
        ),
        NavigationDestination(
          icon: Icon(Icons.spa_outlined, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.spa, color: MuseColors.cyanGlow),
          label: 'Resources',
        ),
        NavigationDestination(
          icon: Icon(Icons.psychology_alt_outlined, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.psychology_alt, color: MuseColors.cyanGlow),
          label: 'AI Guide',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.person, color: MuseColors.cyanGlow),
          label: 'Profile',
        ),
      ];
    } else {
      screens = [
        MeditateHomeScreen(onOpenConnectTab: () => _onTabSelected(1)),
        const HeadbandConnectScreen(),
        const ResourcesScreen(),
        const AiWellnessChatScreen(),
        const ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.self_improvement_outlined, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.self_improvement, color: MuseColors.cyanGlow),
          label: 'Meditate',
        ),
        NavigationDestination(
          icon: Icon(Icons.sensors, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.sensors, color: MuseColors.cyanGlow),
          label: 'Connect',
        ),
        NavigationDestination(
          icon: Icon(Icons.spa_outlined, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.spa, color: MuseColors.cyanGlow),
          label: 'Resources',
        ),
        NavigationDestination(
          icon: Icon(Icons.psychology_alt_outlined, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.psychology_alt, color: MuseColors.cyanGlow),
          label: 'AI Guide',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: MuseColors.textSecondary),
          selectedIcon: Icon(Icons.person, color: MuseColors.cyanGlow),
          label: 'Profile',
        ),
      ];
    }

    final currentIndex = ref.watch(mainNavIndexProvider);
    final safeIndex = currentIndex < screens.length ? currentIndex : 0;

    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1A).withValues(alpha: 0.96),
          border: const Border(
            top: BorderSide(color: Color(0x334DF0FF), width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: MuseColors.cyanGlow.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: _onTabSelected,
          backgroundColor: Colors.transparent,
          indicatorColor: isTherapist && safeIndex == 0
              ? MuseColors.mysticPurple.withValues(alpha: 0.25)
              : MuseColors.cyanGlow.withValues(alpha: 0.2),
          destinations: destinations,
        ),
      ),
    );
  }
}
