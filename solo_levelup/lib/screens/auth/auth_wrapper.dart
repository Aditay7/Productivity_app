import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../main_screen.dart';
import 'login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0F16), // Deeper core background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouncing, pulsing app logo
              Image.asset('lib/assets/app_logo1.png', width: 100, height: 100)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 2.seconds,
                    color: const Color(0xFF00FFCC).withOpacity(0.5),
                  )
                  .scaleXY(
                    begin: 0.9,
                    end: 1.1,
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scaleXY(
                    begin: 1.1,
                    end: 0.9,
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),

              const SizedBox(height: 32),

              // Glowing text
              const Text(
                    'SYSTEM INITIALIZING...',
                    style: TextStyle(
                      color: Color(0xFF00FFCC),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: Color(0xFF00FFCC), blurRadius: 10),
                      ],
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .fade(begin: 0.3, end: 1.0, duration: 1.seconds),
            ],
          ),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
