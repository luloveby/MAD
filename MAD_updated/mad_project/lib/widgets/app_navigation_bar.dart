import 'package:flutter/material.dart';

import '../home_page.dart';
import '../pages/user_requests_page.dart';
import '../pages/borrow_it_screen.dart';

class AppNavigation {
  static const home = '/home';
  static const equipment = '/equipment';
  static const requests = '/requests';

  static void openRequests(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == requests) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: requests),
        builder: (_) => const UserRequestsPage(),
      ),
    );
  }

  static void openHome(BuildContext context) {
    final navigator = Navigator.of(context);
    var foundHome = false;
    navigator.popUntil((route) {
      foundHome = route.settings.name == home;
      return foundHome || route.isFirst;
    });
    if (!foundHome) {
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: home),
          builder: (_) => const HomePage(),
        ),
      );
    }
  }

  static void openEquipment(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == equipment) return;
    final navigator = Navigator.of(context);
    var foundEquipment = false;
    navigator.popUntil((route) {
      foundEquipment = route.settings.name == equipment;
      return foundEquipment || route.settings.name == home || route.isFirst;
    });
    if (foundEquipment) return;
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: equipment),
        builder: (_) => const BorrowItScreen(),
      ),
    );
  }
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: currentIndex,
    backgroundColor: const Color(0xFF202020),
    selectedItemColor: const Color(0xFFFF692B),
    unselectedItemColor: Colors.white,
    type: BottomNavigationBarType.fixed,
    onTap: (index) {
      if (index == 0 && currentIndex == 0) return;
      if (index == 0) {
        AppNavigation.openHome(context);
      } else if (index == 1) {
        AppNavigation.openEquipment(context);
      } else {
        AppNavigation.openRequests(context);
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Equipment'),
      BottomNavigationBarItem(
        icon: Icon(Icons.touch_app),
        label: 'My Requests',
      ),
    ],
  );
}
