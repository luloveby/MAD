import 'package:flutter/material.dart';

import 'app_navigation_bar.dart';
import 'borrow_it_app_bar.dart';
import 'main_drawer.dart';

/// The shared chrome for signed-in pages, including loading and error states.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.navigationIndex,
    this.showBack = false,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor = Colors.white,
  });

  final Widget body;
  final int? navigationIndex;
  final bool showBack;
  final bool resizeToAvoidBottomInset;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildBorrowItAppBar(showBack: showBack),
    drawer: const MainDrawer(),
    backgroundColor: backgroundColor,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    bottomNavigationBar: navigationIndex == null
        ? null
        : AppNavigationBar(currentIndex: navigationIndex!),
    body: body,
  );
}
