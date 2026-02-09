import 'package:flutter/material.dart';
import 'package:stump_vision/score_book/scoring/scorecard_logic.dart';
import 'package:stump_vision/score_book/scoring/match_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/bowling_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/overs_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/graph_summary.dart';

// --- DARK & YELLOW THEME PALETTE ---
const Color _darkPrimary = Color(0xFF333333); // Card & AppBar Background
const Color _yellowAccent = Color(0xFFFCFB04); // Highlights
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text
const Color _highlightGreen = Color(0xFF10B981); // Not Out
const Color _highlightRed = Color(0xFFEF4444);   // Out

class BattingSummaryScreen extends StatefulWidget {
  final ScorecardLogic logic;
  final String selectedInning;
  final Map<String, dynamic> matchDetails;

  const BattingSummaryScreen({
    super.key,
    required this.logic,
    required this.selectedInning,
    required this.matchDetails,
  });

  @override
  State<BattingSummaryScreen> createState() => _BattingSummaryScreenState();
}

class _BattingSummaryScreenState extends State<BattingSummaryScreen> {
  final int _selectedIndex = 2;
  late String _currentViewInning;

  @override
  void initState() {
    super.initState();
    _currentViewInning = widget.selectedInning;
    widget.logic.addUpdateListener(_updateUI);
  }

  @override
  void dispose() {
    widget.logic.removeUpdateListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
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
      case 2: // Current
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BowlingSummaryScreen(logic: logic, selectedInning: currentActiveInning, matchDetails: details)));
        break;
      case 4:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OverSummaryScreen(logic: logic, selectedInning: currentActiveInning, matchDetails: details)));
        break;
      case 5:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GraphSummaryScreen(logic: logic, matchDetails: details, selectedInning: currentActiveInning)));
        break;
    }
  }

  // --- UPDATED: DARK INNING SELECTOR ---
  Widget _buildInningSelector(List<String> options) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      decoration: BoxDecoration(
        color: _darkPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _yellowAccent.withOpacity(0.3)), // Subtle Yellow Border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentViewInning,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _yellowAccent),
          dropdownColor: _darkPrimary,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            color: _whiteText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Roboto',
          ),
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
                  Icon(Icons.sports_cricket, size: 18, color: value == _currentViewInning ? _yellowAccent : _textSecondary),
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

  // --- HEADER (Dark Theme) ---
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // Slightly darker strip
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('BATSMAN', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
          _headerText('R', 1),
          _headerText('B', 1),
          _headerText('4s', 1),
          _headerText('6s', 1),
          _headerText('SR', 1.5),
        ],
      ),
    );
  }

  Widget _headerText(String text, double flex) {
    return Expanded(
      flex: flex.toInt(),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // --- BATSMAN CARD (Dark Theme) ---
  Widget _buildBatsmanRow(Batsman batsman) {
    final bool isNotOut = !batsman.isOut;
    final Color statusColor = isNotOut ? _highlightGreen : _highlightRed;
    final bool isStriker = batsman.isOnStrike && widget.logic.currentInnings == (widget.selectedInning == '1st Inning' ? 1 : 2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _darkPrimary, // Dark Card
        borderRadius: BorderRadius.circular(12),
        border: isStriker ? Border.all(color: _yellowAccent.withOpacity(0.3)) : null, // Highlight active striker
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status Strip
              Container(
                width: 4,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Name and Stats
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              '${batsman.name}${batsman.isOnStrike ? '*' : ''}',
                              style: TextStyle(
                                color: batsman.isOnStrike ? _yellowAccent : _whiteText,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Stats
                          _statItem('${batsman.runs}', 1, isBold: true, color: _whiteText),
                          _statItem('${batsman.balls}', 1),
                          _statItem('${batsman.fours}', 1),
                          _statItem('${batsman.sixes}', 1),
                          _statItem(batsman.strikeRate.toStringAsFixed(1), 1.5),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Dismissal Text
                      Text(
                        _getDismissalText(batsman),
                        style: TextStyle(
                          color: isNotOut ? _highlightGreen : _textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  String _getDismissalText(Batsman batsman) {
    if (!batsman.isOut) return 'Not Out';
    return batsman.dismissalDetails ?? batsman.dismissalMethod ?? 'Out';
  }

  @override
  Widget build(BuildContext context) {
    int inningsNumber = _currentViewInning == '1st Inning' ? 1 : 2;
    List<Batsman> batsmenToDisplay = widget.logic.getBatsmenForInnings(inningsNumber);

    batsmenToDisplay = batsmenToDisplay.where((batsman) {
      bool isCurrentBatsman = inningsNumber == widget.logic.currentInnings &&
          (batsman.name == widget.logic.striker.name || batsman.name == widget.logic.nonStriker.name);
      return isCurrentBatsman || batsman.runs > 0 || batsman.balls > 0 || batsman.isOut;
    }).toList();

    List<String> inningOptions = ['1st Inning'];
    if (widget.logic.currentInnings == 2 || widget.matchDetails['startFirstInning'] == false) {
      inningOptions.add('2nd Inning');
    }

    return Scaffold(
      backgroundColor: _background, // Dark Background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _darkPrimary,
        elevation: 0,
        title: const Text('Batting Summary', style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _yellowAccent),
      ),
      body: Column(
        children: [
          // 1. Selector
          _buildInningSelector(inningOptions),

          // 2. Header
          _buildHeader(),

          // 3. List
          Expanded(
            child: batsmenToDisplay.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_cricket_outlined, size: 50, color: _textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  Text(
                    'No batting data yet',
                    style: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 14),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: batsmenToDisplay.length,
              itemBuilder: (context, index) {
                return _buildBatsmanRow(batsmenToDisplay[index]);
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