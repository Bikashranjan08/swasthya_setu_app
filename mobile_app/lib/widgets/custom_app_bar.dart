import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomAppBar({super.key, this.title, this.leading, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: title ?? const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: Replace with your logo
          // Image.asset(
          //   'assets/images/logo.png',
          //   height: 30,
          // ),
          Icon(Icons.local_hospital, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Swasthya Setu',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: actions,
      backgroundColor: Theme.of(context).primaryColor,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}