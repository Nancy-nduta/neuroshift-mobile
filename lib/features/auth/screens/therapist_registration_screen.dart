import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/muse_colors.dart';
import '../../../core/theme/muse_spacing.dart';
import '../../../core/widgets/muse_button.dart';
import '../../../core/widgets/muse_card.dart';

class TherapistRegistrationScreen extends ConsumerStatefulWidget {
  const TherapistRegistrationScreen({super.key});

  @override
  ConsumerState<TherapistRegistrationScreen> createState() => _TherapistRegistrationScreenState();
}

class _TherapistRegistrationScreenState extends ConsumerState<TherapistRegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final org = _orgController.text.trim();
    final license = _licenseController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || org.isEmpty || license.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please complete all required practitioner fields.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match. Please verify your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.registerTherapist(
        email: email,
        password: password,
        displayName: name,
        organization: org,
        licenseNumber: license,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Practitioner profile created successfully! Welcome to NeuroShift.'),
            backgroundColor: MuseColors.breathMint,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\]'), '').trim();
        final lower = e.toString().toLowerCase();
        if (lower.contains('email-already-in-use')) {
          msg = 'This email is already registered. You can sign in directly from the login screen.';
        } else if (lower.contains('invalid-email')) {
          msg = 'Please enter a valid email address (e.g. clinician@clinic.org).';
        } else if (lower.contains('weak-password')) {
          msg = 'The password is too weak. Please use at least 6 characters.';
        } else if (lower.contains('permission-denied') || lower.contains('insufficient permissions')) {
          msg = 'Registration was partially blocked by security policy. Please verify your email format and details.';
        }
        setState(() {
          _errorMessage = msg;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MuseColors.spaceBackground,
      appBar: AppBar(
        title: const Text('PRACTITIONER PORTAL'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MuseColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: MuseSpacing.xl, vertical: MuseSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Practitioner Badge Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [MuseColors.mysticPurple, Color(0xFF320A5C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MuseColors.mysticPurple.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 36,
                      color: MuseColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),
                const Text(
                  'Clinician & Therapist Registration',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MuseColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: MuseSpacing.xs),
                const Text(
                  'Create your professional account to review client biofeedback, calm metrics, and session trends with client consent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MuseColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: MuseSpacing.xl),

                // Practitioner Notice
                MuseCard(
                  backgroundColor: MuseColors.cardSurface.withValues(alpha: 0.6),
                  padding: const EdgeInsets.all(MuseSpacing.md),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: MuseColors.cyanGlow, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Practitioner credentials require active state or organizational licensure for client linkage.',
                          style: TextStyle(color: MuseColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuseSpacing.lg),

                // Full Name
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: MuseColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Full Name (e.g. Dr. Alex Mercer, LMFT)',
                    prefixIcon: const Icon(Icons.badge_outlined, color: MuseColors.textSecondary),
                    fillColor: MuseColors.cardSurface,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                      borderSide: const BorderSide(color: MuseColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),

                // Professional Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: MuseColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Professional Email',
                    prefixIcon: const Icon(Icons.email_outlined, color: MuseColors.textSecondary),
                    fillColor: MuseColors.cardSurface,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                      borderSide: const BorderSide(color: MuseColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),

                // Organization / Clinic Name
                TextField(
                  controller: _orgController,
                  style: const TextStyle(color: MuseColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Clinic, Practice, or Organization',
                    prefixIcon: const Icon(Icons.business_outlined, color: MuseColors.textSecondary),
                    fillColor: MuseColors.cardSurface,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                      borderSide: const BorderSide(color: MuseColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),

                // License Number
                TextField(
                  controller: _licenseController,
                  style: const TextStyle(color: MuseColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Professional License # (e.g. PSY-98214)',
                    prefixIcon: const Icon(Icons.card_membership_outlined, color: MuseColors.textSecondary),
                    fillColor: MuseColors.cardSurface,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MuseSpacing.radiusMd),
                      borderSide: const BorderSide(color: MuseColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: MuseSpacing.md),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: MuseColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Create Password (min. 6 characters)',
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

                // Confirm Password
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
                  label: 'Register as Practitioner',
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: MuseSpacing.lg),

                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Return to Client Sign In',
                    style: TextStyle(
                      color: MuseColors.cyanGlow,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
