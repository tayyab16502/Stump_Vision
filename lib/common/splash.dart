import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'dart:async'; // For Timer
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth Added

// --- MODERN DARK & YELLOW THEME ---
const Color _darkPrimary = Color(0xFF333333);
const Color _yellowAccent = Color(0xFFFCFB04); // Highlights
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Set system UI overlay
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // 3 Seconds ka timer
    Timer(const Duration(seconds: 3), () {
      _checkUserAndNavigate();
    });
  }

  // --- UPDATED LOGIC HERE ---
  Future<void> _checkUserAndNavigate() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // STEP 1: Server se verify karo ke user abhi b exist karta hai ya nahi
        await user.reload();

        // STEP 2: Reload hone k baad dubara user instance lo
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null) {
          // Account Exists -> Go to Live Score
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/live_score');
          }
        } else {
          // Rare case: Reload hua but user null ho gya
          _handleLogout();
        }

      } on FirebaseAuthException catch (e) {
        // STEP 3: Agar Account delete ho chuka hai ya disable hai
        if (e.code == 'user-not-found' || e.code == 'user-disabled') {
          // Session clear karo
          await FirebaseAuth.instance.signOut();
          _handleLogout();
        } else {
          // STEP 4: Agar Internet ka masla hai ya koi aur error hai
          // To hum user ko rokain gay nahi, cache par hi login karwa denge
          // (Agar strict security chahiye to yahan b logout karwa sakte hain)
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/live_score');
          }
        }
      }
    } else {
      // User pehle se hi logout hai
      _handleLogout();
    }
  }

  void _handleLogout() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: _darkPrimary,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _darkPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_darkPrimary, _background, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // --- Background Image ---
            Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/splash.png',
                fit: BoxFit.cover,
                color: Colors.black,
                colorBlendMode: BlendMode.darken,
              ),
            ),

            // --- Cricket Icon Overlay ---
            Center(
              child: Opacity(
                opacity: 0.05,
                child: Transform.rotate(
                  angle: -0.5,
                  child: const Icon(Icons.sports_cricket, size: 350, color: _yellowAccent),
                ),
              ),
            ),

            // --- Main Content ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(flex: 2),

                  // Logo Text
                  Column(
                    children: [
                      const Text(
                        'Stump Vision',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _yellowAccent,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          height: 1.1,
                          shadows: [
                            Shadow(blurRadius: 30.0, color: _yellowAccent, offset: Offset(0, 0)),
                            Shadow(blurRadius: 10.0, color: Colors.black, offset: Offset(0, 5.0)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI-Powered DRS & Real-Time Scoring',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _whiteText.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Quote Section
                  Column(
                    children: [
                      const Text(
                        "\"Every innings is a new opportunity.\"",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _whiteText,
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        height: 3, width: 60,
                        decoration: BoxDecoration(
                            color: _yellowAccent,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [BoxShadow(color: _yellowAccent.withOpacity(0.5), blurRadius: 5)]
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "- Rahul Dravid",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _yellowAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // Loading Indicator
                  const SizedBox(
                    height: 30, width: 30,
                    child: CircularProgressIndicator(color: _yellowAccent, strokeWidth: 3.0),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}