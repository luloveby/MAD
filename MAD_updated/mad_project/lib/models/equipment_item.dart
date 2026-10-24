class EquipmentItem {
  final String id;
  final String name;
  final String category;
  final String status;
  final String imagePath;
  final String description;
  final String eligiblePrograms;
  final List<String> recommendedPrograms;
  final bool inventoryVerified;
  final int? totalQuantity;
  final int? availableQuantity;

  EquipmentItem({
    this.id = '',
    required this.name,
    required this.category,
    required this.status,
    required this.imagePath,
    required this.description,
    this.eligiblePrograms = 'BSIT – BSIS – BLISS',
    this.recommendedPrograms = const [],
    this.inventoryVerified = true,
    this.totalQuantity,
    this.availableQuantity,
  });

  factory EquipmentItem.fromFirestore(String id, Map<String, dynamic> data) {
    final name = data['name'];
    final category = data['category'];
    if (name is! String || category is! String || name.trim().isEmpty) {
      throw FormatException('Equipment $id is missing its name or category.');
    }
    final verified = data['inventoryVerified'] == true;
    final available = data['availableQuantity'];
    final total = data['totalQuantity'];
    final validCounts =
        available is int &&
        total is int &&
        available >= 0 &&
        total >= available;
    return EquipmentItem(
      id: id,
      name: name,
      category: category,
      description: data['description'] as String? ?? '',
      imagePath: data['imagePath'] as String? ?? '',
      status: !verified || !validCounts
          ? 'Check availability'
          : available > 0
          ? 'Available'
          : 'Unavailable',
      eligiblePrograms: (data['eligiblePrograms'] as List? ?? [])
          .whereType<String>()
          .join(' – '),
      recommendedPrograms: (data['recommendedPrograms'] as List? ?? [])
          .whereType<String>()
          .toList(),
      inventoryVerified: verified && validCounts,
      totalQuantity: total is int ? total : null,
      availableQuantity: available is int ? available : null,
    );
  }
}
