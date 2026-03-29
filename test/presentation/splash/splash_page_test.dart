import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Stub destination pages — avoids pulling in real page dependencies (GetIt, Firebase)
class _StubHome extends StatelessWidget {
  const _StubHome();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('home'));
}

class _StubGetStarted extends StatelessWidget {
  const _StubGetStarted();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('get_started'));
}

// Testable SplashPage that accepts injected auth and destination builders
class TestableSplashPage extends StatefulWidget {
  final FirebaseAuth auth;
  final Widget signedInDest;
  final Widget signedOutDest;
  const TestableSplashPage({
    super.key,
    required this.auth,
    required this.signedInDest,
    required this.signedOutDest,
  });

  @override
  State<TestableSplashPage> createState() => _TestableSplashPageState();
}

class _TestableSplashPageState extends State<TestableSplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = widget.auth.currentUser;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user != null ? widget.signedInDest : widget.signedOutDest,
      ),
    );
  }
}

void main() {
  testWidgets('routes to signed-out destination when no user is signed in',
      (tester) async {
    final mockAuth = MockFirebaseAuth(signedIn: false);
    await tester.pumpWidget(MaterialApp(
      home: TestableSplashPage(
        auth: mockAuth,
        signedInDest: const _StubHome(),
        signedOutDest: const _StubGetStarted(),
      ),
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('get_started'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });

  testWidgets('routes to signed-in destination when user is already signed in',
      (tester) async {
    final mockAuth = MockFirebaseAuth(signedIn: true);
    await tester.pumpWidget(MaterialApp(
      home: TestableSplashPage(
        auth: mockAuth,
        signedInDest: const _StubHome(),
        signedOutDest: const _StubGetStarted(),
      ),
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.text('get_started'), findsNothing);
  });
}
