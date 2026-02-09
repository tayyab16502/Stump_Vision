import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // UUID package

// --- MODERN DARK & YELLOW THEME ---
const Color _darkPrimary = Color(0xFF333333); // Card & AppBar Background
const Color _yellowAccent = Color(0xFFFCFB04); // Buttons & Highlights
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text
const Color _blackText = Color(0xFF1F1F1F);     // Text on Yellow buttons

class NewMatch extends StatefulWidget {
  const NewMatch({super.key});

  @override
  _NewMatchState createState() => _NewMatchState();
}

class _NewMatchState extends State<NewMatch> {
  final _formKey = GlobalKey<FormState>();
  String? team1Name, team2Name, venue, tossWinner, choice;
  int? overs, firstInningScore, firstInningOuts;
  bool isFirstInningSetup = true;

  // --- 2nd Inning Setup Form ---
  Widget _buildInningScoreForm() {
    String firstBattingTeam = (tossWinner == team1Name && choice == 'Batting') ||
        (tossWinner == team2Name && choice == 'Bowling')
        ? team1Name ?? 'Team 1'
        : team2Name ?? 'Team 2';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _darkPrimary,
        title: const Text(
          'Inning Score',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: _whiteText,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: _yellowAccent), // Yellow Back Arrow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              isFirstInningSetup = true;
            });
          },
        ),
      ),
      body: Container(
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Team Name Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _darkPrimary,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: _yellowAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text("Batting First", style: TextStyle(color: _textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        firstBattingTeam,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _whiteText,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                _buildTextField(
                  label: 'Runs Scored',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => firstInningScore = int.tryParse(value) ?? 0),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter the score';
                    if (int.tryParse(value) == null || int.parse(value) < 0) return 'Invalid score';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Number of Outs',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => firstInningOuts = int.tryParse(value) ?? 0),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter number of outs';
                    if (int.tryParse(value) == null || int.parse(value) < 0 || int.parse(value) > 10) {
                      return 'Invalid outs (0-10)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Target Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _darkPrimary,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: _whiteText.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Target to Chase: ", style: TextStyle(color: _textSecondary, fontSize: 16)),
                        Text(
                          '${firstInningScore != null ? firstInningScore! + 1 : '0'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _yellowAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                _buildButton(
                  text: 'START 2ND INNING',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final String newMatchId = const Uuid().v4();
                      final int targetValue = firstInningScore != null ? firstInningScore! + 1 : 0;

                      Navigator.pushNamed(context, '/scoring_screen', arguments: {
                        'matchDetails': {
                          'matchId': newMatchId,
                          'team1Name': team1Name,
                          'team2Name': team2Name,
                          'overs': overs,
                          'tossWinner': tossWinner,
                          'choice': choice,
                          'firstInningBattingTeamName': firstBattingTeam,
                          'firstInningBattingTeam': firstBattingTeam,
                          'target': targetValue,
                          'targetToChase': targetValue,
                          'venue': venue,
                          'firstInningScore': firstInningScore,
                          'firstInningOuts': firstInningOuts,
                          'currentInnings': 2,
                          'startFirstInning': false,
                        }
                      });
                    }
                  },
                  height: 55,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Custom Text Field (Dark Theme) ---
  Widget _buildTextField({
    required String label,
    TextInputType? keyboardType,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      style: const TextStyle(color: _whiteText, fontSize: 16),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSecondary),
        filled: true,
        fillColor: _darkPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: _whiteText.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: _yellowAccent, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  // --- Custom Dropdown (Dark Theme) ---
  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      dropdownColor: _darkPrimary,
      style: const TextStyle(color: _whiteText, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSecondary),
        filled: true,
        fillColor: _darkPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: _whiteText.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: _yellowAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: _yellowAccent),
      items: items.isNotEmpty
          ? items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList()
          : [
        const DropdownMenuItem<String>(
          value: null,
          enabled: false,
          child: Text('Enter Team Names First', style: TextStyle(color: _textSecondary)),
        ),
      ],
      value: (items.contains(tossWinner)) ? tossWinner : null,
      onChanged: items.isNotEmpty ? onChanged : null,
      validator: validator,
    );
  }

  // --- Full Width Yellow Button ---
  Widget _buildButton({required String text, required VoidCallback onPressed, double height = 55}) {
    return Container(
      width: double.infinity, // MAX WIDTH
      height: height,
      decoration: BoxDecoration(
        color: _yellowAccent, // Solid Yellow
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: _yellowAccent.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.0),
          splashColor: Colors.black12,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800, // Bold
                letterSpacing: 1.0,
                color: _blackText, // Black Text on Yellow
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'New Match Setup',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: _whiteText,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _darkPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: _yellowAccent),
      ),
      body: Container(
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: isFirstInningSetup ? _buildMatchSetupForm() : _buildInningScoreForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchSetupForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MATCH DETAILS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _yellowAccent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            label: 'Team 1 Name',
            onChanged: (value) {
              setState(() {
                team1Name = value.isNotEmpty ? value : null;
                if (tossWinner != null && tossWinner != team1Name && tossWinner != team2Name) {
                  tossWinner = null;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Team 2 Name',
            onChanged: (value) {
              setState(() {
                team2Name = value.isNotEmpty ? value : null;
                if (tossWinner != null && tossWinner != team1Name && tossWinner != team2Name) {
                  tossWinner = null;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Venue',
            onChanged: (value) => venue = value.isNotEmpty ? value : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Total Overs',
            keyboardType: TextInputType.number,
            onChanged: (value) => overs = int.tryParse(value) ?? 0,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter Overs';
              if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Invalid number of overs';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Toss Won By',
            items: [team1Name, team2Name].whereType<String>().toList(),
            onChanged: (value) => setState(() => tossWinner = value),
            validator: (value) {
              if (value == null && (team1Name != null || team2Name != null)) {
                return 'Please select a team';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Chosen To',
            items: ['Batting', 'Bowling'],
            onChanged: (value) => setState(() => choice = value),
            validator: (value) => value == null ? 'Please select an option' : null,
          ),
          const SizedBox(height: 40),

          _buildButton(
            text: 'START SCORING',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                String firstBattingTeam = (tossWinner == team1Name && choice == 'Batting') ||
                    (tossWinner == team2Name && choice == 'Bowling')
                    ? team1Name ?? 'Team 1'
                    : team2Name ?? 'Team 2';

                final String newMatchId = const Uuid().v4();

                Navigator.pushNamed(context, '/scoring_screen', arguments: {
                  'matchDetails': {
                    'matchId': newMatchId,
                    'team1Name': team1Name,
                    'team2Name': team2Name,
                    'overs': overs,
                    'tossWinner': tossWinner,
                    'choice': choice,
                    'firstInningBattingTeamName': firstBattingTeam,
                    'firstInningBattingTeam': firstBattingTeam,
                    'venue': venue,
                    'startFirstInning': true,
                    'currentInnings': 1,
                  }
                });
              }
            },
            height: 55,
          ),
          const SizedBox(height: 16),

          // Secondary Button (Outlined Style for contrast)
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              border: Border.all(color: _yellowAccent, width: 1.5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.0),
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      isFirstInningSetup = false;
                    });
                  }
                },
                child: const Center(
                  child: Text(
                    'SKIP TO 2ND INNING',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _yellowAccent,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}