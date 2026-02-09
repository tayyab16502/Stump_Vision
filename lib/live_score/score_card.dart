import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// --- MODERN DARK & YELLOW THEME ---
const Color _darkPrimary = Color(0xFF333333); // Card & AppBar
const Color _yellowAccent = Color(0xFFFCFB04); // Highlights
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text
const Color _dividerColor = Colors.white12;     // Subtle dividers

class ApiConstants {
  static const String rapidApiHost = 'cricbuzz-cricket.p.rapidapi.com';
  static const String scorecardBaseUrl = 'https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/';
  static const List<String> rapidApiKeys = [
    'b9f4a3138cmshc28892568454dd2p1501a9jsn382b9c1e258e',
    '9dff4b764fmshde2d4d7361697dap19c4abjsn122e42cc462a',
    'a82524868dmsh62625f7938d211bp1eab47jsn122e42cc462a',
    '5e3424bed5msh855415fc9172119p13e89ejsnce61459b93b1',
  ];
}

class ScorecardScreen extends StatefulWidget {
  final String matchId;
  const ScorecardScreen({super.key, required this.matchId});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> with TickerProviderStateMixin {
  Future<Map<String, dynamic>>? _scorecardFuture;
  Timer? _timer;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _fetchAndSetScorecard();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  void _startAutoUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 150), (timer) {
      _fetchAndSetScorecard();
    });
  }

  Future<void> _fetchAndSetScorecard() async {
    setState(() {
      _scorecardFuture = _fetchScorecard();
    });
  }

  Future<Map<String, dynamic>> _fetchScorecard() async {
    final String url = '${ApiConstants.scorecardBaseUrl}${widget.matchId}/hscard';
    for (String apiKey in ApiConstants.rapidApiKeys) {
      try {
        final response = await http.get(Uri.parse(url), headers: {
          'x-rapidapi-host': ApiConstants.rapidApiHost,
          'x-rapidapi-key': apiKey,
        });
        if (response.statusCode == 200) {
          final decodedData = json.decode(response.body) as Map<String, dynamic>;
          if (decodedData.containsKey('scorecard') && (decodedData['scorecard'] as List).isNotEmpty) {
            return decodedData;
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
    throw Exception('No scorecard data available yet.');
  }

  // --- Helpers ---
  int _toInt(dynamic v) => v == null ? 0 : int.tryParse('$v') ?? 0;
  double _toDouble(dynamic v) => v == null ? 0.0 : double.tryParse('$v') ?? 0.0;

  String _formatOvers(dynamic rawOvers) {
    if (rawOvers == null) return '0.0';
    num actual = _toDouble(rawOvers);
    int overs = actual.floor();
    int balls = ((actual - overs) * 10 + 0.5).toInt();
    if (balls >= 6) { overs++; balls = 0; }
    return '$overs.$balls';
  }

  String _formatPlayerDisplay(Map<String, dynamic> p) {
    String n = p['name'] ?? 'N/A';
    if (p['iscaptain'] == true) n += ' (C)';
    if (p['iskeeper'] == true) n += ' (WK)';
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _darkPrimary,
        elevation: 0,
        title: const Text('Match Scorecard', style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _yellowAccent),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _scorecardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _yellowAccent));
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No Data Available', style: TextStyle(color: _textSecondary)),
                  TextButton(
                    onPressed: _fetchAndSetScorecard,
                    child: const Text('Retry', style: TextStyle(color: _yellowAccent)),
                  )
                ],
              ),
            );
          }

          final scorecardData = snapshot.data!;
          List<dynamic> inningsList = scorecardData['scorecard'];
          // Sort so Inning 1 comes first
          inningsList.sort((a, b) => (a['inningsId'] ?? 0).compareTo(b['inningsId'] ?? 0));

          // Initialize Tab Controller dynamically based on innings count
          if (_tabController == null || _tabController!.length != inningsList.length) {
            _tabController = TabController(length: inningsList.length, vsync: this);
          }

          return Column(
            children: [
              // --- SEXY TAB BAR ---
              Container(
                color: _darkPrimary,
                child: TabBar(
                  controller: _tabController,
                  labelColor: _darkPrimary,
                  unselectedLabelColor: _textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: _yellowAccent,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tabs: inningsList.map((inning) {
                    String name = inning['batteamname'] ?? 'Inning';
                    // Shorten name if too long
                    if (name.length > 15) name = name.substring(0, 3).toUpperCase();
                    return Tab(
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
                        alignment: Alignment.center,
                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // --- TAB VIEW (CONTENT) ---
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: inningsList.map((inning) {
                    return _buildSingleInningView(inning);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSingleInningView(Map<String, dynamic> inning) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- SCORE HEADER ---
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_darkPrimary, Colors.black]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _yellowAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '${inning['score']}/${inning['wickets']}',
                  style: const TextStyle(color: _yellowAccent, fontSize: 36, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Overs: ${_formatOvers(inning['overs'])}  |  CRR: ${inning['runrate']}',
                  style: const TextStyle(color: _whiteText, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // --- BATTING ---
          _buildSectionHeader('BATTING'),
          _buildBattingTable(inning['batsman'] ?? []),

          const SizedBox(height: 10),

          // --- BOWLING ---
          _buildSectionHeader('BOWLING'),
          _buildBowlingTable(inning['bowler'] ?? []),

          const SizedBox(height: 10),

          // --- COLLAPSIBLE DETAILS ---
          _buildCollapsibleDetails(inning),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26,
      child: Text(
        title,
        style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  // --- COMPACT BATTING TABLE ---
  Widget _buildBattingTable(List<dynamic> batsmen) {
    if (batsmen.isEmpty) return const SizedBox();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _darkPrimary,
          child: const Row(
            children: [
              Expanded(flex: 4, child: Text('Batter', style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 1, child: Text('B', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(color: _textSecondary, fontSize: 11))),
            ],
          ),
        ),
        const Divider(height: 1, color: _dividerColor),
        // Rows
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: batsmen.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _dividerColor),
          itemBuilder: (context, index) {
            final b = batsmen[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: _background,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatPlayerDisplay(b), style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 13)),
                        if (b['outdec'] != null && b['outdec'] != 'not out')
                          Text(b['outdec'], style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontStyle: FontStyle.italic))
                        else
                          const Text('Not Out', style: TextStyle(color: Colors.greenAccent, fontSize: 10))
                      ],
                    ),
                  ),
                  Expanded(flex: 1, child: Text('${_toInt(b['runs'])}', textAlign: TextAlign.center, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('${_toInt(b['balls'])}', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                  Expanded(flex: 1, child: Text('${_toInt(b['fours'])}', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                  Expanded(flex: 1, child: Text('${_toInt(b['sixes'])}', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                  Expanded(flex: 2, child: Text(_toDouble(b['strkrate']).toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- COMPACT BOWLING TABLE ---
  Widget _buildBowlingTable(List<dynamic> bowlers) {
    if (bowlers.isEmpty) return const SizedBox();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _darkPrimary,
          child: const Row(
            children: [
              Expanded(flex: 4, child: Text('Bowler', style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 1, child: Text('O', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 1, child: Text('M', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: _textSecondary, fontSize: 11))),
              Expanded(flex: 2, child: Text('Eco', textAlign: TextAlign.right, style: TextStyle(color: _textSecondary, fontSize: 11))),
            ],
          ),
        ),
        const Divider(height: 1, color: _dividerColor),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: bowlers.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _dividerColor),
          itemBuilder: (context, index) {
            final b = bowlers[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: _background,
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(b['name'] ?? 'N/A', style: const TextStyle(color: _whiteText, fontWeight: FontWeight.w600, fontSize: 13))),
                  Expanded(flex: 1, child: Text(_formatOvers(b['overs']), textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                  Expanded(flex: 1, child: Text('${_toInt(b['maidens'])}', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                  Expanded(flex: 1, child: Text('${_toInt(b['runs'])}', textAlign: TextAlign.center, style: const TextStyle(color: _whiteText, fontSize: 12))),
                  Expanded(flex: 1, child: Text('${_toInt(b['wickets'])}', textAlign: TextAlign.center, style: const TextStyle(color: _yellowAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(flex: 2, child: Text(_toDouble(b['economy']).toStringAsFixed(1), textAlign: TextAlign.right, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- COLLAPSIBLE DETAILS ---
  Widget _buildCollapsibleDetails(Map<String, dynamic> inning) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text("Match Details (FOW, Extras)", style: TextStyle(color: _yellowAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        iconColor: _yellowAccent,
        collapsedIconColor: _textSecondary,
        children: [
          // Extras
          if (inning['extras'] != null)
            _buildKeyValueRow('Extras', '${_toInt(inning['extras']['total'])} (wd ${_toInt(inning['extras']['wides'])}, nb ${_toInt(inning['extras']['noballs'])}, lb ${_toInt(inning['extras']['legbyes'])}, b ${_toInt(inning['extras']['byes'])})'),

          const Divider(color: _dividerColor),

          // Fall of Wickets
          if (inning['fow'] != null && inning['fow']['fow'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Fall of Wickets", style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: (inning['fow']['fow'] as List).map((f) {
                      return Text(
                        "${_toInt(f['runs'])}-${(inning['fow']['fow'] as List).indexOf(f) + 1} (${f['batsmanname']}, ${_formatOvers(f['overnbr'])})",
                        style: const TextStyle(color: _whiteText, fontSize: 12),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Text(key, style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(color: _whiteText, fontSize: 13))),
        ],
      ),
    );
  }
}