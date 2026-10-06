import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

// ── Shared selection widgets (same as players page) ──────────────────────────

class _AdminSelectionItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _AdminSelectionItem({required this.label, required this.isSelected, required this.onTap});
  @override State<_AdminSelectionItem> createState() => _AdminSelectionItemState();
}
class _AdminSelectionItemState extends State<_AdminSelectionItem> {
  bool _hovered = false;
  @override Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFFFDD000) : _hovered ? const Color(0xFFFDD000).withValues(alpha: 0.4) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(9.6),
            border: Border.all(color: widget.isSelected ? const Color(0xFFFDD000) : Colors.transparent, width: 1.6),
          ),
          child: Center(child: Text(widget.label, style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w600, fontFamily: 'Poppins'))),
        ),
      ),
    );
  }
}

class _AdminAvatarItem extends StatefulWidget {
  final String avatarPath, avatarName;
  final bool isSelected;
  final VoidCallback onTap;
  const _AdminAvatarItem({required this.avatarPath, required this.avatarName, required this.isSelected, required this.onTap});
  @override State<_AdminAvatarItem> createState() => _AdminAvatarItemState();
}
class _AdminAvatarItemState extends State<_AdminAvatarItem> {
  bool _hovered = false;
  @override Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFFFDD000) : _hovered ? const Color(0xFFFDD000).withValues(alpha: 0.4) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(9.6),
            border: Border.all(color: widget.isSelected ? const Color(0xFFFDD000) : Colors.transparent, width: 1.6),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(widget.avatarPath, width: 40, height: 40, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 32, color: Color(0xFF046EB8))),
            const SizedBox(height: 3.2),
            Text(widget.avatarName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500, fontFamily: 'Poppins'), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class AdminUsersAdminsPage extends StatefulWidget {
  final String? currentAdminId;
  const AdminUsersAdminsPage({super.key, this.currentAdminId});

  @override
  State<AdminUsersAdminsPage> createState() => _AdminUsersAdminsPageState();
}

class _AdminUsersAdminsPageState extends State<AdminUsersAdminsPage> {
  final TextEditingController searchController = TextEditingController();
  final ApiService _api = ApiService();

  static const List<String> _avatarPaths = [
    "assets/images-avatars/Adventurer.png", "assets/images-avatars/Astronaut.png",
    "assets/images-avatars/Boy.png",        "assets/images-avatars/Brainy.png",
    "assets/images-avatars/Cool-Monkey.png","assets/images-avatars/Cute-Elephant.png",
    "assets/images-avatars/Doctor-Boy.png", "assets/images-avatars/Doctor-Girl.png",
    "assets/images-avatars/Engineer-Boy.png","assets/images-avatars/Engineer-Girl.png",
    "assets/images-avatars/Girl.png",       "assets/images-avatars/Hacker.png",
    "assets/images-avatars/Leonel.png",     "assets/images-avatars/Scientist-Boy.png",
    "assets/images-avatars/Scientist-Girl.png","assets/images-avatars/Sly-Fox.png",
    "assets/images-avatars/Sneaky-Snake.png","assets/images-avatars/Teacher-Boy.png",
    "assets/images-avatars/Teacher-Girl.png","assets/images-avatars/Twirky.png",
    "assets/images-avatars/Whiz-Achiever.png","assets/images-avatars/Whiz-Busy.png",
    "assets/images-avatars/Whiz-Happy.png", "assets/images-avatars/Whiz-Ready.png",
    "assets/images-avatars/Wise-Turtle.png",
  ];
  static List<String> get _avatarNames => _avatarPaths
      .map((p) => p.split('/').last.replaceAll('.png', '').replaceAll('-', ' ')).toList();

  void _showAvatarPicker(BuildContext ctx, String? current, void Function(String) onPicked) {
    showDialog(context: ctx, builder: (dCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
      child: Container(width: 400, padding: const EdgeInsets.all(19.2),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.8)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Choose Avatar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF046EB8), fontFamily: 'Poppins')),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dCtx)),
          ]),
          const SizedBox(height: 12.8),
          SizedBox(height: 304, child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
            itemCount: _avatarPaths.length,
            itemBuilder: (_, i) => _AdminAvatarItem(
              avatarPath: _avatarPaths[i], avatarName: _avatarNames[i],
              isSelected: current == _avatarPaths[i],
              onTap: () { onPicked(_avatarPaths[i]); Navigator.pop(dCtx); },
            ),
          )),
        ]),
      ),
    ));
  }

  void _showSexPicker(BuildContext ctx, String? current, void Function(String) onPicked) {
    showDialog(context: ctx, builder: (dCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
      child: Container(width: 288, padding: const EdgeInsets.all(19.2),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.8)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Select Sex", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF046EB8), fontFamily: 'Poppins')),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dCtx)),
          ]),
          const SizedBox(height: 12.8),
          ...['Male', 'Female', 'Prefer Not to Say'].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AdminSelectionItem(label: s, isSelected: current == s, onTap: () { onPicked(s); Navigator.pop(dCtx); }),
          )),
        ]),
      ),
    ));
  }

  String searchQuery = '';
  List<Map<String, dynamic>> adminsData = [];
  bool isLoading = false;
  String? errorMessage;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // ── Debounced search: wait for the admin to stop typing before hitting
  // the API, instead of firing a request on every keystroke.
  void _onSearchChanged(String v) {
    setState(() => searchQuery = v);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadAdmins);
  }

  // ─── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadAdmins() async {
    setState(() { isLoading = true; errorMessage = null; });
    final result = await _api.getAdmins(search: searchQuery.isEmpty ? null : searchQuery);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        adminsData = List<Map<String, dynamic>>.from(result['admins'] ?? []);
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Failed to load admins.';
        isLoading = false;
      });
    }
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

  // ─── Input decoration helper ────────────────────────────────────────────────

  InputDecoration _inputDec(String label, {IconData? prefixIcon, Widget? suffix}) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.grey));
    final focusBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF046EB8), width: 1.6));
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.black54, size: 16) : null,
      suffixIcon: suffix,
      border: border, enabledBorder: border, focusedBorder: focusBorder,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  // ─── Image file picker helper ────────────────────────────────────────────────

  /// Returns a map with a 'status' key so callers can show the *exact*
  /// failure reason on screen (as a SnackBar) instead of only in the
  /// browser console — console screenshots weren't making it through, so
  /// this makes the diagnosis visible directly in the app.
  /// status: 'ok' | 'cancelled' | 'no_bytes' | 'error'
  /// Shows the exact pick result as a SnackBar so it's visible on screen
  /// (not just console) — makes it easy to report back what actually
  /// happened when tapping "Upload Photo".
  void _showPickResultSnack(Map<String, dynamic> picked) {
    switch (picked['status']) {
      case 'ok':
        _snack('Picked "${picked['name']}" (${picked['size']} bytes)', const Color(0xFF27AE60));
        break;
      case 'cancelled':
        _snack('No file was selected (picker closed with nothing chosen).', Colors.orange);
        break;
      case 'no_bytes':
        _snack('Picked "${picked['name']}" but the browser returned no file data — the file_picker web plugin isn\'t working.', Colors.red);
        break;
      case 'error':
        _snack('File picker error: ${picked['error']}', Colors.red);
        break;
    }
  }

  Future<Map<String, dynamic>> _pickImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        debugPrint('FilePicker: user cancelled or no file returned');
        return {'status': 'cancelled'};
      }
      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) {
        // On web this means the browser/file_picker didn't hand back bytes —
        // usually a missing/broken web plugin registration.
        debugPrint('FilePicker: no bytes returned for ${file.name} (kIsWeb=$kIsWeb)');
        return {'status': 'no_bytes', 'name': file.name};
      }
      // file.path is unsupported on web — merely reading the getter throws
      // there, so only include it on non-web platforms.
      return {'status': 'ok', 'bytes': bytes, 'path': kIsWeb ? null : file.path, 'name': file.name, 'size': bytes.length};
    } catch (e) {
      debugPrint('FilePicker error: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  Widget _buildImageCircle({
    Uint8List? imageBytes,
    String? imagePath,
    bool hasError = false,
    double radius = 52,
  }) {
    ImageProvider? provider;
    if (imageBytes != null) {
      provider = MemoryImage(imageBytes);
    } else if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        // Already a full URL
        provider = NetworkImage(imagePath);
      } else if (imagePath.startsWith('uploads/') || imagePath.startsWith('/uploads/')) {
        // ── FIX: route through /api/uploads/ so CORS headers are applied ──────
        final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
        provider = NetworkImage('${ApiService.baseUrl}/$cleanPath');
      } else if (!kIsWeb) {
        // Local file path on mobile
        provider = FileImage(File(imagePath));
      }
    }

    return CircleAvatar(
      radius: radius + 3,
      backgroundColor: hasError ? Colors.red : const Color(0xFFFDD000),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: provider,
        child: provider == null
            ? ClipOval(child: Image.asset(
                'assets/images-badges/whiz-happy.png',
                width: radius * 2, height: radius * 2, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.person, size: radius * 0.9, color: Colors.grey),
              ))
            : null,
      ),
    );
  }

  // ─── Add Admin dialog ───────────────────────────────────────────────────────

  void _showAddAdminDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmCtrl  = TextEditingController();
    String? selectedSex;
    Uint8List? imageBytes;
    String?    imagePath;
    String?    imageName;
    bool imageErr     = false;
    bool showPassword = false;
    bool showConfirm  = false;
    bool saving       = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
        child: Container(
          width: 448,
          padding: const EdgeInsets.all(19.2),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.person_add, size: 19.2), SizedBox(width: 9.6),
              Text('Add New Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            ]),
            const SizedBox(height: 19.2),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Real image picker ──
              Column(children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await _pickImageFile();
                      _showPickResultSnack(picked);
                      if (picked['status'] == 'ok') {
                        setDS(() {
                          imageBytes = picked['bytes'] as Uint8List?;
                          imagePath  = picked['path'] as String?;
                          imageName  = picked['name'] as String?;
                          imageErr   = false;
                        });
                      }
                    },
                    child: _buildImageCircle(
                      imageBytes: imageBytes,
                      imagePath: imagePath,
                      hasError: imageErr,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await _pickImageFile();
                    _showPickResultSnack(picked);
                    if (picked['status'] == 'ok') {
                      setDS(() {
                        imageBytes = picked['bytes'] as Uint8List?;
                        imagePath  = picked['path'] as String?;
                        imageName  = picked['name'] as String?;
                        imageErr   = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload, size: 11.2),
                  label: const Text("Upload Photo", style: TextStyle(fontSize: 8.8, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000), foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
                ),
                if (imageName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3.2),
                    child: SizedBox(
                      width: 88,
                      child: Text(imageName!, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 7.2, color: Colors.black54, fontFamily: 'Poppins'),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                if (imageErr)
                  const Padding(padding: EdgeInsets.only(top: 3.2),
                      child: Text('Photo required', style: TextStyle(color: Colors.red, fontSize: 8, fontFamily: 'Poppins'))),
              ]),
              const SizedBox(width: 16),
              // ── Fields ──
              Expanded(child: Column(children: [
                // Username + Sex on the same row, same height
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(flex: 2, child: TextField(
                      controller: usernameCtrl,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                      decoration: _inputDec('Username', prefixIcon: Icons.person),
                    )),
                    const SizedBox(width: 9.6),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: selectedSex,
                      hint: const Text('Sex', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.black38)),
                      decoration: _inputDec(''),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.black),
                      items: ['Male', 'Female', 'Prefer not to say']
                          .map((s) => DropdownMenuItem(value: s,
                          child: Text(s, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4))))
                          .toList(),
                      onChanged: (v) => setDS(() => selectedSex = v),
                      isExpanded: true,
                    )),
                  ]),
                ),
                const SizedBox(height: 11.2),
                TextField(controller: passwordCtrl, obscureText: !showPassword,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    decoration: _inputDec('Password', prefixIcon: Icons.lock, suffix: IconButton(
                        icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.black54),
                        onPressed: () => setDS(() => showPassword = !showPassword)))),
                const SizedBox(height: 11.2),
                TextField(controller: confirmCtrl, obscureText: !showConfirm,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    decoration: _inputDec('Confirm Password', prefixIcon: Icons.lock, suffix: IconButton(
                        icon: Icon(showConfirm ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.black54),
                        onPressed: () => setDS(() => showConfirm = !showConfirm)))),
              ])),
            ]),
            const SizedBox(height: 19.2),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: Colors.grey.shade400)),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black, fontFamily: 'Poppins'))),
              ElevatedButton(
                  onPressed: saving ? null : () async {
                    final username = usernameCtrl.text.trim();
                    final password = passwordCtrl.text;
                    bool err = false;
                    if (username.isEmpty || username.length < 3) { _snack('Username must be at least 3 characters.', Colors.red); err = true; }
                    if (selectedSex == null) { _snack('Please select a sex.', Colors.red); err = true; }
                    final pwErr = _adminPasswordError(password);
                    if (pwErr != null) { _snack(pwErr, Colors.red); err = true; }
                    if (password != confirmCtrl.text) { _snack('Passwords do not match.', Colors.red); err = true; }
                    if (err) return;
                    setDS(() => saving = true);
                    final result = await _api.addAdmin(
                      username: username,
                      password: password,
                      sex: selectedSex,
                      imageBytes: imageBytes,
                    );
                    if (!mounted) return;
                    setDS(() => saving = false);
                    if (result['success'] == true) {
                      Navigator.pop(ctx);
                      _snack('Admin "$username" added successfully!', const Color(0xFF27AE60));
                      _loadAdmins();
                    } else {
                      _snack(result['message'] ?? 'Failed to add admin.', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000), foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.6, color: Color(0xFF816A03)))
                      : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
            ]),
          ]),
        ),
      )),
    );
  }

  // ─── Edit Admin dialog ──────────────────────────────────────────────────────

  void _showEditAdminDialog(Map<String, dynamic> admin) {
    final usernameCtrl = TextEditingController(text: admin['username']);
    String? selectedSex    = ((admin['sex'] ?? '').toString().isEmpty) ? null : admin['sex'].toString();
    String? existingImage  = admin['image'];   // real photo URL/path from server
    Uint8List? newImageBytes;
    String?    newImagePath;
    String?    newImageName;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
        child: Container(
          width: 336,
          padding: const EdgeInsets.all(19.2),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.edit, size: 16), SizedBox(width: 6.4),
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
                      _showPickResultSnack(picked);
                      if (picked['status'] == 'ok') {
                        setDS(() {
                          newImageBytes = picked['bytes'] as Uint8List?;
                          newImagePath  = picked['path'] as String?;
                          newImageName  = picked['name'] as String?;
                        });
                      }
                    },
                    child: _buildImageCircle(
                      imageBytes: newImageBytes,
                      imagePath: newImageBytes == null ? existingImage : null,
                      radius: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 6.4),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await _pickImageFile();
                    _showPickResultSnack(picked);
                    if (picked['status'] == 'ok') {
                      setDS(() {
                        newImageBytes = picked['bytes'] as Uint8List?;
                        newImagePath  = picked['path'] as String?;
                        newImageName  = picked['name'] as String?;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload, size: 9.6),
                  label: const Text("Upload Photo", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000), foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 1),
                ),
                if (newImageName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3.2),
                    child: SizedBox(width: 80,
                      child: Text(newImageName!, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 7.2, color: Colors.black54, fontFamily: 'Poppins'),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
              ]),
              const SizedBox(width: 12.8),
              Expanded(child: Column(children: [
                TextField(controller: usernameCtrl,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.2),
                    decoration: _inputDec('Username', prefixIcon: Icons.person)),
                const SizedBox(height: 9.6),
                DropdownButtonFormField<String>(
                  value: selectedSex,
                  hint: const Text('Sex', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.black38)),
                  decoration: _inputDec(''),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4, color: Colors.black),
                  isExpanded: true,
                  items: ['Male', 'Female', 'Prefer not to say']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10.4)))).toList(),
                  onChanged: (v) => setDS(() => selectedSex = v),
                ),
              ])),
            ]),
            const SizedBox(height: 19.2),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Colors.black54)),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 10.4))),
              ElevatedButton(
                  onPressed: saving ? null : () async {
                    final newUsername = usernameCtrl.text.trim();
                    if (newUsername.isEmpty) { _snack('Username cannot be empty.', Colors.red); return; }
                    if (selectedSex == null) { _snack('Please select a sex.', Colors.red); return; }
                    setDS(() => saving = true);
                    final result = await _api.updateAdmin(admin['id'].toString(), {
                      'username': newUsername,
                      'sex': selectedSex!,
                    }, imageBytes: newImageBytes);
                    if (!mounted) return;
                    setDS(() => saving = false);
                    if (result['success'] == true) {
                      Navigator.pop(ctx);
                      _snack('Admin updated successfully!', const Color(0xFF27AE60));
                      _loadAdmins();
                    } else {
                      _snack(result['message'] ?? 'Failed to update.', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD000), foregroundColor: const Color(0xFF816A03),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: saving
                      ? const SizedBox(width: 14.4, height: 14.4, child: CircularProgressIndicator(strokeWidth: 1.6, color: Color(0xFF816A03)))
                      : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 10.4))),
            ]),
          ]),
        ),
      )),
    );
  }

  // ─── Change Password dialog ─────────────────────────────────────────────────

  void _showChangeAdminPasswordDialog(Map<String, dynamic> admin) {
    final oldPwCtrl  = TextEditingController();
    final newPwCtrl  = TextEditingController();
    final confPwCtrl = TextEditingController();
    bool showOld = false, showNew = false, showConf = false, saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(19.2),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.key, size: 16), SizedBox(width: 6.4),
              Text('Change Password', style: TextStyle(fontSize: 12.8, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            ]),
            const SizedBox(height: 16),
            TextField(controller: oldPwCtrl, obscureText: !showOld,
                decoration: _inputDec('Current Password', prefixIcon: Icons.lock, suffix: IconButton(
                    icon: Icon(showOld ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.black54),
                    onPressed: () => setDS(() => showOld = !showOld)))),
            const SizedBox(height: 9.6),
            TextField(controller: newPwCtrl, obscureText: !showNew,
                decoration: _inputDec('New Password', prefixIcon: Icons.lock, suffix: IconButton(
                    icon: Icon(showNew ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.black54),
                    onPressed: () => setDS(() => showNew = !showNew)))),
            const SizedBox(height: 9.6),
            TextField(controller: confPwCtrl, obscureText: !showConf,
                decoration: _inputDec('Confirm New Password', prefixIcon: Icons.lock, suffix: IconButton(
                    icon: Icon(showConf ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.black54),
                    onPressed: () => setDS(() => showConf = !showConf)))),
            const SizedBox(height: 19.2),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Colors.black54)),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 10.4))),
              ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (oldPwCtrl.text.isEmpty || newPwCtrl.text.isEmpty) { _snack('Please fill all fields.', Colors.red); return; }
                    if (newPwCtrl.text != confPwCtrl.text) { _snack('New passwords do not match.', Colors.red); return; }
                    final pwErr = _adminPasswordError(newPwCtrl.text);
                    if (pwErr != null) { _snack(pwErr, Colors.red); return; }
                    setDS(() => saving = true);
                    final result = await _api.changeAdminPassword(admin['id'].toString(),
                        oldPassword: oldPwCtrl.text, newPassword: newPwCtrl.text);
                    if (!mounted) return;
                    setDS(() => saving = false);
                    if (result['success'] == true) {
                      Navigator.pop(ctx);
                      _snack('Password changed successfully!', const Color(0xFF27AE60));
                    } else {
                      _snack(result['message'] ?? 'Failed to change password.', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046EB8), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: saving
                      ? const SizedBox(width: 14.4, height: 14.4, child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white))
                      : const Text('CHANGE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 10.4))),
            ]),
          ]),
        ),
      )),
    );
  }

  // ─── Delete Admin dialog ────────────────────────────────────────────────────

  void _showDeleteAdminDialog(Map<String, dynamic> admin) {
    if (_isSuperadmin(admin)) {
      _snack('The superadmin account cannot be deleted.', Colors.red);
      return;
    }
    bool deleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.8)),
        child: Container(
          width: 304,
          padding: const EdgeInsets.all(25.6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 51.2, height: 51.2,
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever, size: 25.6, color: Colors.red)),
            const SizedBox(height: 12.8),
            const Text('Are you sure you want to\ndelete this account?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.4, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 9.6),
            Text('Admin "${admin['username']}" will be permanently removed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.2, fontFamily: 'Poppins', color: Colors.grey.shade700)),
            const SizedBox(height: 25.6),
            // ✅ FIX: buttons had no Expanded/Flexible wrapper, so their
            // fixed 32px horizontal padding + "Delete this account" text
            // overflowed this dialog's fixed 304px width. Wrapped in
            // Expanded (same pattern the Delete Player dialog already uses
            // correctly) so both buttons share the available width instead.
            Row(children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(color: Colors.grey.shade400)),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black, fontFamily: 'Poppins'))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                    onPressed: deleting ? null : () async {
                      setDS(() => deleting = true);
                      final result = await _api.deleteAdmin(admin['id'].toString());
                      if (!ctx.mounted) { setDS(() => deleting = false); return; }
                      setDS(() => deleting = false);
                      if (result['success'] == true) {
                        Navigator.pop(ctx);
                        // Immediately remove from local list so UI updates right away
                        if (mounted) {
                          setState(() {
                            adminsData.removeWhere((a) => a['id'].toString() == admin['id'].toString());
                          });
                        }
                        _snack('Admin "${admin['username']}" deleted.', Colors.red);
                        // Then refresh from backend to confirm
                        _loadAdmins();
                      } else {
                        _snack(result['message'] ?? 'Failed to delete.', Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                    child: deleting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white))
                        : const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
              ),
            ]),
          ]),
        ),
      )),
    );
  }

  // ─── UI helpers ─────────────────────────────────────────────────────────────

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
      child: IconButton(
        icon: Icon(icon, color: color, size: 12.8),
        onPressed: onPressed, tooltip: tooltip,
        padding: const EdgeInsets.all(4.8),
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      ),
    );
  }

  // The built-in superadmin account — never deletable from the UI, backed
  // up by the same check server-side in AdminController::deleteAdmin.
  static const _superadminUsername = 'starbooks_admin';

  bool _isSuperadmin(Map<String, dynamic> admin) =>
      (admin['username'] ?? '').toString().toLowerCase() == _superadminUsername;

  Widget _buildDeleteButton(Map<String, dynamic> admin) {
    final isSelf = widget.currentAdminId != null &&
        admin['id'].toString() == widget.currentAdminId.toString();
    final isOnlyAdmin = adminsData.length <= 1;
    final isSuperadmin = _isSuperadmin(admin);
    final isDisabled = isSelf || isOnlyAdmin || isSuperadmin;

    final tooltip = isSuperadmin
        ? 'The superadmin account cannot be deleted'
        : isSelf
        ? 'Cannot delete your own account'
        : isOnlyAdmin
        ? 'Cannot delete — at least one admin must remain'
        : 'Delete Admin';

    return Tooltip(
      message: isDisabled ? tooltip : '',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDisabled
              ? Colors.grey.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
        ),
        child: IconButton(
          icon: Icon(Icons.delete,
              color: isDisabled ? Colors.grey.shade400 : Colors.red, size: 12.8),
          onPressed: isDisabled ? null : () => _showDeleteAdminDialog(admin),
          padding: const EdgeInsets.all(4.8),
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        ),
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    final String? realImage  = admin['image'];   // real photo (URL or server path)
    final String? avatarPath = admin['avatar'];  // asset fallback

    Widget photoWidget;
    if (realImage != null && realImage.isNotEmpty) {
      final imageUrl = (realImage.startsWith('http://') || realImage.startsWith('https://'))
          ? realImage
          : '${ApiService.baseUrl}/$realImage';  // goes through /api/uploads/...
      photoWidget = ClipOval(child: Image.network(
        imageUrl, width: 57.6, height: 57.6, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28.8, color: Color(0xFF046EB8)),
      ));
    } else if (avatarPath != null && avatarPath.isNotEmpty) {
      photoWidget = ClipOval(child: Image.asset(
        avatarPath, width: 57.6, height: 57.6, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28.8, color: Color(0xFF046EB8)),
      ));
    } else {
      photoWidget = ClipOval(child: Image.asset(
        'assets/images-badges/whiz-happy.png', width: 57.6, height: 57.6, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 28.8, color: Color(0xFF046EB8)),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(9.6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4.8, offset: const Offset(0, 2))],
        border: Border.all(color: const Color(0xFF046EB8), width: 1.6),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 57.6, height: 57.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF046EB8), width: 1.6),
            color: Colors.grey.shade50,
          ),
          clipBehavior: Clip.hardEdge,
          child: photoWidget,
        ),
        const SizedBox(height: 4.8),
        Text(admin['username'] ?? '',
            style: const TextStyle(fontSize: 9.6, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        if ((admin['sex'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 1.6),
          Text(admin['sex'], style: TextStyle(fontSize: 9.6, fontFamily: 'Poppins', color: Colors.grey.shade600)),
        ],
        const SizedBox(height: 4.8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildActionButton(Icons.edit, Colors.green, 'Edit Admin', () => _showEditAdminDialog(admin)),
          const SizedBox(width: 4.8),
          _buildActionButton(Icons.key, const Color(0xFF046EB8), 'Change Password', () => _showChangeAdminPasswordDialog(admin)),
          const SizedBox(width: 4.8),
          _buildDeleteButton(admin),
        ]),
      ]),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF94D2FD),
      padding: const EdgeInsets.all(19.2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6.4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(19.2),
        child: Column(children: [
          // Header
          Row(children: [
            const Icon(Icons.people, size: 22.4),
            const SizedBox(width: 9.6),
            const Text('List of Admins', style: TextStyle(fontSize: 19.2, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(width: 19.2),
            Expanded(child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Icon(Icons.search, color: Color(0xFF858585), size: 16),
                const SizedBox(width: 6.4),
                Expanded(child: TextField(
                  controller: searchController,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.8),
                  decoration: const InputDecoration(
                      hintText: 'Search admins...', hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12.8),
                      border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                  onChanged: _onSearchChanged,
                )),
                if (searchQuery.isNotEmpty)
                  IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Color(0xFF858585)),
                      onPressed: () { _searchDebounce?.cancel(); searchController.clear(); setState(() => searchQuery = ''); _loadAdmins(); },
                      padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
            )),
            const SizedBox(width: 12.8),
            ElevatedButton.icon(
              onPressed: _showAddAdminDialog,
              icon: const Icon(Icons.add, size: 14.4),
              label: const Text('ADD NEW ADMIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.4, fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046EB8), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2),
            ),
            const SizedBox(width: 6.4),
            IconButton(
                onPressed: _loadAdmins,
                icon: const Icon(Icons.refresh, size: 16),
                style: IconButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: const CircleBorder()),
                tooltip: 'Refresh'),
          ]),
          const SizedBox(height: 12.8),
          Expanded(child: _buildContent()),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF046EB8)));
    }
    if (errorMessage != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 51.2, color: Colors.red.shade300),
        const SizedBox(height: 12.8),
        Text(errorMessage!, style: const TextStyle(fontSize: 12.8, fontFamily: 'Poppins', color: Colors.red)),
        const SizedBox(height: 12.8),
        ElevatedButton(onPressed: _loadAdmins, child: const Text('Retry')),
      ]));
    }
    if (adminsData.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off, size: 51.2, color: Colors.grey[400]),
        const SizedBox(height: 12.8),
        Text('No admins found', style: TextStyle(fontSize: 14.4, color: Colors.grey[600], fontFamily: 'Poppins')),
      ]));
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9),
      itemCount: adminsData.length,
      itemBuilder: (context, index) => _buildAdminCard(adminsData[index]),
    );
  }
}


/// Admin password rules (mirrors AdminController::validatePasswordInput):
/// 8-12 characters, at least one lowercase, uppercase, number and special
/// character. Returns an error message, or null when valid.
String? _adminPasswordError(String pw) {
  if (pw.length < 8) return 'Password must be at least 8 characters.';
  if (pw.length > 12) return 'Password must not exceed 12 characters.';
  if (!RegExp(r'[a-z]').hasMatch(pw)) return 'Password must contain at least one lowercase letter.';
  if (!RegExp(r'[A-Z]').hasMatch(pw)) return 'Password must contain at least one uppercase letter.';
  if (!RegExp(r'\d').hasMatch(pw)) return 'Password must contain at least one number.';
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\/;~`+=]').hasMatch(pw)) {
    return 'Password must contain at least one special character.';
  }
  return null;
}