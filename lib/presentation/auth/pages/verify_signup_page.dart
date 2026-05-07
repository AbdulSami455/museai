import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;
import 'package:museai/common/widgets/appbar/app_bar_widget.dart';
import 'package:museai/common/widgets/buttons/primary_app_button.dart';
import 'package:museai/core/configs/app_config.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/core/error/failures.dart';
import 'package:museai/domain/entities/auth/user_entity.dart';
import 'package:museai/domain/usecases/auth/signin_usecase.dart';
import 'package:museai/presentation/auth/pages/signin_page.dart';
import 'package:museai/presentation/home/pages/home_page.dart';
import 'package:museai/presentation/auth/widgets/text_field_widget.dart';
import 'package:museai/service_locator.dart';

class VerifySignupPage extends StatefulWidget {
  final String email;
  final String password;

  const VerifySignupPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<VerifySignupPage> createState() => _VerifySignupPageState();
}

class _VerifySignupPageState extends State<VerifySignupPage> {
  final TextEditingController _codeController = TextEditingController();
  final http.Client _httpClient = http.Client();
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(
        title: Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Enter Verification Code',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  'We sent a code to ${widget.email}. Enter it here, then continue to sign in.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFieldWidget(
                  hintText: '6-digit code',
                  inputType: TextInputType.number,
                  controller: _codeController,
                ),
                const SizedBox(height: 16),
                PrimaryAppButton(
                  onPressed: _isSubmitting ? () {} : () => _verifyCode(),
                  title: _isSubmitting
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white,
                          size: 50,
                        )
                      : const Text(
                          'Verify And Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
                  height: 70,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  child: _isResending
                      ? const Text('Sending...')
                      : const Text(
                          'Resend Code',
                          style: TextStyle(color: AppColors.primaryColor),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    if (_codeController.text.trim().isEmpty) {
      _showMessage('Verification code is required.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final response = await _httpClient.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/v1/auth/signup/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': _codeController.text.trim(),
        }),
      );
      final message = _extractErrorMessage(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _completeSignInAfterVerification();
        return;
      }

      if (response.statusCode == 404 &&
          message.toLowerCase().contains('no pending signup found')) {
        await _completeSignInAfterVerification(
          fallbackMessage: 'Email already verified. Signing you in.',
        );
        return;
      }
      _showMessage(message);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _completeSignInAfterVerification(
      {String? fallbackMessage}) async {
    if (fallbackMessage != null) {
      _showMessage(fallbackMessage);
    }

    Failure? lastFailure;
    for (var attempt = 0; attempt < 3; attempt++) {
      final signInResult = await sl<SignInUsecase>().call(
        params: UserEntity(
          email: widget.email,
          password: widget.password,
        ),
      );

      if (!mounted) return;
      final success = signInResult.fold(
        (Failure failure) {
          lastFailure = failure;
          return false;
        },
        (_) => true,
      );

      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
        return;
      }

      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
    if (lastFailure != null) {
      _showMessage(
        'Verification completed. Please sign in manually. ${lastFailure!.message}',
      );
    } else {
      _showMessage('Verification completed. Please sign in manually.');
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      final response = await _httpClient.post(
        Uri.parse(
            '${AppConfig.backendBaseUrl}/api/v1/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      _showMessage(
        response.statusCode >= 200 && response.statusCode < 300
            ? 'Verification code resent.'
            : _extractErrorMessage(response.body),
      );
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return 'Request failed.';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
