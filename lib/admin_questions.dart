import 'package:flutter/material.dart';

class AdminQuizQuestionsPage extends StatefulWidget {
  const AdminQuizQuestionsPage({super.key});

  @override
  State<AdminQuizQuestionsPage> createState() => _AdminQuizQuestionsPageState();
}

class _AdminQuizQuestionsPageState extends State<AdminQuizQuestionsPage> {
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  int itemsPerPage = 4;
  int currentPageIndex = 0;

  // Filter & Sort States
  String? selectedYearFilter;
  String? selectedCategoryFilter;
  String? selectedDifficultyFilter;
  bool? selectedStatusFilter;
  String sortColumn = 'id';
  bool sortAscending = true;

  List<Map<String, dynamic>> questionsData = [
    {
      "id": 1,
      "question":
          "Which organ is responsible for pumping blood throughout the body?",
      "yearLevel": "Junior (Grade 7-10)",
      "category": "Science",
      "correctAnswer": "Heart",
      "options": ["Brain", "Lungs", "Heart", "Liver"],
      "difficulty": "Easy",
      "status": true,
    },
    {
      "id": 2,
      "question": "What is the chemical symbol for water?",
      "yearLevel": "Junior (Grade 7-10)",
      "category": "Science",
      "correctAnswer": "H2O",
      "options": ["O2", "H2O", "CO2", "NaCl"],
      "difficulty": "Average",
      "status": true,
    },
    {
      "id": 3,
      "question": "Which gas do plants absorb during photosynthesis?",
      "yearLevel": "Junior (Grade 7-10)",
      "category": "Science",
      "correctAnswer": "Carbon dioxide (CO₂)",
      "options": ["Oxygen", "Nitrogen", "Carbon dioxide (CO₂)", "Hydrogen"],
      "difficulty": "Average",
      "status": true,
    },
    {
      "id": 4,
      "question": "What part of the plant makes food using sunlight?",
      "yearLevel": "Elem (Grade 1-6)",
      "category": "Science",
      "correctAnswer": "Leaves",
      "options": ["Roots", "Stem", "Leaves", "Flowers"],
      "difficulty": "Easy",
      "status": true,
    },
    {
      "id": 5,
      "question": "What is the capital of France?",
      "yearLevel": "Junior (Grade 7-10)",
      "category": "Geography",
      "correctAnswer": "Paris",
      "options": ["London", "Berlin", "Madrid", "Paris"],
      "difficulty": "Easy",
      "status": true,
    },
    {
      "id": 6,
      "question": "Who painted the Mona Lisa?",
      "yearLevel": "Senior (Grade 11-12)",
      "category": "Arts",
      "correctAnswer": "Leonardo da Vinci",
      "options": ["Picasso", "Van Gogh", "Leonardo da Vinci", "Michelangelo"],
      "difficulty": "Average",
      "status": false,
    },
  ];

  List<Map<String, dynamic>> get filteredQuestions {
    List<Map<String, dynamic>> list = questionsData.where((question) {
      bool matchesSearch = question['question'].toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      bool matchesYear =
          selectedYearFilter == null ||
          question['yearLevel'] == selectedYearFilter;

      bool matchesCategory =
          selectedCategoryFilter == null ||
          question['category'] == selectedCategoryFilter;

      bool matchesDifficulty =
          selectedDifficultyFilter == null ||
          question['difficulty'] == selectedDifficultyFilter;

      bool matchesStatus =
          selectedStatusFilter == null ||
          question['status'] == selectedStatusFilter;

      return matchesSearch &&
          matchesYear &&
          matchesCategory &&
          matchesDifficulty &&
          matchesStatus;
    }).toList();

    list.sort((a, b) {
      final aValue = a[sortColumn].toString();
      final bValue = b[sortColumn].toString();

      int comparison;
      if (sortColumn == 'id') {
        comparison = (a['id'] as int).compareTo(b['id'] as int);
      } else {
        comparison = aValue.compareTo(bValue);
      }

      return sortAscending ? comparison : -comparison;
    });

    return list;
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => QuestionFilterDialog(
        initialYearLevel: selectedYearFilter,
        initialCategory: selectedCategoryFilter,
        initialDifficulty: selectedDifficultyFilter,
        initialStatus: selectedStatusFilter,
        onApply: (year, category, difficulty, status) {
          setState(() {
            selectedYearFilter = year;
            selectedCategoryFilter = category;
            selectedDifficultyFilter = difficulty;
            selectedStatusFilter = status;
            currentPageIndex = 0;
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            selectedYearFilter = null;
            selectedCategoryFilter = null;
            selectedDifficultyFilter = null;
            selectedStatusFilter = null;
            currentPageIndex = 0;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openSortDialog() {
    showDialog(
      context: context,
      builder: (context) => QuestionSortDialog(
        initialSortColumn: sortColumn,
        initialSortAscending: sortAscending,
        onApply: (column, ascending) {
          setState(() {
            sortColumn = column;
            sortAscending = ascending;
            currentPageIndex = 0;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleRefresh() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      searchController.clear();
      searchQuery = '';
      currentPageIndex = 0;
      isLoading = false;
      selectedYearFilter = null;
      selectedCategoryFilter = null;
      selectedDifficultyFilter = null;
      selectedStatusFilter = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data refreshed successfully'),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleImport() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final newQuestions = [
      {
        "id": DateTime.now().millisecondsSinceEpoch,
        "question": "Imported Question 1: What is 2 + 2?",
        "yearLevel": "Elem (Grade 1-6)",
        "category": "Math",
        "correctAnswer": "4",
        "options": ["3", "4", "5", "6"],
        "difficulty": "Easy",
        "status": true,
      },
      {
        "id": DateTime.now().millisecondsSinceEpoch + 1,
        "question": "Imported Question 2: Speed of light?",
        "yearLevel": "Senior (Grade 11-12)",
        "category": "Physics",
        "correctAnswer": "299,792 km/s",
        "options": ["300 km/s", "150,000 km/s", "299,792 km/s", "Unknown"],
        "difficulty": "Hard",
        "status": false,
      },
    ];

    setState(() {
      questionsData.addAll(newQuestions);
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newQuestions.length} questions imported.'),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _deleteQuestion(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        onConfirm: () {
          setState(() {
            questionsData.removeWhere((item) => item['id'] == question['id']);
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Question deleted.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openQuestionDialog({Map<String, dynamic>? question}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuestionEditorDialog(
        existingQuestion: question,
        onSave: (Map<String, dynamic> newData) {
          setState(() {
            if (question == null) {
              newData['id'] = DateTime.now().millisecondsSinceEpoch;
              newData['status'] = true;
              questionsData.insert(0, newData);
            } else {
              final index = questionsData.indexWhere(
                (item) => item['id'] == question['id'],
              );
              if (index != -1) {
                questionsData[index] = {...question, ...newData};
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedQuestions = filteredQuestions;
    final startIndex = currentPageIndex * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      displayedQuestions.length,
    );
    final paginatedQuestions = displayedQuestions.sublist(startIndex, endIndex);
    final totalPages = (displayedQuestions.length / itemsPerPage).ceil();

    if (currentPageIndex >= totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          currentPageIndex = totalPages - 1;
        });
      });
    }

    bool isFilterActive =
        selectedYearFilter != null ||
        selectedCategoryFilter != null ||
        selectedDifficultyFilter != null ||
        selectedStatusFilter != null;

    return Stack(
      children: [
        Container(
          color: const Color(0xFF94D2FD),
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.list_alt, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'List of Questions',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _handleImport,
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          label: const Text('Import'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openQuestionDialog(),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('ADD QUESTION'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF046EB8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _handleRefresh,
                          icon: const Icon(Icons.refresh),
                          style: IconButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[600]),
                            const SizedBox(width: 12),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _openSortDialog,
                      icon: Icon(
                        sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 18,
                      ),
                      label: Text(
                        'Sort by ${sortColumn.toUpperCase()}',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _openFilterDialog,
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: Text(
                        isFilterActive ? 'Filter (Active)' : 'Filter',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFilterActive
                            ? Colors.white
                            : Colors.black87,
                        backgroundColor: isFilterActive
                            ? Colors.orange
                            : Colors.transparent,
                        side: BorderSide(
                          color: isFilterActive
                              ? Colors.orange
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Question',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Year Level',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Category',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Correct Answer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Difficulty',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Actions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: paginatedQuestions.length,
                            itemBuilder: (context, index) {
                              final question = paginatedQuestions[index];
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom:
                                        index < paginatedQuestions.length - 1
                                        ? BorderSide(
                                            color: Colors.grey.shade300,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        question['question'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        question['yearLevel'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        question['category'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        question['correctAnswer'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        question['difficulty'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Switch(
                                          value: question['status'],
                                          onChanged: (value) {
                                            setState(() {
                                              question['status'] = value;
                                            });
                                          },
                                          activeThumbColor: const Color(
                                            0xFF046EB8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _deleteQuestion(question),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Delete',
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _openQuestionDialog(
                                                  question: question,
                                                ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Edit',
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
                            items: [4, 8, 12, 20].map((value) {
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
                    if (displayedQuestions.isNotEmpty)
                      Text(
                        '${startIndex + 1}-$endIndex of ${displayedQuestions.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
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
        ),
        if (isLoading)
          Container(
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

// Dialogs

class DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400, // Add this line
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Are you sure you want to delete this question?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionFilterDialog extends StatefulWidget {
  final String? initialYearLevel;
  final String? initialCategory;
  final String? initialDifficulty;
  final bool? initialStatus;
  final Function(String?, String?, String?, bool?) onApply;
  final VoidCallback onClear;

  const QuestionFilterDialog({
    super.key,
    this.initialYearLevel,
    this.initialCategory,
    this.initialDifficulty,
    this.initialStatus,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<QuestionFilterDialog> createState() => _QuestionFilterDialogState();
}

class _QuestionFilterDialogState extends State<QuestionFilterDialog> {
  late String? yearLevel;
  late String? category;
  late String? difficulty;
  late bool? status;

  final List<String> yearLevels = [
    'Elem (Grade 1-6)',
    'Junior (Grade 7-10)',
    'Senior (Grade 11-12)',
  ];
  final List<String> categories = [
    'Science',
    'Math',
    'Geography',
    'Arts',
    'Physics',
  ];
  final List<String> difficulties = ['Easy', 'Average', 'Hard'];

  @override
  void initState() {
    super.initState();
    yearLevel = widget.initialYearLevel;
    category = widget.initialCategory;
    difficulty = widget.initialDifficulty;
    status = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Questions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const Divider(height: 30),
            _buildDropdownFilter(
              label: 'Year Level',
              currentValue: yearLevel,
              items: yearLevels,
              onChanged: (v) => setState(() => yearLevel = v),
            ),
            _buildDropdownFilter(
              label: 'Category',
              currentValue: category,
              items: categories,
              onChanged: (v) => setState(() => category = v),
            ),
            _buildDropdownFilter(
              label: 'Difficulty',
              currentValue: difficulty,
              items: difficulties,
              onChanged: (v) => setState(() => difficulty = v),
            ),
            _buildStatusFilter(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: widget.onClear,
                  child: const Text(
                    'Clear Filters',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => widget.onApply(
                        yearLevel,
                        category,
                        difficulty,
                        status,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046EB8),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
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

  Widget _buildDropdownFilter({
    required String label,
    required String? currentValue,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                hint: const Text('All'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatusChip('All', null),
              const SizedBox(width: 8),
              _buildStatusChip('Active', true),
              const SizedBox(width: 8),
              _buildStatusChip('Inactive', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool? value) {
    bool isSelected = status == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue.withValues(alpha: 0.1),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300),
      onSelected: (selected) {
        setState(() {
          status = value;
        });
      },
    );
  }
}

class QuestionSortDialog extends StatefulWidget {
  final String initialSortColumn;
  final bool initialSortAscending;
  final Function(String, bool) onApply;

  const QuestionSortDialog({
    super.key,
    required this.initialSortColumn,
    required this.initialSortAscending,
    required this.onApply,
  });

  @override
  State<QuestionSortDialog> createState() => _QuestionSortDialogState();
}

class _QuestionSortDialogState extends State<QuestionSortDialog> {
  late String sortColumn;
  late bool sortAscending;

  final Map<String, String> sortOptions = const {
    'id': 'ID (Default)',
    'question': 'Question',
    'yearLevel': 'Year Level',
    'category': 'Category',
    'difficulty': 'Difficulty',
  };

  @override
  void initState() {
    super.initState();
    sortColumn = widget.initialSortColumn;
    sortAscending = widget.initialSortAscending;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Questions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const Divider(height: 30),
            const Text(
              'Sort By:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortColumn,
                  isExpanded: true,
                  items: sortOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => sortColumn = v!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildOrderChip('Ascending (A-Z, 1-9)', true)),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOrderChip('Descending (Z-A, 9-1)', false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => widget.onApply(sortColumn, sortAscending),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046EB8),
                  ),
                  child: const Text(
                    'Apply Sort',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderChip(String label, bool value) {
    bool isSelected = sortAscending == value;
    return ChoiceChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
      ),
      selected: isSelected,
      selectedColor: Colors.blue.withValues(alpha: 0.1),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300),
      onSelected: (selected) {
        setState(() {
          sortAscending = value;
        });
      },
    );
  }
}

class QuestionEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? existingQuestion;
  final Function(Map<String, dynamic>) onSave;

  const QuestionEditorDialog({
    super.key,
    this.existingQuestion,
    required this.onSave,
  });

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  String? selectedCategory;
  String? selectedYearLevel;
  String? selectedDifficulty;
  int selectedCorrectOptionIndex = 0;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;
    _questionController = TextEditingController(text: q?['question'] ?? '');

    List<String> options = q != null && q['options'] != null
        ? List<String>.from(q['options'])
        : ['', '', '', ''];

    _optionControllers = options
        .map((opt) => TextEditingController(text: opt))
        .toList();

    selectedCategory = q?['category'];
    selectedYearLevel = q?['yearLevel'];
    selectedDifficulty = q?['difficulty'];

    if (q != null && q['correctAnswer'] != null) {
      int index = options.indexOf(q['correctAnswer']);
      if (index != -1) selectedCorrectOptionIndex = index;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, size: 28, color: Colors.black87),
                const SizedBox(width: 12),
                Text(
                  widget.existingQuestion == null
                      ? 'Add Question'
                      : 'Edit Question',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    hint: 'Category',
                    value: selectedCategory,
                    items: const [
                      'Science',
                      'Math',
                      'Geography',
                      'Arts',
                      'Physics',
                    ],
                    onChanged: (v) => setState(() => selectedCategory = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    hint: 'Year Level',
                    value: selectedYearLevel,
                    items: const [
                      'Elem (Grade 1-6)',
                      'Junior (Grade 7-10)',
                      'Senior (Grade 11-12)',
                    ],
                    onChanged: (v) => setState(() => selectedYearLevel = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    hint: 'Difficulty',
                    value: selectedDifficulty,
                    items: const ['Easy', 'Average', 'Hard'],
                    onChanged: (v) => setState(() => selectedDifficulty = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.format_bold, size: 20),
                        const SizedBox(width: 12),
                        const Icon(Icons.format_italic, size: 20),
                        const SizedBox(width: 12),
                        const Icon(Icons.format_underlined, size: 20),
                        const SizedBox(width: 12),
                        const Icon(Icons.strikethrough_s, size: 20),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Icon(Icons.format_list_bulleted, size: 20),
                        const SizedBox(width: 12),
                        const Icon(Icons.format_list_numbered, size: 20),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Icon(Icons.image_outlined, size: 20),
                        const SizedBox(width: 12),
                        const Icon(Icons.attach_file, size: 20),
                        const SizedBox(width: 12),
                        const Icon(Icons.more_horiz, size: 20),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type a question...',
                      hintStyle: TextStyle(fontFamily: 'Poppins'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 6,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => selectedCorrectOptionIndex = index),
                        child: Icon(
                          selectedCorrectOptionIndex == index
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: selectedCorrectOptionIndex == index
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Option ${index + 1}',
                            hintStyle: const TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            suffixIcon: const Icon(
                              Icons.image_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_questionController.text.isEmpty) return;

                    final options = _optionControllers
                        .map((c) => c.text)
                        .toList();
                    final correctAnswer = options[selectedCorrectOptionIndex];

                    widget.onSave({
                      "question": _questionController.text,
                      "yearLevel": selectedYearLevel ?? 'Junior (Grade 7-10)',
                      "category": selectedCategory ?? 'Science',
                      "correctAnswer": correctAnswer,
                      "options": options,
                      "difficulty": selectedDifficulty ?? 'Average',
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD000),
                    foregroundColor: const Color(0xFF816A03),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "SAVE CHANGES",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[400], fontFamily: 'Poppins'),
          ),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontFamily: 'Poppins')),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}