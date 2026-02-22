import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../app/theme.dart';
import 'auth_wrapper.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .register(username, email, password);

    if (mounted) {
      if (success) {
        // Enforce a hard routing reset to AuthWrapper which will now evaluate true
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Premium Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0C20), // Darker than darkBackground
                    Color(0xFF1E173D), // Deep purple tint
                    Color(0xFF0F0C20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      size: 64,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'NEW AWAKENING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: AppTheme.primaryPurple,
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Register to begin your journey as a Player',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 56),

                    // Glassmorphic Form Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Username
                          _buildPremiumTextField(
                            controller: _usernameController,
                            label: 'Player Designation',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildPremiumTextField(
                            controller: _emailController,
                            label: 'Player Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildPremiumTextField(
                            controller: _passwordController,
                            label: 'Passkey Formulation',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 10,
                                shadowColor: AppTheme.primaryPurple.withOpacity(
                                  0.6,
                                ),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'ACCEPT INTEGRATION',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Navigate to Login
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already a Player? ',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Return to interface.',
                              style: TextStyle(
                                color: AppTheme.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        floatingLabelStyle: const TextStyle(
          color: AppTheme.primaryPurple,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }
}
