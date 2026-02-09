import 'package:flutter/material.dart';
import 'package:stump_vision/score_book/scoring/scorecard_logic.dart';
import 'package:stump_vision/score_book/scoring/match_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/batting_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/bowling_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/overs_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/graph_summary.dart';
import 'package:stump_vision/main.dart';
// import 'package:stump_vision/score_book/database_service.dart'; // Uncomment if needed

// --- THEME COLORS CONSTANTS (Dark & Yellow) ---
const Color _darkPrimary = Color(0xFF333333); // Card & AppBar Background
const Color _yellowAccent = Color(0xFFFCFB04); // Buttons & Highlights
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text for labels
const Color _blackText = Color(0xFF1F1F1F);     // Text on Yellow buttons

class CricketScoringScreen extends StatefulWidget {
  final Map<String, dynamic> matchDetails;
  final String? matchId;
  final ScorecardLogic? scorecardLogicInstance;

  const CricketScoringScreen({
    super.key,
    required this.matchDetails,
    this.matchId,
    this.scorecardLogicInstance,
  });

  @override
  State<CricketScoringScreen> createState() => _CricketScoringScreenState();
}

class _CricketScoringScreenState extends State<CricketScoringScreen> {
  late ScorecardLogic _scorecardLogic;
  bool _isLoading = true;
  final TextEditingController _batsmanNameController = TextEditingController();
  final TextEditingController _bowlerNameController = TextEditingController();
  final TextEditingController _runsController = TextEditingController();
  final TextEditingController _fielderNameController = TextEditingController();
  List<String> extraTypes = [];
  int checkedCount = 0;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeScorecardLogic();
  }

  // --- LOGIC INITIALIZATION ---
  Future<void> _initializeScorecardLogic() async {
    try {
      if (widget.scorecardLogicInstance != null) {
        _scorecardLogic = widget.scorecardLogicInstance!;
      } else if (widget.matchId != null) {
        try {
          _scorecardLogic = await ScorecardLogic.loadMatchFromDatabase(
            widget.matchId!,
            navigatorKey: MyApp.navigatorKey,
          );
        } catch (e) {
          print('CricketScoringScreen: Failed to load from database: $e');
          _scorecardLogic = ScorecardLogic(navigatorKey: MyApp.navigatorKey);
          await _scorecardLogic.initializeMatchState(widget.matchDetails);
          await _scorecardLogic.saveMatchToDatabase();
        }
      } else {
        _scorecardLogic = ScorecardLogic(navigatorKey: MyApp.navigatorKey);
        await _scorecardLogic.initializeMatchState(widget.matchDetails);
        await _scorecardLogic.saveMatchToDatabase();
      }
      _scorecardLogic.currentInnings = widget.matchDetails['currentInnings'] ?? 1;
      _scorecardLogic.target = widget.matchDetails['targetToChase'] ?? 0;
      _scorecardLogic.addUpdateListener(_onScorecardUpdated);
    } catch (e) {
      print('Error initializing: $e');
      try {
        _scorecardLogic = ScorecardLogic(navigatorKey: MyApp.navigatorKey);
        await _scorecardLogic.initializeMatchState(widget.matchDetails);
        await _scorecardLogic.saveMatchToDatabase();
        _scorecardLogic.addUpdateListener(_onScorecardUpdated);
      } catch (fbError) {
        print('Fallback failed: $fbError');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onScorecardUpdated() {
    if (mounted) {
      setState(() {
        if (_scorecardLogic.isOverComplete) {
          _scorecardLogic.isOverComplete = false;
          _showNewBowlerDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    _scorecardLogic.removeUpdateListener(_onScorecardUpdated);
    _batsmanNameController.dispose();
    _bowlerNameController.dispose();
    _runsController.dispose();
    _fielderNameController.dispose();
    super.dispose();
  }

  // --- SCORING FUNCTIONS ---
  void _scoreBall({
    required int runs,
    List<String>? extraTypes,
    int extraRuns = 0,
    bool isWicket = false,
    String? wicketMethod,
    String? outBatsmanName,
    String? fielderName,
  }) async {
    await _scorecardLogic.scoreBall(
      runs: runs,
      extraTypes: extraTypes,
      extraRuns: extraRuns,
      isWicket: isWicket,
      wicketMethod: wicketMethod,
      outBatsmanName: outBatsmanName,
      fielderName: fielderName,
    );
    if (isWicket) {
      _showNewBatsmanDialog();
    }
    setState(() {
      this.extraTypes.clear();
      checkedCount = 0;
    });
  }

  String _calculateEconomy(int runsConceded, double oversDisplay) {
    if (oversDisplay <= 0) return "0.0";
    int completedOvers = oversDisplay.truncate();
    int balls = ((oversDisplay - completedOvers) * 10).round();
    double totalOversDecimal = completedOvers + (balls / 6.0);
    if (totalOversDecimal == 0) return "0.0";
    double economy = runsConceded / totalOversDecimal;
    return economy.toStringAsFixed(1);
  }

  // --- ALL DIALOGS ---
  Future<void> _showRunOutDialog(int runs, List<String>? currentExtraTypes) async {
    _runsController.text = runs.toString();
    int? confirmedRuns;
    await showDialog(
      context: _scorecardLogic.navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: _darkPrimary,
          title: const Text('Runs Scored', style: TextStyle(fontSize: 18, color: _whiteText)),
          content: TextField(
            controller: _runsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _whiteText),
            decoration: const InputDecoration(
              labelText: 'Enter Runs',
              labelStyle: TextStyle(color: _textSecondary),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textSecondary)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _yellowAccent)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel', style: TextStyle(color: _yellowAccent))),
            TextButton(
              onPressed: () {
                confirmedRuns = int.tryParse(_runsController.text) ?? 0;
                Navigator.pop(context, confirmedRuns);
              },
              child: const Text('OK', style: TextStyle(color: _yellowAccent)),
            ),
          ],
        ),
      ),
    ).then((value) async {
      if (value != null) {
        await _showWicketDetailsDialog(value, 'Run Out', currentExtraTypes);
      }
    });
  }

  Future<void> _showWicketDetailsDialog(int runs, String wicketMethod, List<String>? currentExtraTypes) async {
    String? selectedBatsmanName;
    String? fielderName;
    final currentBatsmen = _scorecardLogic.allBatsmen.where((b) => !b.isOut).toList();
    if (currentBatsmen.isEmpty) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: _darkPrimary,
          title: Text(wicketMethod == 'Run Out' ? 'Run Out Details' : 'Wicket Details', style: const TextStyle(color: _whiteText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: _darkPrimary,
                decoration: const InputDecoration(
                    labelText: 'Select Batsman Out',
                    labelStyle: TextStyle(color: _textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textSecondary))
                ),
                style: const TextStyle(color: _whiteText),
                items: currentBatsmen.map((b) => DropdownMenuItem(value: b.name, child: Text(b.name ?? 'Unknown'))).toList(),
                onChanged: (value) => selectedBatsmanName = value,
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              if (wicketMethod == 'Caught' || wicketMethod == 'Run Out' || wicketMethod == 'Stumped')
                TextField(
                  controller: _fielderNameController,
                  style: const TextStyle(color: _whiteText),
                  decoration: InputDecoration(
                    labelText: wicketMethod == 'Run Out' ? 'Fielder Name' : (wicketMethod == 'Stumped' ? 'WK Name' : 'Catcher Name'),
                    labelStyle: const TextStyle(color: _textSecondary),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _textSecondary)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _yellowAccent)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _yellowAccent))),
            TextButton(
              onPressed: () {
                fielderName = _fielderNameController.text.isNotEmpty ? _fielderNameController.text : null;
                Navigator.pop(context, {'batsman': selectedBatsmanName, 'fielder': fielderName});
              },
              child: const Text('Confirm', style: TextStyle(color: _yellowAccent)),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result != null) {
        _scoreBall(
          runs: runs,
          extraTypes: currentExtraTypes,
          isWicket: true,
          wicketMethod: wicketMethod,
          outBatsmanName: result['batsman'],
          fielderName: result['fielder'],
        );
      }
      _fielderNameController.clear();
    });
  }

  Future<void> _showNewBatsmanDialog() async {
    String? newBatsmanName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: _darkPrimary,
          title: const Text('New Batsman', style: TextStyle(color: _whiteText)),
          content: TextField(
            controller: _batsmanNameController,
            style: const TextStyle(color: _whiteText),
            decoration: const InputDecoration(
                labelText: 'Enter new batsman name',
                labelStyle: TextStyle(color: _textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textSecondary)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _yellowAccent))
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_batsmanNameController.text.isNotEmpty) {
                  Navigator.pop(context, _batsmanNameController.text);
                } else {
                  Navigator.pop(context, "New Batsman");
                }
              },
              child: const Text('Confirm', style: TextStyle(color: _yellowAccent)),
            ),
          ],
        ),
      ),
    );
    if (newBatsmanName != null) {
      _scorecardLogic.addNewBatsman(newBatsmanName);
      _batsmanNameController.clear();
    }
  }

  Future<void> _showNewBowlerDialog() async {
    String? selectedBowlerName;
    String? newBowlerName;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: _darkPrimary,
          title: const Text('End of Over', style: TextStyle(color: _whiteText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select existing or enter new bowler.', style: TextStyle(color: _textSecondary)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                dropdownColor: _darkPrimary,
                style: const TextStyle(color: _whiteText),
                decoration: const InputDecoration(
                    labelText: 'Select Bowler',
                    labelStyle: TextStyle(color: _textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textSecondary))
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('Select existing bowler')),
                  ..._scorecardLogic.allBowlers.map((b) => DropdownMenuItem<String>(value: b.name, child: Text(b.name ?? 'Unknown'))),
                ],
                onChanged: (value) => selectedBowlerName = value,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bowlerNameController,
                style: const TextStyle(color: _whiteText),
                decoration: const InputDecoration(
                    labelText: 'New Bowler Name',
                    labelStyle: TextStyle(color: _textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textSecondary)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _yellowAccent))
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                newBowlerName = _bowlerNameController.text.isNotEmpty ? _bowlerNameController.text : null;
                if (selectedBowlerName != null || newBowlerName != null) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Confirm', style: TextStyle(color: _yellowAccent)),
            ),
          ],
        ),
      ),
    );
    if (selectedBowlerName != null) {
      _scorecardLogic.addNewBowler(selectedBowlerName!);
    } else if (newBowlerName != null && newBowlerName!.isNotEmpty) {
      _scorecardLogic.addNewBowler(newBowlerName!);
    }
    _bowlerNameController.clear();
  }

  Future<void> _undoLastBall() async {
    await _scorecardLogic.undoLastBall();
    setState(() {});
  }

  Future<void> _editBatsmanName(Batsman batsman) async {
    _batsmanNameController.text = batsman.name ?? '';
    String? newName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _darkPrimary,
        title: const Text('Edit Batsman Name', style: TextStyle(color: _whiteText)),
        content: TextField(
            controller: _batsmanNameController,
            style: const TextStyle(color: _whiteText),
            decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textSecondary)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _yellowAccent))
            )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, _batsmanNameController.text), child: const Text('Save', style: TextStyle(color: _yellowAccent))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _yellowAccent))),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await _scorecardLogic.editBatsmanName(batsman, newName);
      setState(() {});
    }
  }

  Future<void> _editBowlerName(Bowler bowler) async {
    _bowlerNameController.text = bowler.name ?? '';
    String? newName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _darkPrimary,
        title: const Text('Edit Bowler Name', style: TextStyle(color: _whiteText)),
        content: TextField(
            controller: _bowlerNameController,
            style: const TextStyle(color: _whiteText),
            decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textSecondary)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _yellowAccent))
            )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, _bowlerNameController.text), child: const Text('Save', style: TextStyle(color: _yellowAccent))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _yellowAccent))),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await _scorecardLogic.editBowlerName(bowler, newName);
      setState(() {});
    }
  }

  // --- UI WIDGETS ---
  Widget _buildGradientCard({required Widget child}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _yellowAccent.withOpacity(0.1), width: 1)
      ),
      color: _darkPrimary,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
        child: child,
      ),
    );
  }

  // --- NEW: ROUND "BALL-LIKE" BUTTON ---
  Widget _buildCircularButton(String text, VoidCallback onPressed, {Color? customColor}) {
    final bool isActionBtn = customColor == null;
    final Color bgColor = customColor ?? _yellowAccent;
    final Color textColor = isActionBtn ? _blackText : _whiteText;

    return Container(
      decoration: ShapeDecoration(
        color: bgColor,
        // PERFECT CIRCLE SHAPE
        shape: const CircleBorder(),
        shadows: isActionBtn ? [
          BoxShadow(
              color: _yellowAccent.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3)
          )
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.3),
          child: Center(
            child: Text(
                text,
                style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900 // Extra Bold
                )
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: ROUND "BALL-LIKE" DROPDOWN (For the + Button) ---
  Widget _buildCircularDropdownButton<T>(String hintText, T? value, List<DropdownMenuItem<T>> items, ValueChanged<T?>? onChanged) {
    return Container(
      decoration: ShapeDecoration(
        color: _darkPrimary,
        // PERFECT CIRCLE SHAPE
        shape: CircleBorder(
          side: BorderSide(color: _yellowAccent.withOpacity(0.5), width: 2),
        ),
        shadows: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Center(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: false,
            hint: Icon(Icons.add, color: _yellowAccent, size: 28), // Show + icon as hint
            value: value,
            icon: const SizedBox.shrink(), // Hide default arrow
            dropdownColor: _darkPrimary,
            style: const TextStyle(color: _whiteText, fontSize: 16, fontWeight: FontWeight.bold),
            onChanged: onChanged,
            items: items,
          ),
        ),
      ),
    );
  }

  // --- STANDARD RECTANGULAR BUTTON (For Undo/Actions) ---
  Widget _buildStandardButton(String text, VoidCallback onPressed, {Color? customColor}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: customColor ?? _yellowAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: Text(text, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // --- STANDARD DROPDOWN (For Wicket Type) ---
  Widget _buildStandardDropdown<T>(String hintText, T? value, List<DropdownMenuItem<T>> items, ValueChanged<T?>? onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _darkPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _yellowAccent.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(hintText, style: const TextStyle(color: _textSecondary, fontSize: 14)),
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: _yellowAccent),
          dropdownColor: _darkPrimary,
          style: const TextStyle(color: _whiteText, fontSize: 14),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _buildExtraCheckbox(String type, String labelText, int defaultRuns) {
    bool isSelected = extraTypes.contains(type);
    return Column(
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: isSelected,
            onChanged: (bool? newValue) {
              setState(() {
                if (newValue == true && checkedCount < 2) {
                  if (!extraTypes.contains(type)) {
                    extraTypes.add(type);
                    checkedCount++;
                  }
                } else if (newValue == false && extraTypes.contains(type)) {
                  extraTypes.remove(type);
                  checkedCount--;
                }
                if (checkedCount > 2) {
                  extraTypes.removeLast();
                  checkedCount = 2;
                }
              });
            },
            activeColor: _yellowAccent,
            checkColor: _blackText,
            side: const BorderSide(color: _textSecondary),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Text(labelText, style: const TextStyle(color: _whiteText, fontSize: 11)),
      ],
    );
  }

  Widget _buildBatsmanHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
      child: const Row(
        children: [
          SizedBox(width: 30.0),
          Expanded(flex: 4, child: Text('Batsman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('4s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('6s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 2, child: Text('S.R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildBowlerHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('O', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary))),
          Expanded(flex: 1, child: Text('E', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildDynamicBatsmanRow(Batsman batsman) {
    final bool isStriker = batsman.isOnStrike;
    final TextStyle statStyle = TextStyle(
        fontSize: 15,
        color: isStriker ? _yellowAccent : _whiteText,
        fontWeight: isStriker ? FontWeight.bold : FontWeight.normal
    );

    return Container(
      margin: const EdgeInsets.only(top: 2.0),
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      decoration: isStriker ? BoxDecoration(color: _yellowAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)) : null,
      child: Row(
        children: [
          SizedBox(
            width: 30.0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!batsman.isOnStrike) {
                  setState(() {
                    _scorecardLogic.striker.isOnStrike = false;
                    _scorecardLogic.nonStriker.isOnStrike = true;
                    var temp = _scorecardLogic.striker;
                    _scorecardLogic.striker = _scorecardLogic.nonStriker;
                    _scorecardLogic.nonStriker = temp;
                  });
                }
              },
              child: Icon(
                isStriker ? Icons.play_arrow : Icons.radio_button_off,
                color: isStriker ? _yellowAccent : Colors.white38,
                size: 20,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () async => await _editBatsmanName(batsman),
              child: Text('${batsman.name ?? 'Unknown'}${isStriker ? '*' : ''}', style: statStyle, overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(flex: 1, child: Text((batsman.runs ?? 0).toString(), style: statStyle)),
          Expanded(flex: 1, child: Text((batsman.balls ?? 0).toString(), style: statStyle)),
          Expanded(flex: 1, child: Text((batsman.fours ?? 0).toString(), style: statStyle)),
          Expanded(flex: 1, child: Text((batsman.sixes ?? 0).toString(), style: statStyle)),
          Expanded(flex: 2, child: Text((batsman.strikeRate ?? 0.0).toStringAsFixed(1), style: statStyle, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildDynamicBowlerRow(Bowler bowler) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(bowler.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _whiteText), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 1, child: Text((bowler.overs ?? 0.0).toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _whiteText))),
          Expanded(flex: 1, child: Text((bowler.runsGiven ?? 0).toString(), style: const TextStyle(fontSize: 15, color: _whiteText))),
          Expanded(flex: 1, child: Text((bowler.maidens ?? 0).toString(), style: const TextStyle(fontSize: 15, color: _whiteText))),
          Expanded(flex: 1, child: Text((bowler.wickets ?? 0).toString(), style: const TextStyle(fontSize: 15, color: _whiteText))),
          Expanded(
            flex: 1,
            child: Text(
              _calculateEconomy(bowler.runsGiven ?? 0, bowler.overs ?? 0.0),
              style: const TextStyle(fontSize: 15, color: _whiteText),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM NAVIGATION HANDLER ---
  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    final inning = _scorecardLogic.currentInnings == 1 ? '1st Inning' : '2nd Inning';

    void navigateAndReset(Widget screen) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      ).then((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }

    switch (index) {
      case 0:
        break;
      case 1:
        navigateAndReset(MatchSummaryScreen(logic: _scorecardLogic, matchDetails: widget.matchDetails));
        break;
      case 2:
        navigateAndReset(BattingSummaryScreen(logic: _scorecardLogic, selectedInning: inning, matchDetails: widget.matchDetails));
        break;
      case 3:
        navigateAndReset(BowlingSummaryScreen(logic: _scorecardLogic, selectedInning: inning, matchDetails: widget.matchDetails));
        break;
      case 4:
        navigateAndReset(OverSummaryScreen(logic: _scorecardLogic, selectedInning: inning, matchDetails: widget.matchDetails));
        break;
      case 5:
        navigateAndReset(GraphSummaryScreen(logic: _scorecardLogic, matchDetails: widget.matchDetails, selectedInning: inning));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: _background, body: Center(child: CircularProgressIndicator(color: _yellowAccent)));

    String currentBattingTeam = _scorecardLogic.currentInnings == 1
        ? (widget.matchDetails['firstInningBattingTeam'] ?? _scorecardLogic.team1Name)
        : ((widget.matchDetails['firstInningBattingTeam'] == _scorecardLogic.team1Name) ? _scorecardLogic.team2Name : _scorecardLogic.team1Name);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _scorecardLogic.saveMatchToDatabase();
        if (context.mounted) Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _darkPrimary,
          elevation: 0,
          title: const Text('Stump Vision Score Book', style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: _yellowAccent),
        ),
        body: Container(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(4.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- TOP CARD (Scores & Rates) ---
                  _buildGradientCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 28,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text('$currentBattingTeam: ${_scorecardLogic.totalRuns}/${_scorecardLogic.totalWickets}', style: const TextStyle(color: _whiteText, fontSize: 16, fontWeight: FontWeight.bold), softWrap: false),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(_scorecardLogic.getOversDisplay(), style: const TextStyle(color: _yellowAccent, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),

                        // --- UPDATED ROW: CRR | TARGET | RRR ---
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CRR: ${_scorecardLogic.currentRunRate.toStringAsFixed(2)}', style: const TextStyle(color: _textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),

                              if (_scorecardLogic.currentInnings == 2 && _scorecardLogic.target > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: _textSecondary.withOpacity(0.3))
                                  ),
                                  child: Text('Target: ${_scorecardLogic.target}', style: const TextStyle(color: _whiteText, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),

                              Text('RRR: ${_scorecardLogic.requiredRunRate.toStringAsFixed(2)}', style: const TextStyle(color: _textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // --- BATSMAN CARD ---
                  _buildGradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBatsmanHeaderRow(),
                        const SizedBox(height: 4),
                        _buildDynamicBatsmanRow(_scorecardLogic.striker),
                        _buildDynamicBatsmanRow(_scorecardLogic.nonStriker),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // --- BOWLER CARD ---
                  _buildGradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBowlerHeaderRow(),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async => await _editBowlerName(_scorecardLogic.currentBowler),
                          child: _buildDynamicBowlerRow(_scorecardLogic.currentBowler),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // --- THIS OVER CARD ---
                  _buildGradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('This Over', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textSecondary)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 32,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _scorecardLogic.thisOverBalls.length,
                            itemBuilder: (context, index) {
                              final ball = _scorecardLogic.thisOverBalls[index];
                              Color ballColor = const Color(0xFF4B5563);
                              Color textColor = _whiteText;

                              if (ball.isWicket) {
                                ballColor = Colors.redAccent;
                              } else if (ball.runs == 4 || ball.runs == 6) {
                                ballColor = Colors.green;
                              } else if (ball.extraTypes != null && ball.extraTypes!.isNotEmpty) {
                                ballColor = Colors.orangeAccent;
                                textColor = _blackText;
                              }

                              return Container(
                                alignment: Alignment.center,
                                width: 32,
                                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                decoration: BoxDecoration(
                                    color: ballColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24, width: 1)
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(ball.display, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // --- EXTRAS & ACTIONS ---
                  _buildGradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildExtraCheckbox('wide', 'Wide', 1),
                            _buildExtraCheckbox('noball', 'NB', 1),
                            _buildExtraCheckbox('legbye', 'LB', 0),
                            _buildExtraCheckbox('bye', 'Bye', 0),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildStandardDropdown<String>('Wicket', _scorecardLogic.selectedWicketMethod, ['Bowled', 'Caught', 'Run Out', 'Stumped', 'LBW'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), (String? newValue) {
                                setState(() {
                                  _scorecardLogic.selectedWicketMethod = newValue;
                                  if (newValue != null) {
                                    if (newValue == 'Run Out') _showRunOutDialog(0, List<String>.from(extraTypes));
                                    else if (newValue == 'Caught' || newValue == 'Stumped') _showWicketDetailsDialog(0, newValue, List<String>.from(extraTypes));
                                    else _scoreBall(runs: 0, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes), isWicket: true, wicketMethod: newValue);
                                  }
                                });
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: _buildStandardButton('Undo', () async => await _undoLastBall(), customColor: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- KEYPAD (CIRCULAR BALL BUTTONS) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0, // Perfect Circle
                      physics: const NeverScrollableScrollPhysics(),
                      children: <Widget>[
                        _buildCircularButton('0', () => _scoreBall(runs: 0, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes))),
                        _buildCircularButton('1', () => _scoreBall(runs: 1, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes))),
                        _buildCircularButton('2', () => _scoreBall(runs: 2, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes))),
                        _buildCircularButton('3', () => _scoreBall(runs: 3, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes))),
                        _buildCircularButton('4', () => _scoreBall(runs: 4, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes))),
                        _buildCircularButton('5', () => _scoreBall(runs: 5, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes))),
                        _buildCircularButton('6', () => _scoreBall(runs: 6, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes))),

                        // Plus (+) Dropdown with Circular Style
                        _buildCircularDropdownButton<int>('+', null, List.generate(6, (index) => index + 7).map((int value) => DropdownMenuItem<int>(value: value, child: Text(value.toString(), style: const TextStyle(fontSize: 16)))).toList(), (int? newValue) { if (newValue != null) _scoreBall(runs: newValue, extraTypes: extraTypes.isEmpty ? null : List<String>.from(extraTypes)); }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
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
      ),
    );
  }
}