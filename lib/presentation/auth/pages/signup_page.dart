import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:museai/common/widgets/buttons/primary_app_button.dart';
import 'package:museai/core/configs/assets/app_vectors.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/usecases/auth/signup_usecase.dart';
import 'package:museai/presentation/auth/pages/signin_page.dart';
import 'package:museai/presentation/auth/widgets/text_field_widget.dart';
import 'package:museai/presentation/home/pages/home_page.dart';
import 'package:museai/service_locator.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _signInOption(context),
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
                  'Register',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                TextFieldWidget(
                  hintText: 'Full Name',
                  inputType: TextInputType.name,
                  controller: _fullNameController,
                ),
                const SizedBox(
                  height: 15,
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
                  onPressed: _signupAction,
                  title: _isLoading
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white, size: 50)
                      : const Text(
                          'Create Account',
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

  void _signupAction() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    var result = await sl<SignUpUsecase>().call(
        params: UserEntity(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim()));
    result.fold((Failure l) {
      var snackbar = SnackBar(
        content: Text(l.message),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }, (_) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false);
    });
    setState(() {
      _isLoading = false;
    });
  }

  _signInOption(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Do you have an Account?',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const SignInPage()));
            },
            child: const Text(
              'Sign In',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          )
        ],
      ),
    );
  }
}
