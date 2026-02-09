import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- THEME CONSTANTS ---
const Color _darkPrimary = Color(0xFF333333);
const Color _yellowAccent = Color(0xFFFCFB04);
const Color _background = Color(0xFF1F1F1F);
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF);

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? playerInfo;

  const ProfileScreen({
    Key? key,
    this.playerInfo,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  File? _localImagePicker;
  final String _defaultProfileAsset = 'assets/images/de.jpg';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.playerInfo != null) {
      setState(() {
        _userData = widget.playerInfo;
        _isLoading = false;
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // --- DELETE ACCOUNT LOGIC ---
  Future<void> _deleteAccount() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete Account?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          "This action is permanent. All your data and stats will be lost forever.",
          style: TextStyle(color: _whiteText),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: _textSecondary)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Step A: Delete Firestore Data
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

        // Step B: Delete Auth Account
        await user.delete();

        // Step C: Success & Navigate
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully.')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'requires-recent-login') {
        _showErrorSnackBar('Security: Please Log Out and Log In again to delete your account.');
      } else {
        _showErrorSnackBar('Error: ${e.message}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Something went wrong. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      content: Text(message, style: const TextStyle(color: Colors.white)),
    ));
  }

  void _viewProfilePicture(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(child: Center(child: Hero(tag: 'profile_full', child: CircleAvatar(radius: 150, backgroundImage: imageProvider)))),
            Padding(padding: const EdgeInsets.all(20), child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Scaffold(backgroundColor: _background, body: Center(child: CircularProgressIndicator(color: _yellowAccent)));
    }

    final data = _userData ?? {};
    final String name = data['name'] ?? 'Guest';
    final String email = data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
    final String teamName = data['teamName'] ?? 'No Team';
    final String role = data['role'] ?? 'Player';
    final String? serverImageUrl = data['profileImage'];

    ImageProvider profileImageProvider;
    if (_localImagePicker != null) {
      profileImageProvider = FileImage(_localImagePicker!);
    } else if (serverImageUrl != null && serverImageUrl.startsWith('http')) {
      profileImageProvider = NetworkImage(serverImageUrl);
    } else {
      profileImageProvider = AssetImage(_defaultProfileAsset);
    }

    return Scaffold(
      backgroundColor: _background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _whiteText),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _logout),
          const SizedBox(width: 10),
        ],
      ),
      // Fixed Screen (No Scroll)
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned(
            top: 0, left: 0, right: 0,
            height: screenHeight * 0.35,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_darkPrimary, _background]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Opacity(opacity: 0.1, child: Center(child: Icon(Icons.sports_cricket, size: 180, color: _yellowAccent))),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 5), // Top margin

                // --- PROFILE PIC ---
                GestureDetector(
                  onTap: () => _viewProfilePicture(context, profileImageProvider),
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _yellowAccent, width: 3), boxShadow: [BoxShadow(color: _yellowAccent.withOpacity(0.3), blurRadius: 20)]),
                    child: CircleAvatar(radius: 55, backgroundColor: _background, backgroundImage: profileImageProvider),
                  ),
                ),

                const SizedBox(height: 10),
                Text(name.toUpperCase(), style: const TextStyle(color: _whiteText, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text(email, style: const TextStyle(color: _textSecondary, fontSize: 13)),

                const SizedBox(height: 8),
                Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: _yellowAccent.withOpacity(0.15),
                    label: Text(teamName, style: const TextStyle(color: _yellowAccent, fontWeight: FontWeight.bold, fontSize: 12))
                ),

                const SizedBox(height: 15),

                // --- PERSONAL INFO ROW ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header('PERSONAL INFO'),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _infoCard(Icons.cake, 'DOB', data['dateOfBirth'] ?? 'N/A')),
                        const SizedBox(width: 10),
                        Expanded(child: _infoCard(Icons.location_city, 'City', data['city'] ?? 'N/A')),
                      ]),
                    ],
                  ),
                ),

                // --- GAP REDUCED (Yehan pehle Spacer tha) ---
                const SizedBox(height: 10), // Sirf 10 pixel ka faasla ab

                // --- CRICKET STATS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header('CRICKET STATS'),
                      const SizedBox(height: 5),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.1, // Flat cards
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 10,
                        children: [
                          _gridCard(Icons.person, 'Role', role),
                          if(role != 'Bowler') _gridCard(Icons.sports_baseball, 'Batting', data['battingStyle'] ?? 'N/A'),
                          if(role != 'Batsman') _gridCard(Icons.sports_tennis, 'Bowling', data['bowlingType'] ?? 'N/A'),
                          if(role != 'Batsman') _gridCard(Icons.accessibility, 'Arm', data['bowlingArm'] ?? 'N/A'),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- SPACER MOVED HERE ---
                // Ye baaki bachi hui jagah le lega aur Delete button ko bottom pe dhakel dega
                const Spacer(),

                // --- DELETE ACCOUNT BUTTON ---
                const SizedBox(height: 5),
                TextButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever, size: 20, color: Colors.redAccent),
                  label: const Text(
                    "DELETE ACCOUNT",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                    backgroundColor: Colors.redAccent.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 10), // Bottom Safe Padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String t) => Text(t, style: TextStyle(color: _textSecondary.withOpacity(0.7), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12));

  Widget _infoCard(IconData i, String l, String v) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _darkPrimary, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(i, color: _yellowAccent, size: 16), const SizedBox(width: 5), Text(l, style: const TextStyle(color: _textSecondary, fontSize: 11))]),
      const SizedBox(height: 5),
      Text(v, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)
    ]),
  );

  Widget _gridCard(IconData i, String l, String v) => Container(
    decoration: BoxDecoration(color: _darkPrimary, borderRadius: BorderRadius.circular(16), border: Border.all(color: _yellowAccent.withOpacity(0.1))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(i, color: _textSecondary.withOpacity(0.5), size: 20),
      const SizedBox(height: 2),
      Text(l.toUpperCase(), style: const TextStyle(color: _textSecondary, fontSize: 10)),
      Text(v, style: const TextStyle(color: _yellowAccent, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)
    ]),
  );
}