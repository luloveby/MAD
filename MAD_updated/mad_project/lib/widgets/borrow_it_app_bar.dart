import 'package:flutter/material.dart';

AppBar buildBorrowItAppBar({bool showBack = false}) => AppBar(
  toolbarHeight: 60,
  centerTitle: false,
  titleSpacing: 0,
  leading: Builder(
    builder: (context) => IconButton(
      tooltip: 'Open menu',
      icon: const Icon(Icons.menu),
      onPressed: () => Scaffold.of(context).openDrawer(),
    ),
  ),
  title: Image.asset('assets/images/5.png', height: 55, fit: BoxFit.contain),
  actions: [if (showBack) const BackButton()],
  backgroundColor: const Color(0xFF202020),
  foregroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
);
