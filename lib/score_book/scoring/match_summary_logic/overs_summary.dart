import 'package:flutter/material.dart';
import 'package:stump_vision/score_book/scoring/scorecard_logic.dart';
import 'package:stump_vision/score_book/scoring/match_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/batting_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/bowling_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/graph_summary.dart';

// --- PREMIUM DARK THEME PALETTE ---
const Color _bgDark = Color(0xFF121212);       // Ultra Dark Background
const Color _cardSurface = Color(0xFF1E1E1E);  // Matte Grey Card
const Color _yellowNeon = Color(0xFFF4FF00);   // High Viz Yellow
const Color _textWhite = Colors.white;
const Color _textGrey = Color(0xFFAAAAAA);

// Ball Colors
const Color _wicketRed = Color(0xFFFF4C4C);
const Color _boundaryGreen = Color(0xFF00E676);
const Color _sixPurple = Color(0xFFD500F9);
const Color _extraOrange = Color(0xFFFF9100);
const Color _dotGrey = Color(0xFF424242);

class OverSummaryScreen extends StatefulWidget {
  final ScorecardLogic logic;
  final String selectedInning;
  final Map<String, dynamic> matchDetails;

  const OverSummaryScreen({
    super.key,
    required this.logic,
    required this.selectedInning,
    required this.matchDetails,
  });

  @override
  State<OverSummaryScreen> createState() => _OverSummaryScreenState();
}

class _OverSummaryScreenState extends State<OverSummaryScreen> {
  final int _selectedIndex = 4;
  late String _currentViewInning;

  @override
  void initState() {
    super.initState();
    _currentViewInning = widget.selectedInning;
    widget.logic.addUpdateListener(_onScorecardLogicUpdate);
  }

  @override
  void dispose() {
    widget.logic.removeUpdateListener(_onScorecardLogicUpdate);
    super.dispose();
  }

  void _onScorecardLogicUpdate() {
    if (mounted) setState(() {});
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    final logic = widget.logic;
    final details = widget.matchDetails;
    final currentActiveInning = widget.logic.currentInnings == 1 ? '1st Inning' : '2nd Inning';

    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MatchSummaryScreen(logic: logic, matchDetails: details)));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BattingSummaryScreen(logic: logic, selectedInning: currentActiveInning, matchDetails: details)));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BowlingSummaryScreen(logic: logic, selectedInning: currentActiveInning, matchDetails: details)));
        break;
      case 4: // Current
        break;
      case 5:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GraphSummaryScreen(logic: logic, matchDetails: details, selectedInning: currentActiveInning)));
        break;
    }
  }

  // --- SEXY INNING SELECTOR ---
  Widget _buildInningSelector(List<String> options) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentViewInning,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _yellowNeon),
          dropdownColor: _cardSurface,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(color: _textWhite, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _currentViewInning = newValue;
              });
            }
          },
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(Icons.format_list_numbered, size: 18, color: value == _currentViewInning ? _yellowNeon : _textGrey),
                  const SizedBox(width: 10),
                  Text(value),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- ELEGANT BALL WIDGET (Fixed Overflow) ---
  Widget _buildBallButton(BallOutcome ball) {
    Color bgColor;
    Color textColor = _textWhite;
    bool isSpecial = false;

    if (ball.isWicket) {
      bgColor = _wicketRed;
      isSpecial = true;
    } else if (ball.extraTypes != null && ball.extraTypes!.isNotEmpty) {
      bgColor = _extraOrange;
      textColor = Colors.black;
    } else if (ball.runs == 4) {
      bgColor = _boundaryGreen;
      textColor = Colors.black;
      isSpecial = true;
    } else if (ball.runs == 6) {
      bgColor = _sixPurple;
      isSpecial = true;
    } else if (ball.runs == 0) {
      bgColor = _dotGrey;
      textColor = Colors.white54;
    } else {
      bgColor = Colors.black26; // Normal runs (1, 2, 3)
      textColor = _yellowNeon;
    }

    return Container(
      margin: const EdgeInsets.only(right: 6.0),
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isSpecial ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
        boxShadow: isSpecial ? [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 6)] : null,
      ),
      // --- FIX: FittedBox used here ---
      child: Padding(
        padding: const EdgeInsets.all(3.0), // Padding to prevent touching edges
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            ball.display,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --- SEXY OVER CARD ---
  Widget _buildOverCard(OverSummary overSummary) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(20),
        // Subtle gradient border effect via Shadow/Border
        border: Border(left: BorderSide(color: _yellowNeon.withOpacity(0.5), width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Over Number & Bowler
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'OVER ${overSummary.overNumber}',
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: _textGrey, shape: BoxShape.circle)
                    ),
                    const SizedBox(width: 10),
                    Text(
                      overSummary.bowlerName.toUpperCase(),
                      style: const TextStyle(
                        color: _textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Total Runs in Over
                Text(
                  '${overSummary.runsScoredInOver} RUNS',
                  style: const TextStyle(
                    color: _yellowNeon,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.white.withOpacity(0.05), height: 1),

          // Bottom Row: Balls Scroll
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: overSummary.ballDetails.map((ball) => _buildBallButton(ball)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inning Selection Logic
    int selectedInningNumber = int.tryParse(_currentViewInning.split(' ')[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // 1. Get Completed Overs (Copy list to avoid reference issues)
    List<OverSummary> oversToDisplay = List.from(widget.logic.getCompletedOversForInnings(selectedInningNumber));

    // 2. Logic to show LIVE CURRENT OVER (Without duplication)
    if (widget.logic.currentInnings == selectedInningNumber) {
      int currentOverNum = (widget.logic.currentOvers.toInt() + 1);

      // Check if this over is ALREADY in the completed list
      bool isOverAlreadyCompleted = oversToDisplay.any((o) => o.overNumber == currentOverNum);

      if (!isOverAlreadyCompleted && widget.logic.thisOverBalls.isNotEmpty) {
        int runsInCurrent = 0;
        int wktsInCurrent = 0;
        for(var ball in widget.logic.thisOverBalls) {
          runsInCurrent += (ball.runs + ball.extraRuns);
          if(ball.isWicket) wktsInCurrent++;
        }

        oversToDisplay.add(OverSummary(
          overNumber: currentOverNum,
          bowlerName: widget.logic.currentBowler.name,
          runsScoredInOver: runsInCurrent,
          wicketsTakenInOver: wktsInCurrent,
          ballDetails: widget.logic.thisOverBalls,
        ));
      }
    }

    // Dropdown Options
    List<String> inningOptions = ['1st Inning'];
    if (widget.logic.currentInnings == 2 || widget.matchDetails['startFirstInning'] == false) {
      inningOptions.add('2nd Inning');
    }

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _cardSurface,
        elevation: 0,
        title: const Text('Over Summary', style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _yellowNeon),
      ),
      body: Column(
        children: [
          // 1. Selector
          _buildInningSelector(inningOptions),

          // 2. List
          Expanded(
            child: oversToDisplay.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_outlined, size: 60, color: _textGrey.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  Text(
                    'No overs bowled yet in $_currentViewInning.',
                    style: TextStyle(color: _textGrey.withOpacity(0.5), fontSize: 14),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20, top: 4),
              itemCount: oversToDisplay.length,
              itemBuilder: (context, index) {
                return _buildOverCard(oversToDisplay[index]);
              },
            ),
          ),
        ],
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
              BoxShadow(color: Colors.black, blurRadius: 15, offset: Offset(0, -2))
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            backgroundColor: _cardSurface,
            selectedItemColor: _yellowNeon,
            unselectedItemColor: _textGrey,
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