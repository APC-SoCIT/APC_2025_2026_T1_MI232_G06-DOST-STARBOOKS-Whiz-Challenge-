import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'difficulty_settings_service.dart';

class AdminQuizDifficultyPage extends StatefulWidget {
  const AdminQuizDifficultyPage({super.key});

  @override
  State<AdminQuizDifficultyPage> createState() =>
      _AdminQuizDifficultyPageState();
}

class _AdminQuizDifficultyPageState extends State<AdminQuizDifficultyPage> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  // Difficulty settings loaded from API
  Map<String, Map<String, int>> difficultySettings = {
    'Easy':      {'questions': 10, 'time': 15},
    'Average':   {'questions': 10, 'time': 20},
    'Difficult': {'questions': 10, 'time': 25},
  };

  // Active questions available per level (from the server); a level is
  // absent until loaded, in which case only the server check applies.
  final Map<String, int> availableQuestions = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _api.getDifficultySettings();

    if (!mounted) return;

    if (result['success'] == true) {
      final settings = result['settings'] as Map<String, dynamic>;
      final updated = <String, Map<String, int>>{};
      availableQuestions.clear();

      for (final level in ['Easy', 'Average', 'Difficult']) {
        if (settings.containsKey(level)) {
          final s = settings[level] as Map<String, dynamic>;
          updated[level] = {
            'questions': (s['num_questions'] as num?)?.toInt() ?? 10,
            'time':      (s['time_per_qn'] as num?)?.toInt() ?? 15,
          };
          final avail = (s['available_questions'] as num?)?.toInt();
          if (avail != null) availableQuestions[level] = avail;
        }
      }

      setState(() {
        difficultySettings = updated.isNotEmpty ? updated : difficultySettings;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'] ?? 'Failed to load settings.';
      });
    }
  }

  // Must match AdminController::updateDifficultySettings' Laravel validation
  // ('num_questions' => required|integer|min:1|max:50, 'time_per_qn' =>
  // required|integer|min:5|max:120) so the admin sees the real limit before
  // hitting the server instead of after.
  static const int _minQuestions = 1;
  static const int _maxQuestions = 50;
  static const int _minTime = 5;
  static const int _maxTime = 120;

  void _showEditDialog(String difficulty) {
    final settings = difficultySettings[difficulty]!;
    final questionsController =
        TextEditingController(text: settings['questions'].toString());
    final timeController =
        TextEditingController(text: settings['time'].toString());

    bool isSaving = false;
    List<String> formErrors = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(19.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit, color: Color(0xFF046EB8), size: 19.2),
                      const SizedBox(width: 6.4),
                      Text(
                        difficulty,
                        style: const TextStyle(
                          fontSize: 19.2,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),

                  // ── ERROR BANNER — pinned right under the title, above
                  //    both fields, so it's visible without scrolling and
                  //    isn't a snackbar that vanishes off the bottom of the
                  //    whole screen. ──
                  if (formErrors.isNotEmpty) ...[
                    const SizedBox(height: 12.8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(9.6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formErrors.length == 1
                                      ? 'Please fix this before saving:'
                                      : 'Please fix these ${formErrors.length} problems before saving:',
                                  style: TextStyle(
                                    fontFamily: 'Poppins', fontSize: 9.6,
                                    fontWeight: FontWeight.w700, color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...formErrors.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('•  ', style: TextStyle(fontSize: 9.6, color: Colors.red.shade700)),
                                      Expanded(
                                        child: Text(e, style: TextStyle(
                                          fontFamily: 'Poppins', fontSize: 9.6,
                                          height: 1.4, color: Colors.red.shade700,
                                        )),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 19.2),
                  _buildInputField('No. of Questions', questionsController,
                      hasError: formErrors.isNotEmpty,
                      onChanged: () => setDialogState(() => formErrors = [])),
                  if (availableQuestions[difficulty] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 6),
                      child: Text(
                        'Available: ${availableQuestions[difficulty]} active $difficulty question(s)',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                  const SizedBox(height: 12.8),
                  _buildTimeField('Time per Question (seconds)', timeController,
                      hasError: formErrors.isNotEmpty,
                      onChanged: () => setDialogState(() => formErrors = [])),
                  const SizedBox(height: 19.2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF046EB8),
                          side: const BorderSide(color: Color(0xFF046EB8)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Close', style: TextStyle(fontFamily: 'Poppins')),
                      ),
                      const SizedBox(width: 12.8),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                // ── STEP 1: normalise. Leading/trailing spaces
                                //    (and any stray whitespace a paste can
                                //    sneak in around the digits) are trimmed
                                //    automatically and accepted — never an
                                //    error. digitsOnly already blocks letters
                                //    at the keystroke level, so this trim is
                                //    the defensive second layer for paste.
                                final numQRaw = questionsController.text.trim();
                                final timeQRaw = timeController.text.trim();
                                questionsController.text = numQRaw;
                                timeController.text = timeQRaw;

                                // ── STEP 2: validate, one specific reason per
                                //    problem instead of one generic message
                                //    covering every case. ──
                                final problems = <String>[];

                                if (numQRaw.isEmpty) {
                                  problems.add('Number of Questions is empty. Enter a number from '
                                      '$_minQuestions to $_maxQuestions.');
                                } else {
                                  final numQ = int.tryParse(numQRaw);
                                  if (numQ == null) {
                                    problems.add('Number of Questions must be a whole number '
                                        '(no letters or symbols).');
                                  } else if (numQ < _minQuestions) {
                                    problems.add('Number of Questions must be at least $_minQuestions.');
                                  } else if (numQ > _maxQuestions) {
                                    problems.add('Number of Questions cannot be more than $_maxQuestions.');
                                  } else if (availableQuestions[difficulty] != null &&
                                      numQ > availableQuestions[difficulty]!) {
                                    final avail = availableQuestions[difficulty]!;
                                    problems.add(avail == 0
                                        ? 'There are no active $difficulty questions yet. Add questions first.'
                                        : 'Only $avail active $difficulty question${avail == 1 ? '' : 's'} available. '
                                          'Number of Questions cannot be more than $avail.');
                                  }
                                }

                                if (timeQRaw.isEmpty) {
                                  problems.add('Time per Question is empty. Enter a number from '
                                      '$_minTime to $_maxTime seconds.');
                                } else {
                                  final timeQ = int.tryParse(timeQRaw);
                                  if (timeQ == null) {
                                    problems.add('Time per Question must be a whole number '
                                        '(no letters or symbols).');
                                  } else if (timeQ < _minTime) {
                                    problems.add('Time per Question must be at least $_minTime seconds.');
                                  } else if (timeQ > _maxTime) {
                                    problems.add('Time per Question cannot be more than $_maxTime seconds.');
                                  }
                                }

                                if (problems.isNotEmpty) {
                                  setDialogState(() => formErrors = problems);
                                  return;
                                }

                                final numQ = int.parse(numQRaw);
                                final timeQ = int.parse(timeQRaw);

                                setDialogState(() {
                                  isSaving = true;
                                  formErrors = [];
                                });

                                final result = await _api.updateDifficultySettings(
                                  difficulty,
                                  numQuestions: numQ,
                                  timePerQn: timeQ,
                                );

                                if (!context.mounted) return;
                                setDialogState(() => isSaving = false);

                                if (result['success'] == true) {
                                  setState(() {
                                    difficultySettings[difficulty] = {
                                      'questions': numQ,
                                      'time': timeQ,
                                    };
                                  });
                                  // Immediately update singleton so quiz_game.dart uses new values
                                  DifficultySettingsService.instance.update(
                                    difficulty,
                                    questions: numQ,
                                    time: timeQ,
                                  );
                                  Navigator.of(context).pop();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$difficulty settings updated!'),
                                        backgroundColor: const Color(0xFF27AE60),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6.4)),
                                      ),
                                    );
                                  }
                                } else {
                                  // Server-side validation failures (e.g. the
                                  // Laravel min/max rules) land in the same
                                  // top banner instead of a bottom snackbar,
                                  // with one line per field Laravel rejected.
                                  final serverErrors = result['errors'];
                                  final list = <String>[];
                                  if (serverErrors is Map) {
                                    serverErrors.forEach((field, msgs) {
                                      if (msgs is List) {
                                        for (final m in msgs) list.add(m.toString());
                                      }
                                    });
                                  }
                                  setDialogState(() => formErrors = list.isNotEmpty
                                      ? list
                                      : [result['message']?.toString() ?? 'Update failed.']);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF046EB8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 14.4,
                                height: 14.4,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.6, color: Color(0xFF816A03)))
                            : const Text('SAVE',
                                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool hasError = false,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9.6, color: Colors.grey, fontFamily: 'Poppins')),
        const SizedBox(height: 6.4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          // keyboardType only picks the on-screen keyboard on mobile — it
          // doesn't block what a physical/desktop keyboard (or a paste) can
          // type. digitsOnly is what actually stops letters, symbols, and
          // spaces from ever landing in the field.
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 3, // max value is 50 — 3 digits covers it with room to spare
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19.2),
                borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19.2),
                borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19.2),
                borderSide: BorderSide(color: hasError ? Colors.red : const Color(0xFF046EB8))),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(
    String label,
    TextEditingController controller, {
    bool hasError = false,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9.6, color: Colors.grey, fontFamily: 'Poppins')),
        const SizedBox(height: 6.4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 3, // max value is 120 — 3 digits covers it with room to spare
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: const Icon(Icons.access_time, color: Colors.grey),
            suffixText: 's',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19.2),
                borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19.2),
                borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(19.2),
                borderSide: BorderSide(color: hasError ? Colors.red : const Color(0xFF046EB8))),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: const Color(0xFF94D2FD),
        child: LayoutBuilder(builder: (context, bc) {
          final pad = bc.maxWidth < 500 ? 12.0 : 24.0;
          return Padding(padding: EdgeInsets.all(pad), child: Column(
            children: [
              const SizedBox(height: 12.8),
              LayoutBuilder(builder: (context, constraints) {
                final hPad = constraints.maxWidth < 600 ? 16.0 : 40.0;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6.4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Difficulty Settings',
                          style: TextStyle(
                            fontSize: 17.6,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF051525),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        IconButton(
                          onPressed: _loadSettings,
                          icon: const Icon(Icons.refresh, size: 16),
                          style: IconButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: const CircleBorder(),
                            backgroundColor: Colors.white,
                          ),
                          tooltip: 'Refresh settings',
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 25.6),
              Expanded(
                child: _isLoading
                    ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF046EB8)))
                    : _errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 38.4),
                      const SizedBox(height: 9.6),
                      Text(_errorMessage!,
                          style: const TextStyle(
                              fontFamily: 'Poppins', color: Colors.red)),
                      const SizedBox(height: 12.8),
                      ElevatedButton(
                        onPressed: _loadSettings,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF046EB8)),
                        child: const Text('Retry',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                )
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildDifficultyCard('Easy', difficultySettings['Easy']!, Colors.green),
                            const SizedBox(height: 12.8),
                            _buildDifficultyCard('Average', difficultySettings['Average']!, Colors.blue),
                            const SizedBox(height: 12.8),
                            _buildDifficultyCard('Difficult', difficultySettings['Difficult']!, Colors.red),
                            const SizedBox(height: 12.8),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDifficultyCard('Easy', difficultySettings['Easy']!, Colors.green)),
                          const SizedBox(width: 19.2),
                          Expanded(child: _buildDifficultyCard('Average', difficultySettings['Average']!, Colors.blue)),
                          const SizedBox(width: 19.2),
                          Expanded(child: _buildDifficultyCard('Difficult', difficultySettings['Difficult']!, Colors.red)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12.8),
            ],
          ));
        }));
  }

  Widget _buildDifficultyCard(
      String title, Map<String, int> settings, Color accentColor) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored top accent bar
            Container(
              height: 4,
              color: accentColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'DIFFICULTY',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 8,
                        color: accentColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 3.2),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22.4,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                  ]),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showEditDialog(title),
                      child: Container(
                        width: 30.4,
                        height: 30.4,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, color: accentColor, size: 14.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.8, thickness: 1, color: Color(0xFFF0F4F8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Column(
                children: [
                  _buildInfoRow('Questions', settings['questions'].toString(),
                      Icons.help_outline_rounded, accentColor),
                  const SizedBox(height: 12.8),
                  _buildInfoRow('Time / Q', '${settings['time']}s',
                      Icons.access_time_rounded, accentColor),
                  if (availableQuestions[title] != null) ...[
                    const SizedBox(height: 12.8),
                    _buildInfoRow('Available', availableQuestions[title].toString(),
                        Icons.inventory_2_outlined, accentColor),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.4, color: color),
            const SizedBox(width: 6.4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10.4, color: Color(0xFF64748B), fontFamily: 'Poppins')),
          ],
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF051525),
                fontFamily: 'Poppins')),
      ],
    );
  }
}