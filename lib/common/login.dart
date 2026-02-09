import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Note: Ab humein info screen ki import ki zaroorat nahi kyunke hum wahan bhej hi nahi rahay
// import 'package:stump_vision/common/info.dart';

// --- THEME CONSTANTS ---
const Color _bgBlack = Color(0xFF1F1F1F);
const Color _cardSurface = Color(0xFF333333);
const Color _yellowAccent = Color(0xFFFCFB04);
const Color _whiteText = Colors.white;
const Color _textGrey = Color(0xFF9CA3AF);
const Color _inputFill = Color(0xFF252525);

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _emailErrorText;
  String? _passwordErrorText;

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email cannot be empty';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password cannot be empty';
    return null;
  }

  // --- FIREBASE LOGIN LOGIC (UPDATED WITH AUTO-DELETE) ---
  Future<void> _login() async {
    // 1. Validation
    setState(() {
      _emailErrorText = _validateEmail(_emailController.text);
      _passwordErrorText = _validatePassword(_passwordController.text);
    });

    if (_emailErrorText != null || _passwordErrorText != null) return;

    setState(() => _isLoading = true);

    try {
      // 2. Firebase Sign In
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // 3. Email Verification Check
        if (user.emailVerified) {

          // --- CHECK FIRESTORE DATA ---
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (mounted) {
            if (userDoc.exists) {
              // --- CONDITION A: Data Exists -> Sab theek hai -> Go to LIVE SCORE ---
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/live_score',
                    (route) => false,
                arguments: userDoc.data() as Map<String, dynamic>,
              );
            } else {
              // --- CONDITION B: Data Missing -> Auto Delete Auth & Go to Signup ---
              // Logic: Agar data nahi hai to yeh account bekar hai, isay delete karo.

              try {
                // User abhi login hua hai isliye delete() bina re-login error k chal jayega
                await user.delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account data not found. Please create a new account.'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 4),
                    ),
                  );
                  // Navigate to Sign Up
                  Navigator.pushNamedAndRemoveUntil(context, '/signup', (route) => false);
                }
              } catch (e) {
                // Agar kisi wajah se delete fail ho (network etc), to simple SignOut karo
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid Account. Please Sign Up again.'), backgroundColor: Colors.redAccent),
                  );
                  Navigator.pushNamedAndRemoveUntil(context, '/signup', (route) => false);
                }
              }
            }
          }

        } else {
          // Email Verify Nahi Hai
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please verify your email address first.'), backgroundColor: Colors.redAccent),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'user-not-found') message = 'No user found for that email.';
      else if (e.code == 'wrong-password') message = 'Wrong password provided.';
      else if (e.code == 'invalid-credential') message = 'Invalid email or password.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- HEADER ---
              const Icon(Icons.sports_cricket, size: 60, color: _yellowAccent),
              const SizedBox(height: 20),
              const Text('WELCOME BACK!', style: TextStyle(color: _yellowAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              const SizedBox(height: 10),
              const Text('Login to Continue', style: TextStyle(color: _whiteText, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 40),

              // --- FORM ---
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: _cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                  border: Border.all(color: _whiteText.withOpacity(0.05)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildDarkTextField(
                        controller: _emailController,
                        labelText: 'EMAIL',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailErrorText,
                        onChanged: (value) => setState(() => _emailErrorText = _validateEmail(value)),
                      ),
                      const SizedBox(height: 20),
                      _buildDarkTextField(
                        controller: _passwordController,
                        labelText: 'PASSWORD',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        errorText: _passwordErrorText,
                        onChanged: (value) => setState(() => _passwordErrorText = _validatePassword(value)),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: _textGrey),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/reset_password'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Forgot Password?', style: TextStyle(color: _yellowAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildLoginButton(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- SIGN UP LINK ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: _textGrey)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('Sign Up', style: TextStyle(color: _yellowAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildDarkTextField({
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
        Text(labelText, style: const TextStyle(color: _textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: errorText != null ? Colors.redAccent : Colors.transparent),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(color: _whiteText, fontSize: 16),
            cursorColor: _yellowAccent,
            decoration: InputDecoration(
              prefixIcon: Icon(prefixIcon, color: _yellowAccent.withOpacity(0.7)),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              hintText: 'Enter your ${labelText.toLowerCase()}',
              hintStyle: TextStyle(color: _textGrey.withOpacity(0.4), fontSize: 14),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: _yellowAccent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: _yellowAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _login,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : const Text('LOGIN', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ),
        ),
      ),
    );
  }
}