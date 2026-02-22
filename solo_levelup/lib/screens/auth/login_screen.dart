import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../app/theme.dart';
import 'auth_wrapper.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .login(email, password);

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
            content: Text(error ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
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
                      Icons.security,
                      size: 64,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SYSTEM AWAKENED',
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
                      'Authenticate to access the Player interface',
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
                      padding: const EdgeInsets.all(24),
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
                          // Email
                          _buildPremiumTextField(
                            controller: _emailController,
                            label: 'Player Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),

                          // Password
                          _buildPremiumTextField(
                            controller: _passwordController,
                            label: 'Passkey',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 40),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _login,
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
                                      'INITIALIZE LINK',
                                      style: TextStyle(
                                        fontSize: 18,
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

                    // Navigate to Register
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Unregistered Player? ',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Awaken Here.',
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
