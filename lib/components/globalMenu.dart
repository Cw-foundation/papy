import 'package:flutter/material.dart';

class GlobalMenu extends StatelessWidget {
  final Widget child;

  const GlobalMenu({super.key, required this.child});

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuItem(Icons.home, "Home", () {}),
              _menuItem(Icons.collections, "New Collections", () {}),
              _menuItem(Icons.star, "Editor's Picks", () {}),
              _menuItem(Icons.local_offer, "Top Deals", () {}),
              _menuItem(Icons.notifications, "Notifications", () {}),
              _menuItem(Icons.settings, "Settings", () {}),
              const Divider(),
              _menuItem(Icons.logout, "Sign Out", () {}),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(text, style: TextStyle(fontSize: 18)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: 30,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => _showMenu(context),
            child: Icon(Icons.menu, size: 28),
          ),
        ),
      ],
    );
  }
}
