import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museai/presentation/splash/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders without errors', (tester) async {
    // SplashPage routing depends on Supabase.instance which requires
    // initialization — routing tests will be covered in integration tests (#20).
    // This smoke test verifies the initial widget frame builds correctly.
    //
    // redirect() catches the Supabase-not-initialised StateError internally,
    // so pumping past the 2s timer is safe and drains the pending fake timer.
    await tester.pumpWidget(
      const MaterialApp(home: SplashPage()),
    );
    expect(find.byType(SplashPage), findsOneWidget);

    // Drain the pending 2s timer so the test framework does not assert on it.
    await tester.pump(const Duration(seconds: 3));
  });
}
