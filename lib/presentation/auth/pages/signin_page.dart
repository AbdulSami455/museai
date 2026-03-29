import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:museai/common/widgets/buttons/primary_app_button.dart';
import 'package:museai/core/configs/assets/app_vectors.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/domain/usecases/auth/signin_usecase.dart';
import 'package:museai/presentation/auth/pages/signup_page.dart';
import 'package:museai/presentation/auth/widgets/text_field_widget.dart';

import '../../../domain/entities/auth/user_entity.dart';
import '../../../service_locator.dart';
import '../../home/pages/home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _signUpOption(context),
      appBar: AppBarWidget(
        title: SvgPicture.asset(
          AppVectors.logo,
          height: 40,
          width: 40,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                TextFieldWidget(
                  hintText: 'Enter Email',
                  inputType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(
                  height: 15,
                ),
                TextFieldWidget(
                  hintText: 'Password',
                  inputType: TextInputType.visiblePassword,
                  controller: _passwordController,
                ),
                const SizedBox(
                  height: 15,
                ),
                PrimaryAppButton(
                  onPressed: _signinAction,
                  title: _isLoading
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white, size: 50)
                      : const Text(
                          'Sign in',
                          style: TextStyle(color: Colors.white),
                        ),
                  height: 70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signinAction() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    var result = await sl<SignInUsecase>().call(
      params: UserEntity(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
    result.fold((l) {
      var snackbar = SnackBar(
        content: Text(l),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }, (r) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false);
    });
    setState(() {
      _isLoading = false;
    });
  }

  _signUpOption(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Not a Member?',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()));
            },
            child: const Text(
              'Register Now',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          )
        ],
      ),
    );
  }
}
