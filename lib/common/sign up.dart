import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stump_vision/common/info.dart'; // Navigation ke liye Zaroori hai

// --- THEME CONSTANTS ---
const Color _bgDark = Color(0xFF050505);
const Color _yellowNeon = Color(0xFFE8F000);
const Color _fieldFill = Color(0xFF1E1E1E);
const Color _whiteText = Colors.white;
const Color _textGrey = Color(0xFF888888);

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  // --- CONTROLLERS ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STATE VARIABLES ---
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _verificationEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIC: CREATE ACCOUNT ---
  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _verificationEmailSent = false;
    });

    try {
      // 1. User Create karo
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Email Bhejo
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }

      // 3. UI Update karo
      if (mounted) {
        setState(() {
          _verificationEmailSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Please check your email."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred.";
      if (e.code == 'weak-password') {
        errorMessage = 'Password too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email already registered.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: CHECK VERIFICATION (UPDATED FLOW) ---
  Future<void> _checkEmailVerificationAndNavigate() async {
    setState(() => _isLoading = true);
    try {
      // 1. Firebase se fresh status lo
      await _auth.currentUser?.reload();
      final currentUser = _auth.currentUser;

      // 2. Check karo
      if (currentUser != null && currentUser.emailVerified) {
        if (mounted) {

          // --- DIRECT NAVIGATION TO INFO SCREEN ---
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerInfoScreen(
                userEmail: currentUser.email ?? _emailController.text,
              ),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Verification Successful! Please setup your profile."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorSnackBar('Email not verified yet. Please check inbox or spam.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: RESEND EMAIL ---
  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await _auth.currentUser?.sendEmailVerification();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Verification email re-sent! Check Spam folder too."),
              backgroundColor: _yellowNeon,
              behavior: SnackBarBehavior.floating,
            )
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar('Failed to resend: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // --- VALIDATORS ---
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    if (value.length < 6) return 'Min 6 chars required';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Background Effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _yellowNeon.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(color: _yellowNeon.withOpacity(0.2), blurRadius: 150, spreadRadius: 50),
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _yellowNeon.withOpacity(0.3), width: 2),
                    ),
                    child: Icon(
                        _verificationEmailSent ? Icons.mark_email_read : Icons.person_add_alt_1,
                        size: 40,
                        color: _yellowNeon
                    ),
                  ),
                  const SizedBox(height: 25),

                  Text(
                    _verificationEmailSent ? "VERIFY EMAIL" : "CREATE ACCOUNT",
                    style: const TextStyle(
                      color: _whiteText,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),

                  Text(
                    _verificationEmailSent
                        ? "Check your inbox at\n${_emailController.text}"
                        : "JOIN STUMP VISION TODAY",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _yellowNeon.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- CONDITIONAL UI SWITCH ---
                  if (_verificationEmailSent)
                    _buildVerificationView()
                  else
                    _buildSignUpForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. FORM VIEW
  Widget _buildSignUpForm() {
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildNeonTextField(
                controller: _emailController,
                hint: "Email Address",
                icon: Icons.email_outlined,
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),

              _buildNeonTextField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),

              _buildNeonTextField(
                controller: _confirmPasswordController,
                hint: "Confirm Password",
                icon: Icons.lock_reset,
                isPassword: true,
                isVisible: _isConfirmPasswordVisible,
                toggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                validator: _validateConfirmPassword,
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        _buildGradientButton(
          text: "SIGN UP",
          isLoading: _isLoading,
          onTap: _createAccount,
        ),

        const SizedBox(height: 35),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Already have an account?", style: TextStyle(color: _textGrey)),
            GestureDetector(
              onTap: () => Navigator.pop(context), // Back to Login
              child: const Text(
                " Login",
                style: TextStyle(color: _yellowNeon, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. VERIFICATION VIEW
  Widget _buildVerificationView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _fieldFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _yellowNeon.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "We have sent a verification link to your email.\nPlease click the link in your email app, then return here and press the button below.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),

              const SizedBox(height: 15),

              // --- SPAM FOLDER NOTICE ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _yellowNeon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Note: If you don't see the email in your Inbox, please kindly check your Spam/Junk folder.",
                      style: TextStyle(
                          color: _yellowNeon.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                          fontSize: 13
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Button 1: I have Verified
        _buildGradientButton(
          text: "I HAVE VERIFIED",
          isLoading: _isLoading,
          onTap: _checkEmailVerificationAndNavigate,
        ),

        const SizedBox(height: 20),

        // Button 2: Resend Email
        TextButton.icon(
          onPressed: _isLoading ? null : _resendVerificationEmail,
          icon: const Icon(Icons.refresh, color: _yellowNeon),
          label: const Text(
            "Resend Verification Email",
            style: TextStyle(color: _yellowNeon, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 10),

        // Option to go back/cancel
        TextButton(
          onPressed: () {
            setState(() {
              _verificationEmailSent = false;
            });
          },
          child: const Text("Use Different Email", style: TextStyle(color: _textGrey, decoration: TextDecoration.underline)),
        )
      ],
    );
  }

  // --- CUSTOM WIDGETS ---
  Widget _buildNeonTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(color: _whiteText),
        cursorColor: _yellowNeon,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: _yellowNeon),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: _textGrey,
            ),
            onPressed: toggleVisibility,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
    bool isLoading = false
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_yellowNeon, Color(0xFFC6CC00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
              height: 24, width: 24,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
            )
                : Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}