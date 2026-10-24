import 'package:flutter/material.dart';

import 'widgets/app_scaffold.dart';
import 'profile.dart';
import 'services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  final StudentProfile student;

  const EditProfilePage({super.key, required this.student});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const orange = Color(0xFFFF692B);

  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController studentController;
  late final TextEditingController addressController;
  late final TextEditingController contactController;
  String? selectedProgram;

  @override
  void initState() {
    super.initState();

    // Fill the text fields with existing profile data.
    nameController = TextEditingController(text: widget.student.fullName);

    studentController = TextEditingController(
      text: widget.student.studentNumber,
    );

    addressController = TextEditingController(text: widget.student.address);

    contactController = TextEditingController(
      text: widget.student.contactNumber,
    );

    selectedProgram = ['BSIT', 'BSIS', 'BLISS'].contains(widget.student.program)
        ? widget.student.program
        : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    studentController.dispose();
    addressController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Widget editableField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 3,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: orange, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> saveChanges() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      await AuthService().updateProfile(
        fullName: nameController.text,
        studentNumber: studentController.text,
        address: addressController.text,
        contactNumber: contactController.text,
        program: selectedProgram!,
      );

      if (!mounted) return;

      // Return success to Profile page.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final headerHeight = screenSize.height * 0.22;

    return AppScaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

              child: Column(
                children: [
                  // HEADER
                  SizedBox(
                    height: headerHeight + 50,
                    child: Stack(
                      children: [
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
                                top: 25,
                                left: 18,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Edit Profile',
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

                        // AVATAR
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
                                widget.student.initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // EDITABLE FORM
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.17,
                    ),

                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          editableField('FULL NAME', nameController),

                          editableField(
                            'STUDENT NUMBER',
                            studentController,
                            keyboardType: TextInputType.number,
                          ),

                          editableField(
                            'ADDRESS',
                            addressController,
                            keyboardType: TextInputType.multiline,
                            maxLines: 3,
                          ),

                          editableField(
                            'CONTACT NUMBER',
                            contactController,
                            keyboardType: TextInputType.phone,
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COLLEGE PROGRAM',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 6),

                              DropdownButtonFormField<String>(
                                initialValue: selectedProgram,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 13,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: orange,
                                      width: 1.5,
                                    ),
                                  ),
                                ),

                                hint: const Text('Select your program'),

                                items: ['BSIT', 'BSIS', 'BLISS'].map((program) {
                                  return DropdownMenuItem<String>(
                                    value: program,
                                    child: Text(program),
                                  );
                                }).toList(),

                                onChanged: (value) {
                                  setState(() {
                                    selectedProgram = value;
                                  });
                                },

                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select your college program';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 15),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // SAVE BUTTON
                          SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              onPressed: saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save changes'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // CANCEL BUTTON
                          SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF303030),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),

                          const SizedBox(height: 35),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
