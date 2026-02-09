import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:stump_vision/common/splash.dart';
import 'package:stump_vision/common/login.dart';
import 'package:stump_vision/common/sign up.dart';
import 'package:stump_vision/common/reset_password.dart';
import 'package:stump_vision/common/info.dart';
import 'package:stump_vision/common/profile.dart';
import 'package:stump_vision/live_score/live_score.dart';
import 'package:stump_vision/score_book/score_book_main.dart';
import 'package:stump_vision/score_book/new_match.dart';
import 'package:stump_vision/score_book/scoring_screen.dart';
import 'package:stump_vision/score_book/open_existing_score_book.dart';
import 'package:stump_vision/score_book/scoring/scorecard_logic.dart';
import 'package:stump_vision/score_book/scoring/full_match_summary.dart';
import 'package:stump_vision/drs/drs_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Professional Setup
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Stump Vision',

      // --- THEME ---
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFFCFB04),
        scaffoldBackgroundColor: const Color(0xFF1F1F1F),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFFCFB04),
          secondary: const Color(0xFFFCFB04),
          surface: const Color(0xFF333333),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),

      initialRoute: '/',

      // --- DYNAMIC ROUTES HANDLING ---
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {

        // 1. Profile Screen
          case '/profile':
            final playerInfo = (args is Map<String, dynamic>) ? args : null;
            return MaterialPageRoute(
              builder: (_) => ProfileScreen(playerInfo: playerInfo),
            );

        // 2. Info Screen
          case '/info':
            if (args is String) {
              return MaterialPageRoute(
                builder: (_) => PlayerInfoScreen(userEmail: args),
              );
            }
            // Fallback (Avoid Error)
            return MaterialPageRoute(builder: (_) => const PlayerInfoScreen(userEmail: ''));

        // 3. Scoring Screen
          case '/scoring_screen':
            if (args is Map<String, dynamic> && args.containsKey('matchDetails')) {
              return MaterialPageRoute(
                builder: (_) => CricketScoringScreen(
                  matchDetails: args['matchDetails'],
                  matchId: args['matchId'] as String?,
                  scorecardLogicInstance: args['scorecard_logic_instance'] as ScorecardLogic?,
                ),
              );
            }
            return MaterialPageRoute(builder: (_) => const ErrorScreen(msg: 'Match details missing.'));

        // 4. Full Match Summary
          case '/full_match_summary':
            if (args is Map<String, dynamic> && args.containsKey('match')) {
              return MaterialPageRoute(
                builder: (_) => FullScorecardSavedScreen(match: args['match']),
              );
            }
            return MaterialPageRoute(builder: (_) => const ErrorScreen(msg: 'Match data missing.'));

          default:
            return null;
        }
      },

      // --- STATIC ROUTES ---
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const Login(),
        '/signup': (context) => const SignUp(),
        '/reset_password': (context) => const ForgotPasswordScreen(),
        '/live_score': (context) => const LiveScoreScreen(),

        // --- DRS SCREEN ROUTE ADDED HERE ---
        '/drs_screen': (context) => const DRSScreen(),

        '/score_book_main': (context) => const ScoreBookHomeScreen(),
        '/new_match': (context) => const NewMatch(),
        '/open_existing_score_book': (context) {
          return OpenExistingScoreBookScreen(
            onResumeScoring: (scorecard) {
              if (scorecard['id'] == null || scorecard['matchDetails'] == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid match data.')));
                return;
              }
              Navigator.pushNamed(
                context,
                '/scoring_screen',
                arguments: {
                  'matchDetails': jsonDecode(scorecard['matchDetails'] ?? '{}'),
                  'matchId': scorecard['id'] as String,
                  'scorecard_logic_instance': ScorecardLogic.fromDatabaseJson(scorecard, navigatorKey: MyApp.navigatorKey),
                },
              );
            },
          );
        },
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String msg;
  const ErrorScreen({super.key, required this.msg});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Error")),
      body: Center(child: Text(msg, style: const TextStyle(color: Colors.red))),
    );
  }
}