import 'package:flutter/material.dart';

// ── Sidebar as its own widget ────────────────────────────────────────────
// Pulled out of _AdminDashboardState so that collapsing the sidebar or
// expanding the Users/Quiz Content submenus only rebuilds this small widget
// tree instead of the whole dashboard (all 8 analytics charts included).
// Owns its own collapse/expand UI state; selection is reported up via
// onSelect so the parent can swap the main content page.
class AdminSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Map<String, dynamic> adminData;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.adminData,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  bool _usersExpanded = false;
  bool _quizContentExpanded = false;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _collapsed ? 70 : 230,
              color: const Color(0xFF1C2736),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hamburger + logo row
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() {
                        _collapsed = !_collapsed;
                        if (_collapsed) {
                          _usersExpanded = false;
                          _quizContentExpanded = false;
                        }
                      }),
                      child: SizedBox(
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _collapsed
                              ? Center(child: _buildHamburger())
                              : Row(
                            children: [
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: SizedBox(
                                  width: 140,
                                  child: Image.asset(
                                    'assets/images-logo/newhomepagelogo.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.centerLeft,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              _buildHamburger(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6.4),

                  // Menu items
                  _buildMenuItem(Icons.analytics_outlined, 'Analytics', 0),
                  const SizedBox(height: 3.2),
                  _buildMenuItem(Icons.leaderboard_outlined, 'Leaderboard', 1),

                  const SizedBox(height: 3.2),
                  // Users
                  _collapsed
                      ? _buildCollapsedDropdownMenu(
                    Icons.people_outline,
                    'Users',
                    [
                      {
                        'icon': Icons.person_outline,
                        'title': 'Players',
                        'index': 3,
                      },
                      {
                        'icon': Icons.admin_panel_settings_outlined,
                        'title': 'Admins',
                        'index': 4,
                      },
                    ],
                  )
                      : _buildExpandableMenuItem(
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

                  ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      heightFactor: _usersExpanded && !_collapsed
                          ? 1.0
                          : 0.0,
                      child: Column(
                        children: [
                          _buildSubMenuItem(Icons.person_outline, 'Players', 3),
                          _buildSubMenuItem(
                            Icons.admin_panel_settings_outlined,
                            'Admins',
                            4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 3.2),
                  // Quiz Content
                  _collapsed
                      ? _buildCollapsedDropdownMenu(
                    Icons.quiz_outlined,
                    'Quiz Content',
                    [
                      {
                        'icon': Icons.question_answer_outlined,
                        'title': 'Questions',
                        'index': 6,
                      },
                      {
                        'icon': Icons.speed_outlined,
                        'title': 'Difficulty',
                        'index': 7,
                      },
                    ],
                  )
                      : _buildExpandableMenuItem(
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

                  ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      heightFactor: _quizContentExpanded && !_collapsed
                          ? 1.0
                          : 0.0,
                      child: Column(
                        children: [
                          _buildSubMenuItem(
                            Icons.question_answer_outlined,
                            'Questions',
                            6,
                          ),
                          _buildSubMenuItem(
                            Icons.speed_outlined,
                            'Difficulty',
                            7,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Profile section at bottom
                  Container(
                    decoration: !_collapsed
                        ? const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFF2A3A52),
                          width: 0.8,
                        ),
                      ),
                    )
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
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
                            child: widget.adminData['image'] != null && (widget.adminData['image'] as String).isNotEmpty
                                ? Image.network(
                              widget.adminData['image'],
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
                            )
                                : Image.asset(
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
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: !_collapsed
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 9.6),
                              AnimatedOpacity(
                                duration: const Duration(
                                  milliseconds: 250,
                                ),
                                opacity: _collapsed ? 0.0 : 1.0,
                                child: Text(
                                  widget.adminData['username'] ?? 'Admin',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.2,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


          ],
        );
      },
    );
  }

  Widget _buildHamburger() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 12.8, height: 1.6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.80), borderRadius: BorderRadius.circular(1.6))),
        const SizedBox(height: 3.2),
        Container(width: 12.8, height: 1.6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.80), borderRadius: BorderRadius.circular(1.6))),
        const SizedBox(height: 3.2),
        Container(width: 12.8, height: 1.6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.80), borderRadius: BorderRadius.circular(1.6))),
      ],
    );
  }

  Widget _buildCollapsedDropdownMenu(
      IconData icon,
      String title,
      List<Map<String, dynamic>> items,
      ) {
    return PopupMenuButton<int>(
      tooltip: title,
      offset: const Offset(70, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6.4),
          bottomRight: Radius.circular(6.4),
        ),
      ),
      color: const Color(0xFF1C2736),
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<int>(
            value: item['index'],
            height: 38.4,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item['icon'], size: 16, color: Colors.white),
                const SizedBox(width: 9.6),
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (index) => widget.onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4.8),
        ),
        child: Center(
          child: Icon(icon, color: const Color(0xFFFFFFFF), size: 16),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = widget.selectedIndex == index;
    return InkWell(
      onTap: () {
        widget.onSelect(index);
        if (index == 0 || index == 1) {
          setState(() {
            _usersExpanded = false;
            _quizContentExpanded = false;
          });
        }
      },
      child: Tooltip(
        message: _collapsed ? title : '',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF046EB8) : Colors.transparent,
            borderRadius: BorderRadius.circular(4.8),
          ),
          child: _collapsed
              ? Center(child: Icon(icon, color: const Color(0xFFFFFFFF), size: 16))
              : Row(
            children: [
              SizedBox(
                width: 16,
                child: Icon(icon, color: const Color(0xFFFFFFFF), size: 16),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 9.6),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: 1.0,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 10.4,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4.8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              child: Icon(icon, color: const Color(0xFFFFFFFF), size: 16),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: !_collapsed
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 9.6),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _collapsed ? 0.0 : 1.0,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 10.4,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),
            const Spacer(),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _collapsed ? 0.0 : 1.0,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: isExpanded ? 0.5 : 0,
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFFFFFFF),
                  size: 14.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(IconData icon, String title, int index) {
    final isSelected = widget.selectedIndex == index;
    return InkWell(
      onTap: () => widget.onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(left: 19.2, right: 6.4, top: 1.6, bottom: 1.6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF046EB8) : Colors.transparent,
          borderRadius: BorderRadius.circular(4.8),
        ),
        child: Row(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: 1.0,
              child: Icon(icon, color: const Color(0xFFFFFFFF), size: 14.4),
            ),
            const SizedBox(width: 9.6),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: 1.0,
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 9.6,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}