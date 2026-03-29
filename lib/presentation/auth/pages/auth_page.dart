import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:museai/common/widgets/buttons/primary_app_button.dart';
import 'package:museai/core/configs/assets/app_vectors.dart';
import 'package:museai/presentation/auth/pages/signup_page.dart';

import '../../../core/configs/assets/app_images.dart';
import '../../../core/configs/themes/app_colors.dart';
import 'signin_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBarWidget(),
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(AppVectors.topDesignAuthPage),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SvgPicture.asset(AppVectors.bottomDesignAuthPage),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(AppImages.authPageImage),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                SvgPicture.asset(AppVectors.logo),
                const SizedBox(
                  height: 50,
                ),
                const Text(
                  'Create Royalty-Free Music',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'MuseAI helps creators and listeners generate original AI tracks instantly from mood and genre preferences.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryAppButton(
                        height: 60,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpPage()));
                        },
                        title: const Text(
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignInPage()));
                        },
                        child: Text(
                          'Sign in',
                          style: TextStyle(
                            color: context.isDarkMode
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 50,
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
