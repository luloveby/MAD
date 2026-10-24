import 'widgets/logout_action.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/app_scaffold.dart';
import 'edit_profile.dart';
import 'dialog.dart';
import 'services/auth_service.dart';

// STUDENT PROFILE MODEL
class StudentProfile {
  final String fullName;
  final String studentNumber;
  final String email;
  final String address;
  final String contactNumber;
  final String program;

  StudentProfile({
    required this.fullName,
    required this.studentNumber,
    required this.email,
    required this.address,
    required this.contactNumber,
    required this.program,
  });

  // CONVERT FIRESTORE DATA TO STUDENT PROFILE
  factory StudentProfile.fromFirestore(Map<String, dynamic> data) {
    return StudentProfile(
      fullName: data['fullName'] as String? ?? '',
      studentNumber: data['studentNumber'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      program: data['program'] as String? ?? '',
    );
  }

  // GET INITIALS FOR PROFILE AVATAR
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));

    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }
}

// PROFILE PAGE
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const orange = Color(0xFFFF692B);

  final AuthService authService = AuthService();

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream;

  @override
  void initState() {
    super.initState();
    profileStream = authService.profileStream();
  }

  // OPEN EDIT PROFILE PAGE
  Future<void> editProfile(StudentProfile student) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(student: student),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      showUpdateDialog();
    }
  }

  // PROFILE UPDATED DIALOG
  void showUpdateDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CustomDialog(
          title: 'Updated Profile',
          message: 'Updated your profile successfully!',
          confirmText: 'OK',
          onConfirm: () {
            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }

  Future<void> showLogoutDialog() => confirmLogout(context);

  // STUDENT DETAIL ITEM
  Widget detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // MAIN PROFILE PAGE
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    final double headerHeight = screenSize.height * 0.23;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileStream,
      builder: (context, snapshot) {
        // FIRESTORE ERROR
        if (snapshot.hasError) {
          return const AppScaffold(
            body: Center(
              child: Text('Error loading profile. Please try again.'),
            ),
          );
        }

        // LOADING PROFILE
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppScaffold(
            body: Center(child: CircularProgressIndicator(color: orange)),
          );
        }

        // CHECK IF DOCUMENT EXISTS
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const AppScaffold(
            body: Center(child: Text('Student profile not found.')),
          );
        }

        final data = snapshot.data!.data();

        if (data == null) {
          return const AppScaffold(
            body: Center(child: Text('No student information available.')),
          );
        }

        // ACTUAL LOGGED-IN STUDENT DATA
        final student = StudentProfile.fromFirestore(data);

        return AppScaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // SCROLLABLE PROFILE CONTENT
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      // ORANGE HEADER AND PROFILE AVATAR
                      SizedBox(
                        height: headerHeight + 50,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // HEADER IMAGE
                            SizedBox(
                              width: double.infinity,
                              height: headerHeight,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/images/header_curved_symmetric.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  const Positioned(
                                    left: 25,
                                    top: 18,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Profile',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        Text(
                                          'ACCOUNT INFORMATION',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // PROFILE INITIALS
                            Positioned(
                              top: headerHeight - 60,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: orange, width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    student.initials,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // STUDENT NAME
                      Text(
                        student.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // STUDENT PROGRAM
                      Text(
                        student.program,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // STUDENT INFORMATION
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.13,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // DETAILS CARD
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFBDBDBD),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'STUDENT DETAILS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  detail(
                                    'Student Number',
                                    student.studentNumber,
                                  ),

                                  detail('Email', student.email),

                                  detail(
                                    'Contact Number',
                                    student.contactNumber,
                                  ),

                                  detail('Address', student.address),

                                  detail('Program', student.program),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // EDIT PROFILE BUTTON
                            SizedBox(
                              height: 45,
                              child: ElevatedButton(
                                onPressed: () {
                                  editProfile(student);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                child: const Text('Edit Profile'),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // LOG OUT BUTTON
                            SizedBox(
                              height: 45,
                              child: ElevatedButton(
                                onPressed: showLogoutDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF303030),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                child: const Text('Log Out'),
                              ),
                            ),

                            const SizedBox(height: 35),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
