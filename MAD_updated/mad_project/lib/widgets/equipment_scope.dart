import 'package:flutter/widgets.dart';

import '../models/equipment_item.dart';
import '../services/equipment_service.dart';

/// Lets previews and tests provide a catalog without a live Firebase connection.
class EquipmentScope extends InheritedWidget {
  const EquipmentScope({super.key, required this.watch, required super.child});

  final Stream<List<EquipmentItem>> Function() watch;

  static Stream<List<EquipmentItem>> watchOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EquipmentScope>()?.watch() ??
      EquipmentService().watchEquipment();

  @override
  bool updateShouldNotify(EquipmentScope oldWidget) => watch != oldWidget.watch;
}
