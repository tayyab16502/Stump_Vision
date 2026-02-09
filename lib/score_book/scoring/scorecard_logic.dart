import 'dart:convert';
import 'dart:async'; // Timer ke liye zaroori hai
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:stump_vision/score_book/database_service.dart';

// --- THEME COLORS CONSTANTS ---
const Color _darkPrimary = Color(0xFF333333);
const Color _yellowAccent = Color(0xFFFCFB04);
const Color _background = Color(0xFF1F1F1F);
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFF9CA3AF);
const Color _blackText = Color(0xFF1F1F1F);
// ------------------------------

// --- CONFIGURATION ---
const int _MAX_UNDO_HISTORY = 18;

class Batsman {
  String name;
  int runs;
  int balls;
  int fours;
  int sixes;
  bool isOnStrike;
  bool isOut;
  String? dismissalMethod;
  String? dismissalDetails;

  Batsman({
    required this.name,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOnStrike = false,
    this.isOut = false,
    this.dismissalMethod,
    this.dismissalDetails,
  });

  Batsman.copy(Batsman other)
      : name = other.name,
        runs = other.runs,
        balls = other.balls,
        fours = other.fours,
        sixes = other.sixes,
        isOnStrike = other.isOnStrike,
        isOut = other.isOut,
        dismissalMethod = other.dismissalMethod,
        dismissalDetails = other.dismissalDetails;

  double get strikeRate => balls == 0 ? 0.0 : (runs / balls) * 100;

  void addRuns(int r) {
    runs += r;
    if (r == 4) fours += 1;
    if (r == 6) sixes += 1;
  }

  void addBall() {
    balls += 1;
  }

  void subtractRuns(int r) {
    runs = r > runs ? 0 : runs - r;
    if (r == 4 && fours > 0) fours -= 1;
    if (r == 6 && sixes > 0) sixes -= 1;
  }

  void subtractBall() {
    balls = balls > 0 ? balls - 1 : 0;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'runs': runs,
    'balls': balls,
    'fours': fours,
    'sixes': sixes,
    'isOnStrike': isOnStrike,
    'isOut': isOut,
    'dismissalMethod': dismissalMethod,
    'dismissalDetails': dismissalDetails,
  };

  factory Batsman.fromJson(Map<String, dynamic> json) => Batsman(
    name: json['name'],
    runs: json['runs'] ?? 0,
    balls: json['balls'] ?? 0,
    fours: json['fours'] ?? 0,
    sixes: json['sixes'] ?? 0,
    isOnStrike: json['isOnStrike'] ?? false,
    isOut: json['isOut'] ?? false,
    dismissalMethod: json['dismissalMethod'],
    dismissalDetails: json['dismissalDetails'],
  );
}

class Bowler {
  String name;
  int ballsBowled;
  int maidens;
  int wickets;
  int runsGiven;

  Bowler({
    required this.name,
    this.ballsBowled = 0,
    this.maidens = 0,
    this.wickets = 0,
    this.runsGiven = 0,
  });

  Bowler.copy(Bowler other)
      : name = other.name,
        ballsBowled = other.ballsBowled,
        maidens = other.maidens,
        wickets = other.wickets,
        runsGiven = other.runsGiven;

  double get overs {
    int wholeOvers = ballsBowled ~/ 6;
    int remainingBalls = ballsBowled % 6;
    return wholeOvers + (remainingBalls / 10.0);
  }

  double get economy => ballsBowled == 0 ? 0.0 : (runsGiven / ballsBowled) * 6;

  void addBall() {
    ballsBowled += 1;
  }

  void addRuns(int r) {
    runsGiven += r;
  }

  void addWicket() {
    wickets += 1;
  }

  void subtractBall() {
    ballsBowled = ballsBowled > 0 ? ballsBowled - 1 : 0;
  }

  void subtractRuns(int r) {
    runsGiven = r > runsGiven ? 0 : runsGiven - r;
  }

  void subtractWicket() {
    wickets = wickets > 0 ? wickets - 1 : 0;
  }

  void mergeStats(Bowler other) {
    ballsBowled += other.ballsBowled;
    maidens += other.maidens;
    wickets += other.wickets;
    runsGiven += other.runsGiven;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'ballsBowled': ballsBowled,
    'maidens': maidens,
    'wickets': wickets,
    'runsGiven': runsGiven,
  };

  factory Bowler.fromJson(Map<String, dynamic> json) => Bowler(
    name: json['name'],
    ballsBowled: json['ballsBowled'] ?? 0,
    maidens: json['maidens'] ?? 0,
    wickets: json['wickets'] ?? 0,
    runsGiven: json['runsGiven'] ?? 0,
  );
}

class BallOutcome {
  final int runs;
  final bool isWicket;
  final List<String>? extraTypes;
  final int extraRuns;
  final bool isLegalDelivery;
  final String display;
  final bool isUserInput;
  final String? wicketMethod;
  final String? dismissalDetails;

  BallOutcome({
    this.runs = 0,
    this.isWicket = false,
    this.extraTypes,
    this.extraRuns = 0,
    this.isLegalDelivery = true,
    required this.display,
    this.isUserInput = true,
    this.wicketMethod,
    this.dismissalDetails,
  });

  Map<String, dynamic> toJson() => {
    'runs': runs,
    'isWicket': isWicket,
    'extraTypes': extraTypes,
    'extraRuns': extraRuns,
    'isLegalDelivery': isLegalDelivery,
    'display': display,
    'wicketMethod': wicketMethod,
    'dismissalDetails': dismissalDetails,
  };

  factory BallOutcome.fromJson(Map<String, dynamic> json) => BallOutcome(
    runs: json['runs'] ?? 0,
    isWicket: json['isWicket'] ?? false,
    extraTypes: (json['extraTypes'] as List?)?.map((e) => e as String).toList(),
    extraRuns: json['extraRuns'] ?? 0,
    isLegalDelivery: json['isLegalDelivery'] ?? true,
    display: json['display'],
    wicketMethod: json['wicketMethod'],
    dismissalDetails: json['dismissalDetails'],
  );
}

class OverSummary {
  final int overNumber;
  final String bowlerName;
  final int runsScoredInOver;
  final int wicketsTakenInOver;
  final List<BallOutcome> ballDetails;

  OverSummary({
    required this.overNumber,
    required this.bowlerName,
    required this.runsScoredInOver,
    required this.wicketsTakenInOver,
    required this.ballDetails,
  });

  OverSummary.copy(OverSummary other)
      : overNumber = other.overNumber,
        bowlerName = other.bowlerName,
        runsScoredInOver = other.runsScoredInOver,
        wicketsTakenInOver = other.wicketsTakenInOver,
        ballDetails = List<BallOutcome>.from(other.ballDetails);

  Map<String, dynamic> toJson() => {
    'overNumber': overNumber,
    'bowlerName': bowlerName,
    'runsScoredInOver': runsScoredInOver,
    'wicketsTakenInOver': wicketsTakenInOver,
    'ballDetails': ballDetails.map((ball) => ball.toJson()).toList(),
  };

  factory OverSummary.fromJson(Map<String, dynamic> json) => OverSummary(
    overNumber: json['overNumber'],
    bowlerName: json['bowlerName'],
    runsScoredInOver: json['runsScoredInOver'],
    wicketsTakenInOver: json['wicketsTakenInOver'],
    ballDetails: (json['ballDetails'] as List).map((e) => BallOutcome.fromJson(e)).toList(),
  );
}

class InningsData {
  final List<Batsman> batsmen;
  final List<Bowler> bowlers;
  final List<OverSummary> completedOvers;
  final List<Map<String, int>> overScores;
  final int totalRuns;
  final int totalWickets;
  final double totalOvers;

  InningsData({
    required this.batsmen,
    required this.bowlers,
    required this.completedOvers,
    required this.overScores,
    required this.totalRuns,
    required this.totalWickets,
    required this.totalOvers,
  });

  Map<String, dynamic> toJson() => {
    'batsmen': batsmen.map((b) => b.toJson()).toList(),
    'bowlers': bowlers.map((b) => b.toJson()).toList(),
    'completedOvers': completedOvers.map((o) => o.toJson()).toList(),
    'overScores': overScores,
    'totalRuns': totalRuns,
    'totalWickets': totalWickets,
    'totalOvers': totalOvers,
  };

  factory InningsData.fromJson(Map<String, dynamic> json) {
    return InningsData(
      batsmen: (json['batsmen'] as List?)?.map((e) => Batsman.fromJson(e)).toList() ?? [],
      bowlers: (json['bowlers'] as List?)?.map((e) => Bowler.fromJson(e)).toList() ?? [],
      completedOvers: (json['completedOvers'] as List?)?.map((e) => OverSummary.fromJson(e)).toList() ?? [],
      overScores: (json['overScores'] as List?)?.map((e) => Map<String, int>.from(e)).toList() ?? [],
      totalRuns: json['totalRuns'] ?? 0,
      totalWickets: json['totalWickets'] ?? 0,
      totalOvers: json['totalOvers']?.toDouble() ?? 0.0,
    );
  }
}

class ScorecardStateSnapshot {
  final int totalRuns;
  final int totalWickets;
  final double currentOvers;
  final Batsman striker;
  final Batsman nonStriker;
  final Bowler currentBowler;
  final List<Batsman> allBatsmen;
  final List<Bowler> allBowlers;
  final List<BallOutcome> thisOverBalls;
  final List<BallOutcome> overHistory;
  final int currentInnings;
  final int target;
  final List<OverSummary> completedOversSummary;
  final List<Map<String, int>> innings1OverScores;
  final List<Map<String, int>> innings2OverScores;
  final InningsData? innings1Data;
  final InningsData? innings2Data;

  ScorecardStateSnapshot({
    required this.totalRuns,
    required this.totalWickets,
    required this.currentOvers,
    required this.striker,
    required this.nonStriker,
    required this.currentBowler,
    required this.allBatsmen,
    required this.allBowlers,
    required this.thisOverBalls,
    required this.overHistory,
    required this.currentInnings,
    required this.target,
    required this.completedOversSummary,
    required this.innings1OverScores,
    required this.innings2OverScores,
    required this.innings1Data,
    required this.innings2Data,
  });

  Map<String, dynamic> toJson() => {
    'totalRuns': totalRuns,
    'totalWickets': totalWickets,
    'currentOvers': currentOvers,
    'striker': striker.toJson(),
    'nonStriker': nonStriker.toJson(),
    'currentBowler': currentBowler.toJson(),
    'allBatsmen': allBatsmen.map((b) => b.toJson()).toList(),
    'allBowlers': allBowlers.map((b) => b.toJson()).toList(),
    'thisOverBalls': thisOverBalls.map((b) => b.toJson()).toList(),
    'overHistory': overHistory.map((b) => b.toJson()).toList(),
    'currentInnings': currentInnings,
    'target': target,
    'completedOversSummary': completedOversSummary.map((o) => o.toJson()).toList(),
    'innings1OverScores': innings1OverScores,
    'innings2OverScores': innings2OverScores,
    'innings1Data': innings1Data?.toJson(),
    'innings2Data': innings2Data?.toJson(),
  };

  factory ScorecardStateSnapshot.fromJson(Map<String, dynamic> json) => ScorecardStateSnapshot(
    totalRuns: json['totalRuns'] ?? 0,
    totalWickets: json['totalWickets'] ?? 0,
    currentOvers: json['currentOvers']?.toDouble() ?? 0.0,
    striker: Batsman.fromJson(json['striker'] ?? {'name': 'Default Striker'}),
    nonStriker: Batsman.fromJson(json['nonStriker'] ?? {'name': 'Default NonStriker'}),
    currentBowler: Bowler.fromJson(json['currentBowler'] ?? {'name': 'Default Bowler'}),
    allBatsmen: (json['allBatsmen'] as List?)?.map((item) => Batsman.fromJson(item)).toList() ?? [],
    allBowlers: (json['allBowlers'] as List?)?.map((item) => Bowler.fromJson(item)).toList() ?? [],
    thisOverBalls: (json['thisOverBalls'] as List?)?.map((item) => BallOutcome.fromJson(item)).toList() ?? [],
    overHistory: (json['overHistory'] as List?)?.map((item) => BallOutcome.fromJson(item)).toList() ?? [],
    currentInnings: json['currentInnings'] ?? 1,
    target: json['target'] ?? 0,
    completedOversSummary: (json['completedOversSummary'] as List?)?.map((item) => OverSummary.fromJson(item)).toList() ?? [],
    innings1OverScores: (json['innings1OverScores'] as List?)?.map((e) => Map<String, int>.from(e)).toList() ?? [],
    innings2OverScores: (json['innings2OverScores'] as List?)?.map((e) => Map<String, int>.from(e)).toList() ?? [],
    innings1Data: json['innings1Data'] != null ? InningsData.fromJson(json['innings1Data']) : null,
    innings2Data: json['innings2Data'] != null ? InningsData.fromJson(json['innings2Data']) : null,
  );
}

class ScorecardLogic extends ChangeNotifier {
  String? matchId;
  late String team1Name;
  late String team2Name;
  late String firstInningBattingTeamName;
  late int totalMatchOvers;
  late String? tossWinner;
  late String? choice;

  int? firstInningScore;
  int? firstInningOuts;
  bool startFirstInning = true;

  int totalRuns = 0;
  int totalWickets = 0;
  double currentOvers = 0.0;
  late int currentInnings;
  int target = 0;
  double requiredRunRate = 0.0;
  double currentRunRate = 0.0;

  late Batsman striker;
  late Batsman nonStriker;
  late Bowler currentBowler;

  List<Batsman> allBatsmen = [];
  List<Bowler> allBowlers = [];
  List<BallOutcome> thisOverBalls = [];
  List<BallOutcome> overHistory = [];
  bool lastStrikeChanged = false;

  List<OverSummary> completedOversSummary = [];
  List<Map<String, int>> innings1OverScores = [];
  List<Map<String, int>> innings2OverScores = [];

  String? selectedExtraType;
  String? selectedWicketMethod;

  InningsData? innings1Data;
  InningsData? innings2Data;

  bool isMatchComplete = false;
  bool _isOverComplete = false;
  int validBallsInOver = 0;

  bool get isOverComplete => _isOverComplete;
  set isOverComplete(bool value) {
    _isOverComplete = value;
    if (value) {
      _notifyListeners();
    }
  }

  final List<String> wicketMethods = const [
    'Bowled',
    'Caught',
    'LBW',
    'Run Out',
    'Stumped',
    'Hit Wicket',
    'Retired Hurt',
    'Obstructing the field',
    'Timed Out',
    'Handled the ball',
    'Hit the ball twice',
  ];

  final GlobalKey<NavigatorState> navigatorKey;
  List<ScorecardStateSnapshot> stateHistory = [];
  final List<VoidCallback> _updateCallbacks = [];
  bool _isDisposed = false;
  Timer? _saveDebounce;

  ScorecardLogic({required this.navigatorKey, this.matchId});

  @override
  void dispose() {
    _isDisposed = true;
    _updateCallbacks.clear();
    _saveDebounce?.cancel();
    super.dispose();
    print('ScorecardLogic disposed.');
  }

  void addUpdateListener(VoidCallback callback) {
    _updateCallbacks.add(callback);
  }

  void removeUpdateListener(VoidCallback callback) {
    _updateCallbacks.remove(callback);
  }

  void _notifyListeners() {
    if (_isDisposed) {
      print('ScorecardLogic is disposed, not notifying listeners.');
      return;
    }
    List<VoidCallback> callbacksCopy = List.from(_updateCallbacks);
    for (var callback in callbacksCopy) {
      try {
        callback();
      } catch (e) {
        print('Error in update callback: $e');
      }
    }
    saveMatchToDatabase();
  }

  Map<String, dynamic> toDatabaseJson() {
    List<ScorecardStateSnapshot> historyToSave = stateHistory;
    if (stateHistory.length > _MAX_UNDO_HISTORY) {
      historyToSave = stateHistory.sublist(stateHistory.length - _MAX_UNDO_HISTORY);
    }

    return {
      'id': matchId,
      'matchDetails': jsonEncode({
        'matchId': matchId,
        'team1Name': team1Name,
        'team2Name': team2Name,
        'firstInningBattingTeamName': firstInningBattingTeamName,
        'totalMatchOvers': totalMatchOvers,
        'tossWinner': tossWinner,
        'choice': choice,
        'totalRuns': totalRuns,
        'totalWickets': totalWickets,
        'currentOvers': currentOvers,
        'currentInnings': currentInnings,
        'target': target,
        'requiredRunRate': requiredRunRate.isFinite ? requiredRunRate : 0.0,
        'currentRunRate': currentRunRate.isFinite ? currentRunRate : 0.0,
        'firstInningScore': firstInningScore,
        'firstInningOuts': firstInningOuts,
        'startFirstInning': startFirstInning,
        'striker': striker.toJson(),
        'nonStriker': nonStriker.toJson(),
        'currentBowler': currentBowler.toJson(),
        'allBatsmen': allBatsmen.map((b) => b.toJson()).toList(),
        'allBowlers': allBowlers.map((b) => b.toJson()).toList(),
        'thisOverBalls': thisOverBalls.map((b) => b.toJson()).toList(),
        'overHistory': overHistory.map((b) => b.toJson()).toList(),
        'completedOversSummary': completedOversSummary.map((o) => o.toJson()).toList(),
        'innings1OverScores': innings1OverScores,
        'innings2OverScores': innings2OverScores,
        'isMatchComplete': isMatchComplete,
        'stateHistory': historyToSave.map((s) => s.toJson()).toList(),
        'validBallsInOver': validBallsInOver,
      }),
      'innings1Data': innings1Data != null ? jsonEncode(innings1Data!.toJson()) : null,
      'innings2Data': innings2Data != null ? jsonEncode(innings2Data!.toJson()) : null,
      'isComplete': isMatchComplete ? 1 : 0,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory ScorecardLogic.fromDatabaseJson(Map<String, dynamic> json,
      {required GlobalKey<NavigatorState> navigatorKey}) {
    final matchDetailsJson = jsonDecode(json['matchDetails'] as String);
    final logic = ScorecardLogic(navigatorKey: navigatorKey, matchId: json['id'] as String?);

    logic.team1Name = matchDetailsJson['team1Name'] ?? 'Team 1';
    logic.team2Name = matchDetailsJson['team2Name'] ?? 'Team 2';

    logic.firstInningBattingTeamName = matchDetailsJson['firstInningBattingTeamName'] ??
        matchDetailsJson['firstInningBattingTeam'] ??
        logic.team1Name;

    logic.totalMatchOvers = matchDetailsJson['totalMatchOvers'] ?? 20;
    logic.tossWinner = matchDetailsJson['tossWinner'];
    logic.choice = matchDetailsJson['choice'];
    logic.totalRuns = matchDetailsJson['totalRuns'] ?? 0;
    logic.totalWickets = matchDetailsJson['totalWickets'] ?? 0;
    logic.currentOvers = (matchDetailsJson['currentOvers'] ?? 0.0).toDouble();
    logic.currentInnings = matchDetailsJson['currentInnings'] ?? 1;

    logic.target = matchDetailsJson['target'] ?? matchDetailsJson['targetToChase'] ?? 0;

    logic.firstInningScore = matchDetailsJson['firstInningScore'];
    logic.firstInningOuts = matchDetailsJson['firstInningOuts'];
    logic.startFirstInning = matchDetailsJson['startFirstInning'] ?? true;

    logic.requiredRunRate = (matchDetailsJson['requiredRunRate'] ?? 0.0).toDouble();
    logic.currentRunRate = (matchDetailsJson['currentRunRate'] ?? 0.0).toDouble();
    logic.striker = Batsman.fromJson(matchDetailsJson['striker'] ?? {'name': 'Default Striker'});
    logic.nonStriker = Batsman.fromJson(matchDetailsJson['nonStriker'] ?? {'name': 'Default NonStriker'});
    logic.currentBowler = Bowler.fromJson(matchDetailsJson['currentBowler'] ?? {'name': 'Default Bowler'});
    logic.allBatsmen = (matchDetailsJson['allBatsmen'] as List?)?.map((item) => Batsman.fromJson(item)).toList() ?? [];
    logic.allBowlers = (matchDetailsJson['allBowlers'] as List?)?.map((item) => Bowler.fromJson(item)).toList() ?? [];
    logic.thisOverBalls = (matchDetailsJson['thisOverBalls'] as List?)?.map((item) => BallOutcome.fromJson(item)).toList() ?? [];
    logic.overHistory = (matchDetailsJson['overHistory'] as List?)?.map((item) => BallOutcome.fromJson(item)).toList() ?? [];
    logic.completedOversSummary =
        (matchDetailsJson['completedOversSummary'] as List?)?.map((item) => OverSummary.fromJson(item)).toList() ?? [];
    logic.innings1OverScores =
        (matchDetailsJson['innings1OverScores'] as List?)?.map((e) => Map<String, int>.from(e)).toList() ?? [];
    logic.innings2OverScores =
        (matchDetailsJson['innings2OverScores'] as List?)?.map((e) => Map<String, int>.from(e)).toList() ?? [];
    logic.isMatchComplete = matchDetailsJson['isMatchComplete'] ?? false;

    // Load Undo History (capped at 18 items max)
    logic.stateHistory =
        (matchDetailsJson['stateHistory'] as List?)?.map((e) => ScorecardStateSnapshot.fromJson(e)).toList() ?? [];

    logic.validBallsInOver = matchDetailsJson['validBallsInOver'] ?? 0;
    logic.innings1Data =
    json['innings1Data'] != null ? InningsData.fromJson(jsonDecode(json['innings1Data'])) : null;
    logic.innings2Data =
    json['innings2Data'] != null ? InningsData.fromJson(jsonDecode(json['innings2Data'])) : null;

    if (!logic.allBatsmen.any((b) => b.name == logic.striker.name)) {
      logic.allBatsmen.add(logic.striker);
    }
    if (!logic.allBatsmen.any((b) => b.name == logic.nonStriker.name)) {
      logic.allBatsmen.add(logic.nonStriker);
    }
    if (!logic.allBowlers.any((b) => b.name == logic.currentBowler.name)) {
      logic.allBowlers.add(logic.currentBowler);
    }

    return logic;
  }

  // --- UPDATED SAVE METHOD (FORCE OPTION ADDED) ---
  Future<void> saveMatchToDatabase({bool forceImmediate = false}) async {
    if (_isDisposed) return;

    if (forceImmediate) {
      if (_saveDebounce?.isActive ?? false) _saveDebounce!.cancel();
      try {
        final id = await DatabaseService().insertOrUpdateMatch(toDatabaseJson());
        if (matchId == null) {
          matchId = id;
        }
        print('Match $matchId FORCE SAVED.');
      } catch (e, stackTrace) {
        print('CRITICAL ERROR FORCE SAVING: $e');
        print(stackTrace);
      }
      return;
    }

    // Normal Debounce Logic
    if (_saveDebounce?.isActive ?? false) _saveDebounce!.cancel();

    _saveDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final id = await DatabaseService().insertOrUpdateMatch(toDatabaseJson());
        if (matchId == null) {
          matchId = id;
        }
        print('Match $matchId saved via debounce.');
      } catch (e, stackTrace) {
        print('CRITICAL ERROR saving match: $e');
        print(stackTrace);
      }
    });
  }

  static Future<ScorecardLogic> loadMatchFromDatabase(String matchId,
      {required GlobalKey<NavigatorState> navigatorKey}) async {
    final matchMap = await DatabaseService().getMatchState(matchId);
    if (matchMap != null) {
      print('Match $matchId loaded from database.');
      final logic = ScorecardLogic.fromDatabaseJson(matchMap, navigatorKey: navigatorKey);
      await logic.resumeMatchState();
      return logic;
    } else {
      throw Exception('Match with ID $matchId not found in database.');
    }
  }

  Future<void> resumeMatchState() async {
    if (isMatchComplete) {
      print('Match is complete, cannot resume.');
      return;
    }
    if (_isDisposed) {
      print('ScorecardLogic is disposed, cannot resume match state.');
      return;
    }
    try {
      striker = allBatsmen.firstWhere((b) => b.name == striker.name,
          orElse: () => Batsman(name: striker.name, isOnStrike: true));
      nonStriker = allBatsmen.firstWhere((b) => b.name == nonStriker.name,
          orElse: () => Batsman(name: nonStriker.name, isOnStrike: false));
      currentBowler = allBowlers.firstWhere((b) => b.name == currentBowler.name,
          orElse: () => Bowler(name: currentBowler.name));

      allBatsmen.forEach((b) {
        b.isOnStrike = (b.name == striker.name && striker.isOnStrike) || (b.name == nonStriker.name && nonStriker.isOnStrike);
      });

      validBallsInOver = thisOverBalls.where((ball) => ball.isLegalDelivery).length;
      calculateRunRates();
      // No immediate save needed on resume
      _notifyListeners();

      if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
        await showDialog(
          context: navigatorKey.currentContext!,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            backgroundColor: _darkPrimary,
            title: const Text('Scoring Resumed', style: TextStyle(color: _whiteText)),
            content: Text('Match resumed. Undo available for last $_MAX_UNDO_HISTORY balls.', style: const TextStyle(color: _textSecondary)),
            actions: [
              TextButton(
                onPressed: () {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('OK', style: TextStyle(color: _yellowAccent)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error resuming match state: $e');
    }
  }

  Future<void> initializeMatchState(Map<String, dynamic> matchDetails) async {
    if (isMatchComplete) {
      print('Match is already complete, cannot initialize new match state.');
      return;
    }
    if (_isDisposed) {
      print('ScorecardLogic is disposed, cannot initialize match state.');
      return;
    }

    matchId = matchDetails['matchId'];

    team1Name = matchDetails['team1Name'] ?? 'Team 1';
    team2Name = matchDetails['team2Name'] ?? 'Team 2';
    totalMatchOvers = matchDetails['overs'] ?? 20;

    firstInningBattingTeamName = matchDetails['firstInningBattingTeam'] ??
        matchDetails['firstInningBattingTeamName'] ??
        team1Name;

    tossWinner = matchDetails['tossWinner'];
    choice = matchDetails['choice'];

    firstInningScore = matchDetails['firstInningScore'];
    firstInningOuts = matchDetails['firstInningOuts'];
    startFirstInning = matchDetails['startFirstInning'] ?? true;

    if (startFirstInning) {
      currentInnings = 1;
      totalRuns = 0;
      totalWickets = 0;
      currentOvers = 0.0;
      target = 0;
      striker = Batsman(name: "Batsman 1", isOnStrike: true);
      nonStriker = Batsman(name: "Batsman 2", isOnStrike: false);
      allBatsmen.clear();
      allBatsmen.add(striker);
      allBatsmen.add(nonStriker);
    } else {
      currentInnings = 2;
      totalRuns = 0;
      totalWickets = 0;
      currentOvers = 0.0;

      target = matchDetails['targetToChase'] ?? matchDetails['target'] ?? 0;

      striker = Batsman(name: "Batsman 3", isOnStrike: true);
      nonStriker = Batsman(name: "Batsman 4", isOnStrike: false);
      allBatsmen.clear();
      allBatsmen.add(striker);
      allBatsmen.add(nonStriker);
    }

    currentBowler = Bowler(name: "New Bowler 1");
    allBowlers.clear();
    allBowlers.add(currentBowler);

    thisOverBalls.clear();
    overHistory.clear();
    completedOversSummary.clear();
    innings1OverScores.clear();
    innings2OverScores.clear();
    stateHistory.clear();
    innings1Data = null;
    innings2Data = null;
    isMatchComplete = false;
    validBallsInOver = 0;
    isOverComplete = false;

    saveStateSnapshot();
    calculateRunRates();
    await saveCurrentInningsData();

    // --- FIX: Force save immediately on initialization ---
    await saveMatchToDatabase(forceImmediate: true);

    _notifyListeners();
  }

  InningsData? getInningsData(int inningsNumber) {
    if (inningsNumber == 1) return innings1Data;
    if (inningsNumber == 2) return innings2Data;
    return null;
  }

  List<Batsman> getBatsmenForInnings(int inningsNumber) {
    if (inningsNumber == currentInnings) {
      return List<Batsman>.from(allBatsmen);
    } else if (inningsNumber == 1 && innings1Data != null) {
      return List<Batsman>.from(innings1Data!.batsmen);
    } else if (inningsNumber == 2 && innings2Data != null) {
      return List<Batsman>.from(innings2Data!.batsmen);
    }
    return [];
  }

  List<Bowler> getBowlersForInnings(int inningsNumber) {
    List<Bowler> bowlers = [];
    if (inningsNumber == currentInnings) {
      bowlers = allBowlers;
    } else if (inningsNumber == 1 && innings1Data != null) {
      bowlers = innings1Data!.bowlers;
    } else if (inningsNumber == 2 && innings2Data != null) {
      bowlers = innings2Data!.bowlers;
    }
    return bowlers.where((bowler) => bowler.ballsBowled > 0).toList();
  }

  List<OverSummary> getCompletedOversForInnings(int inningsNumber) {
    if (inningsNumber == currentInnings) {
      return completedOversSummary;
    } else if (inningsNumber == 1 && innings1Data != null) {
      return innings1Data!.completedOvers;
    } else if (inningsNumber == 2 && innings2Data != null) {
      return innings2Data!.completedOvers;
    }
    return [];
  }

  Bowler? findExistingBowler(String bowlerName) {
    String normalizedName = bowlerName.trim().toLowerCase();
    for (Bowler bowler in allBowlers) {
      if (bowler.name.trim().toLowerCase() == normalizedName) {
        return bowler;
      }
    }
    return null;
  }

  Bowler getOrCreateBowler(String bowlerName) {
    Bowler? existingBowler = findExistingBowler(bowlerName);
    if (existingBowler != null) {
      return existingBowler;
    } else {
      Bowler newBowler = Bowler(name: bowlerName);
      allBowlers.add(newBowler);
      return newBowler;
    }
  }

  Future<void> saveCurrentInningsData() async {
    if (_isDisposed) {
      return;
    }
    if (currentInnings == 1) {
      innings1Data = InningsData(
        batsmen: List<Batsman>.from(allBatsmen.map((b) => Batsman.copy(b))),
        bowlers: List<Bowler>.from(allBowlers.map((b) => Bowler.copy(b))),
        completedOvers: List<OverSummary>.from(completedOversSummary.map((o) => OverSummary.copy(o))),
        overScores: List<Map<String, int>>.from(innings1OverScores.map((e) => Map<String, int>.from(e))),
        totalRuns: totalRuns,
        totalWickets: totalWickets,
        totalOvers: currentOvers,
      );
    } else if (currentInnings == 2) {
      innings2Data = InningsData(
        batsmen: List<Batsman>.from(allBatsmen.map((b) => Batsman.copy(b))),
        bowlers: List<Bowler>.from(allBowlers.map((b) => Bowler.copy(b))),
        completedOvers: List<OverSummary>.from(completedOversSummary.map((o) => OverSummary.copy(o))),
        overScores: List<Map<String, int>>.from(innings2OverScores.map((e) => Map<String, int>.from(e))),
        totalRuns: totalRuns,
        totalWickets: totalWickets,
        totalOvers: currentOvers,
      );
    }
    await saveMatchToDatabase();
    _notifyListeners();
  }

  int get totalOvers => totalMatchOvers;

  String getOversDisplay() {
    return 'Overs: ${currentOvers.toStringAsFixed(1)} / $totalOvers';
  }

  Future<bool> isInningsComplete() async {
    if (isMatchComplete) {
      return true;
    }
    if (_isDisposed) {
      return true;
    }

    bool inningsOver = false;
    if (totalWickets >= 10 || (currentOvers >= totalOvers && totalWickets < 10)) {
      inningsOver = true;
    }
    if (currentInnings == 2 && totalRuns >= target && target > 0) {
      inningsOver = true;
    }

    if (inningsOver) {
      if (currentInnings == 1) {
        await saveCurrentInningsData();
        currentInnings = 2;
        target = totalRuns + 1;
        totalRuns = 0;
        totalWickets = 0;
        currentOvers = 0.0;
        thisOverBalls.clear();
        overHistory.clear();
        completedOversSummary.clear();
        striker = Batsman(name: "Batsman 3", isOnStrike: true);
        nonStriker = Batsman(name: "Batsman 4", isOnStrike: false);
        allBatsmen = [striker, nonStriker];
        allBowlers.clear();
        currentBowler = Bowler(name: "New Bowler 2");
        allBowlers.add(currentBowler);
        validBallsInOver = 0;
        isOverComplete = false;
        saveStateSnapshot();
        calculateRunRates();
        await saveCurrentInningsData();
        _notifyListeners();

        if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
          await showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('1st Inning Complete!', style: TextStyle(color: _whiteText)),
              content: Text('Target for ${firstInningBattingTeamName == team1Name ? team2Name : team1Name} is $target runs.', style: const TextStyle(color: _textSecondary)),
              backgroundColor: _darkPrimary,
              actions: [
                TextButton(
                  onPressed: () {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Start 2nd Inning', style: TextStyle(color: _yellowAccent)),
                ),
              ],
            ),
          );
        }
        return true;
      } else if (currentInnings == 2) {
        await saveCurrentInningsData();
        isMatchComplete = true;
        await declareMatchResult();
        return true;
      }
    }
    return false;
  }

  Future<void> declareMatchResult() async {
    if (_isDisposed) {
      return;
    }

    String message;
    if (totalRuns >= target && target > 0) {
      String winningTeam = (firstInningBattingTeamName == team1Name) ? team2Name : team1Name;
      int wicketsRemaining = 10 - totalWickets;
      message = '$winningTeam wins by $wicketsRemaining wickets!';
    } else if (totalWickets >= 10 && totalRuns < target) {
      String winningTeam = firstInningBattingTeamName;
      int margin = target - totalRuns;
      message = '$winningTeam wins by $margin runs!';
    } else if (totalRuns == target - 1 && totalWickets >= 10) {
      message = 'Match Tied!';
    } else if (currentOvers >= totalOvers && totalRuns < target) {
      String winningTeam = firstInningBattingTeamName;
      int margin = target - totalRuns;
      message = '$winningTeam wins by $margin runs!';
    } else {
      message = 'Match Result: Not yet determined.';
    }

    isMatchComplete = true;
    stateHistory.clear();

    if (navigatorKey.currentContext == null || !navigatorKey.currentContext!.mounted) {
      return;
    }

    try {
      await showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: _darkPrimary,
          title: const Text('Match Over!', style: TextStyle(color: _whiteText)),
          content: Text(message, style: const TextStyle(color: _textSecondary)),
          actions: [
            TextButton(
              onPressed: () {
                if (!context.mounted) return;
                Navigator.pop(context);
                if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
                  Navigator.pushNamed(navigatorKey.currentContext!, '/score_book_main');
                }
              },
              child: const Text('OK', style: TextStyle(color: _yellowAccent)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing match result dialog: $e');
    }

    await saveCurrentInningsData();
    _notifyListeners();
  }

  Future<void> changeStrike() async {
    if (isMatchComplete || _isDisposed) return;

    striker.isOnStrike = false;
    nonStriker.isOnStrike = true;
    Batsman temp = striker;
    striker = nonStriker;
    nonStriker = temp;

    allBatsmen.forEach((b) {
      b.isOnStrike = (b.name == striker.name && striker.isOnStrike) || (b.name == nonStriker.name && nonStriker.isOnStrike);
    });

    saveCurrentInningsData();
    await saveMatchToDatabase();
    _notifyListeners();
  }

  bool shouldChangeStrike(int runs) {
    return runs % 2 != 0;
  }

  void saveStateSnapshot() {
    if (isMatchComplete || _isDisposed) return;

    stateHistory.add(ScorecardStateSnapshot(
      totalRuns: totalRuns,
      totalWickets: totalWickets,
      currentOvers: currentOvers,
      striker: Batsman.copy(striker),
      nonStriker: Batsman.copy(nonStriker),
      currentBowler: Bowler.copy(currentBowler),
      allBatsmen: List<Batsman>.from(allBatsmen.map((b) => Batsman.copy(b))),
      allBowlers: List<Bowler>.from(allBowlers.map((b) => Bowler.copy(b))),
      thisOverBalls: List<BallOutcome>.from(thisOverBalls),
      overHistory: List<BallOutcome>.from(overHistory),
      currentInnings: currentInnings,
      target: target,
      completedOversSummary: List<OverSummary>.from(completedOversSummary.map((o) => OverSummary.copy(o))),
      innings1OverScores: List<Map<String, int>>.from(innings1OverScores.map((e) => Map<String, int>.from(e))),
      innings2OverScores: List<Map<String, int>>.from(innings2OverScores.map((e) => Map<String, int>.from(e))),
      innings1Data: innings1Data != null
          ? InningsData(
        batsmen: List<Batsman>.from(innings1Data!.batsmen.map((b) => Batsman.copy(b))),
        bowlers: List<Bowler>.from(innings1Data!.bowlers.map((b) => Bowler.copy(b))),
        completedOvers: List<OverSummary>.from(innings1Data!.completedOvers.map((o) => OverSummary.copy(o))),
        overScores: List<Map<String, int>>.from(innings1Data!.overScores.map((e) => Map<String, int>.from(e))),
        totalRuns: innings1Data!.totalRuns,
        totalWickets: innings1Data!.totalWickets,
        totalOvers: innings1Data!.totalOvers,
      )
          : null,
      innings2Data: innings2Data != null
          ? InningsData(
        batsmen: List<Batsman>.from(innings2Data!.batsmen.map((b) => Batsman.copy(b))),
        bowlers: List<Bowler>.from(innings2Data!.bowlers.map((b) => Bowler.copy(b))),
        completedOvers: List<OverSummary>.from(innings2Data!.completedOvers.map((o) => OverSummary.copy(o))),
        overScores: List<Map<String, int>>.from(innings2Data!.overScores.map((e) => Map<String, int>.from(e))),
        totalRuns: innings2Data!.totalRuns,
        totalWickets: innings2Data!.totalWickets,
        totalOvers: innings2Data!.totalOvers,
      )
          : null,
    ));

    // --- RAM LIMIT ENFORCED HERE ---
    if (stateHistory.length > _MAX_UNDO_HISTORY) {
      stateHistory.removeAt(0);
    }
  }

  bool shouldAddRunsToBatsman(List<String>? extraTypes) {
    if (extraTypes == null || extraTypes.isEmpty) return true;
    return extraTypes.contains('noball');
  }

  bool shouldAddRunsToBowler(List<String>? extraTypes) {
    if (extraTypes == null || extraTypes.isEmpty) return true;
    if (extraTypes.contains('legbye') || extraTypes.contains('bye')) {
      return false;
    }
    return true;
  }

  bool shouldCreditWicketToBowler(String? wicketMethod) {
    if (wicketMethod == null) return false;
    List<String> bowlerWickets = ['Bowled', 'Caught', 'LBW', 'Hit Wicket', 'Stumped'];
    return bowlerWickets.contains(wicketMethod);
  }

  bool shouldAddBallToBatsman(List<String>? extraTypes) {
    if (extraTypes == null || extraTypes.isEmpty) return true;
    if (extraTypes.contains('noball')) {
      return true;
    }
    if (extraTypes.contains('wide')) {
      return false;
    }
    return true;
  }

  String createDisplayString({
    required int totalRunsOnBall,
    List<String>? extraTypes,
    bool isWicket = false,
    String? wicketMethod,
  }) {
    List<String> displayParts = [];
    if (extraTypes != null && extraTypes.isNotEmpty) {
      for (String extraType in extraTypes) {
        if (extraType == 'wide') displayParts.add('wd');
        if (extraType == 'noball') displayParts.add('nb');
        if (extraType == 'legbye') displayParts.add('lb');
        if (extraType == 'bye') displayParts.add('b');
      }
    }
    if (isWicket) {
      displayParts.add('W');
    }

    int runsToDisplayNumerically = totalRunsOnBall;
    if (extraTypes != null) {
      if (extraTypes.contains('wide')) {
        runsToDisplayNumerically -= 1;
      }
      if (extraTypes.contains('noball')) {
        runsToDisplayNumerically -= 1;
      }
    }

    if (runsToDisplayNumerically > 0) {
      displayParts.add(runsToDisplayNumerically.toString());
    } else if (!isWicket && (extraTypes == null || extraTypes.isEmpty)) {
      if (displayParts.isEmpty) {
        return '•';
      }
    }
    return displayParts.join('+');
  }

  void addNewBowler(String name) async {
    if (isMatchComplete || _isDisposed) return;

    currentBowler = getOrCreateBowler(name);
    validBallsInOver = 0;
    thisOverBalls.clear();
    isOverComplete = false;
    await saveCurrentInningsData();
    await saveMatchToDatabase();
    _notifyListeners();
  }

  void addNewBatsman(String name) async {
    if (isMatchComplete || _isDisposed) return;

    bool isStrikerOut = striker.isOut;
    bool isNonStrikerOut = nonStriker.isOut;

    Batsman newBatsman = Batsman(name: name, isOnStrike: isStrikerOut);
    allBatsmen.add(newBatsman);

    if (isStrikerOut) {
      striker = newBatsman;
    } else if (isNonStrikerOut) {
      nonStriker = newBatsman;
    }

    await saveCurrentInningsData();
    await saveMatchToDatabase();
    _notifyListeners();
  }

  Future<void> scoreBall({
    int runs = 0,
    List<String>? extraTypes,
    int extraRuns = 0,
    bool isWicket = false,
    String? wicketMethod,
    String? fielderName,
    String? outBatsmanName,
  }) async {
    if (isMatchComplete || _isDisposed) return;

    String? dismissalDetailString;
    int runsFromBat = 0;
    int totalExtraRuns = 0;
    int runsForBowler = 0;
    bool isLegalDelivery = true;

    if (extraTypes != null && extraTypes.isNotEmpty) {
      bool isWide = extraTypes.contains('wide');
      bool isNoball = extraTypes.contains('noball');
      bool isLegbye = extraTypes.contains('legbye');
      bool isBye = extraTypes.contains('bye');

      if (isNoball && !isWide && !isLegbye && !isBye) {
        runsFromBat = runs;
      } else {
        runsFromBat = 0;
      }

      if (isWide) {
        totalExtraRuns += (1 + runs);
        runsForBowler += (1 + runs);
        isLegalDelivery = false;
      }
      if (isNoball) {
        totalExtraRuns += 1;
        runsForBowler += 1;
        isLegalDelivery = false;
      }
      if (isLegbye || isBye) {
        totalExtraRuns += runs;
      }
    } else {
      runsFromBat = runs;
      runsForBowler = runs;
    }

    int totalRunsOnBall = runsFromBat + totalExtraRuns;
    totalRuns += totalRunsOnBall;

    if (isWicket) {
      totalWickets += 1;
      if (shouldCreditWicketToBowler(wicketMethod)) {
        currentBowler.addWicket();
      }

      if (wicketMethod == 'Run Out') {
        String? selectedBatsmanName = outBatsmanName;
        if (selectedBatsmanName == null) {
          selectedBatsmanName = striker.name;
        }

        if (selectedBatsmanName != null && selectedBatsmanName.isNotEmpty) {
          Batsman? outBatsman = allBatsmen.firstWhere(
                (b) => b.name == selectedBatsmanName && !b.isOut,
            orElse: () => striker,
          );
          outBatsman.isOut = true;
          outBatsman.dismissalMethod = 'Run Out';
          String? fielder = fielderName ?? 'Fielder';
          dismissalDetailString = 'run out ($fielder)';
          outBatsman.dismissalDetails = dismissalDetailString;
        }
      } else if (wicketMethod == 'Caught') {
        String? fielder = fielderName ?? 'Fielder';
        dismissalDetailString = 'c $fielder b ${currentBowler.name}';
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      } else if (wicketMethod == 'Bowled') {
        dismissalDetailString = 'b ${currentBowler.name}';
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      } else if (wicketMethod == 'LBW') {
        dismissalDetailString = 'lbw b ${currentBowler.name}';
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      } else if (wicketMethod == 'Stumped') {
        String? keeper = fielderName ?? 'Wicket-Keeper';
        dismissalDetailString = 'st $keeper b ${currentBowler.name}';
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      } else if (wicketMethod == 'Hit Wicket') {
        dismissalDetailString = 'hw b ${currentBowler.name}';
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      } else if (wicketMethod == 'Obstructing the field') {
        dismissalDetailString = 'obstructing the field';
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      } else if (wicketMethod == 'Handled the ball') {
        dismissalDetailString = 'handled the ball';
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      } else if (wicketMethod == 'Timed Out') {
        dismissalDetailString = 'timed out';
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      } else if (wicketMethod == 'Retired Hurt' || wicketMethod == 'Retired Out') {
        dismissalDetailString = wicketMethod?.toLowerCase().replaceAll(' ', '');
        striker.dismissalDetails = dismissalDetailString;
        striker.isOut = true;
        striker.isOnStrike = false;
      }
    }

    if (shouldAddRunsToBatsman(extraTypes)) {
      striker.addRuns(runsFromBat);
    }
    if (shouldAddRunsToBowler(extraTypes)) {
      currentBowler.addRuns(runsForBowler);
    }

    if (shouldAddBallToBatsman(extraTypes) && isLegalDelivery) {
      striker.addBall();
      currentBowler.addBall();
      validBallsInOver++;
    } else if (extraTypes != null && extraTypes.contains('noball')) {
      striker.addBall();
    }

    String display = createDisplayString(
      totalRunsOnBall: totalRunsOnBall,
      extraTypes: extraTypes,
      isWicket: isWicket,
      wicketMethod: wicketMethod,
    );
    BallOutcome newBallOutcome = BallOutcome(
      runs: runsFromBat,
      isWicket: isWicket,
      extraTypes: extraTypes,
      extraRuns: totalExtraRuns,
      isLegalDelivery: isLegalDelivery,
      display: display,
      wicketMethod: wicketMethod,
      dismissalDetails: dismissalDetailString,
    );
    thisOverBalls.add(newBallOutcome);
    overHistory.add(newBallOutcome);
    lastStrikeChanged = false;

    int currentOverNumber = (currentOvers ~/ 1) + 1;
    int runsInCurrentOver = 0;
    int wicketsInCurrentOver = 0;
    for (var ball in thisOverBalls) {
      runsInCurrentOver += ball.runs + ball.extraRuns;
      if (ball.isWicket) wicketsInCurrentOver += 1;
    }

    int currentOverIndex = completedOversSummary.indexWhere((over) => over.overNumber == currentOverNumber);

    if (currentOverIndex != -1) {
      completedOversSummary[currentOverIndex] = OverSummary(
        overNumber: currentOverNumber,
        bowlerName: currentBowler.name,
        runsScoredInOver: runsInCurrentOver,
        wicketsTakenInOver: wicketsInCurrentOver,
        ballDetails: List<BallOutcome>.from(thisOverBalls),
      );
    } else {
      completedOversSummary.add(OverSummary(
        overNumber: currentOverNumber,
        bowlerName: currentBowler.name,
        runsScoredInOver: runsInCurrentOver,
        wicketsTakenInOver: wicketsInCurrentOver,
        ballDetails: List<BallOutcome>.from(thisOverBalls),
      ));
    }

    bool shouldStrikeChangeBasedOnRuns = false;
    if (extraTypes != null && extraTypes.isNotEmpty) {
      shouldStrikeChangeBasedOnRuns = shouldChangeStrike(runs);
    } else {
      shouldStrikeChangeBasedOnRuns = shouldChangeStrike(runsFromBat);
    }

    if (shouldStrikeChangeBasedOnRuns && !isWicket) {
      changeStrike();
      lastStrikeChanged = true;
    }

    if (isLegalDelivery) {
      if (validBallsInOver >= 6) {
        if (currentInnings == 1) {
          innings1OverScores.add({'overs': currentOverNumber, 'runs': totalRuns, 'wickets': totalWickets});
        } else {
          innings2OverScores.add({'overs': currentOverNumber, 'runs': totalRuns, 'wickets': totalWickets});
        }

        currentOvers = (currentOvers ~/ 1) + 1.0;

        if (currentBowler.runsGiven == 0 &&
            currentBowler.wickets == 0 &&
            thisOverBalls.every((ball) => ball.extraRuns == 0)) {
          currentBowler.maidens += 1;
        }

        thisOverBalls.clear();
        validBallsInOver = 0;
        isOverComplete = true;

        changeStrike();
        lastStrikeChanged = true;
      } else {
        currentOvers = (currentOvers ~/ 1) + (validBallsInOver / 10.0);
      }
    }

    calculateRunRates();
    selectedExtraType = null;
    selectedWicketMethod = null;
    await saveCurrentInningsData();
    await isInningsComplete();
    saveStateSnapshot();
    _notifyListeners();
  }

  List<BallOutcome> getUserInputBallsThisOver() {
    return thisOverBalls;
  }

  Future<void> undoLastBall() async {
    if (isMatchComplete || _isDisposed) return;

    if (stateHistory.length <= 1) {
      print("Cannot undo further.");
      return;
    }

    final int currentInningsNow = stateHistory.last.currentInnings;
    final int boundaryIndex = stateHistory.indexWhere((s) => s.currentInnings == currentInningsNow);
    if (boundaryIndex != -1) {
      final int prevIndex = stateHistory.length - 2;
      if (prevIndex < boundaryIndex) {
        return;
      }
    }

    stateHistory.removeLast();
    ScorecardStateSnapshot lastState = stateHistory.last;

    totalRuns = lastState.totalRuns;
    totalWickets = lastState.totalWickets;
    currentOvers = lastState.currentOvers;
    currentInnings = lastState.currentInnings;
    target = lastState.target;
    allBatsmen = List<Batsman>.from(lastState.allBatsmen.map((b) => Batsman.copy(b)));
    allBowlers = List<Bowler>.from(lastState.allBowlers.map((b) => Bowler.copy(b)));
    thisOverBalls = List<BallOutcome>.from(lastState.thisOverBalls);
    overHistory = List<BallOutcome>.from(lastState.overHistory);
    completedOversSummary = List<OverSummary>.from(lastState.completedOversSummary.map((o) => OverSummary.copy(o)));
    innings1OverScores = List<Map<String, int>>.from(lastState.innings1OverScores.map((e) => Map<String, int>.from(e)));
    innings2OverScores = List<Map<String, int>>.from(lastState.innings2OverScores.map((e) => Map<String, int>.from(e)));
    validBallsInOver = thisOverBalls.where((ball) => ball.isLegalDelivery).length;
    isOverComplete = false;

    try {
      striker = allBatsmen.firstWhere((b) => b.name == lastState.striker.name);
      nonStriker = allBatsmen.firstWhere((b) => b.name == lastState.nonStriker.name);
      currentBowler = allBowlers.firstWhere((b) => b.name == lastState.currentBowler.name);
    } catch (e) {
      striker = Batsman(name: "Fallback Striker", isOnStrike: true);
      nonStriker = Batsman(name: "Fallback NonStriker", isOnStrike: false);
      currentBowler = Bowler(name: "Fallback Bowler");
    }

    allBatsmen.forEach((b) {
      if (b.name == striker.name) {
        b.isOnStrike = true;
      } else if (b.name == nonStriker.name) {
        b.isOnStrike = false;
      } else {
        b.isOnStrike = false;
      }
    });

    innings1Data = lastState.innings1Data != null
        ? InningsData(
      batsmen: List<Batsman>.from(lastState.innings1Data!.batsmen.map((b) => Batsman.copy(b))),
      bowlers: List<Bowler>.from(lastState.innings1Data!.bowlers.map((b) => Bowler.copy(b))),
      completedOvers: List<OverSummary>.from(lastState.innings1Data!.completedOvers.map((o) => OverSummary.copy(o))),
      overScores: List<Map<String, int>>.from(lastState.innings1Data!.overScores.map((e) => Map<String, int>.from(e))),
      totalRuns: lastState.innings1Data!.totalRuns,
      totalWickets: lastState.innings1Data!.totalWickets,
      totalOvers: lastState.innings1Data!.totalOvers,
    )
        : null;
    innings2Data = lastState.innings2Data != null
        ? InningsData(
      batsmen: List<Batsman>.from(lastState.innings2Data!.batsmen.map((b) => Batsman.copy(b))),
      bowlers: List<Bowler>.from(lastState.innings2Data!.bowlers.map((b) => Bowler.copy(b))),
      completedOvers: List<OverSummary>.from(lastState.innings2Data!.completedOvers.map((o) => OverSummary.copy(o))),
      overScores: List<Map<String, int>>.from(lastState.innings2Data!.overScores.map((e) => Map<String, int>.from(e))),
      totalRuns: lastState.innings2Data!.totalRuns,
      totalWickets: lastState.innings2Data!.totalWickets,
      totalOvers: lastState.innings2Data!.totalOvers,
    )
        : null;

    calculateRunRates();
    await saveMatchToDatabase();
    _notifyListeners();
  }

  void calculateRunRates() async {
    if (isMatchComplete || _isDisposed) return;

    // 1. Calculate Total Legal Balls delivered so far
    int completedOvers = currentOvers.floor(); // e.g., 4.2 -> 4
    int ballsInCurrentOver = ((currentOvers - completedOvers) * 10).round(); // e.g., 0.2 -> 2
    int totalBallsDelivered = (completedOvers * 6) + ballsInCurrentOver;

    // 2. CRR Formula: (Runs / Balls Delivered) * 6
    if (totalBallsDelivered > 0) {
      currentRunRate = (totalRuns / totalBallsDelivered) * 6;
    } else {
      currentRunRate = 0.0;
    }

    // 3. RRR Formula: (Runs Needed / Balls Remaining) * 6
    if (currentInnings == 2 && target > 0) {
      int runsNeeded = target - totalRuns;
      int totalBallsInMatch = totalMatchOvers * 6;
      int ballsRemaining = totalBallsInMatch - totalBallsDelivered;

      if (ballsRemaining > 0) {
        if (runsNeeded <= 0) {
          requiredRunRate = 0.0;
        } else {
          requiredRunRate = (runsNeeded / ballsRemaining) * 6;
        }
      } else {
        requiredRunRate = 0.0;
      }
    } else {
      requiredRunRate = 0.0;
    }

    await saveCurrentInningsData();
    await saveMatchToDatabase();
    _notifyListeners();
  }

  Future<void> editBatsmanName(Batsman batsman, String newName) async {
    if (isMatchComplete || _isDisposed) return;
    batsman.name = newName;
    await saveCurrentInningsData();
    await saveMatchToDatabase();
    _notifyListeners();
  }

  Future<void> editBowlerName(Bowler bowler, String newName) async {
    if (isMatchComplete || _isDisposed) return;
    bowler.name = newName;
    await saveCurrentInningsData();
    await saveMatchToDatabase();
    _notifyListeners();
  }

  Future<String> _getNewBatsmanName() async {
    if (isMatchComplete) return 'No New Batsman';
    if (_isDisposed) return 'New Batsman ${allBatsmen.length + 1}';
    final newName = 'Batsman ${allBatsmen.length + 1}';
    await saveCurrentInningsData();
    return newName;
  }

  Future<String> _getFielderName({String prompt = 'Enter Fielder Name'}) async {
    return 'Fielder';
  }

  void onNumberButtonPressed(int runs) async {
    if (isMatchComplete || _isDisposed) return;
    await scoreBall(runs: runs);
  }
}