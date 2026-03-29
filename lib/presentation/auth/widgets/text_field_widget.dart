import 'package:flutter/material.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/core/configs/themes/app_colors.dart';

class TextFieldWidget extends StatelessWidget {
  final String hintText;
  final TextInputType inputType;
  final TextEditingController controller;
  const TextFieldWidget(
      {super.key,
      required this.inputType,
      required this.controller,
      required this.hintText});

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: context.isDarkMode ? Colors.white : Colors.black,
        width: 0.4,
      ),
    );
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: inputType == TextInputType.visiblePassword,
      cursorColor: context.isDarkMode ? AppColors.grey : AppColors.darkGrey,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: context.isDarkMode ? AppColors.grey : AppColors.darkGrey,
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
        border: inputBorder,
      ),
    );
  }
}
