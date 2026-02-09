import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gal/gal.dart'; // NEW PACKAGE: Gal (Best for saving images)

// --- SCREEN THEME CONSTANTS ---
const Color _darkPrimary = Color(0xFF2C2C2C);
const Color _darkSecondary = Color(0xFF1E1E1E);
const Color _background = Color(0xFF121212);
const Color _yellowAccent = Color(0xFFFDD835);
const Color _whiteText = Colors.white;
const Color _textSecondary = Color(0xFFB0BEC5);
const Color _rowHighlight = Color(0xFF383838);
const Color _wicketRed = Color(0xFFFF5252);
const Color _boundaryGreen = Color(0xFF69F0AE);
const Color _sixPurple = Color(0xFFE040FB);
const Color _extraOrange = Color(0xFFFFAB40);

class FullScorecardSavedScreen extends StatelessWidget {
  final Map<String, dynamic> match;

  // GlobalKey for Image Capture
  final GlobalKey _globalKey = GlobalKey();

  FullScorecardSavedScreen({super.key, required this.match});

  // ---------- Helpers ----------
  int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse('$v') ?? fallback;
  }

  double _asDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }

  String _asString(dynamic v, [String fallback = '']) {
    if (v is String) return v;
    return v?.toString() ?? fallback;
  }

  // ==========================================================================
  // ===================== 1. IMAGE SUMMARY LOGIC & UI ========================
  // ==========================================================================

  List<Map<String, dynamic>> _getTopBatters(List<dynamic> batsmen) {
    List<Map<String, dynamic>> list = batsmen.map((e) => Map<String, dynamic>.from(e)).toList();
    list.sort((a, b) {
      int runsA = _asInt(a['runs']);
      int runsB = _asInt(b['runs']);
      if (runsB != runsA) return runsB.compareTo(runsA);
      int ballsA = _asInt(a['balls']);
      int ballsB = _asInt(b['balls']);
      double srA = ballsA > 0 ? (runsA / ballsA) * 100 : 0.0;
      double srB = ballsB > 0 ? (runsB / ballsB) * 100 : 0.0;
      return srB.compareTo(srA);
    });
    return list.take(3).toList();
  }

  List<Map<String, dynamic>> _getTopBowlers(List<dynamic> bowlers) {
    List<Map<String, dynamic>> list = bowlers.map((e) => Map<String, dynamic>.from(e)).toList();
    list.sort((a, b) {
      int wA = _asInt(a['wickets']);
      int wB = _asInt(b['wickets']);
      if (wB != wA) return wB.compareTo(wA);
      int ballsA = _asInt(a['ballsBowled']);
      int runsA = _asInt(a['runsGiven']);
      int ballsB = _asInt(b['ballsBowled']);
      int runsB = _asInt(b['runsGiven']);
      double ecoA = ballsA > 0 ? (runsA / ballsA) * 6 : 0.0;
      double ecoB = ballsB > 0 ? (runsB / ballsB) * 6 : 0.0;
      return ecoA.compareTo(ecoB);
    });
    return list.take(3).toList();
  }

  // --- UPDATED: SAVE TO GALLERY FUNCTION (USING GAL) ---
  Future<void> _captureAndSavePng() async {
    try {
      // 1. Permission (Gal handles permissions smartly, but request just in case)
      // Only needed for older Android versions mostly
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // 2. Capture Widget
      RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // High Quality (PixelRatio 4.0)
      ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 3. SAVE DIRECTLY TO GALLERY using GAL (Modern & Fast)
      final now = DateTime.now();
      final String fileName = "StumpVision_Summary_${now.millisecondsSinceEpoch}.png";

      // This saves to the gallery/photos app directly
      await Gal.putImageBytes(pngBytes, name: fileName);

      // 4. Notify User
      Fluttertoast.showToast(msg: "Image Saved to Gallery!", toastLength: Toast.LENGTH_LONG, backgroundColor: Colors.green);

    } catch (e) {
      debugPrint(e.toString());
      Fluttertoast.showToast(msg: "Failed to save: $e", backgroundColor: Colors.red);
    }
  }

  void _showSummaryPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _globalKey,
                child: _buildProfessionalSummaryCard(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _captureAndSavePng();
                    },
                    backgroundColor: _yellowAccent,
                    label: const Text("Save to Gallery", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.black),
                  ),
                  const SizedBox(width: 15),
                  CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW PROFESSIONAL UI FOR IMAGE (Signature Removed) ---
  Widget _buildProfessionalSummaryCard() {
    final matchDetails = Map<String, dynamic>.from(match['matchDetails'] ?? {});
    final innings1 = Map<String, dynamic>.from(match['innings1Data'] ?? {});
    final innings2 = Map<String, dynamic>.from(match['innings2Data'] ?? {});

    final team1Name = _asString(matchDetails['team1Name'], 'Team 1');
    final team2Name = _asString(matchDetails['team2Name'], 'Team 2');
    final innings1Team = _asString(matchDetails['firstInningBattingTeamName'], team1Name);
    final innings2Team = (innings1Team == team1Name) ? team2Name : team1Name;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkPrimary, Colors.black],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellowAccent.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_cricket_rounded, color: _yellowAccent, size: 28),
                const SizedBox(width: 10),
                const Text("STUMP VISION", style: TextStyle(color: _yellowAccent, letterSpacing: 2, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                const Spacer(),
                const Text("MATCH SUMMARY", style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Match Info
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(team1Name.toUpperCase(), style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 14)),
                const Text("VS", style: TextStyle(color: _yellowAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(team2Name.toUpperCase(), style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Innings 1
          _buildProInningsSection(innings1, innings1Team, true),

          // Innings 2
          if(innings2.isNotEmpty || _asInt(matchDetails['currentInnings']) == 2) ...[
            const Divider(color: Colors.white12, height: 1),
            _buildProInningsSection(innings2, innings2Team, false),
          ],

          const Divider(color: Colors.white12, height: 1),

          // Footer (Centered)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(color: _yellowAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text("Generated by Stump Vision App", style: TextStyle(color: _yellowAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProInningsSection(Map<String, dynamic> innings, String teamName, bool isFirstInnings) {
    int runs = _asInt(innings['totalRuns']);
    int wkts = _asInt(innings['totalWickets']);
    double overs = _asDouble(innings['totalOvers']);

    final topBatters = _getTopBatters(innings['batsmen'] as List? ?? []);
    final topBowlers = _getTopBowlers(innings['bowlers'] as List? ?? []);

    return Column(
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFirstInnings
                    ? [_darkSecondary, _darkPrimary]
                    : [_darkPrimary, _darkSecondary],
              ),
              border: const Border(left: BorderSide(color: _yellowAccent, width: 4))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(teamName.toUpperCase(), style: const TextStyle(color: _whiteText, fontWeight: FontWeight.w800, fontSize: 16)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text("$runs", style: const TextStyle(color: _whiteText, fontWeight: FontWeight.w900, fontSize: 24)),
                  Text("/$wkts", style: const TextStyle(color: _yellowAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(width: 5),
                  Text("(${overs} ov)", style: const TextStyle(color: _textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        // Stats
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black.withOpacity(0.2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Batters
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatHeader(Icons.sports_baseball, "TOP BATTERS"),
                    if(topBatters.isEmpty) const Text("No data", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ...topBatters.map((b) => _buildBetterPlayerRow(
                        name: _asString(b['name']),
                        mainStat: "${_asInt(b['runs'])}",
                        subStat: "(${_asInt(b['balls'])})",
                        isBowler: false
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              // Bowlers
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatHeader(Icons.sports_cricket, "TOP BOWLERS"),
                    if(topBowlers.isEmpty) const Text("No data", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ...topBowlers.map((b) {
                      int balls = _asInt(b['ballsBowled']);
                      double ov = (balls ~/ 6) + ((balls % 6) / 10.0);
                      return _buildBetterPlayerRow(
                          name: _asString(b['name']),
                          mainStat: "${_asInt(b['wickets'])}",
                          subStat: "/${_asInt(b['runsGiven'])} (${ov}ov)",
                          isBowler: true
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _textSecondary),
          const SizedBox(width: 5),
          Text(title, style: const TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBetterPlayerRow({required String name, required String mainStat, required String subStat, required bool isBowler}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(color: _whiteText, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          Text(mainStat, style: const TextStyle(color: _yellowAccent, fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(width: 3),
          Text(subStat, style: const TextStyle(color: _textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  // ==========================================================================
  // ===================== 2. DARK THEME PDF GENERATION =======================
  // ==========================================================================

  static const PdfColor _pdfBg = PdfColor.fromInt(0xFF121212);
  static const PdfColor _pdfCard = PdfColor.fromInt(0xFF2C2C2C);
  static const PdfColor _pdfYellow = PdfColor.fromInt(0xFFFDD835);
  static const PdfColor _pdfWhite = PdfColors.white;
  static const PdfColor _pdfGreyText = PdfColor.fromInt(0xFFB0BEC5);
  static const PdfColor _pdfGreen = PdfColor.fromInt(0xFF69F0AE);
  static const PdfColor _pdfRedText = PdfColor.fromInt(0xFFFF5252);

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) status = await Permission.storage.request();

      final pdfFile = await _generatePdf();
      await OpenFile.open(pdfFile.path);
      Fluttertoast.showToast(msg: "PDF saved to ${pdfFile.path}", toastLength: Toast.LENGTH_LONG);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to save PDF: $e", toastLength: Toast.LENGTH_LONG, backgroundColor: Colors.red);
    }
  }

  Future<File> _generatePdf() async {
    final matchDetails = Map<String, dynamic>.from(match['matchDetails'] ?? {});
    final innings1 = Map<String, dynamic>.from(match['innings1Data'] ?? {});
    final innings2 = Map<String, dynamic>.from(match['innings2Data'] ?? {});

    final team1Name = _asString(matchDetails['team1Name'], 'Team 1');
    final team2Name = _asString(matchDetails['team2Name'], 'Team 2');

    final innings1BattingTeamName = _asString(matchDetails['firstInningBattingTeamName'],
        _asString(matchDetails['firstInningBattingTeam'], team1Name));
    final innings2BattingTeamName = (innings1BattingTeamName == team1Name) ? team2Name : team1Name;

    final now = DateTime.now();
    final dateString = '${now.day}-${now.month}-${now.year}';

    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      buildBackground: (context) => pw.FullPage(ignoreMargins: true, child: pw.Container(color: _pdfBg)),
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    // Page 1: Innings 1
    pdf.addPage(pw.MultiPage(
      maxPages: 100,
      pageTheme: pageTheme,
      build: (context) => [
        _buildPdfMatchHeader(team1Name, team2Name, dateString),
        pw.SizedBox(height: 15),
        _buildPdfInningsSection(innings1, "1st Innings", innings1BattingTeamName, matchDetailsFallback: matchDetails),
        pw.SizedBox(height: 20),
        pw.Divider(color: _pdfGreyText, thickness: 0.5),
        pw.Center(child: pw.Text("Page 1 - Powered by Stump Vision", style: const pw.TextStyle(color: _pdfGreyText, fontSize: 8))),
      ],
    ));

    // Page 2: Innings 2 (if exists)
    if (innings2.isNotEmpty || _asInt(matchDetails['currentInnings']) == 2) {
      pdf.addPage(pw.MultiPage(
        maxPages: 100,
        pageTheme: pageTheme,
        build: (context) => [
          _buildPdfMatchHeader(team1Name, team2Name, dateString),
          pw.SizedBox(height: 15),
          _buildPdfInningsSection(innings2, "2nd Innings", innings2BattingTeamName),
          pw.SizedBox(height: 20),
          pw.Divider(color: _pdfGreyText, thickness: 0.5),
          pw.Center(child: pw.Text("Page 2 - Powered by Stump Vision", style: const pw.TextStyle(color: _pdfGreyText, fontSize: 8))),
        ],
      ));
    }

    final directory = await _getDownloadDirectory();
    final cleanTeam1 = team1Name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final cleanTeam2 = team2Name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final filePath = '${directory.path}/${cleanTeam1}_vs_${cleanTeam2}_Scorecard.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildPdfMatchHeader(String t1, String t2, String date) {
    return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: _pdfCard,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: _pdfGreyText, width: 0.5),
        ),
        child: pw.Column(
            children: [
              pw.Text("MATCH SUMMARY", style: pw.TextStyle(color: _pdfGreyText, fontSize: 10, letterSpacing: 2, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPdfTeamAvatar(t1),
                    pw.Column(children: [
                      pw.Text("VS", style: pw.TextStyle(color: _pdfYellow, fontSize: 24, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 4),
                      pw.Text(date, style: const pw.TextStyle(color: _pdfGreyText, fontSize: 10)),
                    ]),
                    _buildPdfTeamAvatar(t2),
                  ]
              )
            ]
        )
    );
  }

  pw.Widget _buildPdfTeamAvatar(String name) {
    String initials = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    if (name.split(' ').length > 1) initials = name.split(' ').take(2).map((e) => e[0].toUpperCase()).join();
    return pw.Column(children: [
      pw.Container(
          width: 40, height: 40,
          decoration: const pw.BoxDecoration(color: _pdfYellow, shape: pw.BoxShape.circle),
          alignment: pw.Alignment.center,
          child: pw.Text(initials, style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 18))
      ),
      pw.SizedBox(height: 5),
      pw.Text(name, style: pw.TextStyle(color: _pdfWhite, fontSize: 12, fontWeight: pw.FontWeight.bold)),
    ]);
  }

  pw.Widget _buildPdfInningsSection(Map<String, dynamic> innings, String label, String teamName, {Map<String, dynamic>? matchDetailsFallback}) {
    int runs = _asInt(innings['totalRuns']);
    int wkts = _asInt(innings['totalWickets']);
    double overs = _asDouble(innings['totalOvers']);

    if (matchDetailsFallback != null && runs == 0 && wkts == 0 && overs == 0.0) {
      runs = _asInt(matchDetailsFallback['firstInningScore']);
      wkts = _asInt(matchDetailsFallback['firstInningOuts']);
      overs = _asDouble(matchDetailsFallback['totalMatchOvers'], _asDouble(matchDetailsFallback['overs']));
    }
    final oversText = overs > 0 ? overs.toStringAsFixed(1) : '0.0';
    int totalBalls = (overs.truncate() * 6) + ((overs - overs.truncate()) * 10).round();
    double crr = totalBalls > 0 ? (runs / totalBalls) * 6 : 0.0;

    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _pdfCard,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _pdfGreyText, width: 0.5),
              ),
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(color: _pdfYellow, borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Text(label.toUpperCase(), style: pw.TextStyle(color: PdfColors.black, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(teamName, style: pw.TextStyle(color: _pdfWhite, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                        pw.Text("$runs", style: pw.TextStyle(color: _pdfWhite, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text("/$wkts", style: pw.TextStyle(color: _pdfYellow, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      ]),
                      pw.Text("$oversText Overs (CRR: ${crr.toStringAsFixed(2)})", style: const pw.TextStyle(color: _pdfGreyText, fontSize: 10)),
                    ])
                  ]
              )
          ),
          pw.SizedBox(height: 10),
          _buildPdfSectionTitle("Batting"),
          _buildCustomPdfBattingTable(innings),
          pw.SizedBox(height: 10),
          _buildPdfSectionTitle("Bowling"),
          _buildPdfBowlingTable(innings),
        ]
    );
  }

  pw.Widget _buildPdfSectionTitle(String title) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5, left: 5),
        child: pw.Row(children: [
          pw.Container(width: 3, height: 10, color: _pdfYellow),
          pw.SizedBox(width: 5),
          pw.Text(title.toUpperCase(), style: pw.TextStyle(color: _pdfWhite, fontSize: 10, fontWeight: pw.FontWeight.bold))
        ])
    );
  }

  pw.Widget _buildCustomPdfBattingTable(Map<String, dynamic> innings) {
    final list = (innings['batsmen'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    if (list.isEmpty) return pw.Container();
    const tableHeaders = ['BATTER', 'DISMISSAL', 'R', 'B', '4s', '6s', 'SR'];
    const Map<int, pw.TableColumnWidth> colWidths = {
      0: pw.FlexColumnWidth(3.0),
      1: pw.FlexColumnWidth(4.0),
      2: pw.FlexColumnWidth(1.0),
      3: pw.FlexColumnWidth(1.0),
      4: pw.FlexColumnWidth(1.0),
      5: pw.FlexColumnWidth(1.0),
      6: pw.FlexColumnWidth(1.5),
    };

    return pw.Table(
        columnWidths: colWidths,
        border: null,
        children: [
          pw.TableRow(children: tableHeaders.map((h) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: pw.Text(h, style: pw.TextStyle(color: _pdfGreyText, fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: (h == 'BATTER' || h == 'DISMISSAL') ? pw.TextAlign.left : pw.TextAlign.center)
          )).toList()),
          ...list.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            final runs = _asInt(b['runs']);
            final balls = _asInt(b['balls']);
            final sr = balls > 0 ? (runs / balls * 100).toStringAsFixed(1) : "0.0";
            final isOut = b['isOut'] == true;
            final name = _asString(b['name']);

            String dismissalInfo = "Not Out";
            PdfColor dismissalColor = _pdfGreen;
            if (isOut) {
              dismissalInfo = _asString(b['dismissalDetails'], _asString(b['dismissalMethod'], 'Out'));
              if(dismissalInfo.isEmpty) dismissalInfo = "Out";
              dismissalColor = _pdfRedText;
            }
            final cellStyle = const pw.TextStyle(color: _pdfWhite, fontSize: 10);

            return pw.TableRow(
                decoration: pw.BoxDecoration(color: i % 2 == 0 ? _pdfCard : null),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(name, style: pw.TextStyle(color: _pdfWhite, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(dismissalInfo, style: pw.TextStyle(color: dismissalColor, fontSize: 9, fontStyle: isOut ? pw.FontStyle.normal : pw.FontStyle.italic))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$runs', style: pw.TextStyle(color: _pdfWhite, fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$balls', style: cellStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${b['fours']}', style: cellStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${b['sixes']}', style: cellStyle, textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(sr, style: cellStyle, textAlign: pw.TextAlign.center)),
                ]
            );
          }).toList()
        ]
    );
  }

  pw.Widget _buildPdfBowlingTable(Map<String, dynamic> innings) {
    final list = (innings['bowlers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    final data = list.map((b) {
      final balls = _asInt(b['ballsBowled']);
      final runs = _asInt(b['runsGiven']);
      final overs = (balls ~/ 6) + ((balls % 6) / 10.0);
      final eco = balls > 0 ? (runs/balls)*6 : 0.0;
      return [_asString(b['name']), overs.toStringAsFixed(1), _asInt(b['maidens']).toString(), runs.toString(), _asInt(b['wickets']).toString(), eco.toStringAsFixed(1)];
    }).toList();

    return pw.Table.fromTextArray(
      headers: ['BOWLER', 'O', 'M', 'R', 'W', 'ECO'],
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: _pdfGreyText),
      headerDecoration: const pw.BoxDecoration(),
      cellStyle: const pw.TextStyle(fontSize: 10, color: _pdfWhite),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.center, 5: pw.Alignment.centerRight},
      rowDecoration: const pw.BoxDecoration(),
      oddRowDecoration: const pw.BoxDecoration(color: _pdfCard),
    );
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      Directory downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) return downloadsDir;
      Directory? directory = await getExternalStorageDirectory();
      if (directory != null && await directory.exists()) return directory;
    }
    return await getApplicationDocumentsDirectory();
  }

  // ==========================================================================
  // ===================== 3. RESTORED APP SCREEN UI ==========================
  // ==========================================================================

  Widget _buildDarkCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4.0),
      padding: padding ?? const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: _darkPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _teamAvatar(String name) {
    String initials = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    if (name.split(' ').length > 1) initials = name.split(' ').take(2).map((e) => e[0].toUpperCase()).join();
    return CircleAvatar(
      radius: 24,
      backgroundColor: _yellowAccent,
      child: Text(initials, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 0, 4),
      child: Row(children: [
        Container(width: 3, height: 16, color: _yellowAccent),
        const SizedBox(width: 8),
        Text(text.toUpperCase(), style: const TextStyle(color: _whiteText, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.0)),
      ]),
    );
  }

  Widget _matchHeader(String team1, String team2) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_darkPrimary, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: _yellowAccent.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(children: [
        const Text("MATCH SUMMARY", style: TextStyle(color: _textSecondary, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(children: [_teamAvatar(team1), const SizedBox(height: 8), Text(team1, textAlign: TextAlign.center, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 14))])),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("VS", style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic))),
          Expanded(child: Column(children: [_teamAvatar(team2), const SizedBox(height: 8), Text(team2, textAlign: TextAlign.center, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 14))])),
        ]),
      ]),
    );
  }

  Widget _inningsScoreCard(Map<String, dynamic> innings, String label, String battingTeamName, {Map<String, dynamic>? matchDetailsFallback}) {
    int runs = _asInt(innings['totalRuns']);
    int wkts = _asInt(innings['totalWickets']);
    double overs = _asDouble(innings['totalOvers']);

    if (matchDetailsFallback != null && runs == 0 && wkts == 0 && overs == 0.0) {
      runs = _asInt(matchDetailsFallback['firstInningScore']);
      wkts = _asInt(matchDetailsFallback['firstInningOuts']);
      overs = _asDouble(matchDetailsFallback['totalMatchOvers'], _asDouble(matchDetailsFallback['overs']));
    }
    final oversText = overs > 0 ? overs.toStringAsFixed(1) : '0.0';
    int totalBalls = (overs.truncate() * 6) + ((overs - overs.truncate()) * 10).round();
    double crr = totalBalls > 0 ? (runs / totalBalls) * 6 : 0.0;

    return _buildDarkCard(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _yellowAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text(label.toUpperCase(), style: const TextStyle(color: _yellowAccent, fontSize: 10, fontWeight: FontWeight.bold))),
          Text("CRR: ${crr.toStringAsFixed(2)}", style: const TextStyle(color: _textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text(battingTeamName, style: const TextStyle(color: _whiteText, fontSize: 18, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('$runs', style: const TextStyle(color: _whiteText, fontSize: 28, fontWeight: FontWeight.w900, height: 1.0)),
              Text('/$wkts', style: const TextStyle(color: _yellowAccent, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            Text('$oversText Overs', style: const TextStyle(color: _textSecondary, fontSize: 12)),
          ])
        ])
      ]),
    );
  }

  Widget _tableHeader(List<String> columns, List<int> flexes) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: const BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
      child: Row(children: List.generate(columns.length, (index) {
        return Expanded(flex: flexes[index], child: Text(columns[index], textAlign: index == 0 ? TextAlign.left : TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.bold)));
      })),
    );
  }

  Widget _battingTable(Map<String, dynamic> innings) {
    final list = (innings['batsmen'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Batting'),
      _buildDarkCard(padding: EdgeInsets.zero, child: Column(children: [
        _tableHeader(['BATSMAN', 'R', 'B', '4s', '6s', 'SR'], [4, 1, 1, 1, 1, 2]),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final b = list[i];
            final name = _asString(b['name'], '—');
            final runs = _asInt(b['runs']);
            final balls = _asInt(b['balls']);
            final fours = _asInt(b['fours']);
            final sixes = _asInt(b['sixes']);
            final sr = (balls > 0) ? (runs / balls) * 100 : 0.0;
            final isOut = b['isOut'] == true;
            final dismissal = _asString(b['dismissalDetails'], _asString(b['dismissalMethod'], isOut ? 'Out' : 'Not out'));

            return Container(
              color: i % 2 == 0 ? Colors.transparent : _rowHighlight,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(flex: 4, child: Text(name, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.w600, fontSize: 12))),
                  Expanded(flex: 1, child: Text('$runs', textAlign: TextAlign.center, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text('$balls', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                  Expanded(flex: 1, child: Text('$fours', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                  Expanded(flex: 1, child: Text('$sixes', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                  Expanded(flex: 2, child: Text(sr.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                ]),
                if (isOut) Padding(padding: const EdgeInsets.only(top: 2), child: Text(dismissal.toLowerCase(), style: const TextStyle(color: _wicketRed, fontSize: 10, fontStyle: FontStyle.italic)))
                else const Padding(padding: EdgeInsets.only(top: 2), child: Text("not out", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontStyle: FontStyle.italic))),
              ]),
            );
          },
        ),
      ])),
    ]);
  }

  Widget _bowlingTable(Map<String, dynamic> innings) {
    final list = (innings['bowlers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Bowling'),
      _buildDarkCard(padding: EdgeInsets.zero, child: Column(children: [
        _tableHeader(['BOWLER', 'O', 'M', 'R', 'W', 'ECO'], [3, 1, 1, 1, 1, 2]),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final bw = list[i];
            final name = _asString(bw['name'], '—');
            final ballsBowled = _asInt(bw['ballsBowled']);
            final runs = _asInt(bw['runsGiven']);
            final overs = (ballsBowled ~/ 6) + ((ballsBowled % 6) / 10.0);
            final maidens = _asInt(bw['maidens']);
            final wkts = _asInt(bw['wickets']);
            final eco = ballsBowled > 0 ? (runs / ballsBowled) * 6 : 0.0;
            return Container(
              color: i % 2 == 0 ? Colors.transparent : _rowHighlight,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(children: [
                Expanded(flex: 3, child: Text(name, style: const TextStyle(color: _whiteText, fontWeight: FontWeight.w600, fontSize: 12))),
                Expanded(flex: 1, child: Text(overs.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                Expanded(flex: 1, child: Text('$maidens', textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
                Expanded(flex: 1, child: Text('$runs', textAlign: TextAlign.center, style: const TextStyle(color: _whiteText, fontSize: 12))),
                Expanded(flex: 1, child: Text('$wkts', textAlign: TextAlign.center, style: const TextStyle(color: _yellowAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 2, child: Text(eco.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12))),
              ]),
            );
          },
        ),
      ])),
    ]);
  }

  Widget _oversSection(Map<String, dynamic> innings) {
    List overs = (innings['completedOvers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    if (overs.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Overs Summary'),
      _buildDarkCard(child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => Divider(color: _textSecondary.withOpacity(0.1), height: 16),
        itemCount: overs.length,
        itemBuilder: (_, i) {
          final o = overs[i];
          final overNum = _asInt(o['overNumber']);
          final runs = _asInt(o['runsScoredInOver']);
          final bowler = _asString(o['bowlerName'], '');
          final balls = (o['ballDetails'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _yellowAccent, borderRadius: BorderRadius.circular(4)), child: Text('Ov $overNum', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))),
                const SizedBox(width: 8),
                Text(bowler, style: const TextStyle(color: _whiteText, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              Text('Runs: $runs', style: const TextStyle(color: _textSecondary, fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 4, runSpacing: 4, children: balls.map((b) {
              String label = _asString(b['display'], '•');
              Color color = Colors.grey.shade800;
              Color textColor = _whiteText;
              if (b['isWicket'] == true) { color = _wicketRed; }
              else if ((b['extraTypes'] as List?)?.isNotEmpty == true) { color = _extraOrange; textColor = Colors.black; }
              else if (label == '4') { color = _boundaryGreen; textColor = Colors.black; }
              else if (label == '6') { color = _sixPurple; textColor = Colors.white; }
              else if (label == '0') { color = _rowHighlight; textColor = Colors.white38; }
              return Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: Text(label, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)));
            }).toList()),
          ]);
        },
      )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final matchDetails = Map<String, dynamic>.from(match['matchDetails'] ?? {});
    final innings1 = Map<String, dynamic>.from(match['innings1Data'] ?? {});
    final innings2 = Map<String, dynamic>.from(match['innings2Data'] ?? {});

    final team1Name = _asString(matchDetails['team1Name'], 'Team 1');
    final team2Name = _asString(matchDetails['team2Name'], 'Team 2');
    final innings1BattingTeamName = _asString(matchDetails['firstInningBattingTeamName'],
        _asString(matchDetails['firstInningBattingTeam'], team1Name));
    final innings2BattingTeamName = (innings1BattingTeamName == team1Name) ? team2Name : team1Name;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _darkPrimary,
        elevation: 0,
        title: const Text('SCORECARD', style: TextStyle(color: _whiteText, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _yellowAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            onPressed: () => _showSummaryPreview(context),
            tooltip: 'Download Summary Image',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => _downloadPdf(context),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _matchHeader(team1Name, team2Name),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  _inningsScoreCard(
                      innings1,
                      '1st Innings',
                      innings1BattingTeamName,
                      matchDetailsFallback: matchDetails
                  ),
                  _battingTable(innings1),
                  _bowlingTable(innings1),
                  _oversSection(innings1),

                  if (innings2.isNotEmpty || _asInt(matchDetails['currentInnings']) == 2) ...[
                    const SizedBox(height: 16),
                    Divider(color: _textSecondary.withOpacity(0.2), thickness: 2, indent: 20, endIndent: 20),
                    const SizedBox(height: 8),
                    _inningsScoreCard(innings2, '2nd Innings', innings2BattingTeamName),
                    _battingTable(innings2),
                    _bowlingTable(innings2),
                    _oversSection(innings2),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}