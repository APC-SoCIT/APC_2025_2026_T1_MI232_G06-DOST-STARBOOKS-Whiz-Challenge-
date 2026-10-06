import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'api_service.dart';
import 'difficulty_settings_service.dart';

/// Result of validating a single CSV data row before import.
class _CsvRowValidation {
  final int rowNumber; // matches the row's position in the spreadsheet (header = row 1)
  final List<String> cols;
  final Map<String, dynamic> payload;
  final List<String> errors;

  _CsvRowValidation({
    required this.rowNumber,
    required this.cols,
    required this.payload,
    required this.errors,
  });

  bool get isValid => errors.isEmpty;
}

class AdminQuizQuestionsPage extends StatefulWidget {
  const AdminQuizQuestionsPage({super.key});

  @override
  State<AdminQuizQuestionsPage> createState() => _AdminQuizQuestionsPageState();
}

class _AdminQuizQuestionsPageState extends State<AdminQuizQuestionsPage> {
  final ApiService _api = ApiService();

  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  int itemsPerPage = 10;
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;

  String? selectedCategoryFilter;
  String? selectedDifficultyFilter;
  // ✅ FIX: "Deactivate" is a soft-delete (is_active=0), and the list was
  // never filtering by status at all — deactivated questions kept showing
  // in the same table (just sorted toward the bottom), which read as
  // "cannot delete question, it's still in the list". Default view now
  // shows active questions only; this toggle reveals deactivated ones so
  // they can still be restored.
  bool includeInactive = false;

  String sortColumn = 'status';
  bool sortAscending = false; // desc: active (1) first, inactive (0) last

  List<Map<String, dynamic>> questionsData = [];
  Set<String> selectedIds = {}; // ids of checked rows, cleared whenever the page reloads

  static const List<String> _categories  = ['Math', 'Science'];
  static const List<String> _difficulties = ['Easy', 'Average', 'Difficult'];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Renders an image from either a base64 data URI (freshly picked, not yet
  /// saved to the server) or a real server URL. Image.network alone only
  /// reliably handles data URIs on the web renderer, so data URIs are routed
  /// through Image.memory instead — this is what was silently failing for
  /// picked-but-unsaved images.
  Widget _renderImage(String? data, {double? width, double? height, BoxFit fit = BoxFit.cover, required Widget Function() onError}) {
    if (data == null || data.isEmpty) return const SizedBox.shrink();
    if (data.startsWith('data:')) {
      final commaIndex = data.indexOf(',');
      if (commaIndex == -1) return onError();
      try {
        final bytes = base64Decode(data.substring(commaIndex + 1));
        return Image.memory(bytes, width: width, height: height, fit: fit,
            errorBuilder: (_, __, ___) => onError());
      } catch (_) {
        return onError();
      }
    }
    return Image.network(data, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => onError());
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadQuestions({int? page}) async {
    if (page != null) setState(() => currentPage = page);
    setState(() => isLoading = true);

    final result = await _api.getQuestions(
      category:   selectedCategoryFilter,
      difficulty: selectedDifficultyFilter,
      yearLevel:  null,
      status:     includeInactive ? null : 1,
      search:     searchQuery.isEmpty ? null : searchQuery,
      sortBy:     sortColumn == 'difficulty' ? 'difficulty_level'
          : sortColumn == 'status' ? 'is_active'
          : sortColumn,
      sortDir:    sortAscending ? 'asc' : 'desc',
      page:       currentPage,
      perPage:    itemsPerPage,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final raw = (result['questions'] as List<dynamic>? ?? [])
          .map((q) => _mapQuestion(q as Map<String, dynamic>))
          .toList();
      setState(() {
        questionsData = raw;
        totalPages    = result['total_pages'] ?? 1;
        totalItems    = result['total'] ?? 0;
        isLoading     = false;
        selectedIds.clear();
      });
    } else {
      setState(() => isLoading = false);
      _snack(result['message'] ?? 'Failed to load questions.', Colors.red);
    }
  }

  Map<String, dynamic> _mapQuestion(Map<String, dynamic> q) => {
    'id':               q['id'],
    'question':         q['question'],
    'topic':            q['topic'],
    'category':         q['category'],
    'difficulty':       q['difficulty_level'],
    'correctAnswer':    q['correct_answer'],
    'choice_a':         q['choice_a'],
    'choice_b':         q['choice_b'],
    'choice_c':         q['choice_c'],
    'choice_d':         q['choice_d'],
    // These were previously dropped here, which is why images always came up
    // empty when editing an existing question — the edit dialog reads these
    // exact keys back out.
    'question_image':  q['question_image'] ?? q['image_url'],
    'choice_a_image':  q['choice_a_image'],
    'choice_b_image':  q['choice_b_image'],
    'choice_c_image':  q['choice_c_image'],
    'choice_d_image':  q['choice_d_image'],
    'image_url':        q['image_url'],
    'status':           (q['is_active'] ?? 1) == 1,
  };

  void _onSearch(String v) {
    setState(() { searchQuery = v; currentPage = 1; });
    _loadQuestions();
  }

  void _applyFilter() {
    setState(() => currentPage = 1);
    _loadQuestions();
  }

  void _clearFilters() {
    setState(() {
      selectedCategoryFilter   = null;
      selectedDifficultyFilter = null;
      searchQuery              = '';
      searchController.clear();
      currentPage              = 1;
    });
    _loadQuestions();
  }

  void _sortBy(String column) {
    setState(() {
      sortAscending = sortColumn == column ? !sortAscending : true;
      sortColumn    = column;
      currentPage   = 1;
    });
    _loadQuestions();
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.4)),
    ));
  }

  // ── Question Preview ─────────────────────────────────────────────────────

  /// Opens a full-screen preview of how a question will render in Whiz
  /// Challenge / Whiz Battle. Every size, padding, and color below is copied
  /// straight from quiz_game.dart's _buildHeader / _buildQuestionView /
  /// _buildAnswerButton so this is a real match, not an approximation. The
  /// only additions are the back button (replacing the real pause button)
  /// and the small correct-answer badge, which is admin-only reference and
  /// never shown to players.
  void _openQuestionPreview({
    required String question,
    String? questionImage,
    required Map<String, String> choices,       // {'A': text, 'B': text, 'C': text, 'D': text}
    required Map<String, String?> choiceImages,  // {'A': imgOrNull, ...}
    required String? correctLetter,
    required String category,
    required String difficulty,
    String? topic,
  }) {
    final difficultyColor = _previewDifficultyColor(difficulty);
    final backgroundAsset = _previewDifficultyBackground(difficulty);
    const letters = ['A', 'B', 'C', 'D'];
    final hasImageChoices = choiceImages.values.any((v) => v != null && v.isNotEmpty);

    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) {
        final isMobile = MediaQuery.of(ctx).size.width < 600;
        return Scaffold(
          backgroundColor: const Color(0xFF87CEEB), // same Scaffold background as the real quiz screen
          body: Stack(children: [
            // Same difficulty-tinted background image at 0.3 opacity as the real screen
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(backgroundAsset, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
            Column(children: [
              _previewHeader(ctx, isMobile, difficultyColor, category, difficulty),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(height: isMobile ? 10 : 16),
                      // Dot indicator row — exact copy of the real "Question X of N" row,
                      // pulling the real per-difficulty question count so "of N" matches
                      // what players actually see instead of a hardcoded 'of 1'.
                      Builder(builder: (_) {
                        final totalQuestions = DifficultySettingsService.instance.getQuestions(difficulty);
                        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('Question 1',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Poppins', color: difficultyColor)),
                          const SizedBox(width: 10),
                          ...List.generate(totalQuestions, (i) {
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == 0 ? difficultyColor : difficultyColor.withValues(alpha: 0.2),
                              ),
                            );
                          }),
                          const SizedBox(width: 10),
                          Text('of $totalQuestions', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Poppins', color: Color(0xFFAAAAAA))),
                        ]);
                      }),
                      const SizedBox(height: 12),

                      if (topic != null && topic.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _previewChip('Topic: $topic', Colors.purple),
                        ),
                      if (questionImage != null && questionImage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _renderImage(questionImage, height: isMobile ? 160 : 220,
                                width: isMobile ? 340 : 500, onError: () => const SizedBox()),
                          ),
                        ),

                      // White question box — exact padding/shadow from _buildQuestionView
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: isMobile ? 100 : 140, maxWidth: isMobile ? 400 : 900),
                        child: Container(
                          width: isMobile ? MediaQuery.of(ctx).size.width - 36 : 840,
                          padding: isMobile
                              ? const EdgeInsets.fromLTRB(18, 20, 18, 20)
                              : const EdgeInsets.fromLTRB(30, 32, 30, 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Center(
                            child: Text(question.isEmpty ? '(no question text)' : question,
                                style: TextStyle(fontSize: isMobile ? 15 : 20, fontWeight: FontWeight.w600, fontFamily: 'Poppins', height: 1.4),
                                textAlign: TextAlign.center),
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 16 : 24),

                      // Answer grid — same three layout branches as the real screen:
                      // image choices / desktop text / mobile text (intrinsic-height rows)
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 900),
                          margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 15),
                          child: Builder(builder: (_) {
                            if (hasImageChoices) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobile ? 2 : 4,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: isMobile ? 1.0 : 0.75,
                                ),
                                itemCount: 4,
                                itemBuilder: (_, i) => _previewAnswerButton(
                                  text: choices[letters[i]] ?? '',
                                  imageData: choiceImages[letters[i]],
                                  color: _previewAnswerColor(i),
                                  isCorrect: letters[i] == correctLetter,
                                  isMobile: isMobile,
                                ),
                              );
                            }
                            if (!isMobile) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 3.5,
                                ),
                                itemCount: 4,
                                itemBuilder: (_, i) => _previewAnswerButton(
                                  text: choices[letters[i]] ?? '',
                                  imageData: null,
                                  color: _previewAnswerColor(i),
                                  isCorrect: letters[i] == correctLetter,
                                  isMobile: isMobile,
                                ),
                              );
                            }
                            // Mobile text-only: intrinsic-height rows so wrapped text never clips
                            final rows = <Widget>[];
                            for (int i = 0; i < 4; i += 2) {
                              rows.add(Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: IntrinsicHeight(
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                    Expanded(child: _previewAnswerButton(
                                      text: choices[letters[i]] ?? '', imageData: null,
                                      color: _previewAnswerColor(i), isCorrect: letters[i] == correctLetter, isMobile: isMobile,
                                    )),
                                    const SizedBox(width: 12),
                                    Expanded(child: _previewAnswerButton(
                                      text: choices[letters[i + 1]] ?? '', imageData: null,
                                      color: _previewAnswerColor(i + 1), isCorrect: letters[i + 1] == correctLetter, isMobile: isMobile,
                                    )),
                                  ]),
                                ),
                              ));
                            }
                            return Column(mainAxisSize: MainAxisSize.min, children: rows);
                          }),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.info_outline, size: 13, color: Colors.grey.shade800),
                          const SizedBox(width: 5.6),
                          Flexible(child: Text(
                              "The ✓ marks the correct answer for your reference — players won't see it highlighted like this.",
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.grey.shade800),
                              textAlign: TextAlign.center)),
                        ]),
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                    ]),
                  ),
                ),
              ),
            ]),
          ]),
        );
      },
    ));
  }

  /// Exact copy of _buildHeader()'s two layout variants — the pill on the
  /// left, empty center column, and a floating timer circle overlapping the
  /// header via Positioned/Stack. The real pause button becomes a back
  /// button here, and the timer shows a clock icon instead of a live count
  /// since this preview isn't a running game.
  Widget _previewHeader(BuildContext ctx, bool isMobile, Color difficultyColor, String category, String difficulty) {
    if (isMobile) {
      return Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(ctx),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: 'Back to questions'),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: difficultyColor, borderRadius: BorderRadius.circular(16)),
                child: Text('$category · $difficulty',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.2, fontFamily: 'Poppins'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close, size: 28, color: difficultyColor),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Close preview',
            ),
          ]),
        ),
        Positioned(top: 18, child: _previewTimerCircle(difficultyColor, difficulty, size: 82, fontSize: 28)),
      ]);
    }

    return Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
      Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Row(children: [
          Expanded(
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(ctx), tooltip: 'Back to questions'),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: difficultyColor, borderRadius: BorderRadius.circular(20)),
                child: Text('$category  ·  $difficulty',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.4, fontFamily: 'Poppins')),
              ),
            ]),
          ),
          const Expanded(child: SizedBox()), // center spacer for the floating timer circle
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(
                icon: Icon(Icons.close, size: 36, color: difficultyColor),
                onPressed: () => Navigator.pop(ctx),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Close preview',
              ),
            ]),
          ),
        ]),
      ),
      Positioned(top: 30, child: _previewTimerCircle(difficultyColor, difficulty, size: 110, fontSize: 38)),
    ]);
  }

  /// Same circle styling as _buildTimerCircle() — shows the difficulty's
  /// configured starting time as a static number, same as what a player
  /// would see the instant the real timer starts (real screen counts down
  /// from here; nothing is actually running in this preview).
  Widget _previewTimerCircle(Color difficultyColor, String difficulty, {required double size, required double fontSize}) {
    final startSeconds = DifficultySettingsService.instance.getTime(difficulty);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: difficultyColor,
        border: Border.all(color: Colors.white, width: size > 90 ? 5 : 4),
        boxShadow: [BoxShadow(color: difficultyColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Text('$startSeconds',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
      ),
    );
  }

  /// Same 4 colors _getButtonColor() rotates through on the real quiz screen.
  Color _previewAnswerColor(int index) {
    const colors = [Color(0xFF046EB8), Color(0xFFF39C12), Color(0xFFE67E22), Color(0xFF9B59B6)];
    return colors[index % colors.length];
  }

  /// Same mapping as _getDifficultyColor() on the real quiz screen.
  Color _previewDifficultyColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':      return const Color(0xFF1D9358);
      case 'AVERAGE':   return const Color(0xFF046EB8);
      case 'DIFFICULT': return const Color(0xFFBD442E);
      default:          return const Color(0xFF1D9358);
    }
  }

  /// Same mapping as _getDifficultyBackground() on the real quiz screen.
  String _previewDifficultyBackground(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':      return 'assets/backgrounds/easybg.png';
      case 'AVERAGE':   return 'assets/backgrounds/averagebg.png';
      case 'DIFFICULT': return 'assets/backgrounds/difficultbg.png';
      default:          return 'assets/backgrounds/easybg.png';
    }
  }

  /// Unselected-state clone of _buildAnswerButton() — same border, shadow,
  /// image-with-label-overlay treatment, and exact font sizes. A small check
  /// badge marks the correct choice for the admin only; the real game never
  /// shows this before the player answers.
  Widget _previewAnswerButton({required String text, String? imageData, required Color color, required bool isCorrect, required bool isMobile}) {
    final hasImage = imageData != null && imageData.isNotEmpty;
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: hasImage
            ? Stack(fit: StackFit.expand, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _renderImage(imageData, fit: BoxFit.contain,
                  onError: () => Icon(Icons.broken_image_outlined, color: color, size: 32)),
            ),
          ),
          if (text.isNotEmpty)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                ),
                child: Text(text,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
        ])
            : Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 8 : 10),
            child: Text(text.isEmpty ? '(empty)' : text,
                style: TextStyle(fontSize: isMobile ? 13.5 : 18, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'Poppins', height: 1.2),
                textAlign: TextAlign.center),
          ),
        ),
      ),
      if (isCorrect)
        Positioned(
          top: -6, right: -6,
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
          ),
        ),
    ]);
  }

  Widget _previewChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 9.2, fontWeight: FontWeight.w600, color: color)),
  );

  // ── Status / Delete actions ───────────────────────────────────────────────

  /// Turns an API failure into a message that says what actually went wrong,
  /// instead of one catch-all "Action failed."
  String _friendlyApiError(Map<String, dynamic> result, String verb) {
    final status = result['status'] is int ? result['status'] as int : null;
    final raw = (result['message'] ?? '').toString().trim();
    final lower = raw.toLowerCase();

    if (status == 401 || lower.contains('unauthorized')) {
      return 'Your admin session has expired. Log out, log back in, then try again.';
    }
    if (status == 403) {
      return 'Your admin account does not have permission to $verb questions.';
    }
    if (status == 404 || lower.contains('not found')) {
      return 'This question no longer exists in the database. '
          'It may already have been deleted — close this and refresh the list.';
    }
    if (lower.contains('failed to fetch') ||
        lower.contains('clientexception') ||
        lower.contains('socketexception') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('connection refused')) {
      return 'Could not reach the server. Check that the backend is running, '
          'then try again.';
    }
    if (lower.contains('invalid server response') || lower.contains('error page')) {
      return 'The server sent something the app could not read. '
          'This is usually a PHP error — check storage/logs/laravel.log.';
    }
    if (lower.contains('base table') ||
        lower.contains("doesn't exist") ||
        lower.contains('no such table') ||
        lower.contains('collection')) {
      return 'The server looked in the wrong place for this question '
          '(database error: $raw). This is a backend bug, not a data problem.';
    }
    if (status == 500) {
      return 'The server could not $verb this question: '
          '${raw.isEmpty ? 'unknown server error' : raw}';
    }
    return raw.isEmpty ? 'Could not $verb this question. Please try again.' : raw;
  }

  /// Shared confirm dialog for deactivate / restore / delete.
  ///
  /// The request runs INSIDE the dialog. On success the dialog closes itself.
  /// On failure it stays open and shows the reason in a red banner pinned to
  /// the top of the dialog, where it cannot be missed or scrolled past.
  ///
  /// [onConfirm] returns a list of error messages — empty means it worked.
  Future<bool> _showConfirmActionDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
    required Future<List<String>> Function() onConfirm,
  }) async {
    List<String> errors = const [];
    bool busy = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(19.2),
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                // ── ERROR BANNER — always at the very top of the dialog ──
                if (errors.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(9.6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            errors.length == 1 ? 'That did not work:' : '${errors.length} problems:',
                            style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 9.6,
                              fontWeight: FontWeight.w700, color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...errors.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('•  ', style: TextStyle(fontSize: 9.6, color: Colors.red.shade700)),
                              Expanded(
                                child: Text(e, style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 9.6,
                                  height: 1.4, color: Colors.red.shade700,
                                )),
                              ),
                            ]),
                          )),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],

                Container(
                  width: 41.6, height: 41.6,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 20.8, color: color),
                ),
                const SizedBox(height: 9.6),
                Text(title, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.6, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                const SizedBox(height: 6.4),
                Text(message, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.4, fontFamily: 'Poppins', color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: busy ? null : () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text(errors.isEmpty ? 'Cancel' : 'Close',
                        style: const TextStyle(fontFamily: 'Poppins')),
                  )),
                  const SizedBox(width: 9.6),
                  Expanded(child: ElevatedButton(
                    onPressed: busy ? null : () async {
                      setDS(() { busy = true; errors = const []; });
                      final problems = await onConfirm();
                      if (!ctx.mounted) return;
                      if (problems.isEmpty) {
                        Navigator.pop(ctx, true);
                      } else {
                        setDS(() { busy = false; errors = problems; });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: color.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: busy
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white))
                        : Text(errors.isEmpty ? confirmLabel : 'Try Again',
                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  )),
                ]),
              ]),
            ),
          );
      }),
    );
    return result == true;
  }

  // ── Toggle active/inactive (soft delete / restore) ────────────────────────

  void _toggleStatus(Map<String, dynamic> q) async {
    final isActive = q['status'] as bool;
    final id = q['id']?.toString() ?? '';
    final verb = isActive ? 'deactivate' : 'restore';

    if (id.isEmpty) {
      _snack('This row has no question id, so it cannot be changed. Refresh the list.', Colors.red);
      return;
    }

    final ok = await _showConfirmActionDialog(
      icon: isActive ? Icons.visibility_off : Icons.visibility,
      color: isActive ? Colors.red : Colors.green,
      title: isActive ? 'Deactivate Question?' : 'Restore Question?',
      message: isActive
          ? 'This question will no longer appear in the game. You can restore it later.'
          : 'This question will be active again in the game.',
      confirmLabel: isActive ? 'Deactivate' : 'Restore',
      onConfirm: () async {
        final result = isActive
            ? await _api.deleteQuestion(id)
            : await _api.restoreQuestion(id);
        if (result['success'] == true) return <String>[];
        return [_friendlyApiError(result, verb)];
      },
    );

    if (!mounted || !ok) return;
    _loadQuestions();
    _snack(isActive ? 'Question deactivated.' : 'Question restored.',
        isActive ? Colors.orange : const Color(0xFF27AE60));
  }

  // ── Permanent Delete ─────────────────────────────────────────────────────

  void _permanentDelete(Map<String, dynamic> q) async {
    final id = q['id']?.toString() ?? '';
    final preview = (q['question'] ?? '').toString();

    if (id.isEmpty) {
      _snack('This row has no question id, so it cannot be deleted. Refresh the list.', Colors.red);
      return;
    }

    final ok = await _showConfirmActionDialog(
      icon: Icons.delete_forever,
      color: Colors.red,
      title: 'Delete Permanently?',
      message: preview.isEmpty
          ? 'This cannot be undone. The question will be permanently removed.'
          : 'This cannot be undone. "${preview.length > 60 ? '${preview.substring(0, 60)}...' : preview}" '
              'will be permanently removed.',
      confirmLabel: 'Delete Forever',
      onConfirm: () async {
        final result = await _api.permanentDeleteQuestion(id);
        if (result['success'] == true) return <String>[];
        return [_friendlyApiError(result, 'delete')];
      },
    );

    if (!mounted || !ok) return;
    _loadQuestions();
    _snack('Question permanently deleted.', Colors.red);
  }

  // ── Row selection ─────────────────────────────────────────────────────────

  bool get _allOnPageSelected =>
      questionsData.isNotEmpty && questionsData.every((q) => selectedIds.contains(q['id'].toString()));

  bool get _someOnPageSelected =>
      questionsData.any((q) => selectedIds.contains(q['id'].toString())) && !_allOnPageSelected;

  void _toggleSelectAll(bool? checked) {
    setState(() {
      if (checked == true) {
        for (final q in questionsData) {
          selectedIds.add(q['id'].toString());
        }
      } else {
        for (final q in questionsData) {
          selectedIds.remove(q['id'].toString());
        }
      }
    });
  }

  void _toggleSelectOne(String id, bool? checked) {
    setState(() {
      if (checked == true) {
        selectedIds.add(id);
      } else {
        selectedIds.remove(id);
      }
    });
  }

  /// Deactivates, restores, or permanently deletes every currently-selected
  /// question. Failures are listed one-by-one in the banner at the top of the
  /// dialog, naming which question failed and why, instead of a single
  /// "3 of 5 updated" snackbar that says nothing about the other 2.
  Future<void> _bulkAction(String action) async {
    final targets = questionsData.where((q) => selectedIds.contains(q['id'].toString())).toList();
    if (targets.isEmpty) {
      _snack('No questions selected. Tick at least one row first.', Colors.orange);
      return;
    }

    final n = targets.length;
    late final String title;
    late final String message;
    late final String confirmLabel;
    late final String verb;
    late final Color color;
    late final IconData icon;

    switch (action) {
      case 'deactivate':
        title = 'Deactivate $n Question${n == 1 ? '' : 's'}?';
        message = 'These questions will no longer appear in the game. You can restore them later.';
        confirmLabel = 'Deactivate';
        verb = 'deactivate';
        color = Colors.red;
        icon = Icons.visibility_off;
        break;
      case 'restore':
        title = 'Restore $n Question${n == 1 ? '' : 's'}?';
        message = 'These questions will be active again in the game.';
        confirmLabel = 'Restore';
        verb = 'restore';
        color = Colors.green;
        icon = Icons.visibility;
        break;
      default: // delete
        title = 'Delete $n Question${n == 1 ? '' : 's'} Permanently?';
        message = 'This cannot be undone. The questions will be permanently removed.';
        confirmLabel = 'Delete Forever';
        verb = 'delete';
        color = Colors.red;
        icon = Icons.delete_forever;
    }

    int succeeded = 0;

    final ok = await _showConfirmActionDialog(
      icon: icon,
      color: color,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      onConfirm: () async {
        // Fire all the requests together rather than awaiting one at a time.
        final results = await Future.wait(targets.map((q) {
          final id = q['id'].toString();
          return action == 'deactivate'
              ? _api.deleteQuestion(id)
              : action == 'restore'
                  ? _api.restoreQuestion(id)
                  : _api.permanentDeleteQuestion(id);
        }));

        succeeded = results.where((r) => r['success'] == true).length;

        // Build one specific line per failed question, naming it so the admin
        // knows exactly which rows still need attention.
        final problems = <String>[];
        for (int i = 0; i < results.length; i++) {
          if (results[i]['success'] == true) continue;
          final text = (targets[i]['question'] ?? '').toString();
          final label = text.isEmpty
              ? 'Question ${i + 1}'
              : '"${text.length > 40 ? '${text.substring(0, 40)}...' : text}"';
          problems.add('$label — ${_friendlyApiError(results[i], verb)}');
        }

        if (problems.isNotEmpty && succeeded > 0) {
          problems.insert(0, '$succeeded of $n succeeded. The rest failed:');
        }
        return problems;
      },
    );

    if (!mounted) return;
    // Refresh either way — a partial batch still changed something.
    _loadQuestions(); // also clears selectedIds

    if (ok) {
      final past = action == 'deactivate'
          ? 'deactivated'
          : action == 'restore'
              ? 'restored'
              : 'permanently deleted';
      _snack('$n question${n == 1 ? '' : 's'} $past.', color);
    }
  }

  // ── Add / Edit Dialog ────────────────────────────────────────────────────

  void _showAddQuestionDialog()                         => _showQuestionDialog(null);
  void _showEditQuestionDialog(Map<String, dynamic> q)  => _showQuestionDialog(q);

  void _showQuestionDialog(Map<String, dynamic>? existing) {
    final isEdit = existing != null;

    final questionCtrl = TextEditingController(text: existing?['question'] ?? '');
    final choiceACtrl  = TextEditingController(text: existing?['choice_a'] ?? '');
    final choiceBCtrl  = TextEditingController(text: existing?['choice_b'] ?? '');
    final choiceCCtrl  = TextEditingController(text: existing?['choice_c'] ?? '');
    final choiceDCtrl  = TextEditingController(text: existing?['choice_d'] ?? '');
    final topicCtrl    = TextEditingController(text: existing?['topic'] ?? '');

    // Stored images can come back as an empty string (or whitespace), which
    // is not null and used to slip past the "text or image" checks below.
    // Treat blank as "no image".
    String? nz(dynamic v) {
      final t = v?.toString().trim() ?? '';
      return t.isEmpty ? null : v.toString();
    }
    String? imgA = nz(existing?['choice_a_image']);
    String? imgB = nz(existing?['choice_b_image']);
    String? imgC = nz(existing?['choice_c_image']);
    String? imgD = nz(existing?['choice_d_image']);
    String? questionImageData = nz(existing?['question_image']);

    String selectedCategory   = existing?['category']   ?? 'Math';
    String selectedDifficulty = existing?['difficulty'] ?? 'Easy';

    // Stored correct_answer is the answer TEXT, not a letter — map it back.
    String? initialCorrectLetter;
    if (existing != null) {
      final correctText = _cleanText(existing['correctAnswer'] as String? ?? '').toLowerCase();
      if (correctText.isNotEmpty) {
        const letters = ['A', 'B', 'C', 'D'];
        const keys = ['choice_a', 'choice_b', 'choice_c', 'choice_d'];
        for (int i = 0; i < 4; i++) {
          if (_cleanText(existing[keys[i]] as String? ?? '').toLowerCase() == correctText) {
            initialCorrectLetter = letters[i];
            break;
          }
        }
      }
    }
    String? selectedCorrect = initialCorrectLetter;

    bool isSaving = false;

    // Field-level messages — each one says what is actually wrong.
    String? qErr, aErr, bErr, cErr, dErr, ansErr;

    // Summary banner pinned to the top of the dialog.
    List<String> formErrors = [];

    // Limits
    const int maxQuestionLen = 500;
    const int maxChoiceLen   = 200;
    const int maxTopicLen    = 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) {

        void clearErrors() {
          qErr = aErr = bErr = cErr = dErr = ansErr = null;
          formErrors = [];
        }

        /// Shows an image-picker problem in the top banner.
        void showImageError(String msg) {
          setDS(() => formErrors = [msg]);
        }

        List<String> validChoices() => [
          if (choiceACtrl.text.trim().isNotEmpty || imgA != null) 'A',
          if (choiceBCtrl.text.trim().isNotEmpty || imgB != null) 'B',
          if (choiceCCtrl.text.trim().isNotEmpty || imgC != null) 'C',
          if (choiceDCtrl.text.trim().isNotEmpty || imgD != null) 'D',
        ];

        String choiceLabel(String letter) {
          final ctrl = letter == 'A' ? choiceACtrl : letter == 'B' ? choiceBCtrl : letter == 'C' ? choiceCCtrl : choiceDCtrl;
          final img  = letter == 'A' ? imgA : letter == 'B' ? imgB : letter == 'C' ? imgC : imgD;
          final text = _cleanText(ctrl.text);
          return text.isNotEmpty ? text : (img != null ? '[Image $letter]' : letter);
        }

        InputDecoration fieldDec(String hint, {bool hasError = false}) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 9.6, color: hasError ? Colors.red.shade300 : Colors.grey.shade400, fontFamily: 'Poppins'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9.6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9.6),
            borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9.6),
            borderSide: BorderSide(color: hasError ? Colors.red : const Color(0xFF046EB8), width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        );

        Widget choiceField(String letter, TextEditingController ctrl, Color color,
            String? errorText, String? imgData, Function(String?) onImageChanged) {
          final hasError = errorText != null;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLength: maxChoiceLen,
                  style: const TextStyle(fontSize: 10.4, fontFamily: 'Poppins'),
                  onChanged: (value) {
                    setDS(() {
                      if (letter == 'A') aErr = null;
                      if (letter == 'B') bErr = null;
                      if (letter == 'C') cErr = null;
                      if (letter == 'D') dErr = null;
                      formErrors = [];
                      if (!validChoices().contains(selectedCorrect)) selectedCorrect = null;
                    });
                  },
                  decoration: fieldDec('Choice $letter', hasError: hasError).copyWith(
                    counterText: '',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(6.4),
                      width: 22.4, height: 22.4,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.4)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4.8),
              Tooltip(
                message: imgData != null ? 'Change image' : 'Add image (PNG, JPG, GIF, WEBP — max 2 MB)',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await _pickImageFile();
                      if (picked.error != null) {
                        showImageError(picked.error!);
                        return;
                      }
                      if (picked.dataUri == null) return; // cancelled
                      setDS(() {
                        onImageChanged(picked.dataUri);
                        formErrors = [];
                        if (letter == 'A') aErr = null;
                        if (letter == 'B') bErr = null;
                        if (letter == 'C') cErr = null;
                        if (letter == 'D') dErr = null;
                        if (!validChoices().contains(selectedCorrect)) selectedCorrect = null;
                      });
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: imgData != null ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: imgData != null ? color : Colors.grey.shade300,
                          width: imgData != null ? 1.5 : 1,
                        ),
                      ),
                      child: imgData != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7.2),
                              child: _renderImage(imgData, fit: BoxFit.cover,
                                  onError: () => Icon(Icons.broken_image_outlined, size: 16, color: color)),
                            )
                          : Icon(Icons.image_outlined, size: 16, color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ),
              if (imgData != null) ...[
                const SizedBox(width: 3.2),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setDS(() {
                      onImageChanged(null);
                      if (!validChoices().contains(selectedCorrect)) selectedCorrect = null;
                    }),
                    child: Container(
                      width: 19.2, height: 19.2,
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.shade200)),
                      child: Icon(Icons.close, size: 11.2, color: Colors.red.shade400),
                    ),
                  ),
                ),
              ],
            ]),
            if (hasError) Padding(
              padding: const EdgeInsets.only(left: 3.2, top: 2.4),
              child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 8.8, fontFamily: 'Poppins')),
            ),
          ]);
        }

        Widget dropdownField(String label, String value, List<String> opts, ValueChanged<String?> onChange) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 9.6, fontWeight: FontWeight.w600, color: Color(0xFF444444), fontFamily: 'Poppins')),
            const SizedBox(height: 4.8),
            DropdownButtonFormField<String>(
              initialValue: value,
              onChanged: onChange,
              items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4)))).toList(),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(9.6)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9.6), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9.6), borderSide: const BorderSide(color: Color(0xFF046EB8), width: 1.6)),
                isDense: true,
              ),
            ),
          ]);
        }

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
          child: SizedBox(
            width: 496,
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // ── Header bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                decoration: BoxDecoration(
                  color: isEdit ? Colors.orange.withValues(alpha: 0.05) : const Color(0xFF046EB8).withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isEdit ? Colors.orange : const Color(0xFF046EB8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isEdit ? Icons.edit : Icons.add, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 9.6),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isEdit ? 'Edit Question' : 'Add New Question',
                        style: const TextStyle(fontSize: 14.4, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    Text(isEdit ? 'Update the fields below.' : 'Fill in all fields to add a question.',
                        style: TextStyle(fontSize: 9.6, fontFamily: 'Poppins', color: Colors.grey.shade500)),
                  ]),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),

              // ── ERROR BANNER — sits at the top, outside the scroll area, so
              //    it is always visible no matter where the user has scrolled ──
              if (formErrors.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(19.2, 14, 19.2, 0),
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(9.6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('•  ', style: TextStyle(fontSize: 9.6, color: Colors.red.shade700)),
                            Expanded(
                              child: Text(e, style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 9.6,
                                height: 1.4, color: Colors.red.shade700,
                              )),
                            ),
                          ]),
                        )),
                      ]),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setDS(() => formErrors = []),
                        child: Icon(Icons.close, size: 13, color: Colors.red.shade400),
                      ),
                    ),
                  ]),
                ),

              // ── Body ──
              Flexible(child: SingleChildScrollView(
                padding: const EdgeInsets.all(19.2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Row(children: [
                    Expanded(child: dropdownField('Category', selectedCategory, _categories,
                        (v) => setDS(() => selectedCategory = v!))),
                    const SizedBox(width: 9.6),
                    Expanded(child: dropdownField('Difficulty', selectedDifficulty, _difficulties,
                        (v) => setDS(() => selectedDifficulty = v!))),
                  ]),
                  const SizedBox(height: 14.4),

                  // Topic — optional free text
                  Row(children: [
                    const Text('Topic', style: TextStyle(fontSize: 9.6, fontWeight: FontWeight.w600, color: Color(0xFF444444), fontFamily: 'Poppins')),
                    const SizedBox(width: 6.4),
                    Text('(optional)', style: TextStyle(fontSize: 8.8, fontFamily: 'Poppins', color: Colors.grey.shade500)),
                  ]),
                  const SizedBox(height: 4.8),
                  TextField(
                    controller: topicCtrl,
                    maxLength: maxTopicLen,
                    style: const TextStyle(fontSize: 10.4, fontFamily: 'Poppins'),
                    decoration: fieldDec('e.g. Algebra, Fractions, Cell Biology...').copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 14.4),

                  // Question text — required unless a question image is provided.
                  // Both can be filled in together (image shows above the question,
                  // text shows in the question box) — this only relaxes the requirement.
                  Row(children: [
                    Text(questionImageData == null ? 'Question *' : 'Question',
                        style: const TextStyle(fontSize: 10.4, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Color(0xFF1A1A1A))),
                    if (questionImageData != null) ...[
                      const SizedBox(width: 6.4),
                      Text('(optional — image provided)',
                          style: TextStyle(fontSize: 8.8, fontFamily: 'Poppins', color: Colors.grey.shade500)),
                    ],
                  ]),
                  const SizedBox(height: 4.8),
                  TextField(
                    controller: questionCtrl,
                    maxLines: 3,
                    maxLength: maxQuestionLen,
                    style: const TextStyle(fontSize: 10.4, fontFamily: 'Poppins'),
                    onChanged: (_) => setDS(() { qErr = null; formErrors = []; }),
                    decoration: fieldDec(
                      questionImageData == null ? 'Enter the question text...' : 'Enter the question text (optional)...',
                      hasError: qErr != null,
                    ).copyWith(counterStyle: const TextStyle(fontSize: 8, fontFamily: 'Poppins')),
                  ),
                  if (qErr != null) Padding(
                    padding: const EdgeInsets.only(left: 3.2, top: 2.4),
                    child: Text(qErr!, style: const TextStyle(color: Colors.red, fontSize: 8.8, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(height: 14.4),

                  // ── Question Image (optional) ──
                  Row(children: [
                    const Text('Question Image',
                        style: TextStyle(fontSize: 9.6, fontWeight: FontWeight.w600, color: Color(0xFF444444), fontFamily: 'Poppins')),
                    const SizedBox(width: 6.4),
                    Text('(optional — PNG, JPG, GIF, WEBP, max 2 MB)',
                        style: TextStyle(fontSize: 8.8, fontFamily: 'Poppins', color: Colors.grey.shade500)),
                  ]),
                  const SizedBox(height: 6.4),
                  Row(children: [
                    if (questionImageData != null) ...[
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF046EB8), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.5),
                          child: _renderImage(questionImageData, fit: BoxFit.cover,
                              onError: () => const Icon(Icons.broken_image_outlined, size: 20, color: Color(0xFF046EB8))),
                        ),
                      ),
                      const SizedBox(width: 9.6),
                    ],
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _pickImageFile();
                        if (picked.error != null) {
                          showImageError(picked.error!);
                          return;
                        }
                        if (picked.dataUri == null) return; // cancelled
                        setDS(() {
                          questionImageData = picked.dataUri;
                          qErr = null;
                          formErrors = [];
                        });
                      },
                      icon: Icon(questionImageData != null ? Icons.swap_horiz : Icons.upload_outlined, size: 14.4),
                      label: Text(questionImageData != null ? 'Change image' : 'Upload image',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF046EB8),
                        side: const BorderSide(color: Color(0xFF046EB8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    if (questionImageData != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => setDS(() => questionImageData = null),
                        icon: const Icon(Icons.delete_outline, size: 14.4),
                        label: const Text('Remove',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 14.4),

                  // Answer choices
                  const Text('Answer Choices *',
                      style: TextStyle(fontSize: 10.4, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 6.4),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: choiceField('A', choiceACtrl, const Color(0xFF046EB8), aErr, imgA, (v) => imgA = v)),
                    const SizedBox(width: 9.6),
                    Expanded(child: choiceField('B', choiceBCtrl, Colors.green, bErr, imgB, (v) => imgB = v)),
                  ]),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: choiceField('C', choiceCCtrl, Colors.orange, cErr, imgC, (v) => imgC = v)),
                    const SizedBox(width: 9.6),
                    Expanded(child: choiceField('D', choiceDCtrl, Colors.red, dErr, imgD, (v) => imgD = v)),
                  ]),
                  const SizedBox(height: 14.4),

                  // Correct answer
                  Row(children: [
                    const Text('Correct Answer *',
                        style: TextStyle(fontSize: 10.4, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Color(0xFF1A1A1A))),
                    const SizedBox(width: 6.4),
                    Text('(select from choices above)',
                        style: TextStyle(fontSize: 8.8, fontFamily: 'Poppins', color: Colors.grey.shade500)),
                  ]),
                  const SizedBox(height: 4.8),
                  DropdownButtonFormField<String>(
                    initialValue: validChoices().contains(selectedCorrect) ? selectedCorrect : null,
                    hint: Text('Select the correct answer',
                        style: TextStyle(fontSize: 10.4, fontFamily: 'Poppins',
                            color: ansErr != null ? Colors.red.shade300 : Colors.grey.shade400)),
                    onChanged: (v) => setDS(() { selectedCorrect = v; ansErr = null; formErrors = []; }),
                    items: validChoices().map((letter) => DropdownMenuItem(
                      value: letter,
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 12.8),
                        const SizedBox(width: 6.4),
                        Expanded(child: Text(choiceLabel(letter), style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4), overflow: TextOverflow.ellipsis)),
                      ]),
                    )).toList(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9.6)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9.6),
                        borderSide: BorderSide(color: ansErr != null ? Colors.red : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9.6),
                        borderSide: BorderSide(color: ansErr != null ? Colors.red : Colors.green, width: 1.6),
                      ),
                      isDense: true,
                    ),
                  ),
                  if (ansErr != null) Padding(
                    padding: const EdgeInsets.only(left: 3.2, top: 2.4),
                    child: Text(ansErr!, style: const TextStyle(color: Colors.red, fontSize: 8.8, fontFamily: 'Poppins')),
                  ),
                ]),
              )),

              // ── Footer buttons ──
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(children: [
                  OutlinedButton.icon(
                    onPressed: () => _openQuestionPreview(
                      question: _cleanText(questionCtrl.text),
                      questionImage: questionImageData,
                      choices: {
                        'A': _cleanText(choiceACtrl.text),
                        'B': _cleanText(choiceBCtrl.text),
                        'C': _cleanText(choiceCCtrl.text),
                        'D': _cleanText(choiceDCtrl.text),
                      },
                      choiceImages: {'A': imgA, 'B': imgB, 'C': imgC, 'D': imgD},
                      correctLetter: selectedCorrect,
                      category: selectedCategory,
                      difficulty: selectedDifficulty,
                      topic: _cleanText(topicCtrl.text),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 14.4),
                    label: const Text('Preview', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF046EB8),
                      side: const BorderSide(color: Color(0xFF046EB8)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 9.6),
                  ElevatedButton.icon(
                    icon: isSaving
                        ? const SizedBox(width: 12.8, height: 12.8, child: CircularProgressIndicator(strokeWidth: 1.6, color: Color(0xFF816A03)))
                        : Icon(isEdit ? Icons.save_rounded : Icons.add, size: 14.4),
                    label: Text(isEdit ? 'SAVE CHANGES' : 'ADD QUESTION',
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000),
                      foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: isSaving ? null : () async {

                      // ── STEP 1: normalise whitespace and write it back into
                      //    the fields so the admin sees exactly what gets saved.
                      //    Leading/trailing spaces are silently accepted, not
                      //    treated as an error.
                      final question = _cleanText(questionCtrl.text);
                      final a = _cleanText(choiceACtrl.text);
                      final b = _cleanText(choiceBCtrl.text);
                      final c = _cleanText(choiceCCtrl.text);
                      final d = _cleanText(choiceDCtrl.text);
                      final topic = _cleanText(topicCtrl.text);

                      questionCtrl.text = question;
                      choiceACtrl.text  = a;
                      choiceBCtrl.text  = b;
                      choiceCCtrl.text  = c;
                      choiceDCtrl.text  = d;
                      topicCtrl.text    = topic;

                      // ── STEP 2: validate, one specific message per problem ──
                      final problems = <String>[];
                      clearErrors();

                      if (question.isEmpty && questionImageData == null) {
                        qErr = 'Enter question text or upload an image';
                        problems.add('Question needs either text or an image — both are empty.');
                      } else if (question.isNotEmpty && question.length < 5) {
                        qErr = 'Too short — at least 5 characters';
                        problems.add('Question text is too short (minimum 5 characters).');
                      } else if (question.isNotEmpty && question.length > maxQuestionLen) {
                        qErr = 'Too long — max $maxQuestionLen characters';
                        problems.add('Question text is ${question.length} characters. Maximum is $maxQuestionLen.');
                      }

                      void checkChoice(String letter, String text, String? img, void Function(String) setErr) {
                        if (text.isEmpty && img == null) {
                          setErr('Add text or an image');
                          problems.add('Choice $letter is empty. Type an answer or upload an image for it.');
                        } else if (text.length > maxChoiceLen) {
                          setErr('Too long — max $maxChoiceLen characters');
                          problems.add('Choice $letter is ${text.length} characters. Maximum is $maxChoiceLen.');
                        }
                      }
                      checkChoice('A', a, imgA, (m) => aErr = m);
                      checkChoice('B', b, imgB, (m) => bErr = m);
                      checkChoice('C', c, imgC, (m) => cErr = m);
                      checkChoice('D', d, imgD, (m) => dErr = m);

                      // Duplicate choice text (ignores case and spacing)
                      final filled = <String, String>{
                        if (a.isNotEmpty) 'A': a.toLowerCase(),
                        if (b.isNotEmpty) 'B': b.toLowerCase(),
                        if (c.isNotEmpty) 'C': c.toLowerCase(),
                        if (d.isNotEmpty) 'D': d.toLowerCase(),
                      };
                      final seen = <String, String>{}; // text -> first letter
                      filled.forEach((letter, text) {
                        if (seen.containsKey(text)) {
                          problems.add('Choices ${seen[text]} and $letter are the same. Each choice must be different.');
                        } else {
                          seen[text] = letter;
                        }
                      });

                      // Correct answer
                      if (selectedCorrect == null) {
                        ansErr = 'Select which choice is correct';
                        problems.add('No correct answer selected.');
                      } else if (!validChoices().contains(selectedCorrect)) {
                        ansErr = 'That choice is now empty — pick another';
                        problems.add('The choice marked as correct is empty. Pick a different correct answer.');
                      }

                      if (problems.isNotEmpty) {
                        setDS(() => formErrors = problems);
                        return;
                      }

                      // ── STEP 3: save ─────────────────────────────────────────
                      String correctAnswerValue;
                      switch (selectedCorrect) {
                        case 'A': correctAnswerValue = a.isNotEmpty ? a : 'A'; break;
                        case 'B': correctAnswerValue = b.isNotEmpty ? b : 'B'; break;
                        case 'C': correctAnswerValue = c.isNotEmpty ? c : 'C'; break;
                        case 'D': correctAnswerValue = d.isNotEmpty ? d : 'D'; break;
                        default:  correctAnswerValue = selectedCorrect!;
                      }

                      setDS(() => isSaving = true);

                      final payload = {
                        'question':         question,
                        'choice_a':         a,
                        'choice_b':         b,
                        'choice_c':         c,
                        'choice_d':         d,
                        'correct_answer':   correctAnswerValue,
                        'category':         selectedCategory,
                        'difficulty_level': selectedDifficulty,
                        'topic':            topic,
                        // Always sent (null when removed) so removing an image
                        // on edit actually clears it instead of keeping the old one.
                        'question_image': questionImageData,
                        'choice_a_image': imgA,
                        'choice_b_image': imgB,
                        'choice_c_image': imgC,
                        'choice_d_image': imgD,
                      };

                      final result = isEdit
                          ? await _api.updateQuestion(existing!['id'].toString(), payload)
                          : await _api.addQuestion(payload);

                      if (!ctx.mounted) return;
                      setDS(() => isSaving = false);

                      if (result['success'] == true) {
                        Navigator.pop(ctx);
                        _loadQuestions();
                        _snack(isEdit ? 'Question updated!' : 'Question added!', const Color(0xFF27AE60));
                      } else {
                        // Server-side failures land in the same top banner so
                        // they are impossible to miss.
                        final msg = result['message']?.toString() ?? 'Could not save the question.';
                        final serverErrors = result['errors'];
                        final list = <String>[];
                        if (serverErrors is Map) {
                          serverErrors.forEach((field, msgs) {
                            if (msgs is List) {
                              for (final m in msgs) list.add(m.toString());
                            }
                          });
                        }
                        setDS(() => formErrors = list.isNotEmpty ? list : [msg]);
                      }
                    },
                  ),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
  }

  // ── Image picker + validation ─────────────────────────────────────────────

  /// Max accepted image file size. Base64 inflates by ~33%, so 2 MB on disk
  /// becomes roughly 2.7 MB in the JSON body — safely under PHP's default
  /// post_max_size (8M) and nowhere near Mongo's 16 MB document limit.
  static const int _maxImageBytes = 2 * 1024 * 1024; // 2 MB

  static const List<String> _allowedImageExts = ['png', 'jpg', 'jpeg', 'gif', 'webp'];
  static const List<String> _allowedImageMimes = [
    'image/png', 'image/jpeg', 'image/jpg', 'image/gif', 'image/webp',
  ];

  /// Opens the OS file picker and returns either a validated base64 data URI
  /// or a specific error message explaining why the file was rejected.
  ///
  /// `dataUri == null && error == null` means the user just cancelled.
  Future<({String? dataUri, String? error})> _pickImageFile() async {
    final completer = Completer<({String? dataUri, String? error})>();
    final input = html.FileUploadInputElement();
    input.accept = 'image/png,image/jpeg,image/jpg,image/gif,image/webp';

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete((dataUri: null, error: null)); // cancelled
        return;
      }

      final file = files.first;
      final name = file.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

      // ── 1. Extension check ────────────────────────────────────────────────
      if (!_allowedImageExts.contains(ext)) {
        completer.complete((
          dataUri: null,
          error: '"$name" is not a supported image. '
              'Use PNG, JPG, GIF or WEBP.',
        ));
        return;
      }

      // ── 2. Reported MIME type check ───────────────────────────────────────
      final String? rawType = file.type;
      final mime = (rawType ?? '').toLowerCase();
      if (mime.isNotEmpty && !_allowedImageMimes.contains(mime)) {
        completer.complete((
          dataUri: null,
          error: '"$name" is not a valid image file (detected as $mime).',
        ));
        return;
      }

      // ── 3. Size check ─────────────────────────────────────────────────────
      final num? size = file.size;
      if (size != null && size > _maxImageBytes) {
        completer.complete((
          dataUri: null,
          error: '"$name" is ${_formatBytes(size)}. '
              'Maximum image size is ${_formatBytes(_maxImageBytes)}.',
        ));
        return;
      }
      if (size != null && size == 0) {
        completer.complete((dataUri: null, error: '"$name" is empty (0 bytes).'));
        return;
      }

      // ── 4. Read, then verify the actual file contents ─────────────────────
      final reader = html.FileReader();

      reader.onError.listen((_) {
        completer.complete((
          dataUri: null,
          error: 'Could not read "$name". The file may be corrupted.',
        ));
      });

      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is! String || !result.startsWith('data:')) {
          completer.complete((
            dataUri: null,
            error: 'Could not read "$name" as an image.',
          ));
          return;
        }

        // Magic-byte check — this is what catches a .txt renamed to .png.
        if (!_hasImageSignature(result)) {
          completer.complete((
            dataUri: null,
            error: '"$name" is not a real image file. '
                'Renaming a file to .$ext does not make it an image.',
          ));
          return;
        }

        completer.complete((dataUri: result, error: null));
      });

      reader.readAsDataUrl(file);
    });

    input.click();
    return completer.future;
  }

  /// Reads the first bytes of a base64 data URI and confirms they match a
  /// known image format header. Blocks files that were simply renamed.
  bool _hasImageSignature(String dataUri) {
    final comma = dataUri.indexOf(',');
    if (comma == -1) return false;
    try {
      final head = dataUri.substring(comma + 1);
      // 24 base64 chars ≈ 18 bytes, plenty for every signature below.
      final sample = head.length > 24 ? head.substring(0, 24) : head;
      final pad = sample.length % 4;
      final bytes = base64Decode(pad == 0 ? sample : sample.substring(0, sample.length - pad));
      if (bytes.length < 12) return false;

      // PNG  → 89 50 4E 47
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
      // JPEG → FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
      // GIF  → "GIF8"
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) return true;
      // WEBP → "RIFF" .... "WEBP"
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  // Takes num, not int — file.size comes back as num? on this
  // universal_html version, and passing that straight to an int-typed
  // parameter is exactly what broke `flutter build web` (dart2js rejected
  // it as a num→int assignment).
  String _formatBytes(num bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes bytes';
  }

  /// Trims leading/trailing whitespace and collapses runs of internal
  /// whitespace (including stray tabs and newlines pasted from a document)
  /// down to a single space. "  2 + 2  =   4 " → "2 + 2 = 4"
  String _cleanText(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  // ── CSV helpers ───────────────────────────────────────────────────────────

  /// Opens OS file picker and returns the CSV text content.
  Future<({String name, String content})?> _pickCsvFile() async {
    final completer = Completer<({String name, String content})?>();
    final input = html.FileUploadInputElement();
    input.accept = '.csv,text/csv';
    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }
      final file = files.first;
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is String) {
          completer.complete((name: file.name, content: result));
        } else {
          completer.complete(null);
        }
      });
      reader.readAsText(file);
    });
    input.click();
    return completer.future;
  }

  /// Triggers a browser download of [content] as a CSV file.
  void _triggerDownload(String content, String filename) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Parses CSV text into rows, respecting double-quoted fields.
  List<List<String>> _parseCsvContent(String raw) {
    final result = <List<String>>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cols = <String>[];
      bool inQuotes = false;
      final buf = StringBuffer();
      for (int i = 0; i < trimmed.length; i++) {
        final ch = trimmed[i];
        if (ch == '"') {
          inQuotes = !inQuotes;
        } else if (ch == ',' && !inQuotes) {
          cols.add(buf.toString().trim());
          buf.clear();
        } else {
          buf.write(ch);
        }
      }
      cols.add(buf.toString().trim());
      result.add(cols);
    }
    return result;
  }

  static const List<String> _csvColumns = [
    'question', 'choice_a', 'choice_b', 'choice_c', 'choice_d',
    'correct_answer', 'category', 'difficulty_level', 'topic',
  ];

  /// Validates parsed CSV data rows (no header) before anything is sent to the API.
  /// Returns one [_CsvRowValidation] per row, in file order, with row numbers
  /// counted as if the header were row 1 (so row numbers match what a person
  /// would see if they opened the file in a spreadsheet app).
  List<_CsvRowValidation> _validateCsvRows(List<List<String>> dataRows) {
    final results = <_CsvRowValidation>[];
    final seenQuestions = <String, int>{}; // normalized question text -> first row number

    for (int i = 0; i < dataRows.length; i++) {
      final cols = dataRows[i];
      final rowNumber = i + 2; // header occupies row 1
      final errors = <String>[];

      if (cols.length < _csvColumns.length) {
        errors.add('Incomplete row — expected ${_csvColumns.length} columns, found ${cols.length}');
        results.add(_CsvRowValidation(rowNumber: rowNumber, cols: cols, payload: const {}, errors: errors));
        continue;
      }

      final question   = cols[0].trim();
      final choiceA    = cols[1].trim();
      final choiceB    = cols[2].trim();
      final choiceC    = cols[3].trim();
      final choiceD    = cols[4].trim();
      final correct    = cols[5].trim();
      final category   = cols[6].trim();
      final difficulty = cols[7].trim();
      final topic      = cols[8].trim(); // optional — no requireField check

      void requireField(String label, String value) {
        if (value.isEmpty) errors.add('Missing $label');
      }
      requireField('question text', question);
      requireField('choice A', choiceA);
      requireField('choice B', choiceB);
      requireField('choice C', choiceC);
      requireField('choice D', choiceD);
      requireField('correct answer', correct);
      requireField('category', category);
      requireField('difficulty', difficulty);

      // Duplicate question text (flag the later row, point back at the first one)
      if (question.isNotEmpty) {
        final key = question.toLowerCase();
        if (seenQuestions.containsKey(key)) {
          errors.add('Duplicate question — same as row ${seenQuestions[key]}');
        } else {
          seenQuestions[key] = rowNumber;
        }
      }

      // Correct answer must match one of the four choices
      if (correct.isNotEmpty &&
          ![choiceA, choiceB, choiceC, choiceD].map((c) => c.toLowerCase()).contains(correct.toLowerCase())) {
        errors.add("Correct answer doesn't match any of the 4 choices");
      }

      // Category / difficulty must be recognized values (topic is free text — no enum check)
      final categoryNorm = _categories.firstWhere((c) => c.toLowerCase() == category.toLowerCase(), orElse: () => '');
      if (category.isNotEmpty && categoryNorm.isEmpty) {
        errors.add('Unknown category "$category" (expected ${_categories.join(" or ")})');
      }
      final difficultyNorm = _difficulties.firstWhere((d) => d.toLowerCase() == difficulty.toLowerCase(), orElse: () => '');
      if (difficulty.isNotEmpty && difficultyNorm.isEmpty) {
        errors.add('Unknown difficulty "$difficulty" (expected ${_difficulties.join(", ")})');
      }

      final payload = {
        'question':         question,
        'choice_a':         choiceA,
        'choice_b':         choiceB,
        'choice_c':         choiceC,
        'choice_d':         choiceD,
        'correct_answer':   correct,
        'category':         categoryNorm.isNotEmpty ? categoryNorm : category,
        'difficulty_level': difficultyNorm.isNotEmpty ? difficultyNorm : difficulty,
        'topic':            topic,
      };

      results.add(_CsvRowValidation(rowNumber: rowNumber, cols: cols, payload: payload, errors: errors));
    }
    return results;
  }

  /// Finds which choice letter (A–D) matches a payload's correct_answer text.
  String? _correctLetterFor(Map<String, dynamic> payload) {
    final correct = (payload['correct_answer'] as String? ?? '').toLowerCase();
    const letters = ['A', 'B', 'C', 'D'];
    const keys = ['choice_a', 'choice_b', 'choice_c', 'choice_d'];
    for (int i = 0; i < 4; i++) {
      if ((payload[keys[i]] as String? ?? '').toLowerCase() == correct) return letters[i];
    }
    return null;
  }

  // ── Import CSV Dialog ─────────────────────────────────────────────────────

  void _showImportDialog() {
    String? pickedFileName;
    String? csvContent;
    bool isDragOver = false;
    bool importing = false;
    int imported = 0;
    int failed = 0;
    List<String> failedRows = [];
    List<_CsvRowValidation>? validation; // null until a file has been picked & validated

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) {

        Future<void> pickFile() async {
          final picked = await _pickCsvFile();
          if (picked == null) return;
          final rows = _parseCsvContent(picked.content);
          final dataRows = rows.isNotEmpty && rows.first.isNotEmpty &&
              rows.first.first.toLowerCase() == 'question'
              ? rows.skip(1).toList()
              : rows;
          setDS(() {
            pickedFileName = picked.name;
            csvContent = picked.content;
            validation = _validateCsvRows(dataRows);
            imported = 0;
            failed = 0;
            failedRows = [];
          });
        }

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
          child: SizedBox(
            width: 512,
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // ── Header ──
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                    child: const Icon(Icons.upload_file, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 9.6),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Import Questions from CSV',
                        style: TextStyle(fontSize: 14.4, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    Text('Pick or drag a .csv file to upload questions in bulk',
                        style: TextStyle(fontSize: 9.6, fontFamily: 'Poppins', color: Colors.grey.shade500)),
                  ]),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),

              // ── Body ──
              Flexible(child: SingleChildScrollView(
                padding: const EdgeInsets.all(19.2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Format info
                  Container(
                    padding: const EdgeInsets.all(11.2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.info_outline, size: 12.8, color: Color(0xFF046EB8)),
                        SizedBox(width: 4.8),
                        Text('Required CSV Column Order',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 10.4, color: Color(0xFF046EB8))),
                      ]),
                      const SizedBox(height: 6.4),
                      Text(
                        'question, choice_a, choice_b, choice_c, choice_d, correct_answer, category, difficulty_level, topic\n\n'
                            'topic is optional — leave the cell blank if you don\'t have one.\n\n'
                            'Example:\nWhat is 2+2?,3,4,5,6,4,Math,Easy,Addition',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 8.8, color: Colors.blue.shade900),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Drop zone
                  DragTarget<Object>(
                    onWillAcceptWithDetails: (_) { setDS(() => isDragOver = true); return true; },
                    onLeave: (_) => setDS(() => isDragOver = false),
                    onAcceptWithDetails: (_) => setDS(() => isDragOver = false),
                    builder: (_, __, ___) => GestureDetector(
                      onTap: pickFile,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        decoration: BoxDecoration(
                          color: isDragOver
                              ? Colors.purple.withValues(alpha: 0.08)
                              : pickedFileName != null
                              ? Colors.green.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.04),
                          border: Border.all(
                            color: isDragOver
                                ? Colors.purple
                                : pickedFileName != null
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: isDragOver ? 2 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(11.2),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            pickedFileName != null
                                ? Icons.check_circle_rounded
                                : Icons.upload_file_rounded,
                            size: 41.6,
                            color: pickedFileName != null
                                ? Colors.green
                                : Colors.purple.withValues(alpha: 0.55),
                          ),
                          const SizedBox(height: 9.6),
                          if (pickedFileName != null) ...[
                            Text(pickedFileName!,
                                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                                    fontSize: 11.2, color: Colors.green)),
                            const SizedBox(height: 4.8),
                            TextButton(
                              onPressed: () => setDS(() {
                                pickedFileName = null; csvContent = null;
                                validation = null;
                                imported = 0; failed = 0; failedRows = [];
                              }),
                              child: const Text('Remove file',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 9.6, color: Colors.red)),
                            ),
                          ] else ...[
                            const Text('Drag & drop your CSV file here',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                                    fontWeight: FontWeight.w600, color: Colors.black87)),
                            const SizedBox(height: 4.8),
                            Text('or', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.grey.shade500)),
                            const SizedBox(height: 9.6),
                            ElevatedButton.icon(
                              onPressed: pickFile,
                              icon: const Icon(Icons.folder_open_rounded, size: 14.4),
                              label: const Text('Browse File',
                                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 10.4)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                            ),
                            const SizedBox(height: 6.4),
                            Text('.csv files only',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 8.8, color: Colors.grey.shade400)),
                          ],
                        ]),
                      ),
                    ),
                  ),

                  // ── Validation summary (shown as soon as a file is picked, before import) ──
                  if (validation != null) ...[
                    const SizedBox(height: 14.4),
                    if (validation!.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(11.2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.warning_amber_rounded, size: 14.4, color: Colors.orange.shade800),
                          const SizedBox(width: 6.4),
                          const Expanded(child: Text('No data rows found in the CSV.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4))),
                        ]),
                      )
                    else ...[
                      Builder(builder: (_) {
                        final validCount = validation!.where((r) => r.isValid).length;
                        final invalidCount = validation!.length - validCount;
                        return Row(children: [
                          Text('Checked ${validation!.length} row${validation!.length == 1 ? '' : 's'}',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.grey.shade600)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                            child: Text('$validCount valid', style: TextStyle(fontFamily: 'Poppins', fontSize: 9.6, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                          ),
                          if (invalidCount > 0) ...[
                            const SizedBox(width: 6.4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                              child: Text('$invalidCount need attention', style: TextStyle(fontFamily: 'Poppins', fontSize: 9.6, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                            ),
                          ],
                        ]);
                      }),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(4),
                          itemCount: validation!.length,
                          separatorBuilder: (_, __) => Divider(height: 0.8, color: Colors.grey.shade100),
                          itemBuilder: (_, i) {
                            final row = validation![i];
                            final questionPreviewText = row.payload['question'] as String? ??
                                (row.cols.isNotEmpty ? row.cols.first : '(unreadable row)');
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Icon(row.isValid ? Icons.check_circle : Icons.error,
                                    size: 13, color: row.isValid ? Colors.green : Colors.red),
                                const SizedBox(width: 6.4),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Row ${row.rowNumber}: $questionPreviewText',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4, fontWeight: FontWeight.w600)),
                                    if (!row.isValid)
                                      Text(row.errors.join(' • '),
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 9.2, color: Colors.red.shade600)),
                                  ]),
                                ),
                                if (row.isValid)
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 14.4, color: Color(0xFF046EB8)),
                                    tooltip: 'Preview how this looks to players',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    onPressed: () => _openQuestionPreview(
                                      question: row.payload['question'] as String,
                                      questionImage: null,
                                      choices: {
                                        'A': row.payload['choice_a'] as String,
                                        'B': row.payload['choice_b'] as String,
                                        'C': row.payload['choice_c'] as String,
                                        'D': row.payload['choice_d'] as String,
                                      },
                                      choiceImages: const {'A': null, 'B': null, 'C': null, 'D': null},
                                      correctLetter: _correctLetterFor(row.payload),
                                      category: row.payload['category'] as String,
                                      difficulty: row.payload['difficulty_level'] as String,
                                      topic: row.payload['topic'] as String?,
                                    ),
                                  ),
                              ]),
                            );
                          },
                        ),
                      ),
                      if (validation!.any((r) => !r.isValid)) ...[
                        const SizedBox(height: 6.4),
                        Text('Rows that need attention will be skipped — fix them in the CSV and re-upload if you want them included.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 8.8, color: Colors.grey.shade500)),
                      ],
                    ],
                  ],

                  // Results
                  if (imported > 0 || failed > 0) ...[
                    const SizedBox(height: 12.8),
                    Row(children: [
                      if (imported > 0) Expanded(child: Container(
                        padding: const EdgeInsets.all(9.6),
                        decoration: BoxDecoration(color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200)),
                        child: Row(children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 14.4),
                          const SizedBox(width: 6.4),
                          Text('$imported imported',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4,
                                  fontWeight: FontWeight.w600, color: Colors.green)),
                        ]),
                      )),
                      if (imported > 0 && failed > 0) const SizedBox(width: 8),
                      if (failed > 0) Expanded(child: Container(
                        padding: const EdgeInsets.all(9.6),
                        decoration: BoxDecoration(color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200)),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 14.4),
                          const SizedBox(width: 6.4),
                          Text('$failed failed',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4,
                                  fontWeight: FontWeight.w600, color: Colors.red)),
                        ]),
                      )),
                    ]),
                    if (failedRows.isNotEmpty) ...[
                      const SizedBox(height: 6.4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50, borderRadius: BorderRadius.circular(6.4)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Failed rows:',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 8.8,
                                  fontWeight: FontWeight.w600, color: Colors.red)),
                          const SizedBox(height: 3.2),
                          ...failedRows.take(5).map((r) => Text('• $r',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 8.8, color: Colors.red),
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (failedRows.length > 5)
                            Text('... and ${failedRows.length - 5} more',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 8.8, color: Colors.red)),
                        ]),
                      ),
                    ],
                  ],
                ]),
              )),

              // ── Footer ──
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                child: Row(children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      const header = 'question,choice_a,choice_b,choice_c,choice_d,correct_answer,category,difficulty_level,topic\n';
                      const example = 'What is 2+2?,3,4,5,6,4,Math,Easy,Addition\n';
                      _triggerDownload(header + example, 'quiz_template.csv');
                    },
                    icon: const Icon(Icons.download_rounded, size: 12.8),
                    label: const Text('Download Template',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 9.6)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: importing ? null : () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF046EB8),
                      side: const BorderSide(color: Color(0xFF046EB8)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Close',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 9.6),
                  ElevatedButton.icon(
                    icon: importing
                        ? const SizedBox(width: 12.8, height: 12.8,
                        child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white))
                        : const Icon(Icons.upload_rounded, size: 14.4),
                    label: Text(
                      importing
                          ? 'Importing...'
                          : (validation != null && validation!.isNotEmpty)
                          ? 'IMPORT ${validation!.where((r) => r.isValid).length} VALID'
                          : 'IMPORT',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.purple.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    // Only rows that passed validation are ever sent to the API — invalid
                    // rows are skipped and reported, never silently dropped or blocked outright.
                    onPressed: (importing || validation == null || validation!.every((r) => !r.isValid))
                        ? null
                        : () async {
                      final validRows = validation!.where((r) => r.isValid).toList();
                      final skippedCount = validation!.length - validRows.length;

                      setDS(() { importing = true; imported = 0; failed = 0; failedRows = []; });

                      for (final row in validRows) {
                        final res = await _api.addQuestion(row.payload);
                        setDS(() {
                          if (res['success'] == true) {
                            imported++;
                          } else {
                            failed++;
                            failedRows.add('Row ${row.rowNumber}: ${res['message'] ?? 'failed'}');
                          }
                        });
                      }

                      setDS(() => importing = false);
                      if (!ctx.mounted) return;
                      if (imported > 0) _loadQuestions();
                      if (skippedCount > 0) {
                        _snack('$imported imported. $skippedCount row(s) skipped due to validation errors.', Colors.orange);
                      }
                    },
                  ),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
  }

  // ── Export CSV ────────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    _snack('Fetching questions for export...', const Color(0xFF046EB8));

    final result = await _api.getQuestions(
      category:   selectedCategoryFilter,
      difficulty: selectedDifficultyFilter,
      yearLevel:  null,
      search:     searchQuery.isEmpty ? null : searchQuery,
      page:       1,
      perPage:    99999,
    );

    if (result['success'] != true) {
      _snack('Export failed: ${result['message']}', Colors.red);
      return;
    }

    final questions = (result['questions'] as List<dynamic>? ?? [])
        .map((q) => q as Map<String, dynamic>)
        .toList();

    if (questions.isEmpty) {
      _snack('No questions to export.', Colors.orange);
      return;
    }

    String esc(dynamic v) {
      final s = (v ?? '').toString();
      return s.contains(',') || s.contains('"') || s.contains('\n')
          ? '"${s.replaceAll('"', '""')}"'
          : s;
    }

    final buf = StringBuffer();
    buf.writeln('question,choice_a,choice_b,choice_c,choice_d,correct_answer,category,difficulty_level,topic,status');
    for (final q in questions) {
      buf.writeln([
        esc(q['question']),  esc(q['choice_a']),  esc(q['choice_b']),
        esc(q['choice_c']),  esc(q['choice_d']),  esc(q['correct_answer']),
        esc(q['category']),  esc(q['difficulty_level']), esc(q['topic']),
        esc((q['is_active'] ?? 1) == 1 ? 'Active' : 'Inactive'),
      ].join(','));
    }

    final ts = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    _triggerDownload(buf.toString(), 'quiz_questions_$ts.csv');
    _snack('Exported ${questions.length} questions!', Colors.green);
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _sortIcon(String column) {
    if (sortColumn != column) return const Icon(Icons.unfold_more, size: 12, color: Colors.grey);
    return Icon(sortAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        size: 12, color: const Color(0xFF046EB8));
  }

  Widget _filterDrop(String hint, String? value, List<String> options, ValueChanged<String?> onChange) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: value != null ? const Color(0xFF046EB8) : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
        color: value != null ? const Color(0xFF046EB8).withValues(alpha: 0.05) : Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 10.4, fontFamily: 'Poppins', color: Colors.grey.shade600)),
          icon: Icon(Icons.keyboard_arrow_down, size: 14.4, color: value != null ? const Color(0xFF046EB8) : Colors.grey),
          style: const TextStyle(fontSize: 10.4, fontFamily: 'Poppins', color: Color(0xFF046EB8)),
          isDense: true,
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('All $hint', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.black87))),
            ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.black87)))),
          ],
          onChanged: onChange,
        ),
      ),
    );
  }

  Widget _headerCell(String label, String column, {int flex = 2}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _sortBy(column),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10.4, fontFamily: 'Poppins')),
          const SizedBox(width: 1.6),
          _sortIcon(column),
        ]),
      ),
    );
  }

  Widget _difficultyChip(String diff) {
    final color = diff == 'Easy' ? Colors.green : diff == 'Average' ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Text(diff, style: TextStyle(fontSize: 9.6, color: color, fontFamily: 'Poppins', fontWeight: FontWeight.w600), textAlign: TextAlign.center),
    );
  }

  Widget _buildTableHeader() => Container(
    color: const Color(0xFFF8F9FA),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      SizedBox(
        width: 32,
        child: Checkbox(
          value: _allOnPageSelected ? true : (_someOnPageSelected ? null : false),
          tristate: true,
          activeColor: const Color(0xFF046EB8),
          onChanged: questionsData.isEmpty ? null : _toggleSelectAll,
        ),
      ),
      _headerCell('#', 'id', flex: 1),
      _headerCell('Question', 'question', flex: 5),
      _headerCell('Topic', 'topic', flex: 3),
      _headerCell('Category', 'category', flex: 2),
      _headerCell('Difficulty', 'difficulty', flex: 2),
      _headerCell('Status', 'status', flex: 2),
      const Expanded(flex: 2, child: Text('Actions', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10.4, fontFamily: 'Poppins'))),
    ]),
  );

  Widget _buildTableRow(Map<String, dynamic> q, int index) {
    final isActive = q['status'] as bool;
    final rowNum = (currentPage - 1) * itemsPerPage + index + 1;
    final id = q['id'].toString();
    final isSelected = selectedIds.contains(id);
    return InkWell(
      onTap: () => _showEditQuestionDialog(q),
      hoverColor: const Color(0xFF046EB8).withValues(alpha: 0.03),
      child: Container(
        color: isSelected ? const Color(0xFF046EB8).withValues(alpha: 0.04) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isSelected,
              activeColor: const Color(0xFF046EB8),
              onChanged: (v) => _toggleSelectOne(id, v),
            ),
          ),
          Expanded(flex: 1, child: Text('$rowNum', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.4, fontFamily: 'Poppins', color: Colors.black54))),
          Expanded(flex: 5, child: Text(q['question'].toString(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.4, fontFamily: 'Poppins'))),
          Expanded(flex: 3, child: Text(
              (q['topic'] as String?)?.isNotEmpty == true ? q['topic'].toString() : '—',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.4, fontFamily: 'Poppins',
                  color: (q['topic'] as String?)?.isNotEmpty == true ? Colors.black87 : Colors.grey.shade400))),
          Expanded(flex: 2, child: Text(q['category'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.4, fontFamily: 'Poppins'))),
          Expanded(flex: 2, child: Center(child: _difficultyChip(q['difficulty'].toString()))),
          Expanded(flex: 2, child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(isActive ? 'Active' : 'Inactive',
                style: TextStyle(fontSize: 9.6, color: isActive ? Colors.green : Colors.red, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ))),
          Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(
              icon: const Icon(Icons.edit_rounded, size: 14.4, color: Colors.orange),
              tooltip: 'Edit',
              onPressed: () => _showEditQuestionDialog(q),
              constraints: const BoxConstraints(), padding: const EdgeInsets.all(4.8),
            )),
            const SizedBox(width: 1.6),
            MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(
              icon: Icon(isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 14.4, color: isActive ? Colors.orange : Colors.green),
              tooltip: isActive ? 'Deactivate' : 'Restore',
              onPressed: () => _toggleStatus(q),
              constraints: const BoxConstraints(), padding: const EdgeInsets.all(4.8),
            )),
            const SizedBox(width: 1.6),
            MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(
              icon: const Icon(Icons.delete_forever_rounded, size: 14.4, color: Colors.red),
              tooltip: 'Delete Permanently',
              onPressed: () => _permanentDelete(q),
              constraints: const BoxConstraints(), padding: const EdgeInsets.all(4.8),
            )),
          ])),
        ]),
      ),
    );
  }

  Widget _buildPagination() {
    Widget pageBtn(int p) => GestureDetector(
      onTap: () => _loadQuestions(page: p),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 25.6, height: 25.6,
        decoration: BoxDecoration(
          color: p == currentPage ? const Color(0xFF046EB8) : Colors.transparent,
          borderRadius: BorderRadius.circular(6.4),
          border: Border.all(color: p == currentPage ? const Color(0xFF046EB8) : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text('$p', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4,
          color: p == currentPage ? Colors.white : Colors.black87,
          fontWeight: p == currentPage ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );

    List<Widget> pages = [];
    for (int p = 1; p <= totalPages; p++) {
      if (p == 1 || p == totalPages || (p >= currentPage - 1 && p <= currentPage + 1)) {
        pages.add(pageBtn(p));
      } else if (p == currentPage - 2 || p == currentPage + 2) {
        pages.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('…', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey))));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        Text('Page $currentPage of $totalPages', style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontSize: 10.4)),
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            onPressed: currentPage > 1 ? () => _loadQuestions(page: currentPage - 1) : null,
            icon: Icon(Icons.chevron_left, color: currentPage > 1 ? Colors.black87 : Colors.grey.shade300),
            splashRadius: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          ...pages,
          IconButton(
            onPressed: currentPage < totalPages ? () => _loadQuestions(page: currentPage + 1) : null,
            icon: Icon(Icons.chevron_right, color: currentPage < totalPages ? Colors.black87 : Colors.grey.shade300),
            splashRadius: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ])),
        Row(children: [
          const Text('Show:', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontSize: 10.4)),
          const SizedBox(width: 6.4),
          Container(
            height: 25.6,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6.4)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: itemsPerPage,
                icon: const Icon(Icons.keyboard_arrow_down, size: 12.8),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.black87),
                isDense: true,
                items: [10, 25, 50, 100].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                onChanged: (n) { if (n == null) return; setState(() { itemsPerPage = n; currentPage = 1; }); _loadQuestions(); },
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedCategoryFilter != null || selectedDifficultyFilter != null;

    return Container(
      color: const Color(0xFF94D2FD),
      padding: const EdgeInsets.all(19.2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6.4, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          // ── Top header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(children: [
              const Icon(Icons.quiz_outlined, size: 22.4),
              const SizedBox(width: 9.6),
              const Text('Quiz Questions', style: TextStyle(fontSize: 19.2, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF046EB8).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9.6)),
                child: Text('$totalItems total', style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.6, color: Color(0xFF046EB8))),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download_rounded, size: 14.4),
                label: const Text('Export CSV', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showImportDialog,
                icon: const Icon(Icons.upload_file, size: 14.4),
                label: const Text('Import CSV', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddQuestionDialog,
                icon: const Icon(Icons.add, size: 14.4),
                label: const Text('Add Question', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046EB8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 6.4),
              IconButton(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh, size: 16),
                style: IconButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: const CircleBorder()),
                tooltip: 'Refresh',
              ),
            ]),
          ),

          // ── Search + Filters ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(children: [
              // Search
              Expanded(child: Container(
                height: 33.6,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.search, color: Color(0xFF858585), size: 16),
                  const SizedBox(width: 6.4),
                  Expanded(child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    decoration: const InputDecoration(
                      hintText: 'Search questions...', hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                      border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true,
                    ),
                    onChanged: _onSearch,
                  )),
                  if (searchQuery.isNotEmpty)
                    IconButton(icon: const Icon(Icons.clear, size: 14.4, color: Color(0xFF858585)),
                        onPressed: () { searchController.clear(); _onSearch(''); }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ]),
              )),
              const SizedBox(width: 8),
              _filterDrop('Category', selectedCategoryFilter, _categories,
                      (v) { setState(() { selectedCategoryFilter = v; }); _applyFilter(); }),
              const SizedBox(width: 6.4),
              _filterDrop('Difficulty', selectedDifficultyFilter, _difficulties,
                      (v) { setState(() { selectedDifficultyFilter = v; }); _applyFilter(); }),
              const SizedBox(width: 6.4),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() { includeInactive = !includeInactive; currentPage = 1; });
                    _loadQuestions();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: includeInactive ? const Color(0xFFFDD000).withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: includeInactive ? const Color(0xFFFDD000) : Colors.grey.shade300),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(includeInactive ? Icons.visibility : Icons.visibility_off,
                          size: 14.4, color: includeInactive ? const Color(0xFF816A03) : Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text('Show deactivated',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4,
                              color: includeInactive ? const Color(0xFF816A03) : Colors.grey.shade600)),
                    ]),
                  ),
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 6.4),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 12),
                  label: const Text('Clear', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                ),
              ],
            ]),
          ),

          // ── Bulk selection bar ──
          if (selectedIds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: const Color(0xFF046EB8).withValues(alpha: 0.06),
              child: Row(children: [
                Text('${selectedIds.length} selected',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF046EB8))),
                const SizedBox(width: 14),
                TextButton(
                  onPressed: () => setState(() => selectedIds.clear()),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: Text('Clear', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.8, color: Colors.grey.shade600)),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _bulkAction('restore'),
                  icon: const Icon(Icons.visibility, size: 17, color: Colors.green),
                  label: const Text('Restore', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.8, fontWeight: FontWeight.w600, color: Colors.green)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
                TextButton.icon(
                  onPressed: () => _bulkAction('deactivate'),
                  icon: const Icon(Icons.visibility_off, size: 17, color: Colors.orange),
                  label: const Text('Deactivate', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.8, fontWeight: FontWeight.w600, color: Colors.orange)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
                TextButton.icon(
                  onPressed: () => _bulkAction('delete'),
                  icon: const Icon(Icons.delete_forever, size: 17, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.8, fontWeight: FontWeight.w600, color: Colors.red)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
              ]),
            ),

          // ── Table ──
          Expanded(child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF046EB8)))
              : questionsData.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_off, size: 51.2, color: Colors.grey.shade300),
            const SizedBox(height: 9.6),
            Text(hasFilters || searchQuery.isNotEmpty ? 'No questions match your filters.' : 'No questions yet.',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500, fontSize: 12)),
            if (hasFilters || searchQuery.isNotEmpty) ...[
              const SizedBox(height: 6.4),
              TextButton(onPressed: _clearFilters, child: const Text('Clear filters', style: TextStyle(fontFamily: 'Poppins'))),
            ],
          ]))
              : Column(children: [
            _buildTableHeader(),
            const Divider(height: 0.8, color: Color(0xFFEEEEEE)),
            Expanded(child: ListView.separated(
              itemCount: questionsData.length,
              separatorBuilder: (context, index) => Divider(height: 0.8, color: Colors.grey.shade100),
              itemBuilder: (context, i) => _buildTableRow(questionsData[i], i),
            )),
            _buildPagination(),
          ]),
          ),
        ]),
      ),
    );
  }
}