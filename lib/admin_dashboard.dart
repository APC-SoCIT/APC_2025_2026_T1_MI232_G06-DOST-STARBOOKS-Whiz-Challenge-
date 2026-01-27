import 'package:flutter/material.dart';
import 'admin_leaderboard.dart';
import 'admin_login.dart';
import 'admin_users_players.dart';
import 'admin_users_admins.dart';
import 'admin_questions.dart';
import 'admin_difficulty.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _usersExpanded = false;
  bool _quizContentExpanded = false;
  Map<String, bool> _sortAscending = {};

  Future<void> _logoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images-icons/sadlogout.png",
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.logout,
                    size: 80,
                    color: Color(0xFF046EB8),
                  );
                },
              ),
              const SizedBox(height: 15),
              const Text(
                "Logout Confirmation",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to log out?",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF046EB8),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF046EB8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD000),
                        foregroundColor: const Color(0xFF816A03),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
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

    if (confirmed == true && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF94D2FD),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: const Color(0xFF1C2736),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              'assets/images-logo/starbookslogin.png',
              width: 160,
              height: 90,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, color: Colors.white, size: 40),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Menu items
          _buildMenuItem(Icons.analytics_outlined, 'Analytics', 0),
          _buildMenuItem(Icons.leaderboard_outlined, 'Leaderboard', 1),

          // Users expandable menu
          _buildExpandableMenuItem(
            Icons.people_outline,
            'Users',
            2,
            _usersExpanded,
                () {
              setState(() {
                _usersExpanded = !_usersExpanded;
              });
            },
          ),
          if (_usersExpanded) ...[
            _buildSubMenuItem(Icons.person_outline, 'Players', 3),
            _buildSubMenuItem(Icons.admin_panel_settings_outlined, 'Admins', 4),
          ],

          // Quiz Content expandable menu
          _buildExpandableMenuItem(
            Icons.quiz_outlined,
            'Quiz Content',
            5,
            _quizContentExpanded,
                () {
              setState(() {
                _quizContentExpanded = !_quizContentExpanded;
              });
            },
          ),
          if (_quizContentExpanded) ...[
            _buildSubMenuItem(Icons.question_answer_outlined, 'Questions', 6),
            _buildSubMenuItem(Icons.speed_outlined, 'Difficulty', 7),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          // Collapse expandable menus when selecting main items
          if (index == 0 || index == 1) {
            _usersExpanded = false;
            _quizContentExpanded = false;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF046EB8) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFFFFF), size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem(
      IconData icon,
      String title,
      int index,
      bool isExpanded,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,  // Keep transparent, don't highlight parent
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFFFFF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFFFFFFFF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 8, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF046EB8) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFFFFF), size: 18),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (empty space for alignment)
          const SizedBox(width: 40),

          // Center logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images-logo/mainlogo.png',
                height: 35,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.book,
                    size: 35,
                    color: Color(0xFF046EB8),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Right side buttons
          Row(
            children: [
              // Export button - only show on Analytics page (index 0)
              if (_selectedIndex == 0) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextButton.icon(
                    onPressed: _showExportDialog,
                    icon: const Icon(
                      Icons.upload_outlined,
                      size: 16,
                      color: Colors.black87,
                    ),
                    label: const Text(
                      'Export',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
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
                const SizedBox(width: 16),
              ],

              // Profile circle with logout functionality
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _logoutDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF046EB8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
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
      return const AdminUsersAdminsPage();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Top stat cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('2,348', 'Total Registered Players'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('3.9', 'Average Feedback'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // First row of charts (2 columns)
          Row(
            children: [
              Expanded(
                child: _buildChartCard(
                  'Male vs Female Registered Players',
                  _buildPieChart(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChartCard(
                  'Age Distribution of Players',
                  _buildBarChart(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Second row of charts (2 columns)
          Row(
            children: [
              Expanded(
                child: _buildChartCard(
                  'Registered Players by Region',
                  _buildHorizontalBarChart(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChartCard(
                  'Male vs Female Players Per Game Mode',
                  _buildGroupedBarChart(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Third row of charts (2 columns)
          Row(
            children: [
              Expanded(
                child: _buildChartCard(
                  'Rewards Distribution By Gender and Level',
                  _buildStackedBarChart(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChartCard(
                  'Most Played Game Mode By Age',
                  _buildMultiColorBarChart(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Row(
                children: [
                  // Sort button
                  InkWell(
                    onTap: () {
                      _toggleSort(title);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 2,
                            color: Colors.black54,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 10,
                            height: 2,
                            color: Colors.black54,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 6,
                            height: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Export/Upload button
                  InkWell(
                    onTap: () {
                      _exportChart(title);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CustomPaint(
                        size: const Size(16, 16),
                        painter: UploadIconPainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: chart),
        ],
      ),
    );
  }

  void _toggleSort(String chartTitle) {
    setState(() {
      _sortAscending[chartTitle] = !(_sortAscending[chartTitle] ?? false);
    });

    String order = _sortAscending[chartTitle]! ? 'ascending' : 'descending';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$chartTitle sorted in $order order'),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showExportDialog() {
    final List<String> chartTitles = [
      'Total Registered Players',
      'Average Feedback',
      'Male vs Female Registered Players',
      'Age Distribution of Players',
      'Registered Players by Region',
      'Male vs Female Players Per Game Mode',
      'Rewards Distribution By Gender and Level',
      'Most Played Game Mode By Age',
    ];

    Map<String, bool> selectedCharts = {
      for (var title in chartTitles) title: false
    };
    bool selectAll = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
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
                  // Select All checkbox
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
                  // Individual chart checkboxes
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
                  // Export format selection
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
                          onPressed: () {
                            _performExport(selectedCharts, 'PNG');
                          },
                          icon: const Icon(Icons.image, size: 18),
                          label: const Text(
                            'PNG',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _performExport(selectedCharts, 'PDF');
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text(
                            'PDF',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _performExport(selectedCharts, 'CSV');
                          },
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: const Text(
                            'CSV',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF046EB8),
                            side: const BorderSide(color: Color(0xFF046EB8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFF046EB8),
                              width: 1,
                            ),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _performExport(Map<String, bool> selectedCharts, String format) {
    Navigator.pop(context);

    final selected = selectedCharts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one chart to export'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String message;
    if (selected.length == 1) {
      message = 'Exporting "${selected[0]}" as $format...';
    } else if (selected.length == selectedCharts.length) {
      message = 'Exporting all charts as $format...';
    } else {
      message = 'Exporting ${selected.length} charts as $format...';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _exportChart(String chartTitle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Chart',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Export as PNG', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                leading: const Icon(Icons.image, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exporting $chartTitle as PNG...')),
                  );
                },
              ),
              ListTile(
                title: const Text('Export as PDF', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                leading: const Icon(Icons.picture_as_pdf, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exporting $chartTitle as PDF...')),
                  );
                },
              ),
              ListTile(
                title: const Text('Export as CSV', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                leading: const Icon(Icons.table_chart, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exporting $chartTitle as CSV...')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return CustomPaint(painter: PieChartPainter(), child: Container());
  }

  Widget _buildBarChart() {
    return CustomPaint(painter: BarChartPainter(), child: Container());
  }

  Widget _buildHorizontalBarChart() {
    return CustomPaint(
      painter: HorizontalBarChartPainter(),
      child: Container(),
    );
  }

  Widget _buildGroupedBarChart() {
    return CustomPaint(painter: GroupedBarChartPainter(), child: Container());
  }

  Widget _buildStackedBarChart() {
    return CustomPaint(painter: StackedBarChartPainter(), child: Container());
  }

  Widget _buildMultiColorBarChart() {
    return CustomPaint(
      painter: MultiColorBarChartPainter(),
      child: Container(),
    );
  }
}

class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2 * 0.7;

    // Light blue (larger portion)
    paint.color = const Color(0xFF90B8E8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      4.71,
      true,
      paint,
    );

    // Dark blue (smaller portion)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14,
      1.57,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4285F4);
    final values = [0.3, 0.5, 0.9, 0.4, 0.5, 0.4, 0.2];
    final barWidth = size.width / (values.length * 2);

    for (int i = 0; i < values.length; i++) {
      final x = i * barWidth * 2 + barWidth / 2;
      final height = size.height * values[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - height, barWidth, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HorizontalBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4285F4);
    final values = [0.95, 0.7, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3, 0.1];
    final barHeight = size.height / (values.length * 1.5);

    for (int i = 0; i < values.length; i++) {
      final y = i * barHeight * 1.5;
      final width = size.width * values[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y, width, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GroupedBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFF4285F4);
    final paint2 = Paint()..color = const Color(0xFF90B8E8);
    final groups = 4;
    final barWidth = size.width / (groups * 3);

    for (int i = 0; i < groups; i++) {
      final x = i * barWidth * 3;
      final rect1 = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height * 0.4, barWidth, size.height * 0.6),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect1, paint1);

      final rect2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + barWidth,
          size.height * 0.3,
          barWidth,
          size.height * 0.7,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StackedBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFF4285F4);
    final paint2 = Paint()..color = const Color(0xFF90B8E8);
    final groups = 3;
    final barWidth = size.width / (groups * 2);

    for (int i = 0; i < groups; i++) {
      final x = i * barWidth * 2 + barWidth / 2;

      // Bottom part
      final rect1 = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height * 0.3, barWidth, size.height * 0.7),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect1, paint1);

      // Top part
      final rect2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height * 0.3, barWidth, size.height * 0.4),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MultiColorBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFF39C12),
      const Color(0xFFFDD000),
      const Color(0xFF4285F4),
      const Color(0xFF27AE60),
    ];
    final groups = 4;
    final barWidth = size.width / (groups * 5);

    for (int i = 0; i < groups; i++) {
      final x = i * barWidth * 5;
      for (int j = 0; j < 4; j++) {
        final paint = Paint()..color = colors[j];
        final height = size.height * (0.3 + j * 0.1);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + j * barWidth,
            size.height - height,
            barWidth * 0.8,
            height,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
