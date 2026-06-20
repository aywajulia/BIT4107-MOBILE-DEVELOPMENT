/// login_screen.dart
/// Location: lib/screens/login_screen.dart
///
/// Login screen – now uses SQLite for authentication.
///
/// Features:
///   • Login with email + password (stored in SQLite)
///   • Sign up with email + password (saved to SQLite)
///   • Friendly error messages for wrong password, no account, etc.
///   • Loading spinner while SQLite query is in progress
///   • Forgot password – simply shows a message (no email service)
///
/// 🗄️ All user data is stored locally in SQLite.

library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();

  bool _obscurePassword = true; // toggle show/hide password
  bool _isLoading       = false; // show spinner while SQLite query runs
  bool _isSignUpMode    = false; // toggle between Login and Sign Up

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Queries SQLite for the user with the given email.
  /// If found and password matches, login succeeds and session is saved.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;

      // 1. Query user by email
      final userMap = await db.getUserByEmail(email);

      if (userMap == null) {
        _showError('No account found for this email.');
        return;
      }

      // 2. Verify password (plain text comparison – for demo; use hashing in production)
      if (userMap['password'] != password) {
        _showError('Incorrect password. Please try again.');
        return;
      }

      // 3. Login successful – save session (UID) to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', userMap['uid']);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
      debugPrint('Login error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Sign up ────────────────────────────────────────────────────────────────

  /// Inserts a new user into SQLite.
  /// Generates a unique UID (using timestamp) and saves the user.
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;

      // 1. Check if email already exists
      final existing = await db.getUserByEmail(email);
      if (existing != null) {
        _showError('An account with this email already exists.');
        return;
      }

      // 2. Generate a unique UID (using timestamp)
      final uid = DateTime.now().millisecondsSinceEpoch.toString();

      // 3. Create a User object
      final newUser = User(
        uid: uid,
        name: email.split('@')[0], // default name from email
        email: email,
        password: password, // plain text – consider hashing in real app
        createdAt: DateTime.now().toIso8601String(),
      );

      // 4. Insert into SQLite
      await db.insertUser(newUser.toMap());

      // 5. Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', uid);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showError('Sign up failed. Please try again.');
      debugPrint('SignUp error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────

  /// Since we're using SQLite, there's no email service.
  /// We show a simple dialog informing the user to contact the developer.
  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text(
          'Password reset is not available in the local version. '
              'Please contact the developer to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFB0B0B0)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // App name
                const Text(
                  'Shredded\nSquad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 32),

                // Dark card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title changes between Login and Sign Up
                        Center(
                          child: Text(
                            _isSignUpMode ? 'Sign Up' : 'Login',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Email field
                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Password field
                        _buildField(
                          controller: _passCtrl,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Main action button — Login or Sign Up
                        _buildButton(
                          label: _isSignUpMode ? 'Create Account' : 'Login',
                          isLoading: _isLoading,
                          onPressed: _isSignUpMode ? _handleSignUp : _handleLogin,
                        ),

                        const SizedBox(height: 16),

                        // Forgot password — only shown in login mode
                        if (!_isSignUpMode)
                          Center(
                            child: GestureDetector(
                              onTap: _handleForgotPassword,
                              child: const Text(
                                'Forgot password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Toggle between Login and Sign Up
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(
                                    () => _isSignUpMode = !_isSignUpMode),
                            child: Text(
                              _isSignUpMode
                                  ? 'Already have an account? Login'
                                  : 'Need account? Sign up',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2)),
          errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2)),
          errorStyle: const TextStyle(color: Colors.redAccent),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.only(bottom: 8),
        ),
      );

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3A3A3A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          )
              : Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );
}