import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScoreBookHomeScreen extends StatefulWidget {
  const ScoreBookHomeScreen({super.key});

  @override
  State<ScoreBookHomeScreen> createState() => _ScoreBookHomeScreenState();
}

class _ScoreBookHomeScreenState extends State<ScoreBookHomeScreen> {
  // --- MODERN DARK & YELLOW THEME ---
  static const Color _darkPrimary = Color(0xFF333333); // Card & AppBar
  static const Color _yellowAccent = Color(0xFFFCFB04); // Highlights
  static const Color _background = Color(0xFF1F1F1F);   // Screen Background
  static const Color _whiteText = Colors.white;
  static const Color _textSecondary = Color(0xFF9CA3AF); // Grey text

  // Default index 1 (Scorebook)
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    // Status Bar Styling for Dark Theme
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: _darkPrimary,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _darkPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  // --- UPDATED NAVIGATION LOGIC ---
  void _onTabTapped(int index) {
    if (index == 0) {
      // 1. Matches (Go back to Main Screen / Previous Screen)
      Navigator.of(context).pop();
    } else if (index == 1) {
      // 2. Scorebook (Stay here)
      setState(() {
        _currentIndex = index;
      });
    } else if (index == 2) {
      // 3. DRS (Navigate to DRS Screen)
      Navigator.pushNamed(context, '/drs_screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      // Main Content (Always Scorebook View because DRS navigates away)
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(),
            ),
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _darkPrimary,
            elevation: 0,
            title: const Text(
              "",
              style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.add_chart_outlined,
                    title: 'Create New Score Book',
                    description: 'Start a fresh score book for a new match or practice session.',
                    onTap: () {
                      Navigator.pushNamed(context, '/new_match');
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.folder_open_outlined,
                    title: 'Open Existing Score Book',
                    description: 'Access and manage your saved matches or continue scoring.',
                    onTap: () {
                      Navigator.pushNamed(context, '/open_existing_score_book');
                    },
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),

      // --- BOTTOM NAVIGATION BAR (Yellow Highlight) ---
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black, blurRadius: 15, offset: Offset(0, -2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: _darkPrimary,
              selectedItemColor: _yellowAccent,
              unselectedItemColor: _textSecondary,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              iconSize: 26,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_cricket_outlined),
                  activeIcon: Icon(Icons.sports_cricket),
                  label: 'Matches',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  activeIcon: Icon(Icons.book),
                  label: 'Scorebook',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_front_outlined),
                  activeIcon: Icon(Icons.camera_front),
                  label: 'DRS',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Header Image Logic (FIXED POSITION) ---
  Widget _buildHeaderImage() {
    return Container(
      decoration: const BoxDecoration(
        color: _darkPrimary,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Original Image Widget
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/score_book.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(child: Icon(Icons.sports_cricket, size: 80, color: _whiteText.withOpacity(0.1)));
              },
            ),
          ),

          // 2. Dark Overlay on top of the image
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7), // Darker top
                  Colors.black.withOpacity(0.5), // Slightly transparent middle
                  _background // Seamless transition to body color at bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Text Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20), // Offset for status bar
                  Text(
                    'YOUR CRICKET HUB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _yellowAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.5), offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track every run, every wicket.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _whiteText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  // --- FEATURE CARD WIDGET ---
  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _darkPrimary,
        borderRadius: BorderRadius.circular(20),
        // Subtle Yellow Border
        border: Border.all(color: _yellowAccent.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: _yellowAccent.withOpacity(0.1),
          highlightColor: _yellowAccent.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Icon Circle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _yellowAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: _yellowAccent),
                ),
                const SizedBox(width: 20),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _whiteText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(Icons.arrow_forward_ios, color: _textSecondary.withOpacity(0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}