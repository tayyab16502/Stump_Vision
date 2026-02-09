import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stump_vision/score_book/scoring/scorecard_logic.dart';
import 'dart:math' as math;
import 'package:stump_vision/score_book/scoring/match_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/batting_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/bowling_summary.dart';
import 'package:stump_vision/score_book/scoring/match_summary_logic/overs_summary.dart';

// --- MODERN DARK & YELLOW THEME ---
const Color _darkPrimary = Color(0xFF333333);
const Color _yellowAccent = Color(0xFFFCFB04);
const Color _background = Color(0xFF1F1F1F);
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF);

// Graph Colors
const Color _team1Color = Color(0xFF00E676); // Bright Green
const Color _team2Color = Color(0xFF2979FF); // Bright Blue
const Color _wicketRed = Color(0xFFFF4C4C);  // Red for Wickets

class GraphSummaryScreen extends StatefulWidget {
  final ScorecardLogic logic;
  final Map<String, dynamic> matchDetails;
  final String selectedInning;

  const GraphSummaryScreen({
    super.key,
    required this.logic,
    required this.matchDetails,
    required this.selectedInning,
  });

  @override
  State<GraphSummaryScreen> createState() => _GraphSummaryScreenState();
}

class _GraphSummaryScreenState extends State<GraphSummaryScreen> {
  final int _selectedIndex = 5;

  @override
  void initState() {
    super.initState();
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

  // --- NAVIGATION HANDLER ---
  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;

    final logic = widget.logic;
    final details = widget.matchDetails;
    final inning = widget.selectedInning.isNotEmpty ? widget.selectedInning : (widget.logic.currentInnings == 1 ? '1st Inning' : '2nd Inning');

    switch (index) {
      case 0: Navigator.pop(context); break;
      case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MatchSummaryScreen(logic: logic, matchDetails: details))); break;
      case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BattingSummaryScreen(logic: logic, selectedInning: inning, matchDetails: details))); break;
      case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BowlingSummaryScreen(logic: logic, selectedInning: inning, matchDetails: details))); break;
      case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OverSummaryScreen(logic: logic, selectedInning: inning, matchDetails: details))); break;
      case 5: break;
    }
  }

  // --- UI WIDGETS ---
  Widget _buildGraphCard({required Widget child, required String title}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _darkPrimary,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: _yellowAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String team1Name, String team2Name, bool showTeam2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(_team1Color, team1Name),
          if (showTeam2) ...[
            const SizedBox(width: 20),
            _buildLegendItem(_team2Color, team2Name),
          ],
          const SizedBox(width: 20),
          _buildLegendItem(_wicketRed, "Wicket", isCircle: true),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isCircle = false}) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle
            )
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _whiteText, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool startedDirectlyToSecondInning = widget.matchDetails['startFirstInning'] == false;
    bool showTeam2Data = widget.logic.currentInnings == 2 && !startedDirectlyToSecondInning;

    String team1Name = widget.logic.firstInningBattingTeamName ?? widget.logic.team1Name;
    String team2Name = (team1Name == widget.logic.team1Name) ? widget.logic.team2Name : widget.logic.team1Name;

    // --- 1. WORM GRAPH DATA ---
    List<FlSpot> team1Spots = [const FlSpot(0, 0)];
    List<FlSpot> team2Spots = [const FlSpot(0, 0)];
    List<FlSpot> team1WicketSpots = [];
    List<FlSpot> team2WicketSpots = [];

    // Team 1 Logic
    if (!startedDirectlyToSecondInning) {
      InningsData? innings1Data = widget.logic.getInningsData(1);
      List<Map<String, int>> scores = (widget.logic.currentInnings == 1 && innings1Data == null)
          ? widget.logic.innings1OverScores
          : (innings1Data?.overScores ?? []);

      int prevWickets = 0;
      for (var data in scores) {
        double ov = data['overs']!.toDouble();
        double runs = data['runs']!.toDouble();
        int currentWickets = data['wickets']!;
        team1Spots.add(FlSpot(ov, runs));
        if (currentWickets > prevWickets) team1WicketSpots.add(FlSpot(ov, runs));
        prevWickets = currentWickets;
      }
    }

    // Team 2 Logic
    if (showTeam2Data || startedDirectlyToSecondInning) {
      InningsData? innings2Data = widget.logic.getInningsData(2);
      List<Map<String, int>> scores = (widget.logic.currentInnings == 2 && innings2Data == null)
          ? widget.logic.innings2OverScores
          : (innings2Data?.overScores ?? []);

      int prevWickets = 0;
      for (var data in scores) {
        double ov = data['overs']!.toDouble();
        double runs = data['runs']!.toDouble();
        int currentWickets = data['wickets']!;
        team2Spots.add(FlSpot(ov, runs));
        if (currentWickets > prevWickets) team2WicketSpots.add(FlSpot(ov, runs));
        prevWickets = currentWickets;
      }
    }

    double maxRuns = 0;
    if (team1Spots.isNotEmpty) maxRuns = math.max(maxRuns, team1Spots.last.y);
    if (team2Spots.isNotEmpty) maxRuns = math.max(maxRuns, team2Spots.last.y);
    maxRuns = (maxRuns / 20).ceil() * 20.0;
    if (maxRuns < 40) maxRuns = 40.0;
    double totalOvers = widget.logic.totalMatchOvers.toDouble();

    // --- 2. BAR CHART DATA PREP ---
    List<BarChartGroupData> runsPerOverBars = [];
    List<OverSummary> t1Overs = !startedDirectlyToSecondInning ? widget.logic.getCompletedOversForInnings(1) : [];
    List<OverSummary> t2Overs = (showTeam2Data || startedDirectlyToSecondInning) ? widget.logic.getCompletedOversForInnings(2) : [];

    int maxOversCount = math.max(t1Overs.length, t2Overs.length);
    if (maxOversCount < 5) maxOversCount = 5;

    double maxRunsPerOver = 0.0;

    for (int i = 0; i < maxOversCount; i++) {
      double r1 = i < t1Overs.length ? t1Overs[i].runsScoredInOver.toDouble() : 0.0;
      double r2 = i < t2Overs.length ? t2Overs[i].runsScoredInOver.toDouble() : 0.0;
      maxRunsPerOver = math.max(maxRunsPerOver, math.max(r1, r2));

      runsPerOverBars.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4, // Spacing between thin bars
          barRods: [
            // UPDATED: width changed to 4 for thin sleek look
            BarChartRodData(toY: r1, color: _team1Color, width: 4, borderRadius: BorderRadius.circular(2)),
            if (showTeam2Data || startedDirectlyToSecondInning)
              BarChartRodData(toY: r2, color: _team2Color, width: 4, borderRadius: BorderRadius.circular(2)),
          ],
        ),
      );
    }
    if (maxRunsPerOver < 10) maxRunsPerOver = 10.0;

    // Adjusted dynamic width slightly for thin bars
    double chartWidth = math.max(MediaQuery.of(context).size.width - 64, maxOversCount * 35.0);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _darkPrimary,
        elevation: 0,
        title: const Text('Match Graphs', style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _yellowAccent),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. WORM GRAPH ---
            _buildGraphCard(
              title: 'WORM GRAPH',
              child: Column(
                children: [
                  _buildLegend(team1Name, team2Name, showTeam2Data || startedDirectlyToSecondInning),
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          verticalInterval: 5,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                          getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 5,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(value.toInt().toString(), style: const TextStyle(color: _textSecondary, fontSize: 10)),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: maxRuns / 4,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: _textSecondary, fontSize: 10)),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10)),
                        minX: 0,
                        maxX: totalOvers,
                        minY: 0,
                        maxY: maxRuns * 1.1,
                        lineBarsData: [
                          if (team1Spots.isNotEmpty)
                            LineChartBarData(spots: team1Spots, isCurved: true, color: _team1Color, barWidth: 3, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: false)),
                          if (team2Spots.isNotEmpty)
                            LineChartBarData(spots: team2Spots, isCurved: true, color: _team2Color, barWidth: 3, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: false)),

                          // Wicket Dots Layers
                          if (team1WicketSpots.isNotEmpty)
                            LineChartBarData(spots: team1WicketSpots, color: _wicketRed, barWidth: 0, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: _wicketRed, strokeWidth: 1, strokeColor: Colors.white))),
                          if (team2WicketSpots.isNotEmpty)
                            LineChartBarData(spots: team2WicketSpots, color: _wicketRed, barWidth: 0, dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: _wicketRed, strokeWidth: 1, strokeColor: Colors.white))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. RUNS PER OVER (THIN LINES & SCROLLABLE) ---
            _buildGraphCard(
              title: 'RUNS PER OVER',
              child: Column(
                children: [
                  _buildLegend(team1Name, team2Name, showTeam2Data || startedDirectlyToSecondInning),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      height: 250,
                      width: chartWidth, // Calculated width
                      child: BarChart(
                        BarChartData(
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.grey.shade800,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${rod.toY.toInt()}',
                                  const TextStyle(color: _yellowAccent, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int over = value.toInt() + 1;
                                  // Show label every 5th over to avoid clutter
                                  if (over == 1 || over % 5 == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(over.toString(), style: const TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
                                reservedSize: 25,
                                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: _textSecondary, fontSize: 10)),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.white10), left: BorderSide(color: Colors.white10))),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 0.5, dashArray: [5, 5]),
                          ),
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxRunsPerOver + 2,
                          barGroups: runsPerOverBars,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // --- BOTTOM NAV BAR ---
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