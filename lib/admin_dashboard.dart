import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;
import 'admin_sidebar.dart';
import 'admin_leaderboard.dart';
import 'admin_login.dart';
import 'admin_users_players.dart';
import 'admin_users_admins.dart';
import 'admin_questions.dart';
import 'admin_difficulty.dart';
import 'loading_page.dart';
import 'api_service.dart';
import 'config.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? adminData;
  const AdminDashboard({super.key, this.adminData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final Map<String, GlobalKey> _chartKeys = {
    'Total Registered Players': GlobalKey(),
    'Average Player Rating': GlobalKey(),
    'Male vs Female Registered Players': GlobalKey(),
    'Age Distribution of Players': GlobalKey(),
    'Registered Players by Region': GlobalKey(),
    'Male vs Female Players Per Game Mode': GlobalKey(),
    'Badge Distribution By Gender and Level': GlobalKey(),
    'Most Played Game Mode By Age': GlobalKey(),
  };
  final Map<String, bool> _sortAscending = {};

  // ── Live analytics data from /api/admin/analytics ─────────────────────────
  Map<String, dynamic>? _analytics;
  bool _analyticsLoading = true;
  String? _analyticsError;

  // ── Mutable copy of the logged-in admin's own profile data ────────────────
  // widget.adminData is just the snapshot from login and never changes, so
  // if we read straight from it the sidebar/topbar avatar never updates after
  // editing your own profile picture — you'd have to log out and back in to
  // see it. Everything that displays "my" avatar/username reads from this
  // instead, and _showEditMyProfileDialog() updates it in place on success.
  late Map<String, dynamic> _adminData;

  @override
  void initState() {
    super.initState();
    _adminData = Map<String, dynamic>.from(widget.adminData ?? {});
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _analyticsLoading = true;
      _analyticsError = null;
    });
    try {
      final token = widget.adminData?['token'] as String? ?? '';
      // ✅ FIX: this was hardcoded to 'http://127.0.0.1:8000', which only
      // works if the admin panel happens to run on the exact same machine
      // as the Laravel server. Every other screen in the app (login, quiz,
      // difficulty settings) reads the real server address from
      // AppConfig.baseUrl — this one just never got wired up, so it was
      // silently failing (connection refused / no route to host) for
      // anyone not on localhost, and the dashboard just sat on "—" forever
      // with nothing visible to say why.
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/analytics'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          _rebuildLiveTooltipData(data);
          setState(() {
            _analytics = data;
            _analyticsLoading = false;
          });
          return;
        }
        setState(() => _analyticsError =
            body['message']?.toString() ?? 'Server returned success=false.');
      } else if (res.statusCode == 401) {
        setState(() => _analyticsError =
            'Session expired or unauthorized. Please log in again.');
      } else {
        setState(() =>
            _analyticsError = 'Server error (HTTP ${res.statusCode}).');
      }
    } catch (e) {
      debugPrint('Analytics load error: $e');
      setState(() => _analyticsError =
          'Could not reach the server. Check that the API is running and reachable at ${AppConfig.baseUrl}.');
    }
    setState(() => _analyticsLoading = false);
  }

  // ── Player comments / feedback ─────────────────────────────────────────────
  // Pulled from `_analytics['player_comments']`. Each entry is expected to
  // look like: {player_name, comment, rating, created_at}. If the backend
  // hasn't added this field to /api/admin/analytics yet, this simply shows
  // an empty state instead of any placeholder text.
  List<dynamic> get _playerComments =>
      (_analytics?['player_comments'] as List<dynamic>?) ?? [];

  Future<void> _logoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(19.2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images-icons/sadlogout.png",
                width: 64,
                height: 64,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.logout,
                    size: 64,
                    color: Color(0xFF046EB8),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                "Logout Confirmation",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to log out?",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
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
                        "Cancel",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.2,
                          color: Color(0xFF046EB8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.2,
                          fontWeight: FontWeight.bold,
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

    if (confirmed == true) {
      // ✅ FIX: logout was only navigating to AdminLoginPage without ever
      // clearing the saved admin token. AdminAuthGate (which "ADMIN" on the
      // player login screen routes through) finds that still-valid token
      // and silently logs back in — this actually revokes it server-side
      // and clears it locally first.
      await ApiService().logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      );
    }
  }

  // ── My Profile: pick an image file from disk ───────────────────────────────
  Future<Map<String, dynamic>?> _pickImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      return {'bytes': bytes, 'name': file.name};
    } catch (e) {
      debugPrint('FilePicker: $e');
      return null;
    }
  }

  Widget _buildMyProfileImageCircle(Uint8List? newBytes, String? existingImageUrl) {
    ImageProvider? provider;
    if (newBytes != null) {
      provider = MemoryImage(newBytes);
    } else if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
      provider = NetworkImage(existingImageUrl);
    }
    return CircleAvatar(
      radius: 38.4,
      backgroundColor: const Color(0xFFFDD000),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white,
        backgroundImage: provider,
        child: provider == null
            ? ClipOval(child: Image.asset(
                'assets/images-badges/whiz-happy.png',
                width: 72, height: 72, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 32, color: Colors.grey),
              ))
            : null,
      ),
    );
  }

  /// Lets the logged-in admin change their own username / picture. On
  /// success this updates `_adminData` directly (see field above) so the
  /// sidebar and topbar avatar refresh immediately — no re-login needed.
  void _showEditMyProfileDialog() {
    final usernameCtrl = TextEditingController(text: _adminData['username'] ?? '');
    String? selectedSex = _adminData['sex'];
    final String? existingImage = _adminData['image'] as String?;
    Uint8List? newImageBytes;
    String? newImageName;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
        child: Container(
          width: 336,
          padding: const EdgeInsets.all(19.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 6.4),
                Text('Edit Profile', style: TextStyle(fontSize: 12.8, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Column(children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await _pickImageFile();
                        if (picked != null) {
                          setDS(() {
                            newImageBytes = picked['bytes'] as Uint8List?;
                            newImageName = picked['name'] as String?;
                          });
                        }
                      },
                      child: _buildMyProfileImageCircle(newImageBytes, existingImage),
                    ),
                  ),
                  const SizedBox(height: 6.4),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await _pickImageFile();
                      if (picked != null) {
                        setDS(() {
                          newImageBytes = picked['bytes'] as Uint8List?;
                          newImageName = picked['name'] as String?;
                        });
                      }
                    },
                    icon: const Icon(Icons.upload, size: 9.6),
                    label: const Text("Upload Photo", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000),
                      foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                    ),
                  ),
                  if (newImageName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3.2),
                      child: SizedBox(
                        width: 80,
                        child: Text(newImageName!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 7.2, color: Colors.black54, fontFamily: 'Poppins'),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ]),
                const SizedBox(width: 12.8),
                Expanded(
                  child: Column(children: [
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9.6)),
                      ),
                    ),
                    const SizedBox(height: 9.6),
                    DropdownButtonFormField<String>(
                      value: selectedSex,
                      hint: const Text('Sex', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.black38)),
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(9.6))),
                      isExpanded: true,
                      items: ['Male', 'Female', 'Prefer not to say']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4))))
                          .toList(),
                      onChanged: (v) => setDS(() => selectedSex = v),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 19.2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Colors.black54),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 10.4)),
                  ),
                  ElevatedButton(
                    onPressed: saving ? null : () async {
                      final newUsername = usernameCtrl.text.trim();
                      if (newUsername.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Username cannot be empty.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      setDS(() => saving = true);
                      final result = await ApiService().updateAdmin(
                        _adminData['id'].toString(),
                        {
                          'username': newUsername,
                          if (selectedSex != null) 'sex': selectedSex!,
                        },
                        imageBytes: newImageBytes,
                      );
                      if (!mounted) return;
                      setDS(() => saving = false);
                      if (result['success'] == true) {
                        final updated = result['admin'] as Map<String, dynamic>?;
                        setState(() {
                          if (updated != null) {
                            _adminData['username'] = updated['username'] ?? _adminData['username'];
                            _adminData['sex'] = updated['sex'] ?? _adminData['sex'];
                            _adminData['image'] = updated['image'] ?? _adminData['image'];
                          } else {
                            _adminData['username'] = newUsername;
                            _adminData['sex'] = selectedSex ?? _adminData['sex'];
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated!'), backgroundColor: Color(0xFF27AE60)),
                        );
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Failed to update profile.'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000),
                      foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(width: 14.4, height: 14.4, child: CircularProgressIndicator(strokeWidth: 1.6, color: Color(0xFF816A03)))
                        : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 10.4)),
                  ),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF94D2FD),
      body: Stack(
        children: [
          Row(
            children: [
              AdminSidebar(
                selectedIndex: _selectedIndex,
                adminData: _adminData,
                onSelect: (i) => setState(() => _selectedIndex = i),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildTopBar() {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          // Centered logo
          Center(
            child: Image.asset(
              'assets/images-logo/newhomepagelogo.png',
              height: 35,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/splashscreen/starbooks.png',
                  height: 35,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                );
              },
            ),
          ),

          // Right side buttons
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                // Export button
                if (_selectedIndex == 0) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextButton.icon(
                      onPressed: _showExportDialog,
                      icon: const Icon(
                        Icons.upload_outlined,
                        size: 12.8,
                        color: Colors.black87,
                      ),
                      label: const Text(
                        'Export',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10.4,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.8),
                ],

                // Profile circle — tap goes straight to Log Out confirmation.
                // Editing your own picture/username is still available via the
                // pencil icon on your own card in List of Admins.
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _logoutDialog,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFDD000),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: () {
                          final img = _adminData['image'];
                          if (img != null && (img as String).isNotEmpty) {
                            final imageUrl = (img.startsWith('http://') || img.startsWith('https://'))
                                ? img
                                : '${AppConfig.baseUrl}/$img';
                            return Image.network(
                              imageUrl,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images-badges/whiz-happy.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Color(0xFF046EB8),
                                  size: 19.2,
                                ),
                              ),
                            );
                          }
                          return Image.asset(
                            'assets/images-badges/whiz-happy.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFF046EB8),
                              size: 19.2,
                            ),
                          );
                        }(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // Show leaderboard when index is 1
    if (_selectedIndex == 1) {
      return const AdminLeaderboard();
    }

    // Show players list when index is 3
    if (_selectedIndex == 3) {
      return const AdminPlayersPage();
    }

    // Show admins list when index is 4
    if (_selectedIndex == 4) {
      return AdminUsersAdminsPage(
        currentAdminId: _adminData['id']?.toString(),
      );
    }

    // Questions (index 6)
    if (_selectedIndex == 6) {
      return const AdminQuizQuestionsPage();
    }

    // Difficulty (index 7)
    if (_selectedIndex == 7) {
      return const AdminQuizDifficultyPage();
    }

    // Show analytics for all other cases (index 0 or others)
    if (_analyticsLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF046EB8)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_analyticsError != null) _buildAnalyticsErrorBanner(),
          // Top stat cards
          Row(
            children: [
              Expanded(
                child: RepaintBoundary(
                  key: _chartKeys['Total Registered Players'],
                  child: _buildStatCard(
                    _analytics?['total_players']?.toString() ?? '—',
                    'Total Registered Players',
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: RepaintBoundary(
                  key: _chartKeys['Average Player Rating'],
                  child: _buildRatingStatCard(
                    _analytics?['average_rating']?.toString() ?? '—',
                    'Average Player Rating',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // First row of charts
          Row(
            children: [
              Expanded(
                child: RepaintBoundary(
                  key: _chartKeys['Male vs Female Registered Players'],
                  child: _buildChartCard(
                    'Male vs Female Registered Players',
                    _buildPieChart(isAscending: _sortAscending.containsKey('Male vs Female Registered Players')
                        ? _sortAscending['Male vs Female Registered Players']
                        : null),
                    legends: [
                      {'color': const Color(0xFF046EB8), 'label': 'Male'},
                      {'color': const Color(0xFF00C9B1), 'label': 'Female'},
                    ],
                    sortable: true,
                    // Pie: index 0=Male(75%), index 1=Female(25%), starting from top (-π/2)
                    hitTest: (pos, size) {
                      final cx = size.width / 2, cy = size.height / 2;
                      final r = size.height / 2 * 0.7;
                      final dx = pos.dx - cx, dy = pos.dy - cy;
                      if (dx * dx + dy * dy > r * r) return -1;
                      final angle = (math.atan2(dy, dx) + math.pi / 2 + math.pi * 2) % (math.pi * 2);
                      final isAsc = _sortAscending['Male vs Female Registered Players'];
                      // ASC: Female(25%) drawn first, then Male; DESC/default: Male(75%) first
                      if (isAsc == true) return angle < 0.25 * math.pi * 2 ? 1 : 0;
                      return angle < 0.75 * math.pi * 2 ? 0 : 1;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: RepaintBoundary(
                  key: _chartKeys['Age Distribution of Players'],
                  child: _buildChartCard(
                    'Age Distribution of Players',
                    _buildBarChart(isAscending: _sortAscending.containsKey('Age Distribution of Players')
                        ? _sortAscending['Age Distribution of Players']!
                        : null),
                    legends: [
                      {'color': const Color(0xFF4A90D9), 'label': 'Number of Players'},
                    ],
                    sortable: true,
                    // 7 bars: barWidth = width/(7*2), bar i starts at i*bw*2 + bw/2
                    hitTest: (pos, size) {
                      const labelH = 18.0;
                      if (pos.dy > size.height - labelH) return -1;
                      final bw = size.width / 14;
                      for (int i = 0; i < 7; i++) {
                        final x = i * bw * 2 + bw / 2;
                        if (pos.dx >= x && pos.dx <= x + bw) return i;
                      }
                      return -1;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Second row of charts
          Row(
            children: [
              Expanded(
                child: RepaintBoundary(
                  key: _chartKeys['Registered Players by Region'],
                  child: _buildChartCard(
                    'Registered Players by Region',
                    _buildRegionBarChart(isAscending: _sortAscending.containsKey('Registered Players by Region')
                        ? _sortAscending['Registered Players by Region']!
                        : null),
                    legends: [
                      {'color': const Color(0xFF046EB8), 'label': 'Players per Region'},
                    ],
                    sortable: true,
                    // Uses the painter's own geometry so hover always lines up,
                    // and maps the hovered column back to the original data
                    // index so tooltips stay right after sorting.
                    hitTest: (pos, size) {
                      final regions =
                          (_analytics?['players_by_region'] as List<dynamic>?) ?? [];
                      if (regions.isEmpty) return -1;
                      if (pos.dy >
                          size.height - RegionBarChartPainter.labelAreaHeight) {
                        return -1;
                      }

                      final order = RegionBarChartPainter.orderedIndices(
                          regions, _sortAscending['Registered Players by Region']);

                      for (int i = 0; i < order.length; i++) {
                        final r = RegionBarChartPainter.barRect(
                            size, order.length, i, 1.0);
                        if (pos.dx >= r.left && pos.dx <= r.right) {
                          return order[i];
                        }
                      }
                      return -1;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: RepaintBoundary(
                  key: _chartKeys['Male vs Female Players Per Game Mode'],
                  child: _buildChartCard(
                    'Male vs Female Players Per Game Mode',
                    _buildGroupedBarChart(isAscending: _sortAscending.containsKey('Male vs Female Players Per Game Mode')
                        ? _sortAscending['Male vs Female Players Per Game Mode']
                        : null),
                    legends: [
                      {'color': const Color(0xFF046EB8), 'label': 'Male'},
                      {'color': const Color(0xFF27AE60), 'label': 'Female'},
                    ],
                    sortable: true,
                    // 4 groups × 2 bars: barWidth = width/(4*3)
                    // group i at x=i*bw*3; male=[x..x+bw], female=[x+bw..x+2bw]
                    hitTest: (pos, size) {
                      const labelH = 18.0;
                      if (pos.dy > size.height - labelH) return -1;
                      final bw = size.width / 12;
                      for (int i = 0; i < 4; i++) {
                        final gx = i * bw * 3;
                        if (pos.dx >= gx && pos.dx < gx + bw) return i * 2;       // Male
                        if (pos.dx >= gx + bw && pos.dx < gx + bw * 2) return i * 2 + 1; // Female
                      }
                      return -1;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Third row of charts
          Row(
            children: [
              Expanded(
                child: RepaintBoundary(
                  key: _chartKeys['Badge Distribution By Gender and Level'],
                  child: _buildChartCard(
                    'Badge Distribution By Gender and Level',
                    _buildStackedBarChart(isAscending: _sortAscending.containsKey('Badge Distribution By Gender and Level')
                        ? _sortAscending['Badge Distribution By Gender and Level']
                        : null),
                    legends: [
                      {'color': const Color(0xFF046EB8), 'label': 'Male'},
                      {'color': const Color(0xFF9B59B6), 'label': 'Female'},
                    ],
                    sortable: true,
                    // ✅ FIX: hitTest used to hard-code maleFracs/femaleFracs
                    // as placeholder numbers ([0.7,0.55,0.4]/[0.4,0.3,0.2])
                    // that never got wired up to real data. The bars
                    // themselves were always drawn correctly from
                    // _analytics (via StackedBarChartPainter), but hovering
                    // used these fake proportions to decide the male/female
                    // boundary — so the tooltip could report the wrong
                    // segment (or wrong level) whenever real data didn't
                    // happen to match [0.7,0.55,0.4]/[0.4,0.3,0.2]. This now
                    // computes the same fractions, from the same source
                    // data and the same optional sort, that the painter
                    // actually draws with.
                    hitTest: (pos, size) {
                      const labelH = 18.0;
                      final chartH = size.height - labelH;
                      if (pos.dy > chartH) return -1;

                      final badges =
                          (_analytics?['badges_by_gender_level'] as List<dynamic>?) ?? [];
                      final source = badges.isNotEmpty ? badges : [
                        {'level': 'Easy', 'male': 0, 'female': 0},
                        {'level': 'Average', 'male': 0, 'female': 0},
                        {'level': 'Difficult', 'male': 0, 'female': 0},
                      ];

                      final maxVal = source.fold<double>(1, (m, e) =>
                        math.max(m, ((e['male'] ?? 0) as num).toDouble() + ((e['female'] ?? 0) as num).toDouble()));

                      final groups = List<Map<String, dynamic>>.from(source.asMap().entries.map((entry) => {
                        'originalIndex': entry.key,
                        'male':   ((entry.value['male']   ?? 0) as num).toDouble() / maxVal,
                        'female': ((entry.value['female'] ?? 0) as num).toDouble() / maxVal,
                      }));

                      final isAsc = _sortAscending['Badge Distribution By Gender and Level'];
                      if (isAsc != null) {
                        groups.sort((a, b) {
                          final aT = a['male'] as double;
                          final bT = b['male'] as double;
                          return isAsc ? aT.compareTo(bT) : bT.compareTo(aT);
                        });
                      }

                      final bw = size.width / (groups.length * 2);
                      for (int i = 0; i < groups.length; i++) {
                        final x = i * bw * 2 + bw / 2;
                        if (pos.dx >= x && pos.dx < x + bw) {
                          final maleFrac   = groups[i]['male'] as double;
                          final femaleFrac = groups[i]['female'] as double;
                          final maleTop = chartH - chartH * maleFrac;
                          final femaleTop = maleTop - chartH * femaleFrac;
                          final origI = groups[i]['originalIndex'] as int;
                          if (pos.dy >= femaleTop && pos.dy < maleTop) return origI * 2 + 1; // Female
                          return origI * 2; // Male
                        }
                      }
                      return -1;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: RepaintBoundary(
                  key: _chartKeys['Most Played Game Mode By Age'],
                  child: _buildChartCard(
                    'Most Played Game Mode By Age',
                    _buildMultiColorBarChart(isAscending: _sortAscending.containsKey('Most Played Game Mode By Age')
                        ? _sortAscending['Most Played Game Mode By Age']
                        : null),
                    legends: [
                      {'color': const Color(0xFFFDD000), 'label': 'Memory Match'},
                      {'color': const Color(0xFF4A90D9), 'label': 'Challenge'},
                      {'color': const Color(0xFFE67E22), 'label': 'Battle'},
                      {'color': const Color(0xFF9B59B6), 'label': 'Puzzle'},
                    ],
                    sortable: true,
                    // 4 age groups × 4 mode bars: groupWidth=width/4, barWidth=gw/5
                    // bar j in group i at x = i*gw + j*bw
                    hitTest: (pos, size) {
                      const labelH = 18.0;
                      if (pos.dy > size.height - labelH) return -1;
                      final gw = size.width / 4;
                      final bw = gw / 5;
                      for (int i = 0; i < 4; i++) {
                        for (int j = 0; j < 4; j++) {
                          final x = i * gw + j * bw;
                          if (pos.dx >= x && pos.dx < x + bw * 0.85) return i * 4 + j;
                        }
                      }
                      return -1;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Player comments / feedback — real data from _analytics['player_comments']
          _buildCommentsCard(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsErrorBanner() {
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
              _analyticsError ?? '',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF7A4A00),
              ),
            ),
          ),
          TextButton(
            onPressed: _loadAnalytics,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF046EB8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsCard() {
    final comments = _playerComments;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Player Comments & Feedback',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '${comments.length} comment${comments.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black45,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No player comments yet.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black38,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(height: 13),
                itemBuilder: (context, i) {
                  final c = comments[i] as Map<String, dynamic>;
                  final name = c['player_name']?.toString() ?? 'Player';
                  final text = c['comment']?.toString() ?? '';
                  final rating = (c['rating'] as num?)?.toInt() ?? 0;
                  final date = c['created_at']?.toString() ?? '';

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: const Color(0xFF046EB8).withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF046EB8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                if (rating > 0) ...[
                                  const SizedBox(width: 6),
                                  Row(
                                    children: List.generate(5, (s) => Icon(
                                      s < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 10,
                                      color: const Color(0xFFFDD000),
                                    )),
                                  ),
                                ],
                                const Spacer(),
                                if (date.isNotEmpty)
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.black38,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              text,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFDD000), size: 26),
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.black54,
              fontFamily: 'Poppins',
            )),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart, {List<Map<String, dynamic>>? legends, bool sortable = false, ChartHitTest? hitTest}) {
    final isSorted = sortable && _sortAscending.containsKey(title);
    final isAscending = _sortAscending[title] ?? false;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Row(
                children: [
                  if (sortable) ...[
                    Tooltip(
                      message: isSorted
                          ? (isAscending ? 'Ascending — click for Descending' : 'Descending — click for Ascending')
                          : 'Sort',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _toggleSort(title),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSorted
                                    ? (isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                                    : Icons.swap_vert_rounded,
                                size: 14,
                                color: isSorted ? const Color(0xFF046EB8) : Colors.black45,
                              ),
                              if (isSorted) ...[
                                const SizedBox(width: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF046EB8).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isAscending ? 'ASC' : 'DESC',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF046EB8),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Tooltip(
                    message: 'Export chart',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _exportChart(title),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.upload_outlined,
                          size: 14,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 144,
            child: InteractiveChart(title: title, chart: chart, hitTest: hitTest),
          ),
          if (legends != null && legends.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 5,
              children: legends.map((l) =>
                  _buildLegendDot(l['color'] as Color, l['label'] as String)
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleSort(String chartTitle) {
    setState(() {
      _sortAscending[chartTitle] = !(_sortAscending[chartTitle] ?? false);
    });
  }

  void _showExportDialog() {
    final List<String> chartTitles = [
      'Total Registered Players',
      'Average Player Rating',
      'Male vs Female Registered Players',
      'Age Distribution of Players',
      'Registered Players by Region',
      'Male vs Female Players Per Game Mode',
      'Badge Distribution By Gender and Level',
      'Most Played Game Mode By Age',
    ];

    Map<String, bool> selectedCharts = {
      for (var title in chartTitles) title: false,
    };
    bool selectAll = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Charts',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select charts to export',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: const Text(
                      'Select All',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    value: selectAll,
                    onChanged: (value) {
                      setDialogState(() {
                        selectAll = value ?? false;
                        for (var key in selectedCharts.keys) {
                          selectedCharts[key] = selectAll;
                        }
                      });
                    },
                    activeColor: const Color(0xFF046EB8),
                  ),
                  const Divider(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        children: chartTitles.map((title) {
                          return CheckboxListTile(
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                            ),
                            value: selectedCharts[title],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedCharts[title] = value ?? false;
                                selectAll = selectedCharts.values.every((v) => v);
                              });
                            },
                            activeColor: const Color(0xFF046EB8),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Export Format',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _performExport(selectedCharts, 'PNG', context),
                          icon: const Icon(Icons.image, size: 18),
                          label: const Text('PNG', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _performExport(selectedCharts, 'PDF', context),
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('PDF', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _performExport(selectedCharts, 'CSV', context),
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: const Text('CSV', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF046EB8), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF046EB8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _performExport(Map<String, bool> selectedCharts, String format, BuildContext dialogContext) {
    final selected = selectedCharts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one chart to export',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    _showLoadingAndExport(selected, format, dialogContext);
  }

  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void _showLoadingAndExport(List<String> selected, String format, BuildContext dialogContext) {
    Navigator.pop(dialogContext);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Center(
        child: LoadingWidget(message: 'Preparing $format export...', width: 380, height: 240),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        if (format == 'CSV') {
          await _downloadCSV(selected);
        } else if (format == 'PNG') {
          await _downloadPNG(selected);
        } else if (format == 'PDF') {
          await _downloadPDF(selected);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

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

  Future<void> _downloadPNG(List<String> selected) async {
    final List<Uint8List> chartBytes = [];
    final List<String> captured = [];
    for (final name in selected) {
      final key = _chartKeys[name];
      if (key == null) continue;
      final bytes = await _captureWidget(key);
      if (bytes != null) {
        chartBytes.add(bytes);
        captured.add(name);
      }
    }
    if (chartBytes.isEmpty) return;

    // Decode chart images
    final List<ui.Image> chartImages = [];
    for (final b in chartBytes) {
      final codec = await ui.instantiateImageCodec(b);
      final frame = await codec.getNextFrame();
      chartImages.add(frame.image);
    }

    // For each chart, render a count summary beneath it using Canvas text
    const double padding = 20.0;       // gap between charts
    const double tablePad = 14.0;      // inner padding of data table
    const double rowH = 18.0;          // height per data row
    const double dotSize = 8.0;
    const double headerH = 22.0;       // "Data Summary" label row
    const double dividerH = 1.0;
    const double fontSize = 11.0;

    // We'll draw everything into one tall canvas
    final List<double> blockHeights = [];
    for (int i = 0; i < chartImages.length; i++) {
      final entries = _chartTooltipData[captured[i]] ?? [];
      final tableH = entries.isEmpty
          ? 0.0
          : tablePad * 2 + headerH + dividerH + 4 + entries.length * rowH;
      blockHeights.add(chartImages[i].height.toDouble() + (entries.isEmpty ? 0 : tableH + 12));
    }

    final int totalWidth = chartImages.map((img) => img.width).reduce((a, b) => a > b ? a : b);
    final double totalHeight =
        blockHeights.reduce((a, b) => a + b) + padding * (chartImages.length - 1) + padding * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalWidth.toDouble(), totalHeight),
      Paint()..color = Colors.white,
    );

    double offsetY = padding;

    for (int i = 0; i < chartImages.length; i++) {
      final img = chartImages[i];
      final chartName = captured[i];
      final entries = _chartTooltipData[chartName] ?? [];

      // Draw chart image
      canvas.drawImage(img, Offset(0, offsetY), Paint());
      offsetY += img.height.toDouble();

      if (entries.isNotEmpty) {
        offsetY += 12;

        // Table background
        final tableH = tablePad * 2 + headerH + dividerH + 4 + entries.length * rowH;
        final tableRect = Rect.fromLTWH(tablePad, offsetY, totalWidth - tablePad * 2, tableH);
        canvas.drawRRect(
          RRect.fromRectAndRadius(tableRect, const Radius.circular(8)),
          Paint()..color = const Color(0xFFF5F7FA),
        );
        // Border
        canvas.drawRRect(
          RRect.fromRectAndRadius(tableRect, const Radius.circular(8)),
          Paint()
            ..color = const Color(0xFFDDE3EC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );

        // "Data Summary" header
        double ty = offsetY + tablePad;
        _drawText(canvas, 'Data Summary',
            Offset(tablePad * 2, ty),
            fontSize: 10,
            color: const Color(0xFF6B7280),
            bold: true,
            maxWidth: totalWidth - tablePad * 4);
        ty += headerH;

        // Divider
        canvas.drawLine(
          Offset(tablePad * 2, ty),
          Offset(totalWidth - tablePad * 2, ty),
          Paint()..color = const Color(0xFFDDE3EC)..strokeWidth = 0.8,
        );
        ty += dividerH + 4;

        // Data rows
        final double halfW = (totalWidth - tablePad * 4) / 2;

        // Clean special characters that Canvas TextPainter can't render
        String cl(String s) => s
            .replaceAll('\u2013', '-').replaceAll('\u2014', '-')
            .replaceAll('\u2022', '*').replaceAll('\u2019', "'")
            .replaceAll('\u2026', '...').trim();

        for (int r = 0; r < entries.length; r += 2) {
          final left = entries[r];
          final right = r + 1 < entries.length ? entries[r + 1] : null;

          // Left entry
          _drawDot(canvas, Offset(tablePad * 2 + dotSize / 2, ty + rowH / 2), left.color);
          _drawText(canvas, cl(left.label),
              Offset(tablePad * 2 + dotSize + 6, ty + (rowH - fontSize) / 2),
              fontSize: fontSize, color: const Color(0xFF6B7280), maxWidth: halfW - 90);
          _drawText(canvas, left.value,
              Offset(tablePad * 2 + halfW - 60, ty + (rowH - fontSize) / 2),
              fontSize: fontSize, color: const Color(0xFF111827), bold: true, maxWidth: 80);

          // Right entry
          if (right != null) {
            final rx = tablePad * 2 + halfW + 12;
            _drawDot(canvas, Offset(rx + dotSize / 2, ty + rowH / 2), right.color);
            _drawText(canvas, cl(right.label),
                Offset(rx + dotSize + 6, ty + (rowH - fontSize) / 2),
                fontSize: fontSize, color: const Color(0xFF6B7280), maxWidth: halfW - 90);
            _drawText(canvas, right.value,
                Offset(rx + halfW - 60, ty + (rowH - fontSize) / 2),
                fontSize: fontSize, color: const Color(0xFF111827), bold: true, maxWidth: 80);
          }

          ty += rowH;
        }

        offsetY += tableH;
      }

      offsetY += padding;
    }

    final picture = recorder.endRecording();
    final stitched = await picture.toImage(totalWidth, totalHeight.ceil());
    final byteData = await stitched.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    _triggerBrowserDownload(
      byteData.buffer.asUint8List(),
      'starbooks_analytics_${DateTime.now().millisecondsSinceEpoch}.png',
      'image/png',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Downloaded ${selected.length} chart(s) as one PNG!',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  /// Helper: draw a filled circle dot at [center] with [color].
  void _drawDot(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(center, 4, Paint()..color = color);
  }

  /// Helper: draw text using [TextPainter].
  void _drawText(
      Canvas canvas,
      String text,
      Offset offset, {
        double fontSize = 11,
        Color color = const Color(0xFF111827),
        bool bold = false,
        double maxWidth = 200,
      }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  Future<void> _downloadPDF(List<String> selected) async {
    final List<Uint8List> images = [];
    final List<String> captured = [];
    for (final name in selected) {
      final key = _chartKeys[name];
      if (key == null) continue;
      final bytes = await _captureWidget(key);
      if (bytes != null) {
        images.add(bytes);
        captured.add(name);
      }
    }
    if (images.isEmpty) return;

    final pdf = pw.Document();
    final pwImages = images.map((b) => pw.MemoryImage(b)).toList();

    // PdfColor helper from hex int
    PdfColor hexToPdf(int hex) => PdfColor(
      ((hex >> 16) & 0xFF) / 255,
      ((hex >> 8) & 0xFF) / 255,
      (hex & 0xFF) / 255,
    );

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        // ── Header ──────────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: hexToPdf(0xFF046EB8),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Starbooks Whiz Challenge',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              ),
              pw.Text(
                'Analytics Report',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated: ${DateTime.now().toString().substring(0, 19)}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 20),

        // ── One block per chart ──────────────────────────────────────────
        ...List.generate(pwImages.length, (i) {
          final chartName = captured[i];
          final entries = _chartTooltipData[chartName] ?? [];

          // Helper: clean label of special chars that don't render in default PDF font
          String cleanLabel(String s) => s
              .replaceAll('\u2013', '-')   // en-dash
              .replaceAll('\u2014', '-')   // em-dash
              .replaceAll('\u2022', '*')   // bullet
              .replaceAll('\u2019', "'")   // right single quote
              .replaceAll('\u00e2', '')    // corrupted UTF artifact
              .replaceAll('\u2026', '...') // ellipsis
              .trim();

          // Build two-column grid for the data rows (max 2 per row)
          final List<pw.Widget> dataRows = [];
          for (int r = 0; r < entries.length; r += 2) {
            final left = entries[r];
            final right = r + 1 < entries.length ? entries[r + 1] : null;

            // Use rounded rect instead of circle — PDF circle rendering can corrupt
            pw.Widget colorDot(Color c) => pw.Container(
              width: 8, height: 8,
              decoration: pw.BoxDecoration(
                color: hexToPdf(c.value & 0xFFFFFF),
                borderRadius: pw.BorderRadius.circular(4),
              ),
            );

            dataRows.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  children: [
                    // left cell
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          colorDot(left.color),
                          pw.SizedBox(width: 5),
                          pw.Expanded(
                            child: pw.Text(
                              cleanLabel(left.label),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            left.value,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    // right cell (may be empty)
                    pw.Expanded(
                      child: right == null
                          ? pw.SizedBox()
                          : pw.Row(
                        children: [
                          colorDot(right.color),
                          pw.SizedBox(width: 5),
                          pw.Expanded(
                            child: pw.Text(
                              cleanLabel(right.label),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            right.value,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Chart title bar
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border(left: pw.BorderSide(color: hexToPdf(0xFF046EB8), width: 3)),
                  ),
                  child: pw.Text(
                    chartName,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),

                // Chart image
                pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(pwImages[i], fit: pw.BoxFit.contain, height: 180),
                ),

                // Data counts table
                if (entries.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Data Summary',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Divider(height: 0.5, color: PdfColors.grey300),
                        pw.SizedBox(height: 6),
                        ...dataRows,
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    ));

    final pdfBytes = await pdf.save();
    _triggerBrowserDownload(
      pdfBytes,
      'starbooks_analytics_${DateTime.now().millisecondsSinceEpoch}.pdf',
      'application/pdf',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Downloaded ${selected.length} chart(s) as one PDF!',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  Future<void> _downloadCSV(List<String> selected) async {
    // Build CSV rows directly from _chartTooltipData so it's always accurate & complete
    final buffer = StringBuffer();
    buffer.writeln('Starbooks Whiz Challenge - Analytics Export');
    buffer.writeln('"Generated","${DateTime.now().toString().substring(0, 19)}"');
    buffer.writeln();

    // Static stat cards
    if (selected.contains('Total Registered Players')) {
      buffer.writeln('"=== Total Registered Players ==="');
      buffer.writeln('"Metric","Value"');
      buffer.writeln('"Total Registered Players","${_analytics?['total_players'] ?? '—'}"');
      buffer.writeln();
    }
    if (selected.contains('Average Feedback')) {
      buffer.writeln('"=== Average Feedback ==="');
      buffer.writeln('"Metric","Value"');
      buffer.writeln('"Average Feedback","${_analytics?['average_rating'] ?? '—'}"');
      buffer.writeln();
    }

    // Chart cards — pull every entry from _chartTooltipData
    final chartKeys = [
      'Male vs Female Registered Players',
      'Age Distribution of Players',
      'Registered Players by Region',
      'Male vs Female Players Per Game Mode',
      'Badge Distribution By Gender and Level',
      'Most Played Game Mode By Age',
    ];

    for (final name in chartKeys) {
      if (!selected.contains(name)) continue;
      final entries = _chartTooltipData[name] ?? [];
      if (entries.isEmpty) continue;

      buffer.writeln('"=== $name ==="');
      buffer.writeln('"Label","Value"');
      for (final e in entries) {
        // Clean label: remove bullet characters, trim spaces
        final cleanLabel = e.label.replaceAll('•', '-').trim();
        // Clean value: strip non-numeric suffix for the number column
        buffer.writeln('"$cleanLabel","${e.value}"');
      }
      buffer.writeln();
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    _triggerBrowserDownload(
      bytes,
      'starbooks_charts_${DateTime.now().millisecondsSinceEpoch}.csv',
      'text/csv',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('CSV downloaded!', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  void _exportChart(String chartTitle) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Chart',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                chartTitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Export Format',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // PNG
              _exportOptionBlue(
                icon: Icons.image_outlined,
                label: 'Export as PNG',
                onTap: () => _showLoadingAndExport([chartTitle], 'PNG', dialogCtx),
              ),
              const SizedBox(height: 10),
              // PDF
              _exportOptionBlue(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Export as PDF',
                onTap: () => _showLoadingAndExport([chartTitle], 'PDF', dialogCtx),
              ),
              const SizedBox(height: 10),
              // CSV
              _exportOptionBlue(
                icon: Icons.table_chart_outlined,
                label: 'Export as CSV',
                onTap: () => _showLoadingAndExport([chartTitle], 'CSV', dialogCtx),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF046EB8), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF046EB8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportOptionBlue({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    const color = Color(0xFF046EB8);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart({bool? isAscending}) {
    final gender = (_analytics?['gender_distribution'] as List<dynamic>?) ?? [];
    final male   = (gender.firstWhere((g) => g['label'] == 'Male',   orElse: () => {'count': 0})['count'] as num).toDouble();
    final female = (gender.firstWhere((g) => g['label'] == 'Female', orElse: () => {'count': 0})['count'] as num).toDouble();
    return CustomPaint(
      painter: PieChartPainter(isAscending: isAscending, male: male, female: female),
      child: Container(),
    );
  }

  Widget _buildBarChart({bool? isAscending}) {
    final ages = (_analytics?['age_distribution'] as List<dynamic>?) ?? [];
    return CustomPaint(
      painter: BarChartPainter(isAscending: isAscending, data: ages),
      child: Container(),
    );
  }

  Widget _buildRegionBarChart({bool? isAscending}) {
    final regions = (_analytics?['players_by_region'] as List<dynamic>?) ?? [];
    return CustomPaint(
      painter: RegionBarChartPainter(isAscending: isAscending, data: regions),
      child: Container(),
    );
  }

  // ── Empty-state overlay ─────────────────────────────────────────────────
  // Without this, a chart with zero counts across the board renders as a
  // totally blank white box — axis labels and legend show, but there's no
  // visual cue for *why* there are no bars, so it just looks broken. This
  // makes "there's genuinely no data yet" explicit instead of silent.
  bool _allCountsZero(List<dynamic> data, List<String> keys) {
    if (data.isEmpty) return true;
    for (final e in data) {
      for (final k in keys) {
        final v = e[k];
        if (v is num && v > 0) return false;
      }
    }
    return true;
  }

  Widget _withEmptyOverlay(Widget chart, bool isEmpty, {required String message}) {
    if (!isEmpty) return chart;
    return Stack(
      fit: StackFit.expand,
      children: [
        chart,
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.6,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedBarChart({bool? isAscending}) {
    final modes = (_analytics?['gender_by_game_mode'] as List<dynamic>?) ?? [];
    return _withEmptyOverlay(
      CustomPaint(
        painter: GroupedBarChartPainter(isAscending: isAscending, data: modes),
        child: Container(),
      ),
      _allCountsZero(modes, ['male', 'female']),
      message: 'No game sessions recorded yet',
    );
  }

  Widget _buildStackedBarChart({bool? isAscending}) {
    final badges = (_analytics?['badges_by_gender_level'] as List<dynamic>?) ?? [];
    return _withEmptyOverlay(
      CustomPaint(
        painter: StackedBarChartPainter(isAscending: isAscending, data: badges),
        child: Container(),
      ),
      _allCountsZero(badges, ['male', 'female']),
      message: 'No badges earned yet',
    );
  }

  Widget _buildMultiColorBarChart({bool? isAscending}) {
    final byAge = (_analytics?['game_mode_by_age'] as List<dynamic>?) ?? [];
    return _withEmptyOverlay(
      CustomPaint(
        painter: MultiColorBarChartPainter(isAscending: isAscending, data: byAge),
        child: Container(),
      ),
      _allCountsZero(byAge, ['memory_match', 'challenge', 'battle', 'puzzle']),
      message: 'No game sessions recorded yet',
    );
  }
}

// ── Tooltip data definitions ─────────────────────────────────────────────────
// NOTE: this used to be a `const` map of hand-typed numbers, which is why the
// tooltips/exports could show values that had nothing to do with the actual
// bars on screen (bars are painted from live `_analytics`, but the tooltip
// text was pulling from this separate fake map). It is now a plain mutable
// map that gets rebuilt from the same `_analytics` payload every time
// analytics is (re)loaded, so hovering, PNG/PDF export, and CSV export all
// show the same real numbers as the bars.
Map<String, List<_TooltipEntry>> _chartTooltipData = {};

/// Rebuilds [_chartTooltipData] from the live `/api/admin/analytics` payload.
/// Keeps the exact same keys/shape the UI already expects, just fed by real
/// numbers instead of hardcoded ones. Any field missing from the API simply
/// renders an empty tooltip list for that chart instead of fake data.
void _rebuildLiveTooltipData(Map<String, dynamic>? analytics) {
  const genderColor = {'Male': Color(0xFF046EB8), 'Female': Color(0xFF00C9B1)};

  final gender = (analytics?['gender_distribution'] as List<dynamic>?) ?? [];
  final ages = (analytics?['age_distribution'] as List<dynamic>?) ?? [];
  final regions = (analytics?['players_by_region'] as List<dynamic>?) ?? [];
  final modes = (analytics?['gender_by_game_mode'] as List<dynamic>?) ?? [];
  final badges = (analytics?['badges_by_gender_level'] as List<dynamic>?) ?? [];
  final byAge = (analytics?['game_mode_by_age'] as List<dynamic>?) ?? [];

  const ageColors = [
    Color(0xFF046EB8), Color(0xFF27AE60), Color(0xFFE67E22),
    Color(0xFF9B59B6), Color(0xFFFDD000), Color(0xFF4A90D9), Color(0xFF00C9B1),
  ];
  const regionColors = [
    Color(0xFF046EB8), Color(0xFF27AE60), Color(0xFFE67E22),
    Color(0xFF9B59B6), Color(0xFF4A90D9), Color(0xFFFDD000),
    Color(0xFF5B6FE8), Color(0xFF00C9B1), Color(0xFFE67E22), Color(0xFF046EB8),
  ];
  // ✅ FIX: same swap as MultiColorBarChartPainter — battle=orange, puzzle=purple, matching the legend.
  const modeColors = [Color(0xFFFDD000), Color(0xFF4A90D9), Color(0xFFE67E22), Color(0xFF9B59B6)];

  _chartTooltipData = {
    'Male vs Female Registered Players': gender.map((g) => _TooltipEntry(
      label: (g['label'] as String? ?? ''),
      value: '${g['count'] ?? 0} players',
      color: genderColor[g['label']] ?? const Color(0xFF046EB8),
    )).toList(),

    'Age Distribution of Players': [
      for (int i = 0; i < ages.length; i++)
        _TooltipEntry(
          label: ages[i]['range'] as String? ?? '',
          value: '${ages[i]['count'] ?? 0} players',
          color: ageColors[i % ageColors.length],
        ),
    ],

    'Registered Players by Region': [
      for (int i = 0; i < regions.length; i++)
        _TooltipEntry(
          label: regions[i]['region'] as String? ?? '',
          value: '${regions[i]['count'] ?? 0} players',
          color: regionColors[i % regionColors.length],
        ),
    ],

    'Male vs Female Players Per Game Mode': [
      for (final m in modes) ...[
        _TooltipEntry(label: '${m['mode'] ?? ''} — Male', value: '${m['male'] ?? 0} players', color: const Color(0xFF046EB8)),
        _TooltipEntry(label: '${m['mode'] ?? ''} — Female', value: '${m['female'] ?? 0} players', color: const Color(0xFF27AE60)),
      ],
    ],

    'Badge Distribution By Gender and Level': [
      for (final b in badges) ...[
        _TooltipEntry(label: '${b['level'] ?? ''} — Male', value: '${b['male'] ?? 0} badges', color: const Color(0xFF046EB8)),
        _TooltipEntry(label: '${b['level'] ?? ''} — Female', value: '${b['female'] ?? 0} badges', color: const Color(0xFF9B59B6)),
      ],
    ],

    'Most Played Game Mode By Age': [
      for (final a in byAge) ...[
        _TooltipEntry(label: '${a['age_range'] ?? ''} • Memory Match', value: '${a['memory_match'] ?? 0} plays', color: modeColors[0]),
        _TooltipEntry(label: '${a['age_range'] ?? ''} • Challenge', value: '${a['challenge'] ?? 0} plays', color: modeColors[1]),
        _TooltipEntry(label: '${a['age_range'] ?? ''} • Battle', value: '${a['battle'] ?? 0} plays', color: modeColors[2]),
        _TooltipEntry(label: '${a['age_range'] ?? ''} • Puzzle', value: '${a['puzzle'] ?? 0} plays', color: modeColors[3]),
      ],
    ],
  };
}

class _TooltipEntry {
  final String label;
  final String value;
  final Color color;
  const _TooltipEntry({required this.label, required this.value, required this.color});
}

// ── InteractiveChart ─────────────────────────────────────────────────────────

/// Returns the index of the hovered element, or -1 if none.
typedef ChartHitTest = int Function(Offset pos, Size size);

class InteractiveChart extends StatefulWidget {
  final String title;
  final Widget chart;
  final ChartHitTest? hitTest;
  const InteractiveChart({super.key, required this.title, required this.chart, this.hitTest});

  @override
  State<InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  bool _hovering = false;
  Offset _mousePos = Offset.zero;
  Size _chartSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    final allEntries = _chartTooltipData[widget.title] ?? [];

    // Determine which single entry to show based on hovered element
    _TooltipEntry? visible;
    if (_hovering && allEntries.isNotEmpty && widget.hitTest != null && _chartSize != Size.zero) {
      final idx = widget.hitTest!(_mousePos, _chartSize);
      if (idx >= 0 && idx < allEntries.length) visible = allEntries[idx];
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      onHover: (e) => setState(() => _mousePos = e.localPosition),
      child: GestureDetector(
        onTapDown: (d) => setState(() {
          _hovering = true;
          _mousePos = d.localPosition;
        }),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _chartSize = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: widget.chart),
                if (visible != null)
                  Positioned(
                    left: _tooltipLeft(_mousePos.dx, constraints.maxWidth),
                    top:  _tooltipTop(_mousePos.dy),
                    child: _buildTooltip(visible!),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _tooltipLeft(double x, double chartWidth) {
    const w = 180.0;
    return (x + 12 + w > chartWidth) ? x - w - 8 : x + 12;
  }

  double _tooltipTop(double y) => (y - 10).clamp(0.0, double.infinity);

  Widget _buildTooltip(_TooltipEntry e) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2736),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${e.label}  ',
                      style: const TextStyle(
                        fontFamily: 'Poppins', fontSize: 10, color: Colors.white60,
                      ),
                    ),
                    TextSpan(
                      text: e.value,
                      style: const TextStyle(
                        fontFamily: 'Poppins', fontSize: 10,
                        fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class PieChartPainter extends CustomPainter {
  final bool? isAscending;
  final double male;
  final double female;
  const PieChartPainter({this.isAscending, this.male = 0, this.female = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2 * 0.7;

    final total = male + female;
    // Previously this defaulted to a fake 75/25 split when there was no real
    // data, which drew a convincing-looking pie even with zero players — the
    // exact "still hardcoded?" issue. Now: no data = no fake slices, just an
    // empty outline so it's visually obvious there's nothing to show yet.
    if (total <= 0) {
      final emptyPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.grey.shade300;
      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }
    final maleValue  = male / total;
    final femaleValue = female / total;

    final sorted = isAscending == null
        ? [
      {'color': const Color(0xFF046EB8), 'sweep': maleValue},
      {'color': const Color(0xFF00C9B1), 'sweep': femaleValue},
    ]
        : (isAscending!
        ? [
      {'color': const Color(0xFF00C9B1), 'sweep': femaleValue},
      {'color': const Color(0xFF046EB8), 'sweep': maleValue},
    ]
        : [
      {'color': const Color(0xFF046EB8), 'sweep': maleValue},
      {'color': const Color(0xFF00C9B1), 'sweep': femaleValue},
    ]);

    double startAngle = -1.57;
    for (final slice in sorted) {
      paint.color = slice['color'] as Color;
      final sweep = (slice['sweep'] as double) * 2 * 3.1416;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, true, paint,
      );
      startAngle += sweep;
    }

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter old) =>
      old.isAscending != isAscending || old.male != male || old.female != female;
}

// Custom painter for the upload icon
class UploadIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw arrow shaft
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.8),
      Offset(size.width / 2, size.height * 0.2),
      paint,
    );

    // Draw arrow head (left side)
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.4),
      paint,
    );

    // Draw arrow head (right side)
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.2),
      Offset(size.width * 0.7, size.height * 0.4),
      paint,
    );

    // Draw base line
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.9),
      Offset(size.width * 0.8, size.height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarChartPainter extends CustomPainter {
  final bool? isAscending;
  final List<dynamic> data; // age_distribution from API
  const BarChartPainter({this.isAscending, this.data = const []});

  @override
  void paint(Canvas canvas, Size size) {
    const allColors = [
      Color(0xFF046EB8), Color(0xFF27AE60), Color(0xFFE67E22),
      Color(0xFF9B59B6), Color(0xFFFDD000), Color(0xFF4A90D9), Color(0xFF00C9B1),
    ];

    final source = data.isNotEmpty ? data : [
      {'range': '0-12', 'count': 0}, {'range': '13-17', 'count': 0},
      {'range': '18-22', 'count': 0}, {'range': '23-29', 'count': 0},
      {'range': '30-39', 'count': 0}, {'range': '40+', 'count': 0},
    ];

    final maxCount = source.fold<double>(1, (m, e) => math.max(m, ((e['count'] ?? 0) as num).toDouble()));

    final items = source.asMap().entries.map((entry) => {
      'label': entry.value['range'] as String? ?? '',
      'value': ((entry.value['count'] ?? 0) as num).toDouble() / maxCount,
      'color': allColors[entry.key % allColors.length],
    }).toList();

    if (isAscending != null) {
      items.sort((a, b) => isAscending!
          ? (a['value'] as double).compareTo(b['value'] as double)
          : (b['value'] as double).compareTo(a['value'] as double));
    }

    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final barWidth = size.width / (items.length * 2);

    for (int i = 0; i < items.length; i++) {
      final paint = Paint()..color = items[i]['color'] as Color;
      final x = i * barWidth * 2 + barWidth / 2;
      final barH = chartHeight * (items[i]['value'] as double);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, chartHeight - barH, barWidth, barH),
          const Radius.circular(4),
        ),
        paint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: items[i]['label'] as String,
          style: const TextStyle(color: Color(0xFF555555), fontSize: 8.5, fontFamily: 'Poppins'),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth * 2);
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, chartHeight + 3));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter old) =>
      old.isAscending != isAscending || old.data != data;
}

class RegionBarChartPainter extends CustomPainter {
  final bool? isAscending;
  final List<dynamic> data; // players_by_region from API
  const RegionBarChartPainter({this.isAscending, this.data = const []});

  // Layout constants shared with the chart card's hitTest so hover lines up.
  static const double labelAreaHeight = 52.0; // room for the rotated region name
  static const double topPadding      = 18.0; // room for the count above the bar
  static const double maxBarWidth     = 56.0; // stops 1-2 regions going full-bleed
  static const double minBarWidth     = 8.0;  // stops 20+ regions vanishing

  static const List<Color> palette = [
    Color(0xFF046EB8), Color(0xFF27AE60), Color(0xFFE67E22),
    Color(0xFF9B59B6), Color(0xFF4A90D9), Color(0xFFFDD000),
    Color(0xFF5B6FE8), Color(0xFF00C9B1), Color(0xFFE67E22), Color(0xFF046EB8),
  ];

  /// Original data indices in the order they are drawn left to right.
  /// hitTest uses this too, so tooltips stay correct after sorting.
  static List<int> orderedIndices(List<dynamic> data, bool? isAscending) {
    final idx = List<int>.generate(data.length, (i) => i);
    if (isAscending == null) return idx;
    double c(int i) => ((data[i]['count'] ?? 0) as num).toDouble();
    idx.sort((a, b) =>
        isAscending ? c(a).compareTo(c(b)) : c(b).compareTo(c(a)));
    return idx;
  }

  /// Single source of truth for bar geometry. [fraction] is 0..1 of the plot
  /// height; pass 1.0 to get the full hoverable column.
  static Rect barRect(Size size, int count, int position, double fraction) {
    final chartBottom = size.height - labelAreaHeight;
    final chartHeight = math.max(1.0, chartBottom - topPadding);
    final slotWidth   = size.width / math.max(1, count);
    final barWidth    =
        math.max(minBarWidth, math.min(maxBarWidth, slotWidth * 0.6));
    final left   = slotWidth * position + (slotWidth - barWidth) / 2;
    final height = chartHeight * fraction.clamp(0.0, 1.0);
    return Rect.fromLTWH(left, chartBottom - height, barWidth, height);
  }

  /// "CALABARZON (Region IV-A)" -> "CALABARZON". The parenthetical never fits
  /// under a narrow column and the name alone identifies the region.
  static String shortLabel(String raw) {
    final i = raw.indexOf('(');
    final head = i > 0 ? raw.substring(0, i).trim() : raw.trim();
    return head.isEmpty ? raw.trim() : head;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final order = orderedIndices(data, isAscending);
    final maxCount = data.fold<double>(
        1, (m, e) => math.max(m, ((e['count'] ?? 0) as num).toDouble()));

    final chartBottom = size.height - labelAreaHeight;

    // Baseline, so one short bar still reads as a chart.
    canvas.drawLine(
      Offset(0, chartBottom),
      Offset(size.width, chartBottom),
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..strokeWidth = 1,
    );

    for (int pos = 0; pos < order.length; pos++) {
      final src   = order[pos];
      final count = ((data[src]['count'] ?? 0) as num).toDouble();
      final rect  = barRect(size, order.length, pos, count / maxCount);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()..color = palette[src % palette.length],
      );

      final centerX = rect.left + rect.width / 2;

      // Count above the bar.
      final vp = TextPainter(
        text: TextSpan(
          text: count.toInt().toString(),
          style: const TextStyle(
            color: Color(0xFF444444),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      vp.paint(canvas, Offset(centerX - vp.width / 2, rect.top - vp.height - 3));

      // Rotated region name under the baseline, anchored by its right edge and
      // running down-left (the usual axis-label convention). The old version
      // painted outward from the anchor, which pushed text into the plot area.
      final tp = TextPainter(
        text: TextSpan(
          text: shortLabel(data[src]['region'] as String? ?? ''),
          style: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 8,
            fontFamily: 'Poppins',
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '\u2026',
      )..layout(maxWidth: 58);

      canvas.save();
      canvas.translate(centerX, chartBottom + 6);
      canvas.rotate(-45 * math.pi / 180);
      tp.paint(canvas, Offset(-tp.width, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant RegionBarChartPainter old) =>
      old.isAscending != isAscending || old.data != data;
}

class GroupedBarChartPainter extends CustomPainter {
  final bool? isAscending;
  final List<dynamic> data; // gender_by_game_mode from API
  const GroupedBarChartPainter({this.isAscending, this.data = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final source = data.isNotEmpty ? data : [
      {'mode': 'Memory Match', 'male': 0, 'female': 0},
      {'mode': 'Challenge', 'male': 0, 'female': 0},
      {'mode': 'Battle', 'male': 0, 'female': 0},
      {'mode': 'Puzzle', 'male': 0, 'female': 0},
    ];

    final maxVal = source.fold<double>(1, (m, e) =>
      math.max(m, math.max(((e['male'] ?? 0) as num).toDouble(), ((e['female'] ?? 0) as num).toDouble())));

    final groups = source.map((e) => {
      'label': e['mode'] as String? ?? '',
      'male':  ((e['male']   ?? 0) as num).toDouble() / maxVal,
      'female':((e['female'] ?? 0) as num).toDouble() / maxVal,
    }).toList();

    if (isAscending != null) {
      groups.sort((a, b) {
        final aT = (a['male'] as double) + (a['female'] as double);
        final bT = (b['male'] as double) + (b['female'] as double);
        return isAscending! ? aT.compareTo(bT) : bT.compareTo(aT);
      });
    }

    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final paint1 = Paint()..color = const Color(0xFF046EB8);
    final paint2 = Paint()..color = const Color(0xFF27AE60);
    final barWidth = size.width / (groups.length * 3);

    for (int i = 0; i < groups.length; i++) {
      final x = i * barWidth * 3;
      final mH = chartHeight * (groups[i]['male'] as double);
      final fH = chartHeight * (groups[i]['female'] as double);

      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - mH, barWidth, mH), const Radius.circular(4)), paint1);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x + barWidth, chartHeight - fH, barWidth, fH), const Radius.circular(4)), paint2);

      final tp = TextPainter(
        text: TextSpan(text: groups[i]['label'] as String,
          style: const TextStyle(color: Color(0xFF555555), fontSize: 8.5, fontFamily: 'Poppins')),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth * 3);
      tp.paint(canvas, Offset(x + barWidth - tp.width / 2, chartHeight + 3));
    }
  }

  @override
  bool shouldRepaint(covariant GroupedBarChartPainter old) =>
      old.isAscending != isAscending || old.data != data;
}

class StackedBarChartPainter extends CustomPainter {
  final bool? isAscending;
  final List<dynamic> data; // badges_by_gender_level from API
  const StackedBarChartPainter({this.isAscending, this.data = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final source = data.isNotEmpty ? data : [
      {'level': 'Easy', 'male': 0, 'female': 0},
      {'level': 'Average', 'male': 0, 'female': 0},
      {'level': 'Difficult', 'male': 0, 'female': 0},
    ];

    final maxVal = source.fold<double>(1, (m, e) =>
      math.max(m, ((e['male'] ?? 0) as num).toDouble() + ((e['female'] ?? 0) as num).toDouble()));

    final groups = source.map((e) => {
      'label':  e['level'] as String? ?? '',
      'male':   ((e['male']   ?? 0) as num).toDouble() / maxVal,
      'female': ((e['female'] ?? 0) as num).toDouble() / maxVal,
    }).toList();

    if (isAscending != null) {
      groups.sort((a, b) {
        final aT = (a['male'] as double);
        final bT = (b['male'] as double);
        return isAscending! ? aT.compareTo(bT) : bT.compareTo(aT);
      });
    }

    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final paint1 = Paint()..color = const Color(0xFF046EB8);
    final paint2 = Paint()..color = const Color(0xFF9B59B6);
    final barWidth = size.width / (groups.length * 2);

    for (int i = 0; i < groups.length; i++) {
      final x = i * barWidth * 2 + barWidth / 2;
      final mH = chartHeight * (groups[i]['male'] as double);
      final fH = chartHeight * (groups[i]['female'] as double);

      // ✅ FIX: female segment was drawn at the SAME y as the male segment
      // (chartHeight - mH), so it overlapped/hid behind the male bar instead
      // of stacking above it. It now starts above the male segment's top.
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - mH, barWidth, mH), const Radius.circular(4)), paint1);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - mH - fH, barWidth, fH), const Radius.circular(4)), paint2);

      final tp = TextPainter(
        text: TextSpan(text: groups[i]['label'] as String,
          style: const TextStyle(color: Color(0xFF555555), fontSize: 8.5, fontFamily: 'Poppins')),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth * 2);
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, chartHeight + 3));
    }
  }

  @override
  bool shouldRepaint(covariant StackedBarChartPainter old) =>
      old.isAscending != isAscending || old.data != data;
}

class MultiColorBarChartPainter extends CustomPainter {
  final bool? isAscending;
  final List<dynamic> data; // game_mode_by_age from API
  const MultiColorBarChartPainter({this.isAscending, this.data = const []});

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ FIX: was [Yellow, Blue, Purple, Orange] paired against
    // [memory_match, challenge, battle, puzzle] — that put Battle in
    // purple and Puzzle in orange, backwards from the legend below
    // (which says Battle=orange, Puzzle=purple). Swapped to match.
    const colors = [
      Color(0xFFFDD000), Color(0xFF4A90D9), Color(0xFFE67E22), Color(0xFF9B59B6),
    ];

    final source = data.isNotEmpty ? data : <dynamic>[];
    if (source.isEmpty) return;

    final maxVal = source.fold<double>(1, (m, e) {
      final vals = [(e['memory_match'] ?? 0), (e['challenge'] ?? 0), (e['battle'] ?? 0), (e['puzzle'] ?? 0)];
      return math.max(m, vals.fold<double>(0, (s, v) => s + (v as num).toDouble()));
    });

    final groups = source.map((e) => {
      'label': e['age_range'] as String? ?? '',
      'values': [
        ((e['memory_match'] ?? 0) as num).toDouble() / maxVal,
        ((e['challenge']    ?? 0) as num).toDouble() / maxVal,
        ((e['battle']       ?? 0) as num).toDouble() / maxVal,
        ((e['puzzle']       ?? 0) as num).toDouble() / maxVal,
      ],
    }).toList();

    if (isAscending != null) {
      groups.sort((a, b) {
        final aT = (a['values'] as List<double>).reduce((s, v) => s + v);
        final bT = (b['values'] as List<double>).reduce((s, v) => s + v);
        return isAscending! ? aT.compareTo(bT) : bT.compareTo(aT);
      });
    }

    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final groupWidth = size.width / groups.length;
    final barWidth = groupWidth / 5;

    for (int i = 0; i < groups.length; i++) {
      final values = groups[i]['values'] as List<double>;
      final groupX = i * groupWidth;

      for (int j = 0; j < 4; j++) {
        final paint = Paint()..color = colors[j];
        final h = chartHeight * values[j];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(groupX + j * barWidth, chartHeight - h, barWidth * 0.85, h),
            const Radius.circular(4),
          ),
          paint,
        );
      }

      final tp = TextPainter(
        text: TextSpan(text: groups[i]['label'] as String,
          style: const TextStyle(color: Color(0xFF555555), fontSize: 8.5, fontFamily: 'Poppins')),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: groupWidth);
      tp.paint(canvas, Offset(groupX + groupWidth / 2 - tp.width / 2, chartHeight + 3));
    }
  }

  @override
  bool shouldRepaint(covariant MultiColorBarChartPainter old) =>
      old.isAscending != isAscending || old.data != data;
}