import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_project/data/equipment_catalog.dart';
import 'package:mad_project/home_page.dart';
import 'package:mad_project/pages/borrow_it_screen.dart';
import 'package:mad_project/widgets/app_navigation_bar.dart';
import 'package:mad_project/widgets/equipment_scope.dart';
import 'package:mad_project/models/equipment_item.dart';

// A test-only snapshot keeps navigation tests independent of Firebase.
// ignore: subtype_of_sealed_class
class StudentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  Map<String, dynamic> data() => {
    'fullName': 'Test Student',
    'program': 'BSIT',
  };
}

void main() {
  testWidgets('Catalog reacts to updates, empty results and errors', (
    tester,
  ) async {
    final source = StreamController<List<EquipmentItem>>();
    addTearDown(source.close);
    await tester.pumpWidget(
      EquipmentScope(
        watch: () => source.stream,
        child: const MaterialApp(home: BorrowItScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    source.add([equipmentCatalog.first]);
    await tester.pumpAndSettle();
    expect(find.text('ASUS 2026'), findsOneWidget);
    source.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No equipment found.'), findsOneWidget);
    source.addError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Unable to load equipment. Check your connection or try again later.',
      ),
      findsOneWidget,
    );
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Every catalog item has a bundled image', () {
    expect(equipmentCatalog, isNotEmpty);
    for (final item in equipmentCatalog) {
      expect(File(item.imagePath).existsSync(), isTrue, reason: item.imagePath);
    }
  });

  testWidgets(
    'Home recommendations scroll sideways and See All opens equipment',
    (tester) async {
      await tester.pumpWidget(
        EquipmentScope(
          watch: () => Stream.value(equipmentCatalog),
          child: MaterialApp(
            home: const SizedBox.shrink(),
            initialRoute: AppNavigation.home,
            routes: {
              AppNavigation.home: (_) =>
                  HomePage(profile: Stream.value(StudentSnapshot())),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final program in ['BSIT', 'BSIS', 'BLISS']) {
        expect(find.text('Recommended for $program'), findsOneWidget);
        final row = find.byKey(PageStorageKey(program));
        expect(tester.widget<ListView>(row).scrollDirection, Axis.horizontal);
      }
      final firstRow = find.byKey(const PageStorageKey('BSIT'));
      await tester.ensureVisible(firstRow);
      await tester.drag(firstRow, const Offset(-300, 0));
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: firstRow,
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
      final seeAll = find.text('See All >').first;
      await tester.ensureVisible(seeAll);
      await tester.tap(seeAll);
      await tester.pumpAndSettle();
      expect(find.byType(BorrowItScreen), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        1,
      );
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Main Menu'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        0,
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
      await tester.tap(find.text('Equipment').last);
      await tester.pumpAndSettle();
      expect(find.byType(BorrowItScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Equipment search filters catalog and opens details', (
    tester,
  ) async {
    await tester.pumpWidget(
      EquipmentScope(
        watch: () => Stream.value(equipmentCatalog),
        child: const MaterialApp(home: BorrowItScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Acer');
    await tester.pumpAndSettle();
    expect(find.text('Acer Gateway Chromebook'), findsOneWidget);
    expect(find.text('ASUS 2026'), findsNothing);
    await tester.tap(find.text('Acer Gateway Chromebook'));
    await tester.pumpAndSettle();
    expect(find.text('Description'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Main Menu'), findsOneWidget);
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Description'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
