import 'package:flutter/material.dart';


class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subTitle;
  final Widget action;
  @override
  final Size preferredSize;

  const GlobalAppBar({
    super.key,
    required this.title,
    required this.subTitle,
    required this.action,
  }) : preferredSize = const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: () => Scaffold.of(context).openDrawer(),
        icon: Icon(
          Icons.menu,
          color: Colors.pink.shade400,
        ),
      ),
      actions: [
        action,
        const SizedBox(
          width: 30,
        ),
      ],
      toolbarHeight: 64,
      backgroundColor: Colors.grey.shade100,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade400,
            ),
          ),
          Text(
            subTitle,
            style: TextStyle(
              color: Colors.pink.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          )
        ],
      ),
    );
  }
}
