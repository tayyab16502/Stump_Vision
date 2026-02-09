import 'package:flutter/material.dart';
import 'package:stump_vision/score_book/scoring/scorecard_logic.dart';
import 'package:stump_vision/score_book/scoring/match_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/batting_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/overs_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/graph_summary.dart';

// --- DARK & YELLOW THEME PALETTE ---
const Color _darkPrimary = Color(0xFF333333); // Card & AppBar Background
const Color _yellowAccent = Color(0xFFFCFB04); // Highlights
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text
const Color _highlightGreen = Color(0xFF10B981); // Good Economy
const Color _highlightRed = Color(0xFFEF4444);   // Expensive

class BowlingSummaryScreen extends StatefulWidget {
  final ScorecardLogic logic;
  final String selectedInning;
  final Map<String, dynamic> matchDetails;

  const BowlingSummaryScreen({
    super.key,
    required this.logic,
    required this.selectedInning,
    required this.matchDetails,
  });

  @override
  State<BowlingSummaryScreen> createState() => _BowlingSummaryScreenState();
}

class _BowlingSummaryScreenState extends State<BowlingSummaryScreen> {
  final int _selectedIndex = 3;
  // Initialize with a default to avoid LateInitializationError during reload
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
      case 3: // Current
        break;
      case 4:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OverSummaryScreen(logic: logic, selectedInning: currentActiveInning, matchDetails: details)));
        break;
      case 5:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GraphSummaryScreen(logic: logic, matchDetails: details, selectedInning: currentActiveInning)));
        break;
    }
  }

  // --- DARK INNING SELECTOR ---
  Widget _buildInningSelector(List<String> options) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      decoration: BoxDecoration(
        color: _darkPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _yellowAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentViewInning,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _yellowAccent),
          dropdownColor: _darkPrimary,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(color: _whiteText, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
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
                  Icon(Icons.sports_baseball, size: 18, color: value == _currentViewInning ? _yellowAccent : _textSecondary),
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

  // --- DARK HEADER ---
  Widget _buildBowlerHeaderRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('BOWLER', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
          Expanded(flex: 1, child: Text('O', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('M', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('E', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // --- DARK BOWLER CARD ---
  Widget _buildBowlerRow(Bowler bowler) {
    // Economy Color Logic (Green for good, Red for expensive, Grey for normal)
    Color ecoColor = _textSecondary;
    if (bowler.economy < 6.0 && bowler.overs > 0) ecoColor = _highlightGreen;
    if (bowler.economy > 10.0) ecoColor = _highlightRed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _darkPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        child: Row(
          children: [
            // Name
            Expanded(
              flex: 3,
              child: Text(
                bowler.name,
                style: const TextStyle(color: _whiteText, fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Stats
            _statItem(bowler.overs.toStringAsFixed(1), 1, color: _whiteText),
            _statItem('${bowler.maidens}', 1, color: _textSecondary),
            _statItem('${bowler.runsGiven}', 1, color: _whiteText),
            _statItem('${bowler.wickets}', 1, color: _yellowAccent, isBold: true), // Wickets Highlighted

            // Economy (Centered & 1 Decimal)
            Expanded(
              flex: 1,
              child: Text(
                bowler.economy.toStringAsFixed(1), // 1 Decimal
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ecoColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String text, double flex, {bool isBold = false, Color color = _textSecondary}) {
    return Expanded(
      flex: flex.toInt(),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inning Selection Logic
    int selectedInningNumber = int.tryParse(_currentViewInning.split(' ')[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    List<Bowler> bowlersToDisplay = widget.logic.getBowlersForInnings(selectedInningNumber);
    bowlersToDisplay = bowlersToDisplay.where((bowler) => bowler.ballsBowled > 0).toList();

    // Dropdown Options Logic
    List<String> inningOptions = ['1st Inning'];
    if (widget.logic.currentInnings == 2 || widget.matchDetails['startFirstInning'] == false) {
      inningOptions.add('2nd Inning');
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _darkPrimary,
        elevation: 0,
        title: const Text('Bowling Summary', style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _yellowAccent),
      ),
      body: Column(
        children: [
          // 1. Inning Selector
          _buildInningSelector(inningOptions),

          // 2. Header
          _buildBowlerHeaderRow(),

          // 3. List
          Expanded(
            child: bowlersToDisplay.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_baseball_outlined, size: 50, color: _textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  Text(
                    'No bowling data available for $_currentViewInning.',
                    style: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 14),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: bowlersToDisplay.length,
              itemBuilder: (context, index) {
                return _buildBowlerRow(bowlersToDisplay[index]);
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