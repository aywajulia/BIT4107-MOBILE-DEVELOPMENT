/// profile_screen.dart
/// Location: lib/screens/profile_screen.dart
///
/// The Profile screen (5th / final screen) for Shredded Squad.
///
/// Features:
///   • View & update profile picture (image_picker)
///   • Edit personal details: name, email
///   • Edit physical metrics: height, weight, target weight
///   • Select activity level: Beginner / Intermediate / Advanced
///   • Save changes with validation
///   • Log out button → returns to login screen
///
/// Dependencies to add in pubspec.yaml:
///   image_picker: ^1.0.7
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ─── Activity Level Enum ──────────────────────────────────────────────────────

enum ActivityLevel { beginner, intermediate, advanced }

extension ActivityLevelLabel on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.beginner:
        return 'Beginner';
      case ActivityLevel.intermediate:
        return 'Intermediate';
      case ActivityLevel.advanced:
        return 'Advanced';
    }
  }
}

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ─── Form key ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ─── Controllers ──────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController(text: 'Username');
  final _emailCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  // ─── State ────────────────────────────────────────────────────────────────
  ActivityLevel _activityLevel = ActivityLevel.beginner;
  File? _profileImage;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  // ─── Pick profile picture ─────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Update Profile Photo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
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
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _profileImage = null);
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
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _profileImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ─── Save profile ─────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // TODO: persist with shared_preferences or your backend
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ─── Log out ──────────────────────────────────────────────────────────────

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
            onPressed: () {
              Navigator.pop(context);
              // TODO: clear auth tokens here
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                    (route) => false,
              );
            },
            child: const Text('Log out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFAAAAAA),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile picture + username ───────────────────
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showImageSourceSheet,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor:
                                    const Color(0xFF1A1A1A),
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                    child: _profileImage == null
                                        ? const Icon(Icons.person,
                                        size: 64, color: Colors.white)
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
                                          size: 17,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _nameCtrl.text.isEmpty
                                  ? 'Username'
                                  : _nameCtrl.text,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Edit / Save toggle ───────────────────────────
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

                      // ── Personal Details ─────────────────────────────
                      _sectionTitle('Personal details'),
                      const SizedBox(height: 12),

                      _profileField(
                        label: 'Name',
                        controller: _nameCtrl,
                        enabled: _isEditing,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name is required'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      _profileField(
                        label: 'Email',
                        controller: _emailCtrl,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      // ── Physical Metrics ─────────────────────────────
                      _sectionTitle('Physical metrics'),
                      const SizedBox(height: 12),

                      _profileField(
                        label: 'Height',
                        controller: _heightCtrl,
                        enabled: _isEditing,
                        hint: 'e.g. 175 cm',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'))
                        ],
                      ),
                      const SizedBox(height: 12),

                      _profileField(
                        label: 'Weight',
                        controller: _weightCtrl,
                        enabled: _isEditing,
                        hint: 'e.g. 70 kg',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'))
                        ],
                      ),
                      const SizedBox(height: 12),

                      _profileField(
                        label: 'Target weight',
                        controller: _targetWeightCtrl,
                        enabled: _isEditing,
                        hint: 'e.g. 65 kg',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'))
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Activity Level ───────────────────────────────
                      _sectionTitle('Activity level:'),
                      const SizedBox(height: 8),

                      // Activity level radio buttons
                      _buildActivityLevelSelector(),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),

            // ── Log out button pinned at bottom ───────────────────────
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Activity Level Selector ──────────────────────────────────────────────

  /// Builds the three radio options for Beginner / Intermediate / Advanced.
  /// Uses Radio widget directly to avoid the deprecated RadioListTile params.
  Widget _buildActivityLevelSelector() {
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
                // Radio circle
                // Custom radio circle — avoids deprecated Radio widget params
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1A1A1A),
                      width: 2,
                    ),
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
                const SizedBox(width: 4),
                // Label
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

  // ─── Reusable widgets ─────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _profileField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? const Color(0xFF1A1A1A) : Colors.black54,
            ),
            decoration: InputDecoration(
              hintText: enabled ? hint : null,
              hintStyle:
              const TextStyle(color: Colors.black38, fontSize: 13),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black54, width: 1),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
              disabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26, width: 1),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide:
                BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              errorStyle: const TextStyle(
                  color: Colors.redAccent, fontSize: 11),
              contentPadding: const EdgeInsets.only(bottom: 4),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}