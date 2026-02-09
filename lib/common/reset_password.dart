import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth Import

// --- MODERN DARK & YELLOW THEME ---
const Color _darkPrimary = Color(0xFF333333); // Card/Sheet Background
const Color _yellowAccent = Color(0xFFFCFB04); // Highlights/Buttons
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text
const Color _blackText = Color(0xFF1F1F1F);     // Text on Yellow

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _emailErrorText;
  bool _isLoading = false; // Loading State

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // --- FIREBASE RESET LOGIC ---
  Future<void> _resetPassword() async {
    // 1. Validate Input
    setState(() {
      _emailErrorText = _validateEmail(_emailController.text);
    });

    if (_emailErrorText != null) return;

    setState(() {
      _isLoading = true; // Start Loading
    });

    try {
      // 2. Check User & Send Email
      // Firebase automatically checks if the email exists.
      // If it doesn't, it throws a 'user-not-found' exception.
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      // 3. Success -> Show Dialog & Navigate
      if (mounted) {
        _showSuccessDialog();
      }

    } on FirebaseAuthException catch (e) {
      // 4. Handle Errors (e.g., Email not registered)
      String errorMessage = "An error occurred";

      if (e.code == 'user-not-found') {
        errorMessage = "Ye email registered nahi hai. Please sign up karein.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      } else {
        errorMessage = e.message ?? "Something went wrong.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop Loading
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must click button
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _yellowAccent.withOpacity(0.3)),
          ),
          title: Row(
            children: const [
              Icon(Icons.mark_email_read, color: _yellowAccent),
              SizedBox(width: 10),
              Text(
                'Link Sent!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _whiteText,
                ),
              ),
            ],
          ),
          content: Text(
            'Hum ne ${_emailController.text} par password reset link bhej diya hai.\n\nPlease email check karein, password change karein aur phir naye password se login karein.',
            style: const TextStyle(fontSize: 14, color: _textSecondary),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellowAccent,
                foregroundColor: _blackText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close Dialog
                // Auto Navigate back to Login Screen
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text('OK, Go to Login', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Background Decor
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_background, _darkPrimary],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  // --- HEADER SECTION ---
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glowing Icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _darkPrimary,
                              boxShadow: [
                                BoxShadow(
                                  color: _yellowAccent.withOpacity(0.2),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                              border: Border.all(color: _yellowAccent.withOpacity(0.5), width: 2),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 60,
                              color: _yellowAccent,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'FORGOT PASSWORD?',
                            style: TextStyle(
                              color: _whiteText,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.0),
                            child: Text(
                              'Please enter the email associated with your account to receive a reset link.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- FORM SECTION ---
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                      decoration: BoxDecoration(
                        color: _darkPrimary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                        border: Border(
                          top: BorderSide(color: _yellowAccent.withOpacity(0.1), width: 1),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              _buildTextField(
                                controller: _emailController,
                                labelText: 'Email ID',
                                prefixIcon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                errorText: _emailErrorText,
                                onChanged: (value) {
                                  setState(() {
                                    _emailErrorText = _validateEmail(value);
                                  });
                                },
                              ),
                              const SizedBox(height: 40),

                              // Reset Button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _yellowAccent.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _resetPassword, // Disable if loading
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _yellowAccent,
                                    foregroundColor: _blackText,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 3,
                                    ),
                                  )
                                      : const Text(
                                    'SEND RESET LINK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Back to Login
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    text: "Remember password? ",
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Login',
                                        style: TextStyle(
                                          color: _yellowAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Back Button Top Left
              Positioned(
                top: 50,
                left: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: _whiteText, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? errorText,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText.toUpperCase(),
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(color: _whiteText, fontWeight: FontWeight.w500),
            cursorColor: _yellowAccent,
            decoration: InputDecoration(
              prefixIcon: Icon(prefixIcon, color: _yellowAccent.withOpacity(0.7)),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _yellowAccent, width: 1.5),
              ),
              errorText: errorText,
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}