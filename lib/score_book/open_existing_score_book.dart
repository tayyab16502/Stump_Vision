import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:stump_vision/score_book/scoring/scorecard_logic.dart';
import 'package:stump_vision/score_book/scoring_screen.dart';
import 'package:stump_vision/score_book/database_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stump_vision/main.dart'; // Import MyApp for navigatorKey

// --- MODERN DARK & YELLOW THEME ---
const Color _darkPrimary = Color(0xFF333333); // Card & AppBar Background
const Color _yellowAccent = Color(0xFFFCFB04); // Highlights
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text

class OpenExistingScoreBookScreen extends StatefulWidget {
  const OpenExistingScoreBookScreen({
    super.key,
    required this.onResumeScoring,
  });

  final Function(Map<String, dynamic>) onResumeScoring;

  @override
  State<OpenExistingScoreBookScreen> createState() =>
      _OpenExistingScoreBookScreenState();
}

class _OpenExistingScoreBookScreenState
    extends State<OpenExistingScoreBookScreen> {
  List<Map<String, dynamic>> _savedMatches = [];
  bool _isLoading = true;
  final ScorecardLogic _scorecardLogic =
  ScorecardLogic(navigatorKey: GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _loadSavedMatches();
    _scorecardLogic.addUpdateListener(_onScorecardUpdated);
  }

  @override
  void dispose() {
    _scorecardLogic.removeUpdateListener(_onScorecardUpdated);
    super.dispose();
  }

  // --- Database Interaction Functions (UPDATED FIX) ---
  Future<void> _loadSavedMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allMatches = await DatabaseService().getMatches();

      // Debug Print
      print("DB Loaded: ${allMatches.length} matches found.");

      final Map<String, Map<String, dynamic>> mostRecentMatches = {};

      for (var match in allMatches) {
        // --- FIX: Safely convert ID to String to avoid Type Cast Errors ---
        final String? id = match['id']?.toString();

        if (id != null && id.isNotEmpty) {
          // --- FIX: Handle lastUpdated safely (Int or String) ---
          final lastUpdated = match['lastUpdated'] is String
              ? int.tryParse(match['lastUpdated'] as String) ?? 0
              : (match['lastUpdated'] as num?)?.toInt() ?? 0;

          if (!mostRecentMatches.containsKey(id) ||
              ((mostRecentMatches[id]!['lastUpdated'] as num?)?.toInt() ?? 0) <
                  lastUpdated) {
            mostRecentMatches[id] = match;
          }
        }
      }

      _savedMatches = mostRecentMatches.values.toList();

      // Sort descending by date
      _savedMatches.sort((a, b) {
        final lastUpdatedA = (a['lastUpdated'] as num?)?.toInt() ?? 0;
        final lastUpdatedB = (b['lastUpdated'] as num?)?.toInt() ?? 0;
        return lastUpdatedB.compareTo(lastUpdatedA);
      });

    } catch (e, stack) {
      print('Error loading saved matches: $e');
      print(stack);
      _savedMatches = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMatch(String matchId) async {
    try {
      await DatabaseService().deleteMatch(matchId);
      _loadSavedMatches();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete match: $e')),
        );
      }
    }
  }

  // --- Export/Import Logic ---
  Future<void> _shareMatch(String matchId) async {
    try {
      // Find match safely using string comparison
      final match = _savedMatches.firstWhere((m) => m['id'].toString() == matchId);

      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      Map<String, dynamic> matchDetails = {};
      Map<String, dynamic> innings1Data = {};
      Map<String, dynamic> innings2Data = {};

      try {
        matchDetails = jsonDecode(match['matchDetails'] as String? ?? '{}') as Map<String, dynamic>;
      } catch (e) { matchDetails = {}; }

      try {
        innings1Data = jsonDecode(match['innings1Data'] as String? ?? '{}') as Map<String, dynamic>;
      } catch (e) { innings1Data = {}; }

      try {
        final innings2String = match['innings2Data'] as String?;
        if (innings2String != null && innings2String.isNotEmpty && innings2String != 'null') {
          innings2Data = jsonDecode(innings2String) as Map<String, dynamic>;
        }
      } catch (e) { innings2Data = {}; }

      final jsonData = {
        'matchId': matchId,
        'matchDetails': matchDetails,
        'innings1Data': innings1Data,
        'innings2Data': innings2Data,
        'isComplete': match['isComplete'] ?? 0,
        'lastUpdated': match['lastUpdated'],
        'notes': match['notes'],
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
      };

      final directory = await getExternalStorageDirectory();
      // Navigate up to reach standard Download folder (Android specific logic)
      final downloadsPath = Directory('${directory!.parent.parent.parent.parent.path}/Download');

      if (!await downloadsPath.exists()) {
        await downloadsPath.create(recursive: true);
      }

      final team1 = matchDetails['team1Name'] ?? 'Team1';
      final team2 = matchDetails['team2Name'] ?? 'Team2';
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final fileName = '${team1}_vs_${team2}_$date.json';
      final file = File('${downloadsPath.path}/$fileName');

      await file.writeAsString(jsonEncode(jsonData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Match exported to Downloads/$fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export match: $e')),
        );
      }
    }
  }

  Future<void> _uploadJsonFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

        final newMatchId = await DatabaseService().importMatchFromJson(jsonData);

        if (newMatchId != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Match imported successfully')),
            );
          }
          await _loadSavedMatches();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid match file format')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import match: $e')),
        );
      }
    }
  }

  void _onScorecardUpdated() {
    if (mounted) {
      _loadSavedMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _darkPrimary,
        elevation: 0,
        title: const Text(
          'Saved Matches',
          style: TextStyle(
            color: _whiteText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _yellowAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadJsonFile,
            tooltip: 'Upload Match JSON',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedMatches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _yellowAccent))
          : _savedMatches.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket_outlined, size: 60, color: _textSecondary.withOpacity(0.3)),
            const SizedBox(height: 10),
            Text(
              'No saved matches found.',
              style: TextStyle(fontSize: 16, color: _textSecondary.withOpacity(0.5)),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _savedMatches.length,
        itemBuilder: (context, index) {
          final match = _savedMatches[index];
          // Safe ID extraction
          final String? matchId = match['id']?.toString();

          if (matchId == null) return const SizedBox.shrink();

          // --- Logic for Names and Scores ---
          Map<String, dynamic> matchDetails = {};
          Map<String, dynamic> innings1Data = {};
          Map<String, dynamic> innings2Data = {};

          try {
            matchDetails = jsonDecode(match['matchDetails'] as String? ?? '{}') as Map<String, dynamic>;
          } catch (e) { matchDetails = {}; }

          try {
            innings1Data = jsonDecode(match['innings1Data'] as String? ?? '{}') as Map<String, dynamic>;
          } catch (e) { innings1Data = {}; }

          try {
            final innings2String = match['innings2Data'] as String?;
            if (innings2String != null && innings2String.isNotEmpty && innings2String != 'null') {
              innings2Data = jsonDecode(innings2String) as Map<String, dynamic>;
            }
          } catch (e) { innings2Data = {}; }

          final team1Name = matchDetails['team1Name'] as String? ?? 'Team 1';
          final team2Name = matchDetails['team2Name'] as String? ?? 'Team 2';
          final currentInnings = matchDetails['currentInnings'] ?? 1;

          // Safe Timestamp Parsing
          final lastUpdatedVal = match['lastUpdated'] is String
              ? int.tryParse(match['lastUpdated']) ?? 0
              : (match['lastUpdated'] as num?)?.toInt() ?? 0;
          final lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedVal);

          int totalRuns;
          int totalWickets;
          String scoreText;

          if (currentInnings == 2 && innings2Data.isNotEmpty) {
            totalRuns = innings2Data['totalRuns'] ?? 0;
            totalWickets = innings2Data['totalWickets'] ?? 0;
            scoreText = '$totalRuns/$totalWickets';
          } else {
            totalRuns = innings1Data['totalRuns'] ?? 0;
            totalWickets = innings1Data['totalWickets'] ?? 0;
            scoreText = '$totalRuns/$totalWickets';
          }
          String inningsLabel = currentInnings == 2 ? "(2nd Inn)" : "(1st Inn)";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _darkPrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                try {
                  ScorecardLogic? scorecardInstance;
                  final matchState = await DatabaseService().getMatchState(matchId);
                  if (matchState != null) {
                    try {
                      scorecardInstance = ScorecardLogic.fromDatabaseJson(
                        matchState,
                        navigatorKey: MyApp.navigatorKey,
                      );
                      await scorecardInstance.resumeMatchState();
                    } catch (e) {
                      print("Error reconstructing logic: $e");
                      scorecardInstance = ScorecardLogic(navigatorKey: MyApp.navigatorKey);
                    }
                  }

                  Map<String, dynamic> scoringMatchDetails = Map<String, dynamic>.from(matchDetails);
                  scoringMatchDetails['matchId'] = matchId;

                  var firstBatting = matchDetails['firstInningBattingTeamName'] ?? matchDetails['firstInningBattingTeam'];
                  var targetVal = matchDetails['target'] ?? matchDetails['targetToChase'];
                  scoringMatchDetails['firstInningBattingTeam'] = firstBatting ?? team1Name;
                  scoringMatchDetails['firstInningBattingTeamName'] = firstBatting ?? team1Name;
                  scoringMatchDetails['targetToChase'] = targetVal ?? 0;
                  scoringMatchDetails['target'] = targetVal ?? 0;

                  if (mounted) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CricketScoringScreen(
                          matchDetails: scoringMatchDetails,
                          matchId: null,
                          scorecardLogicInstance: scorecardInstance,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadSavedMatches();
                    }
                  }
                } catch (e) {
                  print('Error navigating: $e');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$team1Name vs $team2Name',
                            style: const TextStyle(color: _whiteText, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _textSecondary),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Score and Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              scoreText,
                              style: const TextStyle(color: _yellowAccent, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              inningsLabel,
                              style: const TextStyle(color: _textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(lastUpdated),
                          style: const TextStyle(color: _textSecondary, fontSize: 12),
                        ),
                      ],
                    ),

                    Divider(color: Colors.white.withOpacity(0.1), height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(Icons.share, "", () => _shareMatch(matchId)),
                        _buildActionButton(Icons.summarize, "", () async {
                          // Summary Logic
                          Map<String, dynamic> summaryMatchDetails = {};
                          Map<String, dynamic> summaryInnings1 = {};
                          Map<String, dynamic> summaryInnings2 = {};

                          try {
                            summaryMatchDetails = jsonDecode(match['matchDetails'] ?? '{}');
                          } catch (e) { print(e); }

                          try {
                            summaryInnings1 = jsonDecode(match['innings1Data'] ?? '{}');
                          } catch (e) { print(e); }

                          try {
                            if (match['innings2Data'] != null && match['innings2Data'] != 'null') {
                              summaryInnings2 = jsonDecode(match['innings2Data']);
                            }
                          } catch (e) { print(e); }

                          Navigator.pushNamed(
                            context,
                            '/full_match_summary',
                            arguments: {
                              'match': {
                                'matchDetails': summaryMatchDetails,
                                'innings1Data': summaryInnings1,
                                'innings2Data': summaryInnings2,
                              },
                            },
                          );
                        }),
                        _buildActionButton(Icons.delete_outline, "Delete", () => _deleteMatch(matchId), isDestructive: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDestructive ? Colors.redAccent.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDestructive ? Colors.redAccent : _yellowAccent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.redAccent : _whiteText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}