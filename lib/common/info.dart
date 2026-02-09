import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';      // Auth
import 'package:cloud_firestore/cloud_firestore.dart';  // Database
import 'package:firebase_storage/firebase_storage.dart'; // Storage (Images)

// --- MODERN DARK & YELLOW THEME ---
const Color _darkPrimary = Color(0xFF333333);
const Color _yellowAccent = Color(0xFFFCFB04);
const Color _background = Color(0xFF1F1F1F);
const Color _fieldFill = Color(0xFF1E1E1E);
const Color _whiteText = Colors.white;
const Color _textGrey = Color(0xFF888888);

class PlayerInfoScreen extends StatefulWidget {
  final String userEmail;

  const PlayerInfoScreen({super.key, required this.userEmail});

  @override
  State<PlayerInfoScreen> createState() => _PlayerInfoScreenState();
}

class _PlayerInfoScreenState extends State<PlayerInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();

  // Selection Variables
  String? _selectedRole;
  String? _selectedBattingStyle;
  String? _selectedBattingPosition;
  String? _selectedBowlingType;
  String? _selectedBowlingArm;

  DateTime? _selectedDate;
  File? _profileImage;
  bool _isSaving = false; // Loading State

  // Error Variables
  String? _nameErrorText;
  String? _dobErrorText;
  String? _cityErrorText;
  String? _countryErrorText;
  String? _teamNameErrorText;
  String? _roleErrorText;
  String? _battingStyleErrorText;
  String? _battingPositionErrorText;
  String? _bowlingTypeErrorText;
  String? _bowlingArmErrorText;

  // Lists
  final List<String> _roles = ['Batsman', 'Bowler', 'All-rounder', 'Coach'];
  final List<String> _battingStyles = ['Right-hand', 'Left-hand'];
  final List<String> _battingPositions = ['Opener', 'Middle Order', 'Finisher'];
  final List<String> _bowlingTypes = ['Spinner', 'Fast', 'Medium Fast'];
  final List<String> _bowlingArms = ['Right Arm', 'Left Arm'];

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _teamNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- IMAGE PICKER ---
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // --- DATE PICKER ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _yellowAccent,
              onPrimary: Colors.black,
              surface: _darkPrimary,
              onSurface: _whiteText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _yellowAccent),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
        _dobErrorText = null;
      });
    }
  }

  // --- 1. UPLOAD IMAGE LOGIC ---
  Future<String?> _uploadImage(File image, String uid) async {
    try {
      // Create ref: profile_images/USER_UID.jpg
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      // Upload
      await ref.putFile(image);

      // Get URL
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  // --- 2. MAIN SUBMIT LOGIC ---
  Future<void> _submitPlayerInfo() async {
    if (_formKey.currentState!.validate()) {
      bool isValid = true;

      // Custom Validations
      if (_selectedRole == null) {
        setState(() => _roleErrorText = 'Please select a role');
        isValid = false;
      } else {
        if (_selectedRole == 'Batsman' || _selectedRole == 'All-rounder') {
          if (_selectedBattingStyle == null) {
            setState(() => _battingStyleErrorText = 'Please select batting style');
            isValid = false;
          }
          if (_selectedBattingPosition == null) {
            setState(() => _battingPositionErrorText = 'Please select batting position');
            isValid = false;
          }
        }
        if (_selectedRole == 'Bowler' || _selectedRole == 'All-rounder') {
          if (_selectedBowlingType == null) {
            setState(() => _bowlingTypeErrorText = 'Please select bowling type');
            isValid = false;
          }
          if (_selectedBowlingArm == null) {
            setState(() => _bowlingArmErrorText = 'Please select bowling arm');
            isValid = false;
          }
        }
      }

      if (isValid) {
        setState(() => _isSaving = true); // Loading Start

        try {
          // A. Get User
          final User? user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception("No user logged in");

          String? imageUrl;

          // B. Upload Image (If Selected)
          if (_profileImage != null) {
            imageUrl = await _uploadImage(_profileImage!, user.uid);
          }

          // C. Prepare Data Map
          Map<String, dynamic> playerInfo = {
            'uid': user.uid,
            'name': _nameController.text.trim(),
            'dateOfBirth': _dobController.text,
            'city': _cityController.text.trim(),
            'country': _countryController.text.trim(),
            'teamName': _teamNameController.text.isNotEmpty ? _teamNameController.text.trim() : 'N/A',
            'role': _selectedRole,
            'email': widget.userEmail,
            'profileImage': imageUrl, // Saving URL instead of local path
            'battingStyle': (_selectedRole == 'Batsman' || _selectedRole == 'All-rounder') ? _selectedBattingStyle : 'N/A',
            'battingPosition': (_selectedRole == 'Batsman' || _selectedRole == 'All-rounder') ? _selectedBattingPosition : 'N/A',
            'bowlingType': (_selectedRole == 'Bowler' || _selectedRole == 'All-rounder') ? _selectedBowlingType : 'N/A',
            'bowlingArm': (_selectedRole == 'Bowler' || _selectedRole == 'All-rounder') ? _selectedBowlingArm : 'N/A',
            'createdAt': FieldValue.serverTimestamp(),
          };

          // D. Save to Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(playerInfo);

          // E. Navigate
          if (mounted) {
            // UPDATED: Go to Live Score Home Screen
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/live_score',
                  (route) => false,
              // Live Score screen ko arguments ki zaroorat nahi hoti usually,
              // data wahan firebase se fetch hoga agar chahiye ho.
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
            );
          }
        } finally {
          if (mounted) setState(() => _isSaving = false); // Loading Stop
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please correct the errors and fill all required fields.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 150,
              decoration: const BoxDecoration(
                  color: _darkPrimary,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'SETUP PROFILE',
                    style: TextStyle(
                      color: _whiteText,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [Shadow(blurRadius: 15.0, color: Colors.black54, offset: Offset(0, 3))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us about your game!',
                    style: TextStyle(color: _yellowAccent.withOpacity(0.7), fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- PROFILE PICTURE UPLOAD ---
                    Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: _fieldFill,
                              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                              child: _profileImage == null
                                  ? const Icon(Icons.person, size: 60, color: _textGrey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _darkPrimary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _yellowAccent, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: _yellowAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: _yellowAccent),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: _darkPrimary,
                                      builder: (BuildContext context) {
                                        return SafeArea(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(Icons.photo_library, color: _yellowAccent),
                                                title: const Text('Choose from Gallery', style: TextStyle(color: _whiteText)),
                                                onTap: () { _pickImage(ImageSource.gallery); Navigator.pop(context); },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.camera_alt, color: _yellowAccent),
                                                title: const Text('Take a Photo', style: TextStyle(color: _whiteText)),
                                                onTap: () { _pickImage(ImageSource.camera); Navigator.pop(context); },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),

                    // --- PERSONAL DETAILS ---
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) => value == null || value.isEmpty ? 'Name required' : null,
                      onChanged: (value) => setState(() => _nameErrorText = null),
                      errorText: _nameErrorText,
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: _dobController,
                      labelText: 'Date of Birth',
                      prefixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => value == null || value.isEmpty ? 'Date of Birth required' : null,
                      errorText: _dobErrorText,
                      onChanged: (value) => setState(() => _dobErrorText = null),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: _cityController,
                      labelText: 'City',
                      prefixIcon: Icons.location_city_outlined,
                      validator: (value) => value == null || value.isEmpty ? 'City required' : null,
                      errorText: _cityErrorText,
                      onChanged: (value) => setState(() => _cityErrorText = null),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: _countryController,
                      labelText: 'Country',
                      prefixIcon: Icons.public_outlined,
                      validator: (value) => value == null || value.isEmpty ? 'Country required' : null,
                      errorText: _countryErrorText,
                      onChanged: (value) => setState(() => _countryErrorText = null),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: _teamNameController,
                      labelText: 'Team Name (Optional)',
                      prefixIcon: Icons.group_outlined,
                      errorText: _teamNameErrorText,
                      onChanged: (value) => setState(() => _teamNameErrorText = null),
                    ),
                    const SizedBox(height: 25),

                    // --- ROLE SELECTION ---
                    _buildDropdownField<String>(
                      labelText: 'Role',
                      prefixIcon: Icons.sports_cricket_outlined,
                      value: _selectedRole,
                      items: _roles,
                      errorText: _roleErrorText,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                          _roleErrorText = null;
                          _selectedBattingStyle = null; _selectedBattingPosition = null;
                          _selectedBowlingType = null; _selectedBowlingArm = null;
                          _battingStyleErrorText = null; _battingPositionErrorText = null;
                          _bowlingTypeErrorText = null; _bowlingArmErrorText = null;
                        });
                      },
                    ),
                    const SizedBox(height: 25),

                    // --- BATTING DETAILS ---
                    if (_selectedRole == 'Batsman' || _selectedRole == 'All-rounder')
                      Column(
                        children: [
                          _buildDropdownField<String>(
                            labelText: 'Batting Style',
                            prefixIcon: Icons.sports_cricket_outlined,
                            value: _selectedBattingStyle,
                            items: _battingStyles,
                            errorText: _battingStyleErrorText,
                            onChanged: (String? newValue) {
                              setState(() { _selectedBattingStyle = newValue; _battingStyleErrorText = null; });
                            },
                          ),
                          const SizedBox(height: 25),
                          _buildDropdownField<String>(
                            labelText: 'Batting Position',
                            prefixIcon: Icons.sports_cricket_outlined,
                            value: _selectedBattingPosition,
                            items: _battingPositions,
                            errorText: _battingPositionErrorText,
                            onChanged: (String? newValue) {
                              setState(() { _selectedBattingPosition = newValue; _battingPositionErrorText = null; });
                            },
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),

                    // --- BOWLING DETAILS ---
                    if (_selectedRole == 'Bowler' || _selectedRole == 'All-rounder')
                      Column(
                        children: [
                          _buildDropdownField<String>(
                            labelText: 'Bowling Type',
                            prefixIcon: Icons.sports_cricket_outlined,
                            value: _selectedBowlingType,
                            items: _bowlingTypes,
                            errorText: _bowlingTypeErrorText,
                            onChanged: (String? newValue) {
                              setState(() { _selectedBowlingType = newValue; _bowlingTypeErrorText = null; });
                            },
                          ),
                          const SizedBox(height: 25),
                          _buildDropdownField<String>(
                            labelText: 'Bowling Arm',
                            prefixIcon: Icons.sports_cricket_outlined,
                            value: _selectedBowlingArm,
                            items: _bowlingArms,
                            errorText: _bowlingArmErrorText,
                            onChanged: (String? newValue) {
                              setState(() { _selectedBowlingArm = newValue; _bowlingArmErrorText = null; });
                            },
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),

                    // --- SUBMIT BUTTON ---
                    _buildSubmitButton(
                        text: 'Save Info',
                        onPressed: _isSaving ? null : _submitPlayerInfo, // Disable if saving
                        isLoading: _isSaving // Pass loading state
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CUSTOM WIDGETS ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: _whiteText),
      readOnly: readOnly,
      onTap: onTap,
      cursorColor: _yellowAccent,
      decoration: InputDecoration(
        labelText: labelText.toUpperCase(),
        labelStyle: const TextStyle(color: _textGrey, fontSize: 13, letterSpacing: 1.0),
        prefixIcon: Icon(prefixIcon, color: _yellowAccent.withOpacity(0.7)),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        filled: true,
        fillColor: _fieldFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _yellowAccent, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _textGrey.withOpacity(0.2))),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String labelText,
    required IconData prefixIcon,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? errorText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorText != null ? Colors.redAccent : Colors.transparent),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: _fieldFill,
        style: const TextStyle(color: _whiteText, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: _yellowAccent),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: labelText.toUpperCase(),
          labelStyle: const TextStyle(color: _textGrey, fontSize: 13, letterSpacing: 1.0),
          prefixIcon: Icon(prefixIcon, color: _yellowAccent.withOpacity(0.7)),
          errorText: errorText,
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
          filled: true,
          fillColor: _fieldFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _yellowAccent, width: 2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _textGrey.withOpacity(0.2))),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        ),
        items: items.map<DropdownMenuItem<T>>((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // UPDATED BUTTON TO HANDLE LOADING
  Widget _buildSubmitButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        // Disable gradient look if loading/disabled
        gradient: onPressed == null ? null : const LinearGradient(
          colors: [_yellowAccent, Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: onPressed == null ? Colors.grey : null, // Fallback color
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null ? [] : [
          BoxShadow(
            color: _yellowAccent.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
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
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}