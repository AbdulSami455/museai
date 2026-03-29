import 'package:flutter/material.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';
import 'package:museai/core/configs/assets/app_images.dart';

import '../../../core/configs/themes/app_colors.dart';

class HomeArtistWidget extends StatelessWidget {
  const HomeArtistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 30),
          alignment: Alignment.bottomRight,
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 25, top: 45),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Album',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: context.isDarkMode? Colors.black:Colors.white,
                ),
              ),
              Text(
                'Happier Than',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: context.isDarkMode? Colors.black:Colors.white,
                ),
              ),
              Text(
                'Ever',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: context.isDarkMode? Colors.black:Colors.white,
                ),
              ),
              Text(
                'Billie Ellish',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: context.isDarkMode? Colors.black:Colors.white,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Image.asset(
            AppImages.homeArtistImage,
            height: 150,
          ),
        ),
      ],
    );
  }
}
