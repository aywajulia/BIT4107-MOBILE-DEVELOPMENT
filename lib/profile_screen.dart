/// profile_screen.dart
/// Profile screen – allows users to view, edit, and save their personal data.


library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'database_helper.dart';
import 'user_model.dart';


// ── Activity level enum ────────────────────────────────────────────────────────

enum ActivityLevel { beginner, intermediate, advanced }

extension ActivityLevelLabel on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.beginner:    return 'Beginner';
      case ActivityLevel.intermediate: return 'Intermediate';
      case ActivityLevel.advanced:    return 'Advanced';
    }
  }
}

// ── Profile Screen ─────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Form Controllers ──────────────────────────────────────────────────────
  final _formKey          = GlobalKey<FormState>();
  final _nameCtrl         = TextEditingController();
  final _emailCtrl        = TextEditingController();
  final _heightCtrl       = TextEditingController();
  final _weightCtrl       = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  // ── State Variables ───────────────────────────────────────────────────────
  ActivityLevel _activityLevel = ActivityLevel.beginner;
  String? _profileImagePath;        // local file path
  bool   _isEditing  = false;
  bool   _isSaving   = false;
  bool   _isLoading  = true;

  String? _currentUid;              // logged-in user UID

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  // ─── Load Profile from SQLite ────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get the current user's UID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentUid = prefs.getString('user_uid');
      debugPrint('Profile: loaded UID -> $_currentUid');

      if (_currentUid == null) {
        debugPrint('Profile: No user logged in');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Query the database for this user
      final db = DatabaseHelper();
      final userMap = await db.getUserByUid(_currentUid!);
      debugPrint('Profile: userMap = $userMap');

      if (userMap != null) {
        final user = User.fromMap(userMap);
        setState(() {
          _nameCtrl.text         = user.name;
          _emailCtrl.text        = user.email;
          _heightCtrl.text       = user.height ?? '';
          _weightCtrl.text       = user.weight ?? '';
          _targetWeightCtrl.text = ''; // not stored in this version
          _profileImagePath      = user.profileImage; // load saved path
        });
        debugPrint('Profile: loaded image path -> $_profileImagePath');
      } else {
        _showError('Profile not found.');
      }
    } catch (e) {
      _showError('Failed to load profile: $e');
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Save Profile to SQLite ──────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      if (_currentUid == null) throw Exception('No user logged in');

      final db = DatabaseHelper();

      // Build the updates map – includes the profileImage path
      final updates = {
        'name':          _nameCtrl.text.trim(),
        'email':         _emailCtrl.text.trim(),
        'height':        _heightCtrl.text.trim().isEmpty ? null : _heightCtrl.text.trim(),
        'weight':        _weightCtrl.text.trim().isEmpty ? null : _weightCtrl.text.trim(),
        'profileImage':  _profileImagePath,
      };
      debugPrint('Profile: saving updates -> $updates');

      await db.updateUser(_currentUid!, updates);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Failed to save: $e');
      }
      debugPrint('Profile save error: $e');
    }
  }

  // ─── Profile Picture Methods ─────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Update Profile Photo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white),
              title: const Text('Take a photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Colors.white),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    // Delete the file
                    final file = File(_profileImagePath!);
                    if (file.existsSync()) file.deleteSync();
                    _profileImagePath = null;
                    // Optionally auto-save after removal
                    if (_isEditing) {
                      _saveProfile();
                    }
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        // Save the image to the app's documents folder
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${_currentUid ?? 'user'}.jpg';
        final localFile = File(path.join(dir.path, fileName));
        await File(picked.path).copy(localFile.path);
        setState(() => _profileImagePath = localFile.path);
        debugPrint('Profile: image saved to $_profileImagePath');
        // If we are in edit mode, auto-save the profile
        if (_isEditing) {
          await _saveProfile();
        }
      }
    } catch (e) {
      debugPrint('Profile: image pick error $e');
      _showError('Could not pick image.');
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              // Clear SharedPreferences session
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_uid');
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              }
            },
            child: const Text('Log out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ));
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFAAAAAA)],
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar + username ─────────────────────
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showImageSourceSheet,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    backgroundImage: _profileImagePath != null
                                        ? FileImage(File(_profileImagePath!))
                                        : null,
                                    child: _profileImagePath == null
                                        ? const Icon(Icons.person, size: 64, color: Colors.white)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          size: 17, color: Color(0xFF1A1A1A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _nameCtrl.text.isEmpty
                                  ? 'Username'
                                  : _nameCtrl.text,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              'UID: ${_currentUid?.substring(0, 8) ?? ''}...',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black38),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Edit / Save toggle ────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _isEditing
                              ? _saveProfile
                              : () => setState(() => _isEditing = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              _isEditing ? 'Save' : 'Edit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Personal details ──────────────────────
                      _sectionTitle('Personal details'),
                      const SizedBox(height: 12),
                      _field(
                        label: 'Name',
                        ctrl: _nameCtrl,
                        enabled: _isEditing,
                        validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Name is required'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        label: 'Email',
                        ctrl: _emailCtrl,
                        enabled: _isEditing,
                        keyboard: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 24),

                      // ── Physical metrics ──────────────────────
                      _sectionTitle('Physical metrics'),
                      const SizedBox(height: 12),
                      _field(
                        label: 'Height (cm)',
                        ctrl: _heightCtrl,
                        enabled: _isEditing,
                        keyboard: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'))
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        label: 'Weight (kg)',
                        ctrl: _weightCtrl,
                        enabled: _isEditing,
                        keyboard: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'))
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        label: 'Target weight (kg)',
                        ctrl: _targetWeightCtrl,
                        enabled: _isEditing,
                        keyboard: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'))
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Activity level ────────────────────────
                      _sectionTitle('Activity level:'),
                      const SizedBox(height: 8),
                      _buildActivitySelector(),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),

            // ── Log out button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Log out',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Activity level radio selector ─────────────────────────────────────────

  Widget _buildActivitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ActivityLevel.values.map((level) {
        final isSelected = _activityLevel == level;
        return GestureDetector(
          onTap: _isEditing
              ? () => setState(() => _activityLevel = level)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF1A1A1A), width: 2),
                  ),
                  child: isSelected
                      ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  level.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: _isEditing
                        ? const Color(0xFF1A1A1A)
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A1A)),
  );

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required bool enabled,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
          ),
          Expanded(
            child: TextFormField(
              controller: ctrl,
              enabled: enabled,
              keyboardType: keyboard,
              inputFormatters: formatters,
              validator: validator,
              onChanged: onChanged,
              style: TextStyle(
                  fontSize: 14,
                  color: enabled
                      ? const Color(0xFF1A1A1A)
                      : Colors.black54),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                    borderSide:
                    BorderSide(color: Colors.black54, width: 1)),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                    BorderSide(color: Colors.black, width: 2)),
                disabledBorder: UnderlineInputBorder(
                    borderSide:
                    BorderSide(color: Colors.black26, width: 1)),
                errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.redAccent, width: 1.5)),
                errorStyle: TextStyle(
                    color: Colors.redAccent, fontSize: 11),
                contentPadding: EdgeInsets.only(bottom: 4),
                isDense: true,
              ),
            ),
          ),
        ],
      );
}