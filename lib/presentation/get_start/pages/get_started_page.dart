import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:museai/common/widgets/buttons/primary_app_button.dart';
import 'package:museai/core/configs/assets/app_images.dart';
import 'package:museai/core/configs/assets/app_vectors.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/presentation/choose_mode/pages/choose_mode_page.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(AppImages.getStartedBg), fit: BoxFit.fill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topCenter,
                    child: SvgPicture.asset(AppVectors.logo)),
                const Spacer(),
                const Text(
                  'Create Music with AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pick your mood, genre, tempo, and instruments. MuseAI will generate an original track you can play, save, remix, and share.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PrimaryAppButton(
                  onPressed: () {
                    // Animation 3: SlideTransition — ChooseModePage slides up from the bottom.
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const ChooseModePage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          final tween = Tween(
                            begin: const Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeInOut));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                    );
                  },
                  title: const Text(
                    'Get Started',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
