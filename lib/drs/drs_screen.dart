import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:async'; // Added for Completer/Future if needed

// --- THEME COLORS ---
const Color _darkPrimary = Color(0xFF333333);
const Color _yellowAccent = Color(0xFFFCFB04);
const Color _background = Color(0xFF1F1F1F);
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF);

class DRSScreen extends StatefulWidget {
  const DRSScreen({super.key});

  @override
  State<DRSScreen> createState() => _DRSScreenState();
}

class _DRSScreenState extends State<DRSScreen> {
  final ImagePicker _picker = ImagePicker();

  // UI State Variables
  bool _isUploading = false;
  String _statusMessage = "Select an option to analyze LBW/Stumps";
  String? _savedPath;

  // --- 1. VIDEO SELECTION ---
  Future<void> _pickAndUploadVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 15),
      );

      if (video != null) {
        File videoFile = File(video.path);
        _uploadVideoToServer(videoFile);
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
    }
  }

  // --- 2. UPLOAD & SAVE TO GALLERY ---
  Future<void> _uploadVideoToServer(File videoFile) async {
    setState(() {
      _isUploading = true;
      _statusMessage = "Analyzing Video via Server...";
      _savedPath = null;
    });

    String serverUrl = "https://nonphrenetically-unepicurean-christoper.ngrok-free.dev/detect-ball/";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));

      request.headers.addAll({
        "ngrok-skip-browser-warning": "true",
      });

      var multipartFile = await http.MultipartFile.fromPath('video', videoFile.path);
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Step A: Create Temp File
        final directory = await getTemporaryDirectory();
        final String tempPath = '${directory.path}/ai_result_video.mp4';
        final File tempFile = File(tempPath);

        // Write Server Data
        await tempFile.writeAsBytes(response.bodyBytes, flush: true);

        // Step B: Save to Gallery via Gal
        try {
          bool hasAccess = await Gal.hasAccess();
          if (!hasAccess) {
            await Gal.requestAccess();
          }

          await Gal.putVideo(tempFile.path, album: "StumpVision AI");

          setState(() {
            _statusMessage = "SUCCESS!\nVideo Saved to Gallery.";
            _savedPath = "Check 'StumpVision AI' in Gallery";
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video Saved to Gallery! 🏏'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          setState(() {
            _statusMessage = "Video Downloaded but failed to save.\nError: $e";
          });
          debugPrint("Gallery Save Error: $e");
        }

      } else {
        setState(() {
          _statusMessage = "Server Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
      debugPrint("API Error: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // --- UI HELPER: ACTION CARD ---
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _darkPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _whiteText.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: _yellowAccent, size: 30),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: _whiteText, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: _textSecondary, fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }

  // --- NAVIGATION LOGIC ---
  void _onTabTapped(int index) {
    if (index == 0) {
      // Navigate back to Home (Matches)
      Navigator.pop(context);
    } else if (index == 1) {
      // Navigate to Scorebook
      Navigator.pushReplacementNamed(context, '/score_book_main');
    }
    // Index 2 is this screen, so do nothing
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('DRS Review System', style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold)),
        backgroundColor: _darkPrimary,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide default back button
        iconTheme: const IconThemeData(color: _yellowAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- STATUS DISPLAY BOX ---
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _savedPath != null ? Colors.green : Colors.transparent, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUploading)
                      const Column(
                        children: [
                          CircularProgressIndicator(color: _yellowAccent),
                          SizedBox(height: 20),
                          Text("Processing & Downloading...", style: TextStyle(color: _textSecondary)),
                        ],
                      )
                    else if (_savedPath != null)
                      Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 60),
                          const SizedBox(height: 20),
                          Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(color: _whiteText, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(_savedPath!, textAlign: TextAlign.center, style: const TextStyle(color: _yellowAccent, fontSize: 14)),
                          const SizedBox(height: 20),
                          const Text("(Go to Gallery to watch)", style: TextStyle(color: _textSecondary, fontSize: 12)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Icon(Icons.cloud_download, color: _textSecondary.withOpacity(0.3), size: 60),
                          const SizedBox(height: 20),
                          Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: _textSecondary)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- BUTTONS ---
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildActionCard(icon: Icons.camera_alt, title: "Record Delivery", subtitle: "Record & Save to Gallery", onTap: () => _pickAndUploadVideo(ImageSource.camera)),
                  _buildActionCard(icon: Icons.photo_library, title: "Upload from Gallery", subtitle: "Analyze & Save Result", onTap: () => _pickAndUploadVideo(ImageSource.gallery)),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- ADDED BOTTOM NAVIGATION BAR ---
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
              currentIndex: 2, // 2 is for DRS
              onTap: _onTabTapped,
              backgroundColor: _darkPrimary,
              selectedItemColor: _yellowAccent,
              unselectedItemColor: _textSecondary,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_cricket_outlined),
                  label: 'Matches',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  label: 'Scorebook',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_front), // Filled Icon for current page
                  label: 'DRS',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}