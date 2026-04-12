import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/configs/assets/app_vectors.dart';
import '../../get_start/pages/get_started_page.dart';
import '../../home/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Animation 1: AnimatedOpacity — logo fades in on splash screen load.
  double _logoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger fade-in shortly after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _logoOpacity = 1.0);
    });
    redirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _logoOpacity,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeIn,
          child: SvgPicture.asset(
            AppVectors.logo,
          ),
        ),
      ),
    );
  }

  Future<void> redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              session != null ? const HomePage() : const GetStartedPage(),
        ),
      );
    } catch (_) {
      // Supabase not initialised (e.g. during tests); silently ignore.
    }
  }
}
