import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:stump_vision/live_score/score_card.dart';

// --- MODERN DARK & YELLOW THEME ---
const Color _darkPrimary = Color(0xFF333333); // Card & AppBar
const Color _yellowAccent = Color(0xFFFCFB04); // Highlights
const Color _background = Color(0xFF1F1F1F);   // Screen Background
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF); // Grey text
const Color _liveRed = Color(0xFFFF4444);       // Live Badge

// --- API Constants ---
class ApiConstants {
  static const String rapidApiHost = 'cricbuzz-cricket.p.rapidapi.com';
  static const String liveMatchesUrl = 'https://cricbuzz-cricket.p.rapidapi.com/matches/v1/live';
  static const String upcomingMatchesUrl = 'https://cricbuzz-cricket.p.rapidapi.com/matches/v1/upcoming';
  static const String scorecardBaseUrl = 'https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/';

  static const List<String> rapidApiKeys = [
    'b9f4a3138cmshc28892568454dd2p1501a9jsn382b9c1e258e',
    '9dff4b764fmshde2d4d7361697dap19c4abjsn122e42cc462a',
    'a82524868dmsh62625f7938d211bp1eab47jsn122e42cc462a',
    '5e3424bed5msh855415fc9172119p13e89ejsnce61459b93b1',
  ];
}

// --- Data Model ---
class UIMatch {
  final String? matchId;
  final String matchTitle;
  final String team1Name;
  final String team2Name;
  final String team1SName;
  final String team2SName;
  final String scoreDisplay;
  final String infoDisplay;
  final String statusCategory;
  final String matchType;
  final String venue;
  final String startDate;
  final String? state;
  final String? stateTitle;

  UIMatch({
    this.matchId,
    required this.matchTitle,
    required this.team1Name,
    required this.team2Name,
    required this.team1SName,
    required this.team2SName,
    required this.scoreDisplay,
    required this.infoDisplay,
    required this.statusCategory,
    required this.matchType,
    required this.venue,
    required this.startDate,
    this.state,
    this.stateTitle,
  });

  static String _formatOvers(num? rawOvers) {
    if (rawOvers == null) return '0.0';
    double actualOvers = rawOvers.toDouble();
    int completedOvers = actualOvers.floor();
    int balls = ((actualOvers - completedOvers) * 10 + 0.5).toInt();
    if (balls >= 6) {
      completedOvers++;
      balls = 0;
    }
    return '$completedOvers.$balls';
  }

  static String formatInnings(Map<String, dynamic>? innings) {
    if (innings == null) return '';
    final runs = innings['runs']?.toString() ?? '0';
    final wickets = innings['wickets']?.toString() ?? '0';
    final double actualOvers = (innings['overs'] as num?)?.toDouble() ?? 0.0;
    final String oversDisplay = _formatOvers(actualOvers);
    return '$runs/$wickets ($oversDisplay ov)';
  }

  factory UIMatch.fromRapidApiJson(Map<String, dynamic> matchInfo, Map<String, dynamic>? matchScore) {
    String calculatedScoreDisplay = '';
    String calculatedInfoDisplay = matchInfo['status'] as String? ?? matchInfo['stateTitle'] as String? ?? 'Match Info N/A';

    String currentMatchState = matchInfo['state'] as String? ?? '';
    String currentStatusCategory;
    if (currentMatchState.toLowerCase().contains('in progress') || currentMatchState.toLowerCase().contains('live') || currentMatchState.toLowerCase().contains('stumps') || currentMatchState.toLowerCase().contains('innings break') || currentMatchState.toLowerCase().contains('tea') || currentMatchState.toLowerCase().contains('lunch')) {
      currentStatusCategory = 'Live';
    } else if (currentMatchState.toLowerCase().contains('complete') || currentMatchState.toLowerCase().contains('finished') || currentMatchState.toLowerCase().contains('abandoned') || currentMatchState.toLowerCase().contains('drawn') || currentMatchState.toLowerCase().contains('forfeit')) {
      currentStatusCategory = 'Finished';
    } else if (currentMatchState.toLowerCase().contains('preview') || currentMatchState.toLowerCase().contains('upcoming') || currentMatchState.toLowerCase().contains('scheduled') || currentMatchState.toLowerCase().contains('starts') || currentMatchState.toLowerCase().contains('not started')) {
      currentStatusCategory = 'Upcoming';
    } else {
      currentStatusCategory = 'Unknown';
    }

    if (currentStatusCategory == 'Upcoming') {
      try {
        final int timestamp = int.parse(matchInfo['startDate']?.toString() ?? '0');
        final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        calculatedScoreDisplay = DateFormat('EEEE, MMMM d, yyyy').format(dateTime) + '\n' + DateFormat('h:mm a').format(dateTime) + ' (Local Time)';
      } catch (e) {
        calculatedScoreDisplay = 'Match not started / Date N/A';
      }
    } else {
      if (matchScore != null && matchScore.isNotEmpty) {
        String team1ScoreStr = '';
        String team2ScoreStr = '';

        final team1Score = matchScore['team1Score'];
        final team2Score = matchScore['team2Score'];

        if (team1Score != null) {
          team1ScoreStr = formatInnings(team1Score['inngs1']);
          if (matchInfo['matchFormat'] == 'TEST' && team1Score['inngs2'] != null) {
            team1ScoreStr += '\n(${matchInfo['team1']['teamSName']} 2nd Inn: ${formatInnings(team1Score['inngs2'])})';
          }
        }
        if (team2Score != null) {
          team2ScoreStr = formatInnings(team2Score['inngs1']);
          if (matchInfo['matchFormat'] == 'TEST' && team2Score['inngs2'] != null) {
            team2ScoreStr += '\n(${matchInfo['team2']['teamSName']} 2nd Inn: ${formatInnings(team2Score['inngs2'])})';
          }
        }

        if (team1ScoreStr.isNotEmpty && team2ScoreStr.isNotEmpty) {
          calculatedScoreDisplay = '${matchInfo['team1']['teamName']} $team1ScoreStr\n${matchInfo['team2']['teamName']} $team2ScoreStr';
        } else if (team1ScoreStr.isNotEmpty) {
          calculatedScoreDisplay = '${matchInfo['team1']['teamName']} $team1ScoreStr';
        } else if (team2ScoreStr.isNotEmpty) {
          calculatedScoreDisplay = '${matchInfo['team2']['teamName']} $team2ScoreStr';
        }
      } else {
        calculatedScoreDisplay = 'Score not available yet.';
      }
    }

    return UIMatch(
      matchId: matchInfo['matchId']?.toString(),
      matchTitle: matchInfo['seriesName'] as String? ?? 'Unknown Series',
      team1Name: matchInfo['team1']['teamName'] as String? ?? 'Team 1',
      team2Name: matchInfo['team2']['teamName'] as String? ?? 'Team 2',
      team1SName: matchInfo['team1']['teamSName'] as String? ?? 'T1',
      team2SName: matchInfo['team2']['teamSName'] as String? ?? 'T2',
      scoreDisplay: calculatedScoreDisplay.isNotEmpty ? calculatedScoreDisplay : 'N/A',
      infoDisplay: calculatedInfoDisplay,
      statusCategory: currentStatusCategory,
      matchType: matchInfo['matchFormat'] as String? ?? 'Unknown',
      venue: '${matchInfo['venueInfo']['ground'] as String? ?? 'Unknown Ground'}, ${matchInfo['venueInfo']['city'] as String? ?? 'Unknown City'}',
      startDate: matchInfo['startDate']?.toString() ?? '',
      state: matchInfo['state'] as String?,
      stateTitle: matchInfo['stateTitle'] as String?,
    );
  }
}

// =========================================================================
// MAIN SCREEN WITH BOTTOM NAVIGATION
// =========================================================================

class LiveScoreScreen extends StatefulWidget {
  const LiveScoreScreen({super.key});

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MatchesTab(),      // Matches Tab (Active)
    const SizedBox(),        // Scorebook (Placeholder - Navigates away)
    const SizedBox(),        // DRS (Placeholder - Navigates away)
  ];

  void _onTabTapped(int index) {
    if (index == 1) {
      // Navigate to Scorebook
      Navigator.pushNamed(context, '/score_book_main');
    } else if (index == 2) {
      // Navigate to DRS Screen
      Navigator.pushNamed(context, '/drs_screen');
    } else {
      // Keep on this screen and switch tab
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black, blurRadius: 15, offset: Offset(0, -2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: _darkPrimary,
              selectedItemColor: _yellowAccent,
              unselectedItemColor: _textSecondary,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(_currentIndex == 0 ? Icons.sports_cricket : Icons.sports_cricket_outlined),
                  label: 'Matches',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  label: 'Scorebook',
                ),
                BottomNavigationBarItem(
                  icon: Icon(_currentIndex == 2 ? Icons.camera_front : Icons.camera_front_outlined),
                  label: 'DRS',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 1: MATCHES TAB
// =========================================================================

class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<UIMatch>> _liveMatchesFuture;
  Future<List<UIMatch>>? _upcomingMatchesFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _liveMatchesFuture = _fetchLiveMatches();

    _tabController.addListener(() {
      if (_tabController.index == 1 && (_upcomingMatchesFuture == null || _upcomingMatchesFuture == Future.value([]))) {
        _fetchAndSetUpcomingMatches();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 150), (timer) {
      if (_tabController.index == 0) {
        _fetchAndSetLiveMatches(showSnackbar: false);
      }
    });
  }

  Future<void> _fetchAndSetLiveMatches({bool showSnackbar = true}) async {
    setState(() {
      _liveMatchesFuture = _fetchLiveMatches();
    });
    try {
      await _liveMatchesFuture;
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing matches...'), duration: Duration(seconds: 1)));
    }
  }

  Future<void> _fetchAndSetUpcomingMatches({bool showSnackbar = false}) async {
    setState(() {
      _upcomingMatchesFuture = _fetchUpcomingMatches();
    });
    try {
      await _upcomingMatchesFuture;
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing upcoming...'), duration: Duration(seconds: 1)));
    }
  }

  // --- LOGIC HELPERS ---
  bool _isMatchLive(String? state, String? stateTitle) {
    final s = (state ?? '') + (stateTitle ?? '');
    final lowerState = s.toLowerCase();
    final liveKeywords = ['live', 'running', 'in progress', 'playing', 'started', 'ongoing', 'stumps', 'innings break', 'tea', 'lunch'];
    for (var keyword in liveKeywords) {
      if (lowerState.contains(keyword)) return true;
    }
    return false;
  }

  bool _isMatchFinished(String? state, String? stateTitle) {
    final s = (state ?? '') + (stateTitle ?? '');
    final lowerState = s.toLowerCase();
    final finishedKeywords = ['finished', 'completed', 'ended', 'result', 'complete', 'abandoned', 'drawn', 'forfeit'];
    for (var keyword in finishedKeywords) {
      if (lowerState.contains(keyword)) return true;
    }
    return false;
  }

  bool _isMatchUpcoming(String? state, String? stateTitle) {
    final s = (state ?? '') + (stateTitle ?? '');
    final lowerState = s.toLowerCase();
    final upcomingKeywords = ['preview', 'upcoming', 'scheduled', 'starts', 'not started'];
    for (var keyword in upcomingKeywords) {
      if (lowerState.contains(keyword)) return true;
    }
    return false;
  }

  // --- NEW SORTING LOGIC ---
  int _getMatchPriority(UIMatch match) {
    String status = (match.state ?? match.stateTitle ?? '').toLowerCase();

    // Priority 1: ACTIVELY RUNNING
    if (status.contains('progress') || status.contains('running') || status.contains('playing')) return 1;

    // Priority 2: LIVE BUT PAUSED (Tea, Lunch, Break)
    if (status.contains('break') || status.contains('tea') || status.contains('lunch') || status.contains('dinner')) return 2;

    // Priority 3: HALTED FOR DAY (Stumps, Rain)
    if (status.contains('stumps') || status.contains('rain') || status.contains('bad light') || status.contains('delay')) return 3;

    // Priority 4: FINISHED
    if (match.statusCategory == 'Finished' || status.contains('complete') || status.contains('result')) return 4;

    // Default
    return 5;
  }

  Future<List<UIMatch>> _fetchMatches(String baseUrl) async {
    for (String apiKey in ApiConstants.rapidApiKeys) {
      final Uri uri = Uri.parse(baseUrl);
      final Map<String, String> headers = {
        'x-rapidapi-host': ApiConstants.rapidApiHost,
        'x-rapidapi-key': apiKey,
      };

      try {
        final response = await http.get(uri, headers: headers);
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          List<UIMatch> matches = [];

          if (data['typeMatches'] != null) {
            for (var typeMatch in data['typeMatches']) {
              if (typeMatch['seriesMatches'] != null) {
                for (var seriesMatch in typeMatch['seriesMatches']) {
                  if (seriesMatch['ad'] != null) continue;
                  if (seriesMatch['seriesAdWrapper'] != null && seriesMatch['seriesAdWrapper']['matches'] != null) {
                    for (var matchContainer in seriesMatch['seriesAdWrapper']['matches']) {
                      final matchInfo = matchContainer['matchInfo'];
                      final matchScore = matchContainer['matchScore'];
                      if (matchInfo != null) {
                        final uiMatch = UIMatch.fromRapidApiJson(matchInfo, matchScore);
                        if (baseUrl == ApiConstants.liveMatchesUrl) {
                          if (_isMatchLive(uiMatch.state, uiMatch.stateTitle) || _isMatchFinished(uiMatch.state, uiMatch.stateTitle)) {
                            matches.add(uiMatch);
                          }
                        } else if (baseUrl == ApiConstants.upcomingMatchesUrl && _isMatchUpcoming(uiMatch.state, uiMatch.stateTitle)) {
                          matches.add(uiMatch);
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // --- SORTING LOGIC APPLIED HERE ---
          if (baseUrl == ApiConstants.liveMatchesUrl) {
            matches.sort((a, b) {
              int priorityA = _getMatchPriority(a);
              int priorityB = _getMatchPriority(b);
              if (priorityA != priorityB) {
                return priorityA.compareTo(priorityB); // Lower priority number comes first
              }
              // Tie-breaker: Match ID or Start Date
              return int.parse(a.startDate).compareTo(int.parse(b.startDate));
            });
          } else {
            // For Upcoming, sort by date only
            matches.sort((a, b) => int.parse(a.startDate).compareTo(int.parse(b.startDate)));
          }

          return matches;
        }
      } catch (e) {
        debugPrint('Error fetching from ${baseUrl}: $e');
      }
    }
    throw Exception('Failed to load matches.');
  }

  Future<List<UIMatch>> _fetchLiveMatches() async {
    return _fetchMatches(ApiConstants.liveMatchesUrl);
  }

  Future<List<UIMatch>> _fetchUpcomingMatches() async {
    return _fetchMatches(ApiConstants.upcomingMatchesUrl);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMatchCard(UIMatch match, {bool isUpcoming = false}) {
    String team1FlagPath = 'assets/flags/${match.team1SName.toLowerCase().replaceAll(' ', '_')}_flag.png';
    String team2FlagPath = 'assets/flags/${match.team2SName.toLowerCase().replaceAll(' ', '_')}_flag.png';

    Color statusColor;
    Color statusTextColor = Colors.black;

    switch (match.statusCategory) {
      case 'Live':
        statusColor = _liveRed;
        statusTextColor = Colors.white;
        break;
      case 'Upcoming':
        statusColor = _yellowAccent;
        break;
      case 'Finished':
        statusColor = Colors.grey;
        statusTextColor = Colors.white;
        break;
      default:
        statusColor = _textSecondary;
    }

    return GestureDetector(
      onTap: () {
        if (isUpcoming) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scorecard will be available once the match starts')),
          );
          return;
        }

        if (match.matchId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScorecardScreen(matchId: match.matchId!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: _darkPrimary,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: _whiteText.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Title
              Text(
                match.matchTitle.toUpperCase(),
                style: const TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Teams and Flags
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        _buildFlag(team1FlagPath),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(match.team1Name, style: const TextStyle(color: _whiteText, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('VS', style: TextStyle(color: _yellowAccent.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(match.team2Name, textAlign: TextAlign.right, style: const TextStyle(color: _whiteText, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
                        ),
                        const SizedBox(width: 10),
                        _buildFlag(team2FlagPath),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Score Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  match.scoreDisplay,
                  style: TextStyle(
                    color: _yellowAccent,
                    fontSize: match.statusCategory == 'Upcoming' ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Status and Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(match.infoDisplay, style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      match.statusCategory.toUpperCase(),
                      style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlag(String flagPath) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _whiteText.withOpacity(0.2), width: 1),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: _background,
        backgroundImage: AssetImage(flagPath),
        onBackgroundImageError: (exception, stackTrace) {},
        child: const Icon(Icons.flag, size: 20, color: _textSecondary), // Fallback icon hidden if image loads
      ),
    );
  }

  Widget _buildToggleButton({required String label, required bool isSelected, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: isSelected ? _yellowAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(25.0),
        border: Border.all(color: isSelected ? _yellowAccent : _textSecondary.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : _whiteText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
        backgroundColor: _darkPrimary,
        elevation: 0,
        title: const Text(
          'Cricket Scores',
          style: TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: _yellowAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tab Toggle Area
          Container(
            color: _darkPrimary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      label: 'LIVE',
                      isSelected: _tabController.index == 0,
                      onPressed: () => setState(() => _tabController.animateTo(0)),
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      label: 'UPCOMING',
                      isSelected: _tabController.index == 1,
                      onPressed: () => setState(() => _tabController.animateTo(1)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Live Tab
                FutureBuilder<List<UIMatch>>(
                  future: _liveMatchesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _yellowAccent));
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading matches', style: TextStyle(color: _textSecondary)));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No Live Matches', style: TextStyle(color: _textSecondary, fontSize: 16)));
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) => _buildMatchCard(snapshot.data![index]),
                      );
                    }
                  },
                ),
                // Upcoming Tab
                FutureBuilder<List<UIMatch>>(
                  future: _upcomingMatchesFuture ?? Future.value([]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _yellowAccent));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No Upcoming Matches', style: TextStyle(color: _textSecondary, fontSize: 16)));
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) => _buildMatchCard(snapshot.data![index], isUpcoming: true),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}