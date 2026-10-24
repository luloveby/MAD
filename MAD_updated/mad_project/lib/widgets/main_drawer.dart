import 'package:flutter/material.dart';

import '../profile.dart';
import 'app_navigation_bar.dart';
import 'logout_action.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  static const Color dark = Color(0xFF222222);

  void navigate(BuildContext context, void Function(BuildContext) action) {
    final scaffold = Scaffold.of(context);
    final pageContext = scaffold.context;
    scaffold.closeDrawer();
    action(pageContext);
  }

  void showComingSoon(BuildContext context, String pageName) {
    navigate(context, (pageContext) {
      ScaffoldMessenger.of(pageContext)
          .showSnackBar(SnackBar(content: Text('$pageName page coming soon.')));
    });
  }

  void openProfile(BuildContext context) {
    navigate(context, (pageContext) {
      Navigator.push(
        pageContext,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    });
  }

  void logout(BuildContext context) {
    navigate(context, (pageContext) => confirmLogout(pageContext));
  }

  Widget menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      leading: Icon(icon, color: Colors.white, size: 27),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.72,
      backgroundColor: dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // MAIN MENU HEADER
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Main Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Divider(color: Colors.white54, thickness: 1),
            ),

            const SizedBox(height: 14),

            // MY PROFILE
            menuItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => navigate(context, AppNavigation.openHome),
            ),
            menuItem(
              icon: Icons.account_circle,
              title: 'My Profile',
              onTap: () => openProfile(context),
            ),

            // EQUIPMENTS
            menuItem(
              icon: Icons.devices,
              title: 'Equipments',
              onTap: () => navigate(context, AppNavigation.openEquipment),
            ),

            // REQUESTS
            menuItem(
              icon: Icons.touch_app,
              title: 'Requests',
              onTap: () => navigate(context, AppNavigation.openRequests),
            ),

            // NOTIFICATIONS
            menuItem(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () => showComingSoon(context, 'Notifications'),
            ),

            // SETTINGS
            menuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => showComingSoon(context, 'Settings'),
            ),

            const Spacer(),

            // LOG OUT
            const Divider(color: Colors.white24),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              trailing: const Icon(Icons.logout, color: Colors.white, size: 27),
              onTap: () => logout(context),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
