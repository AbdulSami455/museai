// This page builds the UI for theme selection.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:museai/core/configs/assets/app_images.dart';
import 'package:museai/core/configs/themes/app_colors.dart';
import 'package:museai/presentation/choose_mode/bloc/theme_cubit.dart';

import '../../../common/widgets/buttons/primary_app_button.dart';
import '../../../core/configs/assets/app_vectors.dart';
import '../../auth/pages/auth_page.dart';
import '../../home/pages/home_page.dart';

class ChooseModePage extends StatefulWidget {
  const ChooseModePage({super.key});

  @override
  State<ChooseModePage> createState() => _ChooseModePageState();
}

class _ChooseModePageState extends State<ChooseModePage> {
  // Animation 2: AnimatedContainer — selected theme button grows and highlights.
  ThemeMode _selected = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage(AppImages.chooseModeBg),
              ),
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
                  'Choose Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ThemeButton(
                      iconAsset: AppVectors.moonIcon,
                      label: 'Dark Mode',
                      isSelected: _selected == ThemeMode.dark,
                      onTap: () {
                        setState(() => _selected = ThemeMode.dark);
                        context.read<ThemeCubit>().updateTheme(ThemeMode.dark);
                      },
                    ),
                    const SizedBox(width: 80),
                    _ThemeButton(
                      iconAsset: AppVectors.sunIcon,
                      label: 'Light Mode',
                      isSelected: _selected == ThemeMode.light,
                      onTap: () {
                        setState(() => _selected = ThemeMode.light);
                        context.read<ThemeCubit>().updateTheme(ThemeMode.light);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                PrimaryAppButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  title: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Sign in / Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ThemeButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.iconAsset,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Animation 2: AnimatedContainer grows and brightens when selected.
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isSelected ? 84 : 70,
            width: isSelected ? 84 : 70,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.grey.withValues(alpha: 0.75)
                  : AppColors.grey.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: SvgPicture.asset(iconAsset, fit: BoxFit.none),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
