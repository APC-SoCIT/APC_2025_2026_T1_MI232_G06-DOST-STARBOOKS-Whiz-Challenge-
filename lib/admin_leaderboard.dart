import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;
import 'config.dart';

class AdminLeaderboard extends StatefulWidget {
  const AdminLeaderboard({super.key});

  @override
  State<AdminLeaderboard> createState() => _AdminLeaderboardState();
}

class _AdminLeaderboardState extends State<AdminLeaderboard> {
  String selectedMode = "challenge";
  bool _isLoading = true;
  String? _loadError;

  // Leaderboard data — fetched live from the backend in _fetchLeaderboards().
  // Badges tab -> GET /api/leaderboard?mode=challenge  (LeaderboardController)
  // Stars tab  -> GET /api/stars/leaderboard           (StarsController)
  // These previously were hardcoded mock lists (ronald/carla/clarisse/etc.)
  // that never talked to the backend at all — _refreshData() even had a
  // comment admitting "in a real app, you'd fetch from backend."
  List<Map<String, dynamic>> challengeData = [];
  List<Map<String, dynamic>> battleData = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboards();
  }

  Future<void> _fetchLeaderboards() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        http
            .get(Uri.parse('${AppConfig.baseUrl}/leaderboard?mode=challenge&limit=100'),
                headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10)),
        http
            .get(Uri.parse('${AppConfig.baseUrl}/stars/leaderboard?limit=100'),
                headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10)),
      ]);

      final badgesRes = results[0];
      final starsRes = results[1];

      List<Map<String, dynamic>> newChallengeData = [];
      List<Map<String, dynamic>> newBattleData = [];

      if (badgesRes.statusCode == 200) {
        final body = json.decode(badgesRes.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final users = (body['users'] as List<dynamic>? ?? []);
          newChallengeData = users.map((u) {
            final m = u as Map<String, dynamic>;
            return {
              "username": m['username']?.toString() ?? 'Player',
              "avatar": (m['avatar']?.toString().isNotEmpty ?? false)
                  ? m['avatar'].toString()
                  : 'assets/images-avatars/Brainy.png',
              "totalRewards": m['total_badges'] ?? 0,
              "easy": m['easy_count'] ?? 0,
              "avg": m['average_count'] ?? 0,
              "diff": m['difficult_count'] ?? 0,
              // Not tracked by this endpoint — badge counts don't carry a
              // per-claim timestamp on the backend yet.
              "last": "",
            };
          }).toList();
        }
      }

      if (starsRes.statusCode == 200) {
        final body = json.decode(starsRes.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = (body['data'] as List<dynamic>? ?? []);
          newBattleData = data.map((u) {
            final m = u as Map<String, dynamic>;
            return {
              "username": m['username']?.toString() ?? 'Player',
              "avatar": (m['avatar']?.toString().isNotEmpty ?? false)
                  ? m['avatar'].toString()
                  : 'assets/images-avatars/Brainy.png',
              "rewards": m['stars'] ?? 0,
              "easy": 0,
              "avg": 0,
              "diff": 0,
              // Not tracked by this endpoint — stars totals don't carry a
              // last-updated timestamp on the backend yet.
              "last": "",
              "status": m['tier']?.toString() ?? '',
            };
          }).toList();
        }
      }

      if (badgesRes.statusCode != 200 || starsRes.statusCode != 200) {
        _loadError =
            'Server error (Badges: HTTP ${badgesRes.statusCode}, Stars: HTTP ${starsRes.statusCode}).';
      }

      setState(() {
        challengeData = newChallengeData;
        battleData = newBattleData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError =
            'Could not reach the server. Check that the API is running and reachable at ${AppConfig.baseUrl}.';
      });
    }
  }

  List<Map<String, dynamic>> get leaderboardData {
    return selectedMode == "challenge" ? challengeData : battleData;
  }

  void _refreshData() async {
    await _fetchLeaderboards();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_loadError == null
            ? 'Leaderboard data refreshed'
            : 'Refresh failed: $_loadError'),
        duration: const Duration(seconds: 2),
        backgroundColor: _loadError == null ? const Color(0xFF27AE60) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.4)),
      ),
    );
  }

  void _exportData() {
    Map<String, bool> selectedLeaderboards = {
      'challenge': false,
      'battle': false,
    };
    bool selectAll = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.8),
            ),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(19.2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Leaderboard Data',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.4,
                    ),
                  ),
                  const SizedBox(height: 6.4),
                  const Text(
                    'Select which leaderboard(s) to export',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.4,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Leaderboard',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.2,
                    ),
                  ),
                  const SizedBox(height: 9.6),
                  CheckboxListTile(
                    title: const Text(
                      'Select All',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 11.2,
                      ),
                    ),
                    value: selectAll,
                    onChanged: (value) {
                      setDialogState(() {
                        selectAll = value ?? false;
                        selectedLeaderboards['challenge'] = selectAll;
                        selectedLeaderboards['battle'] = selectAll;
                      });
                    },
                    activeColor: const Color(0xFF046EB8),
                  ),
                  const Divider(),
                  CheckboxListTile(
                    title: const Text(
                      'Badges',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    ),
                    secondary: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF046EB8),
                    ),
                    value: selectedLeaderboards['challenge'],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLeaderboards['challenge'] = value ?? false;
                        selectAll =
                            selectedLeaderboards['challenge']! &&
                                selectedLeaderboards['battle']!;
                      });
                    },
                    activeColor: const Color(0xFF046EB8),
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Stars',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    ),
                    secondary: const Icon(
                      Icons.star,
                      color: Color(0xFFFDD000),
                    ),
                    value: selectedLeaderboards['battle'],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLeaderboards['battle'] = value ?? false;
                        selectAll =
                            selectedLeaderboards['challenge']! &&
                                selectedLeaderboards['battle']!;
                      });
                    },
                    activeColor: const Color(0xFF046EB8),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Export Format',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.2,
                    ),
                  ),
                  const SizedBox(height: 9.6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _performExportFromDialog(selectedLeaderboards, 'CSV', context),
                          icon: const Icon(Icons.table_chart, size: 14.4),
                          label: const Text('CSV', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6.4),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _performExportFromDialog(selectedLeaderboards, 'Excel', context),
                          icon: const Icon(Icons.grid_on, size: 14.4),
                          label: const Text('Excel', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6.4),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _performExportFromDialog(selectedLeaderboards, 'PDF', context),
                          icon: const Icon(Icons.picture_as_pdf, size: 14.4),
                          label: const Text('PDF', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFF046EB8),
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.2,
                              color: Color(0xFF046EB8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _performExportFromDialog(
      Map<String, bool> selectedLeaderboards,
      String format,
      BuildContext dialogContext,
      ) {
    if (!selectedLeaderboards['challenge']! &&
        !selectedLeaderboards['battle']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select at least one leaderboard',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.4)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Close ONLY the dialog using its own context
    Navigator.of(dialogContext).pop();

    String leaderboardType;
    if (selectedLeaderboards['challenge']! && selectedLeaderboards['battle']!) {
      leaderboardType = 'both';
    } else if (selectedLeaderboards['challenge']!) {
      leaderboardType = 'challenge';
    } else {
      leaderboardType = 'battle';
    }

    _performExport(format, leaderboardType);
  }

  void _selectExportFormat(String leaderboardType) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(19.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Export Format',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14.4,
                ),
              ),
              const SizedBox(height: 6.4),
              Text(
                'Exporting ${_getLeaderboardLabel(leaderboardType)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.4,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.file_upload_outlined,
                      color: Color(0xFF046EB8),
                    ),
                    title: const Text(
                      'Export as CSV',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    ),
                    onTap: () {
                      _performExport('CSV', leaderboardType);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.file_upload_outlined,
                      color: Color(0xFF046EB8),
                    ),
                    title: const Text(
                      'Export as Excel',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    ),
                    onTap: () {
                      _performExport('Excel', leaderboardType);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.file_upload_outlined,
                      color: Color(0xFF046EB8),
                    ),
                    title: const Text(
                      'Export as PDF',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    ),
                    onTap: () {
                      _performExport('PDF', leaderboardType);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF046EB8),
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.2,
                          color: Color(0xFF046EB8),
                        ),
                      ),
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

  String _getLeaderboardLabel(String type) {
    switch (type) {
      case 'challenge':
        return 'Badges';
      case 'battle':
        return 'Stars';
      case 'both':
        return 'Both Leaderboards';
      default:
        return '';
    }
  }

  void _performExport(String format, String leaderboardType) {
    // No Navigator.pop here — dialog is already closed by _performExportFromDialog
    switch (format) {
      case 'CSV':
        _downloadCSV(leaderboardType);
        break;
      case 'Excel':
        _downloadExcel(leaderboardType);
        break;
      case 'PDF':
        _downloadPDF(leaderboardType);
        break;
    }
  }

  // ─── Browser download trigger (same pattern as admin_dashboard.dart) ────────
  void _triggerBrowserDownload(Uint8List bytes, String filename, String mimeType) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..setAttribute('download', filename);
    web.document.body!.appendChild(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: const Color(0xFF27AE60),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.4)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── CSV Download ─────────────────────────────────────────────────────────
  void _downloadCSV(String leaderboardType) {
    final buffer = StringBuffer();
    buffer.writeln('"Starbooks Whiz Challenge - Leaderboard Export"');
    buffer.writeln('"Generated","${DateTime.now().toString().substring(0, 19)}"');
    buffer.writeln();

    if (leaderboardType == 'challenge' || leaderboardType == 'both') {
      buffer.writeln('"=== BADGES LEADERBOARD ==="');
      buffer.writeln('"Rank","Username","Total Badges","Easy","Average","Difficult"');
      for (int i = 0; i < challengeData.length; i++) {
        final p = challengeData[i];
        buffer.writeln(
          '"${i + 1}","${p['username']}","${p['totalRewards']}",'
              '"${p['easy']}","${p['avg']}","${p['diff']}"',
        );
      }
      buffer.writeln();
    }

    if (leaderboardType == 'battle' || leaderboardType == 'both') {
      buffer.writeln('"=== STARS LEADERBOARD ==="');
      buffer.writeln('"Rank","Username","Total Stars","Status"');
      for (int i = 0; i < battleData.length; i++) {
        final p = battleData[i];
        buffer.writeln(
          '"${i + 1}","${p['username']}","${p['rewards']}",'
              '"${p['status']}"',
        );
      }
      buffer.writeln();
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    _triggerBrowserDownload(
      bytes,
      'starbooks_leaderboard_${DateTime.now().millisecondsSinceEpoch}.csv',
      'text/csv',
    );
    _showSuccessSnackBar('Leaderboard exported as CSV!');
  }

  // ─── Excel Download (XLSX via XML SpreadsheetML) ──────────────────────────
  void _downloadExcel(String leaderboardType) {
    // Build a proper XLSX using SpreadsheetML XML format
    final rows = StringBuffer();

    void addHeaderRow(List<String> cols) {
      rows.write('<Row ss:StyleID="header">');
      for (final c in cols) {
        rows.write('<Cell><Data ss:Type="String">$c</Data></Cell>');
      }
      rows.write('</Row>');
    }

    void addDataRow(List<String> cols) {
      rows.write('<Row>');
      for (final c in cols) {
        rows.write('<Cell><Data ss:Type="String">$c</Data></Cell>');
      }
      rows.write('</Row>');
    }

    void addSectionTitle(String title) {
      rows.write(
        '<Row><Cell ss:StyleID="section"><Data ss:Type="String">$title</Data></Cell></Row>',
      );
    }

    void addBlankRow() {
      rows.write('<Row><Cell><Data ss:Type="String"></Data></Cell></Row>');
    }

    if (leaderboardType == 'challenge' || leaderboardType == 'both') {
      addSectionTitle('BADGES LEADERBOARD');
      addHeaderRow(['Rank', 'Username', 'Total Badges', 'Easy', 'Average', 'Difficult']);
      for (int i = 0; i < challengeData.length; i++) {
        final p = challengeData[i];
        addDataRow([
          '${i + 1}', '${p['username']}', '${p['totalRewards']}',
          '${p['easy']}', '${p['avg']}', '${p['diff']}',
        ]);
      }
      addBlankRow();
    }

    if (leaderboardType == 'battle' || leaderboardType == 'both') {
      addSectionTitle('STARS LEADERBOARD');
      addHeaderRow(['Rank', 'Username', 'Total Stars', 'Status']);
      for (int i = 0; i < battleData.length; i++) {
        final p = battleData[i];
        addDataRow([
          '${i + 1}', '${p['username']}', '${p['rewards']}',
          '${p['status']}',
        ]);
      }
    }

    final xml = '''<?xml version="1.0"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
 <Styles>
  <Style ss:ID="header">
   <Font ss:Bold="1" ss:Color="#FFFFFF"/>
   <Interior ss:Color="#046EB8" ss:Pattern="Solid"/>
  </Style>
  <Style ss:ID="section">
   <Font ss:Bold="1" ss:Color="#046EB8"/>
  </Style>
 </Styles>
 <Worksheet ss:Name="Leaderboard">
  <Table>$rows</Table>
 </Worksheet>
</Workbook>''';

    final bytes = Uint8List.fromList(utf8.encode(xml));
    _triggerBrowserDownload(
      bytes,
      'starbooks_leaderboard_${DateTime.now().millisecondsSinceEpoch}.xls',
      'application/vnd.ms-excel',
    );
    _showSuccessSnackBar('Leaderboard exported as Excel!');
  }

  // ─── PDF Download ─────────────────────────────────────────────────────────
  Future<void> _downloadPDF(String leaderboardType) async {
    PdfColor hexToPdf(int hex) => PdfColor(
      ((hex >> 16) & 0xFF) / 255,
      ((hex >> 8) & 0xFF) / 255,
      (hex & 0xFF) / 255,
    );

    final primaryColor = hexToPdf(0xFF046EB8);
    final pdf = pw.Document();

    // Build table rows helper
    pw.Widget buildTable({
      required List<String> headers,
      required List<List<String>> rows,
      required String title,
    }) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(3.2),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 4.8),
          // Table header row
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
            columnWidths: {for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth()},
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: hexToPdf(0xFFE8F4FD)),
                children: headers.map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(h, style: pw.TextStyle(fontSize: 6.4, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                )).toList(),
              ),
              ...rows.asMap().entries.map((entry) {
                final isEven = entry.key % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : hexToPdf(0xFFF8FBFF),
                  ),
                  children: entry.value.map((cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: pw.Text(cell, style: const pw.TextStyle(fontSize: 6.4, color: PdfColors.grey800)),
                  )).toList(),
                );
              }),
            ],
          ),
        ],
      );
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(19.2),
      build: (ctx) => [
        // Report header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: pw.BorderRadius.circular(6.4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Starbooks Whiz Challenge',
                style: pw.TextStyle(fontSize: 11.2, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              ),
              pw.Text(
                'Leaderboard Report',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3.2),
        pw.Text(
          'Generated: ${DateTime.now().toString().substring(0, 19)}',
          style: const pw.TextStyle(fontSize: 6.4, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 16),

        // Badges table
        if (leaderboardType == 'challenge' || leaderboardType == 'both') ...[
          buildTable(
            title: 'BADGES LEADERBOARD',
            headers: ['Rank', 'Username', 'Total Badges', 'Easy', 'Avg', 'Difficult'],
            rows: challengeData.asMap().entries.map((e) => [
              '${e.key + 1}',
              '${e.value['username']}',
              '${e.value['totalRewards']}',
              '${e.value['easy']}',
              '${e.value['avg']}',
              '${e.value['diff']}',
            ]).toList(),
          ),
          pw.SizedBox(height: 16),
        ],

        // Stars table
        if (leaderboardType == 'battle' || leaderboardType == 'both')
          buildTable(
            title: 'STARS LEADERBOARD',
            headers: ['Rank', 'Username', 'Stars', 'Status'],
            rows: battleData.asMap().entries.map((e) => [
              '${e.key + 1}',
              '${e.value['username']}',
              '${e.value['rewards']}',
              '${e.value['status']}',
            ]).toList(),
          ),
      ],
    ));

    final pdfBytes = await pdf.save();
    _triggerBrowserDownload(
      pdfBytes,
      'starbooks_leaderboard_${DateTime.now().millisecondsSinceEpoch}.pdf',
      'application/pdf',
    );
    _showSuccessSnackBar('Leaderboard exported as PDF!');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF94D2FD),
      padding: const EdgeInsets.all(19.2),
      child: Container(
        padding: const EdgeInsets.all(19.2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6.4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF046EB8)))
            : Column(
          children: [
            if (_loadError != null) _buildLoadErrorBanner(),
            // Top controls with buttons on opposite sides
            LayoutBuilder(builder: (context, topConstraints) {
              final isNarrow = topConstraints.maxWidth < 500;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          _buildModeButton("Badges", "challenge"),
                          const SizedBox(width: 6.4),
                          _buildModeButton("Stars", "battle"),
                        ]),
                        Row(children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextButton.icon(
                              onPressed: _exportData,
                              icon: const Icon(Icons.upload_outlined, size: 12.8, color: Colors.black87),
                              label: const Text('Export', style: TextStyle(color: Colors.black87, fontSize: 10.4, fontFamily: 'Poppins')),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                            ),
                          ),
                          const SizedBox(width: 6.4),
                          IconButton(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh, size: 16),
                            style: IconButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: const CircleBorder()),
                            tooltip: 'Refresh',
                          ),
                        ]),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Mode buttons
                  Row(
                    children: [
                      _buildModeButton("Badges", "challenge"),
                      const SizedBox(width: 9.6),
                      _buildModeButton("Stars", "battle"),
                    ],
                  ),
                  // Right side - Action buttons
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextButton.icon(
                          onPressed: _exportData,
                          icon: const Icon(Icons.upload_outlined, size: 12.8, color: Colors.black87),
                          label: const Text('Export', style: TextStyle(color: Colors.black87, fontSize: 10.4, fontFamily: 'Poppins')),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                        ),
                      ),
                      const SizedBox(width: 9.6),
                      IconButton(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh, size: 16),
                        style: IconButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: const CircleBorder(),
                        ),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 19.2),

            // Table
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                Widget tableContent = Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6.4),
                        ),
                      ),
                      child: selectedMode == "challenge"
                          ? Row(
                        children: const [
                          SizedBox(width: 40),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Username",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.2,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Total Badges",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.2,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Easy",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.2,
                                fontFamily: 'Poppins',
                                color: Color(0xFF27AE60),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Average",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.2,
                                fontFamily: 'Poppins',
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Difficult",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.2,
                                fontFamily: 'Poppins',
                                color: Color(0xFFE74C3C),
                              ),
                            ),
                          ),
                        ],
                      )
                          : Row(
                        children: const [
                          SizedBox(width: 40),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Username",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.2,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Total Stars",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.2,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rows
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.grey.shade300),
                            right: BorderSide(color: Colors.grey.shade300),
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(6.4),
                          ),
                        ),
                        child: leaderboardData.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    selectedMode == "challenge"
                                        ? 'No players with badges yet.'
                                        : 'No star rankings yet.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11.2,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                          itemCount: leaderboardData.length,
                          itemBuilder: (context, index) {
                            final player = leaderboardData[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: index % 2 == 0
                                    ? Colors.white
                                    : Colors.grey.shade50,
                                border: Border(
                                  bottom: index < leaderboardData.length - 1
                                      ? BorderSide(color: Colors.grey.shade300)
                                      : BorderSide.none,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              child: selectedMode == "challenge"
                                  ? _buildChallengeRow(player, index)
                                  : _buildBattleRow(player, index),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
                if (isMobile) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: 544, child: tableContent),
                  );
                }
                return tableContent;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeRow(Map<String, dynamic> player, int index) {
    return Row(
      children: [
        _buildRankBadge(index + 1),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF046EB8), width: 1.6),
                  color: Colors.grey.shade200,
                ),
                child: ClipOval(
                  child: Image.asset(
                    player["avatar"],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF046EB8));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 9.6),
              Text(
                player["username"],
                style: const TextStyle(
                  fontSize: 11.2,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            "${player["totalRewards"]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.2,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "${player["easy"]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.2,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "${player["avg"]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.2,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "${player["diff"]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.2,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBattleRow(Map<String, dynamic> player, int index) {
    return Row(
      children: [
        _buildRankBadge(index + 1),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF046EB8), width: 1.6),
                  color: Colors.grey.shade200,
                ),
                child: ClipOval(
                  child: Image.asset(
                    player["avatar"],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF046EB8));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 9.6),
              Text(
                player["username"],
                style: const TextStyle(
                  fontSize: 11.2,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Color(0xFFFDD000), size: 14.4),
              const SizedBox(width: 3.2),
              Text(
                "${player["rewards"]}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.2,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB020).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB25E00), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadError ?? '',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF7A4A00)),
            ),
          ),
          TextButton(
            onPressed: _fetchLeaderboards,
            child: const Text(
              'Retry',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF046EB8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, String mode) {
    final bool isSelected = selectedMode == mode;
    return ElevatedButton(
      onPressed: () => setState(() => selectedMode = mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF046EB8) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSelected ? const Color(0xFF046EB8) : Colors.grey.shade400,
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11.2,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon,
      String? label,
      VoidCallback onPressed,
      ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.4)),
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.4),
          if (label != null) ...[
            const SizedBox(width: 4.8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "May 23, 2025" — divider — "15:45"  (input: "MM/DD/YYYY HH:MM")
  Widget _buildDateTimeCell(String dateTimeStr) {
    String datePart = dateTimeStr;
    String timePart = '';
    final spaceIdx = dateTimeStr.indexOf(' ');
    if (spaceIdx != -1) {
      datePart = dateTimeStr.substring(0, spaceIdx);
      timePart = dateTimeStr.substring(spaceIdx + 1);
    }
    String formattedDate = datePart;
    final pieces = datePart.split('/');
    if (pieces.length == 3) {
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final m = int.tryParse(pieces[0]) ?? 0;
      final d = int.tryParse(pieces[1]) ?? 0;
      final y = pieces[2];
      if (m >= 1 && m <= 12) formattedDate = '${months[m]} $d, $y';
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedDate,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.4,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          if (timePart.isNotEmpty) ...[
            const SizedBox(height: 2.4),
            Container(width: 44.8, height: 0.8, color: Colors.grey.shade300),
            const SizedBox(height: 2.4),
            Text(
              timePart,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.8,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bgColor;
    switch (rank) {
      case 1:
        bgColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        bgColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        bgColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        bgColor = const Color(0xFF34495E);
    }

    return Container(
      width: 28.8,
      height: 28.8,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(right: 9.6),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3.2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        "$rank",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11.2,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}