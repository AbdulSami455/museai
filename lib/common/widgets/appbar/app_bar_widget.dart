import 'package:flutter/material.dart';
import 'package:museai/common/helpers/is_dark_mode.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget{
  final Widget? title;
  final bool showBackButton;
  const AppBarWidget({super.key, this.title,this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title?? const Text(''),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: !showBackButton? null:IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: context.isDarkMode ? Colors.white : Colors.black,
            size: 17,
          ),
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
