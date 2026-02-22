import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import '../screens/auth/auth_wrapper.dart';

/// Main app widget with bottom navigation
class SoloLevelUpApp extends ConsumerStatefulWidget {
  const SoloLevelUpApp({super.key});

  @override
  ConsumerState<SoloLevelUpApp> createState() => _SoloLevelUpAppState();
}

class _SoloLevelUpAppState extends ConsumerState<SoloLevelUpApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The System',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
