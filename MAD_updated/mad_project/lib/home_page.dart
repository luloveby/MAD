import 'widgets/equipment_scope.dart';
import 'models/equipment_item.dart';
import 'models/borrow_request.dart';

import 'pages/equipment_details_page.dart';
import 'pages/request_details_page.dart';
import 'widgets/notification_bell.dart';
import 'widgets/request_scope.dart';
import 'widgets/request_widgets.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/auth_service.dart';

import 'widgets/app_scaffold.dart';
import 'widgets/app_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.profile});

  final Stream<DocumentSnapshot<Map<String, dynamic>>>? profile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color orange = Color(0xFFFF692B);

  final TextEditingController searchController = TextEditingController();

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream;

  Stream<List<EquipmentItem>>? equipmentStream;
  Stream<List<BorrowRequest>>? requestStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    equipmentStream ??= EquipmentScope.watchOf(context);
    requestStream ??= RequestScope.watchOf(context);
  }

  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Computer',
    'Cables',
    'Presentation',
    'Networking',
  ];

  static String categoryGroup(String category) {
    if ([
      'LAN Cables',
      'Switches',
      'LAN Cable Tester',
      'Crimping Tool',
      'USB-to-Ethernet Adapter',
    ].contains(category)) {
      return 'Networking';
    }
    if (['HDMI Cables', 'Extension Cords'].contains(category)) return 'Cables';
    if (['Presentation Clicker', 'Speaker'].contains(category)) {
      return 'Presentation';
    }
    return 'Computer';
  }

  void openEquipment() => AppNavigation.openEquipment(context);

  List<EquipmentItem> recommendations(
    String program,
    List<EquipmentItem> catalog,
  ) {
    const preferred = {
      'BSIT': [
        'Switches',
        'LAN Cable Tester',
        'Crimping Tool',
        'Laptop',
        'LAN Cables',
      ],
      'BSIS': [
        'Laptop',
        'Numeric Keypads',
        'Flash Drives',
        'Presentation Clicker',
      ],
      'BLISS': [
        'Flash Drives',
        'Laptop',
        'Webcams',
        'Presentation Clicker',
        'Speaker',
      ],
    };
    return catalog
        .where(
          (item) =>
              (item.id.isNotEmpty
                  ? item.recommendedPrograms.contains(program)
                  : preferred[program]!.contains(item.category)) &&
              item.eligiblePrograms.contains(program) &&
              (selectedCategory == 'All' ||
                  categoryGroup(item.category) == selectedCategory) &&
              item.name.toLowerCase().contains(
                searchController.text.trim().toLowerCase(),
              ),
        )
        .toList();
  }

  Widget recommendationRow(String program, List<EquipmentItem> catalog) {
    final items = recommendations(program, catalog);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recommended for $program',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF444444),
                  ),
                ),
              ),
              TextButton(
                onPressed: openEquipment,
                child: const Text(
                  'See All >',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No equipment found.'),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              key: PageStorageKey(program),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 170,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => AppNavigation.pushWithTransition(
                      context,
                      EquipmentDetailsPage(item: item),
                    ),
                    child: equipmentCard({
                      'name': item.name,
                      'category': item.category,
                      'status': item.status,
                      'image': item.imagePath,
                    }),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    profileStream = widget.profile ?? AuthService().profileStream();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget equipmentCard(Map<String, String> item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF353535),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EQUIPMENT IMAGE
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(item['image']!, fit: BoxFit.contain),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // EQUIPMENT NAME
          Text(
            item['name'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 3),

          // EQUIPMENT CATEGORY
          Text(
            item['category'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),

          const SizedBox(height: 5),

          // AVAILABILITY STATUS
          Row(
            children: [
              Icon(
                Icons.circle,
                color: item['status'] == 'Available'
                    ? Colors.green
                    : Colors.grey,
                size: 9,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  item['status'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHome(
    String firstName,
    String program,
    List<EquipmentItem> catalog,
    List<BorrowRequest> requests,
  ) {
    final activeRequests = requests
        .where(
          (request) =>
              !request.archived &&
              (request.status == 'Approved' || request.status == 'Borrowed'),
        )
        .toList();
    return Column(
      children: [
        // SCROLLABLE BODY
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ORANGE WELCOME HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF692B), Color(0xFFFFA36D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $firstName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Ready to borrow something for class?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const NotificationBell(),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // SEARCH BAR
                      TextField(
                        controller: searchController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search equipment...',
                          hintStyle: const TextStyle(color: Colors.white),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ANNOUNCEMENTS
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF36C1B),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Announcements',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Office announcements will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // BROWSE CATEGORIES
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: const Text(
                    'Browse categories',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),

                SizedBox(
                  height: 45,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category;

                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: orange,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        side: const BorderSide(color: orange),
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),

                recommendationRow('BSIT', catalog),
                recommendationRow('BSIS', catalog),
                recommendationRow('BLISS', catalog),

                // ACTIVE BORROWINGS
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 22, 16, 10),
                  child: Text(
                    'My Active Borrowings',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),

                if (activeRequests.isEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FFC7),
                      border: Border.all(color: orange),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'No active borrowings yet.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF444444)),
                    ),
                  )
                else
                  for (final request in activeRequests)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RequestCard(
                        request: request,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RequestDetailsPage(requestId: request.id),
                          ),
                        ),
                      ),
                    ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AppScaffold(
            navigationIndex: 0,
            body: Center(child: Text('Unable to load student profile.')),
          );
        }

        if (!snapshot.hasData) {
          return const AppScaffold(
            navigationIndex: 0,
            body: Center(child: CircularProgressIndicator(color: orange)),
          );
        }

        final data = snapshot.data!.data();

        if (data == null) {
          return const AppScaffold(
            navigationIndex: 0,
            body: Center(child: Text('Student profile not found.')),
          );
        }

        final fullName = (data['fullName'] as String? ?? '').trim();
        final program = (data['program'] as String? ?? '').trim();

        final firstName = fullName.isEmpty
            ? 'Student'
            : fullName.split(RegExp(r'\s+')).first;

        return AppScaffold(
          navigationIndex: 0,
          backgroundColor: Colors.white,

          body: StreamBuilder<List<EquipmentItem>>(
            stream: equipmentStream,
            builder: (context, equipmentSnapshot) {
              if (equipmentSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Unable to load equipment. Check your connection or try again later.',
                  ),
                );
              }
              if (!equipmentSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<List<BorrowRequest>>(
                stream: requestStream,
                builder: (context, requestSnapshot) {
                  if (requestSnapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load active borrowings.'),
                    );
                  }
                  if (!requestSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: orange),
                    );
                  }
                  return buildHome(
                    firstName,
                    program.isEmpty ? 'Students' : program,
                    equipmentSnapshot.data!,
                    requestSnapshot.data!,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
