import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/reusable_button.dart';
import 'controllers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background, Color(0xFF1A0B3B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Join Nearmates',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Meet people near you. Share vibes.\nNo algorithms. Just proximity.',
                    style: TextStyle(fontSize: 14, color: Colors.white54, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  if (authState.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Text(
                        authState.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Phone (e.g. +91 9876543210)',
                      prefixIcon: Icon(Icons.phone_outlined, color: Colors.white38),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                      if (!v.trim().startsWith('+')) return 'Include country code (e.g. +91)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  if (authState.isLoading)
                    const Center(child: CircularProgressIndicator(color: AppTheme.mint))
                  else ...[
                    ReusableButton(
                      text: 'Continue with Phone',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ref.read(authControllerProvider.notifier)
                              .requestPhoneOtp(_phoneController.text.trim(), context);
                        }
                      },
                    ),
                    const SizedBox(height: 28),
                    const Row(children: [
                      Expanded(child: Divider(color: Colors.white12)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or continue with', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white12)),
                    ]),
                    const SizedBox(height: 24),
                    _SocialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Google',
                      onTap: () => ref.read(authControllerProvider.notifier).signInWithGoogle(context),
                    ),
                    const SizedBox(height: 12),
                    _SocialButton(
                      icon: Icons.apple_rounded,
                      label: 'Apple',
                      onTap: () => ref.read(authControllerProvider.notifier).signInWithApple(context),
                    ),
                  ],

                  const SizedBox(height: 40),
                  const Text(
                    'By continuing you agree to our Terms & Privacy Policy.',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white70, size: 22),
      label: Text('Continue with $label', style: const TextStyle(color: Colors.white70)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.white.withOpacity(0.15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
