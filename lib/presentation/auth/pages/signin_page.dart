// This page builds the UI for authentication.

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:museai/common/widgets/buttons/primary_app_button.dart';
import 'package:museai/core/configs/assets/app_vectors.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/usecases/auth/signin_usecase.dart';
import 'package:museai/presentation/auth/pages/password_reset_page.dart';
import 'package:museai/presentation/auth/pages/signup_page.dart';
import 'package:museai/presentation/auth/widgets/text_field_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PasswordResetPage(),
                        ),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.18))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with'),
                    ),
                    Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.18))),
                  ],
                ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SocialStubButton(
                      label: 'Google',
                      icon: Icons.account_circle_outlined,
                    ),
                    _SocialStubButton(
                      label: 'Apple',
                      icon: Icons.apple_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signinAction() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    var result = await sl<SignInUsecase>().call(
      params: UserEntity(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
    if (!mounted) return;
    result.fold((Failure l) {
      var snackbar = SnackBar(
        content: Text(l.message),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }, (_) {
      if (Supabase.instance.client.auth.currentSession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Sign in succeeded, but no active session was found.'),
          ),
        );
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false);
      }
    });
    if (!mounted) return;
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

class _SocialStubButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SocialStubButton({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '$label sign-in UI is ready; provider setup is pending.')),
        );
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
