import 'package:flutter/material.dart';

class AdminPlayersPage extends StatefulWidget {
  const AdminPlayersPage({super.key});

  @override
  State<AdminPlayersPage> createState() => _AdminPlayersPageState();
}

class _AdminPlayersPageState extends State<AdminPlayersPage> {
  int itemsPerPage = 9;
  int currentPageIndex = 0;
  String sortBy = 'username';
  bool sortAscending = true;
  Set<String> selectedCategories = {};
  Set<String> selectedRegions = {};
  Set<String> selectedDifficulties = {};
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> playersData = [
    {
      "username": "ronald",
      "avatar": "assets/images-avatars/Brainy.png",
      "category": "Student",
      "address": "NCR, Metro Manila, Caloocan City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
    {
      "username": "carla",
      "avatar": "assets/images-avatars/Girl.png",
      "category": "Student",
      "address": "NCR, Metro Manila, Makati City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
    {
      "username": "clarisse",
      "avatar": "assets/images-avatars/Twirky.png",
      "category": "Student",
      "address": "NCR, Metro Manila, Taguig City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
    {
      "username": "robert",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "category": "Employee",
      "address": "NCR, Metro Manila, Paranaque City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
    {
      "username": "jerome",
      "avatar": "assets/images-avatars/Brainy.png",
      "category": "Student",
      "address": "NCR, Metro Manila, Caloocan City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
    {
      "username": "ariel",
      "avatar": "assets/images-avatars/Twirky.png",
      "category": "Student",
      "address": "NCR, Metro Manila, Pasay City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
    {
      "username": "hannah",
      "avatar": "assets/images-avatars/Girl.png",
      "category": "Student",
      "address": "NCR, Metro Manila, Las Pinas City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
    {
      "username": "rico",
      "avatar": "assets/images-avatars/Sneaky-Snake.png",
      "category": "Student",
      "address": "NCR, Metro Manila, San Juan City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
    {
      "username": "marie",
      "avatar": "assets/images-avatars/Astronaut.png",
      "category": "Employee",
      "address": "NCR, Metro Manila, Quezon City",
      "logDate": "05/23/2025 15:45",
      "easy": 3,
      "average": 1,
      "difficult": 1,
    },
  ];

  List<Map<String, dynamic>> get filteredAndSortedPlayers {
    var filtered = playersData.where((player) {
      if (searchQuery.isNotEmpty) {
        String query = searchQuery.toLowerCase();
        if (!player['username'].toLowerCase().contains(query) &&
            !player['category'].toLowerCase().contains(query) &&
            !player['address'].toLowerCase().contains(query)) {
          return false;
        }
      }

      if (selectedCategories.isNotEmpty &&
          !selectedCategories.contains(player['category'])) {
        return false;
      }

      if (selectedRegions.isNotEmpty) {
        String region = player['address'].split(',')[0].trim();
        if (!selectedRegions.contains(region)) {
          return false;
        }
      }

      if (selectedDifficulties.isNotEmpty) {
        bool hasDifficulty = false;
        if (selectedDifficulties.contains('Easy') && player['easy'] > 0) {
          hasDifficulty = true;
        }
        if (selectedDifficulties.contains('Average') && player['average'] > 0) {
          hasDifficulty = true;
        }
        if (selectedDifficulties.contains('Difficult') &&
            player['difficult'] > 0) {
          hasDifficulty = true;
        }
        if (!hasDifficulty) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      int comparison = 0;
      switch (sortBy) {
        case 'username':
          comparison = a['username'].compareTo(b['username']);
          break;
        case 'category':
          comparison = a['category'].compareTo(b['category']);
          break;
        case 'address':
          comparison = a['address'].compareTo(b['address']);
          break;
        case 'logDate':
          comparison = a['logDate'].compareTo(b['logDate']);
          break;
        case 'easy':
          comparison = a['easy'].compareTo(b['easy']);
          break;
        case 'average':
          comparison = a['average'].compareTo(b['average']);
          break;
        case 'difficult':
          comparison = a['difficult'].compareTo(b['difficult']);
          break;
      }
      return sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _showBadgesDialog(Map<String, dynamic> player) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.amber.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images-badges/whiz-achiever.png',
                              width: 180,
                              height: 180,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.card_giftcard,
                                  size: 100,
                                  color: Colors.amber,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
                _buildBadgeRow(
                  'Easy',
                  player['easy'],
                  const Color(0xFF1D9358),
                  3,
                  'assets/images-badges/whiz-ready.png',
                ),
                const SizedBox(height: 24),
                _buildBadgeRow(
                  'Average',
                  player['average'],
                  const Color(0xFF046EB8),
                  3,
                  'assets/images-badges/whiz-happy.png',
                ),
                const SizedBox(height: 24),
                _buildBadgeRow(
                  'Difficult',
                  player['difficult'],
                  const Color(0xFFBD442E),
                  3,
                  'assets/images-badges/whiz-achiever.png',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeRow(
    String label,
    int earned,
    Color color,
    int total,
    String badgeImagePath,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        ...List.generate(total, (index) {
          bool isEarned = index < earned;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
                color: isEarned ? Colors.white : Colors.grey.shade200,
              ),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    badgeImagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    color: isEarned ? null : Colors.grey.shade400,
                    colorBlendMode: isEarned ? BlendMode.dst : BlendMode.srcIn,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.emoji_events,
                        size: 40,
                        color: isEarned ? color : Colors.grey.shade400,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: earned >= total ? color : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            earned >= total ? 'REWARD' : 'LOCKED',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  void _refreshPlayersList() {
    setState(() {
      searchController.clear();
      searchQuery = '';
      selectedCategories.clear();
      selectedRegions.clear();
      selectedDifficulties.clear();
      sortBy = 'username';
      sortAscending = true;
      currentPageIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Player list refreshed'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = filteredAndSortedPlayers;
    final startIndex = currentPageIndex * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredPlayers.length,
    );
    final displayedPlayers = filteredPlayers.sublist(startIndex, endIndex);
    final totalPages = (filteredPlayers.length / itemsPerPage).ceil();

    return Container(
      color: const Color(0xFF94D2FD),
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
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
              children: [
                const Icon(Icons.people, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'List of Players',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(fontFamily: 'Poppins'),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                currentPageIndex = 0;
                              });
                            },
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                searchController.clear();
                                searchQuery = '';
                                currentPageIndex = 0;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('ADD NEW PLAYER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046EB8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _refreshPlayersList,
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showSortDialog(),
                  icon: const Icon(Icons.sort, size: 18),
                  label: const Text('Sort'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showFilterDialog(),
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(width: 60),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Username",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Category",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "Address",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Log Date",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Average",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Difficult",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Actions",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: displayedPlayers.length,
                        itemBuilder: (context, index) {
                          final player = displayedPlayers[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: index < displayedPlayers.length - 1
                                    ? BorderSide(color: Colors.grey.shade300)
                                    : BorderSide.none,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF046EB8),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      player["avatar"],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              color: Color(0xFF046EB8),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    player["username"],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    player["category"],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    player["address"],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    player["logDate"],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${player["easy"]}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${player["average"]}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${player["difficult"]}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.badge,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _showBadgesDialog(player),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'View Badges',
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit',
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.key,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Reset Password',
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Items per page:',
                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: itemsPerPage,
                        underline: const SizedBox(),
                        items: [9, 18, 27].map((value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              '$value',
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            itemsPerPage = value!;
                            currentPageIndex = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Text(
                  '${startIndex + 1}-$endIndex of ${filteredPlayers.length}',
                  style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page),
                      onPressed: currentPageIndex > 0
                          ? () => setState(() => currentPageIndex = 0)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: currentPageIndex > 0
                          ? () => setState(() => currentPageIndex--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: currentPageIndex < totalPages - 1
                          ? () => setState(() => currentPageIndex++)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page),
                      onPressed: currentPageIndex < totalPages - 1
                          ? () => setState(
                              () => currentPageIndex = totalPages - 1,
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Sort Options',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sort by:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Username',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: 'username',
                      groupValue: sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          if (sortBy == value) {
                            sortAscending = !sortAscending;
                          } else {
                            sortBy = value!;
                            sortAscending = true;
                          }
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Category',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: 'category',
                      groupValue: sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          if (sortBy == value) {
                            sortAscending = !sortAscending;
                          } else {
                            sortBy = value!;
                            sortAscending = true;
                          }
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Address',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: 'address',
                      groupValue: sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          if (sortBy == value) {
                            sortAscending = !sortAscending;
                          } else {
                            sortBy = value!;
                            sortAscending = true;
                          }
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Log Date',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: 'logDate',
                      groupValue: sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          if (sortBy == value) {
                            sortAscending = !sortAscending;
                          } else {
                            sortBy = value!;
                            sortAscending = true;
                          }
                        });
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Sort by Badges:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Easy',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: 'easy',
                      groupValue: sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          if (sortBy == value) {
                            sortAscending = !sortAscending;
                          } else {
                            sortBy = value!;
                            sortAscending = true;
                          }
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Average',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: 'average',
                      groupValue: sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          if (sortBy == value) {
                            sortAscending = !sortAscending;
                          } else {
                            sortBy = value!;
                            sortAscending = true;
                          }
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                        'Difficult',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: 'difficult',
                      groupValue: sortBy,
                      onChanged: (value) {
                        setDialogState(() {
                          if (sortBy == value) {
                            sortAscending = !sortAscending;
                          } else {
                            sortBy = value!;
                            sortAscending = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentPageIndex = 0;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046EB8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Filter Options',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Student',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: selectedCategories.contains('Student'),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedCategories.add('Student');
                          } else {
                            selectedCategories.remove('Student');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Employee',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: selectedCategories.contains('Employee'),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedCategories.add('Employee');
                          } else {
                            selectedCategories.remove('Employee');
                          }
                        });
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Region:',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'NCR',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: selectedRegions.contains('NCR'),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedRegions.add('NCR');
                          } else {
                            selectedRegions.remove('NCR');
                          }
                        });
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Badges (Difficulty):',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Easy',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: selectedDifficulties.contains('Easy'),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedDifficulties.add('Easy');
                          } else {
                            selectedDifficulties.remove('Easy');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Average',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: selectedDifficulties.contains('Average'),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedDifficulties.add('Average');
                          } else {
                            selectedDifficulties.remove('Average');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Difficult',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      value: selectedDifficulties.contains('Difficult'),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedDifficulties.add('Difficult');
                          } else {
                            selectedDifficulties.remove('Difficult');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedCategories.clear();
                      selectedRegions.clear();
                      selectedDifficulties.clear();
                    });
                  },
                  child: const Text('Clear All'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentPageIndex = 0;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046EB8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
