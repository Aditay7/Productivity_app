// This is a basic Flutter widget test for Solo Level Up app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solo_levelup/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SoloLevelUpApp()));

    // Verify that the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
