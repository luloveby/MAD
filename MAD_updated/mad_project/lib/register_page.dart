import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const orange = Color(0xFFFF692B);

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final studentController = TextEditingController();
  final addressController = TextEditingController();
  final contactController = TextEditingController();
  String? selectedProgram;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isRegistering = false;

  @override
  void dispose() {
    nameController.dispose();
    studentController.dispose();
    addressController.dispose();
    contactController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, top: 13),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.3,
          color: Color(0xFF555555),
        ),
      ),
    );
  }

  Widget regularField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: fieldDecoration(hint),
          validator: validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> register() async {
    if (isRegistering) return;
    if (!formKey.currentState!.validate()) return;
    setState(() => isRegistering = true);

    try {
      await AuthService().register(
        fullName: nameController.text,
        studentNumber: studentController.text,
        email: emailController.text,
        password: passwordController.text,
        address: addressController.text,
        contactNumber: contactController.text,
        program: selectedProgram!,
      );

      await AuthService().logout();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Verification Email Sent'),
          content: Text(
            'A verification link was sent to ${emailController.text.trim()}. '
            'Check your inbox and Spam/Junk folder, then tap the link before '
            'logging in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to register: $e')));
    } finally {
      if (mounted) setState(() => isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final headerHeight = screenSize.height * 0.25;
    final panelTop = screenSize.height * 0.18;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

        child: Stack(
          children: [
            // 1. ORANGE HEADER IMAGE
            SizedBox(
              width: double.infinity,
              height: headerHeight,
              child: Image.asset('assets/images/header.png', fit: BoxFit.cover),
            ),

            // 2. WHITE CURVED REGISTRATION SECTION
            Padding(
              padding: EdgeInsets.only(top: panelTop),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(75),
                  ),
                ),

                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.18,
                    vertical: 35,
                  ),

                  child: Form(
                    key: formKey,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        // CREATE ACCOUNT TITLE
                        const Text(
                          'Create new\nAccount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                            color: Color(0xFF202424),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ALREADY REGISTERED
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already Registered? ',
                              style: TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Log in here.',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // FULL NAME
                        regularField(
                          'FULL NAME',
                          'Enter your full name',
                          nameController,
                        ),

                        // STUDENT NUMBER
                        regularField(
                          'STUDENT NUMBER',
                          'Enter your student number',
                          studentController,
                          keyboardType: TextInputType.number,
                        ),

                        // ADDRESS
                        regularField(
                          'ADDRESS',
                          'Enter your address',
                          addressController,
                        ),

                        // CONTACT NUMBER
                        regularField(
                          'CONTACT NUMBER',
                          'Enter your contact number',
                          contactController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^\d{11}$').hasMatch(value.trim())) {
                              return 'Contact number must contain exactly 11 digits';
                            }
                            return null;
                          },
                        ),

                        // COLLEGE PROGRAM
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            fieldLabel('COLLEGE PROGRAM'),

                            DropdownButtonFormField<String>(
                              initialValue: selectedProgram,

                              hint: const Text(
                                'Select your college program',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),

                              decoration: fieldDecoration(
                                'Select your college program',
                              ).copyWith(hintText: null),

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
                          ],
                        ),

                        // EMAIL
                        regularField(
                          'EMAIL',
                          'Enter your email',
                          emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        // PASSWORD
                        fieldLabel('PASSWORD'),

                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          decoration: fieldDecoration(
                            'Enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                              ),
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Use at least 8 characters';
                            }
                            return null;
                          },
                        ),

                        // CONFIRM PASSWORD
                        fieldLabel('CONFIRM PASSWORD'),

                        TextFormField(
                          controller: confirmController,
                          obscureText: hideConfirmPassword,
                          decoration: fieldDecoration(
                            'Confirm your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                hideConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                              ),
                              onPressed: () {
                                setState(() {
                                  hideConfirmPassword = !hideConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // SIGN UP BUTTON
                        SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: isRegistering ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ), // Column
                  ), // Form
                ), // Padding
              ), // Container
            ), // Padding
            // 3. BACK BUTTON
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              left: 20,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ], // Stack children
        ), // Stack
      ), // SingleChildScrollView
    ); // Scaffold
  } // build()
} // _RegisterPageState
