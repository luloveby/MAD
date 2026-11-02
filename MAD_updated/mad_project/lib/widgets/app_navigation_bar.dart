import 'package:flutter/material.dart';

import '../home_page.dart';
import '../pages/user_requests_page.dart';
import '../pages/borrow_it_screen.dart';

class AppNavigation {
  static const home = '/home';
  static const equipment = '/equipment';
  static const requests = '/requests';

  static PageRoute<T> _slideRoute<T>({
    RouteSettings? settings,
    required WidgetBuilder builder,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(slide),
          child: child,
        );
      },
    );
  }

  static Future<T?> pushWithTransition<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      _slideRoute<T>(builder: (_) => page),
    );
  }

  static PageRoute<void> _tabRoute({
    required String name,
    required WidgetBuilder builder,
  }) {
    return _slideRoute<void>(settings: RouteSettings(name: name), builder: builder);
  }

  static void openRequests(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == requests) return;
    Navigator.of(context).push(
      _tabRoute(
        name: requests,
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
        _tabRoute(
          name: home,
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
      _tabRoute(
        name: equipment,
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
