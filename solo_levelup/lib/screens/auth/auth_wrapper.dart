import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../main_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E2128),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFCC)),
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
