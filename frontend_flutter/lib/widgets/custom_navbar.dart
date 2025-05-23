import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Text("📦", style: TextStyle(fontSize: 24)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order Page Coming Soon")));
        },
      ),
      title: TextField(
        decoration: InputDecoration(
          hintText: "Search...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      actions: [
        IconButton(icon: Icon(Icons.account_circle), onPressed: () => Navigator.pushNamed(context, '/auth'))
      ],
    );
  }
}
