import '../widgets/equipment_scope.dart';
import '../widgets/app_scaffold.dart';

import 'package:flutter/material.dart';

import '../models/equipment_item.dart';

import 'equipment_details_page.dart';

class BorrowItScreen extends StatefulWidget {
  const BorrowItScreen({super.key});

  @override
  State<BorrowItScreen> createState() => _BorrowItScreenState();
}

class _BorrowItScreenState extends State<BorrowItScreen> {
  final TextEditingController _searchController = TextEditingController();
  Stream<List<EquipmentItem>>? equipmentStream;
  String selectedCategory = 'Show All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    equipmentStream ??= EquipmentScope.watchOf(context);
  }

  void _filterSearch(String query, {String category = ''}) {
    setState(() {
      if (category.isNotEmpty) selectedCategory = category;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<EquipmentItem>>(
    stream: equipmentStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const AppScaffold(
          navigationIndex: 1,
          body: Center(
            child: Text(
              'Unable to load equipment. Check your connection or try again later.',
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const AppScaffold(
          navigationIndex: 1,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return buildCatalog(snapshot.data!);
    },
  );

  Widget buildCatalog(List<EquipmentItem> allEquipment) {
    final query = _searchController.text.toLowerCase().trim();
    final filteredEquipment = allEquipment
        .where(
          (item) =>
              (item.name.toLowerCase().contains(query) ||
                  item.category.toLowerCase().contains(query)) &&
              (selectedCategory == 'Show All' ||
                  item.category == selectedCategory),
        )
        .toList();
    return AppScaffold(
      navigationIndex: 1,

      backgroundColor: const Color.fromARGB(255, 248, 248, 248),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Equipment",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Browse the equipment catalog",
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar na may real-time filtering
                  TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        _filterSearch(value, category: selectedCategory),
                    decoration: InputDecoration(
                      hintText: "Search equipment...",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _searchController.clear();
                          _filterSearch("", category: "Show All");
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Category List
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip("Laptop"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Flash Drives"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Wireless Mouse"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Keyboards"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Webcams"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Numeric Keypads"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("HDMI Cables"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Extension Cords"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("USB-to-Ethernet Adapter"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("LAN Cables"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Presentation Clicker"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Speaker"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Switches"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("LAN Cable Tester"),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Crimping Tool"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text("Equipment for BSIT, BSIS and BLISS students"),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          if (filteredEquipment.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No equipment found.')),
              ),
            ),
          // Equipment from Firestore
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = filteredEquipment[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 3,
                  shadowColor: const Color(0x40000000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EquipmentDetailsPage(item: item),
                      ),
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.white,
                      child: item.imagePath.isNotEmpty
                          ? Image.asset(
                              item.imagePath,
                              fit: BoxFit.contain,
                              cacheWidth: 150,
                              cacheHeight: 150,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.image_not_supported),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(item.category),
                    trailing: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => EquipmentDetailsPage(item: item),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: item.status == "Available"
                            ? const Color(0xffe76c2e)
                            : Colors.grey,
                        side: BorderSide(
                          color: item.status == "Available"
                              ? const Color(0xffe76c2e)
                              : Colors.grey,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        item.status,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: filteredEquipment.length),
          ),
        ],
      ),
    );
  }

  // Helper widget para hindi na paulit-ulit ang code ng ActionChip
  Widget _buildCategoryChip(String categoryName) {
    final isSelected = selectedCategory == categoryName;

    return ActionChip(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: Color(0xffe76c2e), width: 2.5),
      backgroundColor: isSelected
          ? const Color(0xffe76c2e)
          : Colors.transparent,
      label: Text(
        categoryName,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () {
        // Kung pinindot ulit yung currently selected chip, balik sa "Show All"
        if (selectedCategory == categoryName && categoryName != "Show All") {
          _filterSearch(_searchController.text, category: "Show All");
        } else {
          _filterSearch(_searchController.text, category: categoryName);
        }
      },
    );
  }
}
