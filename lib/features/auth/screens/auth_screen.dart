import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';
import 'therapist_registration_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (_isRegistering && password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match. Please verify your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (_isRegistering) {
        await auth.registerWithEmailAndPassword(
          email: email,
          password: password,
          displayName: name.isNotEmpty ? name : null,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\]'), '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\]'), '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.xl, vertical: MuseSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing Muse Orb
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [MuseColors.cyanGlow, Color(0xFF003847)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MuseColors.cyanGlow.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.self_improvement,
                      size: 44,
                      color: MuseColors.spaceBackground,
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),
                const Text(
                  'NEUROSHIFT',
                  style: TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: MuseSpacing.xs),
                const Text(
                  'Physiological Meditation & Biofeedback',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: MuseSpacing.xl),

                if (_isRegistering) ...[
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: MuseColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Your Name (optional)',
                      prefixIcon: const Icon(Icons.person_outline, color: MuseColors.textSecondary),
                      fillColor: MuseColors.cardSurface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                        borderSide: const BorderSide(color: MuseColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: MuseSpacing.md),
                ],

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: MuseColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: const Icon(Icons.mail_outline, color: MuseColors.textSecondary),
                    fillColor: MuseColors.cardSurface,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                      borderSide: const BorderSide(color: MuseColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: MuseColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: _isRegistering ? 'Create Password (min. 6 chars)' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: MuseColors.textSecondary),
                    fillColor: MuseColors.cardSurface,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                      borderSide: const BorderSide(color: MuseColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),

                // Confirm Password Field (Registration only)
                if (_isRegistering) ...[
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: MuseColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: MuseColors.textSecondary),
                      fillColor: MuseColors.cardSurface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                        borderSide: const BorderSide(color: MuseColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: MuseSpacing.md),
                ],

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(MuseSpacing.sm),
                    decoration: BoxDecoration(
                      color: MuseColors.roseGlow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(MuseSpacing.radiusSm),
                      border: Border.all(color: MuseColors.roseGlow.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: MuseColors.roseGlow, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: MuseColors.roseGlow, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MuseSpacing.md),
                ],

                MuseButton(
                  label: _isRegistering ? 'Create Account' : 'Sign In',
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: MuseSpacing.md),

                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: MuseColors.cardBorder)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: MuseSpacing.md),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: MuseColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: MuseColors.cardBorder)),
                  ],
                ),
                const SizedBox(height: MuseSpacing.md),

                MuseButton(
                  label: 'Continue with Google',
                  variant: MuseButtonVariant.secondary,
                  width: double.infinity,
                  isLoading: _isGoogleLoading,
                  icon: Icons.account_circle,
                  onPressed: _signInWithGoogle,
                ),
                const SizedBox(height: MuseSpacing.md),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                      _errorMessage = null;
                      _confirmPasswordController.clear();
                    });
                  },
                  child: Text(
                    _isRegistering
                        ? 'Already have an account? Sign In'
                        : "Don't have an account? Create one",
                    style: const TextStyle(
                      color: MuseColors.cyanGlow,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.lg),

                // Professional Practitioner Portal Link
                MuseCard(
                  backgroundColor: MuseColors.cardSurface.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.md, vertical: MuseSpacing.sm + 2),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TherapistRegistrationScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MuseColors.mysticPurple.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: MuseColors.mysticPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: MuseSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Are you a clinician or therapist?',
                              style: TextStyle(
                                color: MuseColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Register for the Practitioner Portal →',
                              style: TextStyle(
                                color: MuseColors.cyanGlow,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: MuseColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
