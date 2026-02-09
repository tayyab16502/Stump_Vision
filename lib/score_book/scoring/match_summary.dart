import 'package:flutter/material.dart';
import 'package:stump_vision/score_book/scoring/scorecard_logic.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/batting_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/bowling_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/overs_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/graph_summary.dart';

// --- THEME COLORS (Matching Scoring Screen) ---
const Color _darkPrimary = Color(0xFF333333); // Card & AppBar Background
const Color _yellowAccent = Color(0xFFFCFB04); // Highlights & Score
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text for labels
const Color _liveRed = Color(0xFFFF4444);       // Live Badge

class MatchSummaryScreen extends StatefulWidget {
  final ScorecardLogic logic;
  final Map<String, dynamic> matchDetails;

  const MatchSummaryScreen({super.key, required this.logic, required this.matchDetails});

  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen> {
  // Bottom Nav Bar Index = 1 (Match Summary)
  final int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    widget.logic.addUpdateListener(_onLogicUpdated);
  }

  @override
  void dispose() {
    widget.logic.removeUpdateListener(_onLogicUpdated);
    super.dispose();
  }

  void _onLogicUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  // --- HELPER FUNCTION: Calculate Accurate CRR ---
  // Formula: (Runs / Total Balls) * 6
  // Input Overs example: 4.2 (4 overs, 2 balls) -> 26 balls
  double _calculateCRR(int runs, double overs) {
    int completeOvers = overs.floor(); // e.g., 4
    // Handling floating point precision to get ball count (e.g., 0.2)
    int balls = ((overs - completeOvers) * 10).round();

    int totalBalls = (completeOvers * 6) + balls;

    if (totalBalls == 0) return 0.0;

    return (runs / totalBalls) * 6;
  }

  // --- NAVIGATION HANDLER ---
  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    final inning = widget.logic.currentInnings == 1 ? '1st Inning' : '2nd Inning';

    switch (index) {
      case 0: // Scoring
        Navigator.pop(context);
        break;
      case 1: // Match Summary (Current)
        break;
      case 2: // Batting Summary
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BattingSummaryScreen(logic: widget.logic, selectedInning: inning, matchDetails: widget.matchDetails)));
        break;
      case 3: // Bowling Summary
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BowlingSummaryScreen(logic: widget.logic, selectedInning: inning, matchDetails: widget.matchDetails)));
        break;
      case 4: // Overs Summary
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OverSummaryScreen(logic: widget.logic, selectedInning: inning, matchDetails: widget.matchDetails)));
        break;
      case 5: // Graph Summary
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GraphSummaryScreen(logic: widget.logic, matchDetails: widget.matchDetails, selectedInning: inning)));
        break;
    }
  }

  // --- SEXY CARD BUILDER ---
  Widget _buildInningCard({
    required String title, // "1st Innings"
    required String teamName,
    required int runs,
    required int wickets,
    required String overs,
    required double crr,
    double? rrr,
    int? target,
    bool isCurrent = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: _darkPrimary, // Card Background
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: _yellowAccent.withOpacity(0.6), width: 1.5) // Yellow Glow for Active Inning
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Label + Live Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _liveRed.withOpacity(0.2),
                      border: Border.all(color: _liveRed),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(color: _liveRed, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Team Name
            Text(
              teamName,
              style: const TextStyle(
                color: _whiteText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // MAIN SCORE (Yellow)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$runs/$wickets',
                  style: const TextStyle(
                    color: _yellowAccent, // Hero Color
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    '($overs Ov)',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Divider
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            const SizedBox(height: 16),

            // Footer Stats (Rates & Target)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('CRR', crr.toStringAsFixed(2)),
                if (rrr != null && rrr > 0)
                  _buildStatItem('RRR', rrr.toStringAsFixed(2), isHighlight: true),
                if (target != null && target > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TARGET',
                        style: TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$target',
                        style: const TextStyle(color: _whiteText, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              color: isHighlight ? _yellowAccent : _whiteText,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- DATA EXTRACTION ---
    final logic = widget.logic;
    final matchDetails = widget.matchDetails;

    // Team Names
    String battingTeam1 = logic.firstInningBattingTeamName ?? logic.team1Name;
    String battingTeam2 = (battingTeam1 == logic.team1Name) ? logic.team2Name : logic.team1Name;

    // -- 1st Inning Data --
    int runs1 = 0;
    int wickets1 = 0;
    String overs1Str = "0.0";
    double crr1 = 0.0;

    var innings1Data = logic.getInningsData(1);

    // Logic for 1st Inning values
    if (innings1Data != null) {
      // Inning Completed / Saved
      runs1 = innings1Data.totalRuns;
      wickets1 = innings1Data.totalWickets;
      overs1Str = innings1Data.totalOvers.toStringAsFixed(1);
      // FIXED: Calculate CRR using helper instead of bad math
      crr1 = _calculateCRR(runs1, innings1Data.totalOvers);
    } else if (logic.currentInnings == 1) {
      // Live Inning
      runs1 = logic.totalRuns;
      wickets1 = logic.totalWickets;
      overs1Str = logic.currentOvers.toStringAsFixed(1);
      // Use Live calculation
      crr1 = _calculateCRR(runs1, logic.currentOvers);
    } else {
      // Default / Historical
      runs1 = logic.firstInningScore ?? matchDetails['firstInningScore'] ?? 0;
      wickets1 = logic.firstInningOuts ?? matchDetails['firstInningOuts'] ?? 0;
      int ov = logic.totalMatchOvers > 0 ? logic.totalMatchOvers : (matchDetails['overs'] ?? 0);
      overs1Str = "$ov.0";
      // Calculate based on match details if available
      crr1 = _calculateCRR(runs1, ov.toDouble());
    }

    // -- 2nd Inning Data --
    bool show2ndInning = false;
    int runs2 = 0;
    int wickets2 = 0;
    String overs2Str = "0.0";
    double crr2 = 0.0;
    double rrr2 = 0.0;
    int target = logic.target > 0 ? logic.target : (matchDetails['targetToChase'] ?? 0);

    var innings2Data = logic.getInningsData(2);

    // Logic for 2nd Inning values
    if (innings2Data != null) {
      // Inning Completed / Saved
      show2ndInning = true;
      runs2 = innings2Data.totalRuns;
      wickets2 = innings2Data.totalWickets;
      overs2Str = innings2Data.totalOvers.toStringAsFixed(1);
      // FIXED: removed "crr2 = 0.0" and added calculation
      crr2 = _calculateCRR(runs2, innings2Data.totalOvers);
    } else if (logic.currentInnings == 2) {
      // Live Inning
      show2ndInning = true;
      runs2 = logic.totalRuns;
      wickets2 = logic.totalWickets;
      overs2Str = logic.currentOvers.toStringAsFixed(1);
      crr2 = _calculateCRR(runs2, logic.currentOvers); // Use live calc
      rrr2 = logic.requiredRunRate;
    }

    return Scaffold(
      backgroundColor: _background, // Dark Theme Background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _darkPrimary,
        elevation: 0,
        title: const Text(
          'Match Summary',
          style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Match Result Banner
            if (logic.isMatchComplete)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))]
                ),
                child: const Text(
                  "MATCH COMPLETED",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),

            // --- 1st Inning Card ---
            _buildInningCard(
              title: "1st Innings",
              teamName: battingTeam1,
              runs: runs1,
              wickets: wickets1,
              overs: overs1Str,
              crr: crr1,
              isCurrent: logic.currentInnings == 1,
            ),

            // --- 2nd Inning Card (Only if started) ---
            if (show2ndInning)
              _buildInningCard(
                title: "2nd Innings",
                teamName: battingTeam2,
                runs: runs2,
                wickets: wickets2,
                overs: overs2Str,
                crr: crr2,
                rrr: rrr2,
                target: target,
                isCurrent: logic.currentInnings == 2,
              ),

            // Placeholder message
            if (!show2ndInning)
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Icon(Icons.sports_cricket, size: 40, color: _textSecondary.withOpacity(0.3)),
                    const SizedBox(height: 10),
                    const Text(
                      "2nd Innings yet to start",
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            backgroundColor: _darkPrimary,
            selectedItemColor: _yellowAccent,
            unselectedItemColor: _textSecondary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
            iconSize: 24,
            selectedIconTheme: const IconThemeData(size: 28),
            onTap: _onNavItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Scoring'),
              BottomNavigationBarItem(icon: Icon(Icons.summarize), label: 'Match'),
              BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: 'Batting'),
              BottomNavigationBarItem(icon: Icon(Icons.sports_baseball), label: 'Bowling'),
              BottomNavigationBarItem(icon: Icon(Icons.format_list_numbered), label: 'Overs'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Graphs'),
            ],
          ),
        ),
      ),
    );
  }
}