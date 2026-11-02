import 'widgets/app_navigation_bar.dart';

import 'package:flutter/material.dart';
import 'package:mad_project/register_page.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Poppins'),

      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  static const orange = Color(0xFFFF692B);
  bool isPasswordHidden = true;
  bool isLoggingIn = false;
  String? passwordAuthError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoggingIn) return;
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoggingIn = true);

    try {
      final credential = await AuthService().login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await credential.user!.reload();

      final user = FirebaseAuth.instance.currentUser!;

      // Require email verification before proceeding.
      if (!user.emailVerified) {
        await AuthService().logout();

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Email Not Verified'),
            content: const Text(
              'You need to verify your email first. Check your inbox and '
              'Spam/Junk folder, then tap the verification link before '
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
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: AppNavigation.home),
          builder: (context) => const HomePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Login failed. Please try again.';

      if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        setState(() => passwordAuthError = 'Incorrect password');
        formKey.currentState!.validate();
        return;
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Unable to connect. Check your internet connection.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password sign-in is not enabled in Firebase.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log in. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => isLoggingIn = false);
    }
  }

  InputDecoration fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 32),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      errorStyle: const TextStyle(fontSize: 10, height: 1.1), 
      errorMaxLines: 2,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFFA58A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    final headerHeight = isKeyboardOpen
        ? screenSize.height * 0.25
        : screenSize.height * 0.48;
    final panelTop = isKeyboardOpen
        ? screenSize.height * 0.25
        : screenSize.height * 0.35;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. HEADER BACKGROUND
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Image.asset(
              'assets/images/background_HD.png',
              fit: BoxFit.cover,
              alignment: Alignment(0, 1.5),
            ),
          ),

          // 2. WHITE CURVED SECTION
          Positioned.fill(
            top: panelTop,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topRight: Radius.circular(50)),
              ),
            ),
          ),

          // 3. LOGIN FORM
          Positioned.fill(
            top: panelTop + (isKeyboardOpen ? 48 : 68),
            bottom: keyboardHeight,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: screenSize.width * 0.18,
                  right: screenSize.width * 0.18,
                  bottom: 16,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // EMAIL LABEL
                      const Text(
                        'EMAIL',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: Color(0xFF555555),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // EMAIL FIELD
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        style: const TextStyle(fontSize: 16),
                        decoration: fieldDecoration('Enter your email'),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      // PASSWORD LABEL
                      const Text(
                        'PASSWORD',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: Color(0xFF555555),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // PASSWORD FIELD
                      TextFormField(
                        controller: passwordController,
                        textInputAction: TextInputAction.done,
                        obscureText: isPasswordHidden,
                        onChanged: (_) {
                          if (passwordAuthError != null) {
                            setState(() => passwordAuthError = null);
                          }
                        },
                        style: const TextStyle(fontSize: 16),
                        decoration: fieldDecoration(
                          'Enter your password',
                            suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              isPasswordHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordHidden = !isPasswordHidden;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return passwordAuthError;
                        },
                      ),

                      const SizedBox(height: 12),

                      // LOGIN BUTTON
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: isLoggingIn ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // SIGNUP BUTTON
                      SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      // FORGOT PASSWORD
                      TextButton(
                        onPressed: () {
                          // Password reset comes later.
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. CENTER LOGO - DRAWN ABOVE THE PANEL
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            top: isKeyboardOpen ? panelTop - 45 : panelTop - 70,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isKeyboardOpen ? 90 : 150,
                height: isKeyboardOpen ? 90 : 150,
                child: Image.asset(
                  'assets/images/borrowIT-logo-orange-transparent.png',
                  fit: BoxFit.contain
                ),
              ),
            ),
          ),
        ], // Closes Stack children
      ), // Closes Stack
    ); // Closes Scaffold
  } // Closes build() method
} // Closes _LoginPageState class
