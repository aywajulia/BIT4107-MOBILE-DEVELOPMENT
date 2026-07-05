/// login_screen.dart
/// Location: lib/screen/login_screen.dart
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../validator/auth_validator.dart';
import '../handlers/keyboard_handler.dart';
import '../service/event_logger.dart';
import '../service/database_helper.dart';
import '../model/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUpMode = false;

  late KeyboardActionHandler _keyboardHandler;
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _keyboardHandler = KeyboardActionHandler(
      onEnterPressed: _handleLogin,
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final emailError = AuthValidator.validateEmail(_emailCtrl.text);
    if (emailError != null) { _showError(emailError); return; }
    final passError = AuthValidator.validatePassword(_passCtrl.text);
    if (passError != null) { _showError(passError); return; }

    EventLogger.logEvent('Login_Attempt', screen: 'Login', data: _emailCtrl.text.trim());
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      final userMap = await db.getUserByEmail(email);
      if (userMap == null) { _showError('No account found for this email.'); return; }
      if (userMap['password'] != password) { _showError('Incorrect password. Please try again.'); return; }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', userMap['uid']);
      EventLogger.logEvent('Login_Success', screen: 'Login', data: email);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showError('Something went wrong. Please try again.');
      EventLogger.logEvent('Login_Error', screen: 'Login', data: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final emailError = AuthValidator.validateEmail(_emailCtrl.text);
    if (emailError != null) { _showError(emailError); return; }
    final passError = AuthValidator.validatePassword(_passCtrl.text);
    if (passError != null) { _showError(passError); return; }

    EventLogger.logEvent('SignUp_Attempt', screen: 'Login', data: _emailCtrl.text.trim());
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      final existing = await db.getUserByEmail(email);
      if (existing != null) { _showError('An account with this email already exists.'); return; }

      final uid = DateTime.now().millisecondsSinceEpoch.toString();
      final newUser = User(
        uid: uid,
        name: email.split('@')[0],
        email: email,
        password: password,
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insertUser(newUser.toMap());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', uid);
      EventLogger.logEvent('SignUp_Success', screen: 'Login', data: email);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showError('Sign up failed. Please try again.');
      EventLogger.logEvent('SignUp_Error', screen: 'Login', data: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('Please contact the developer to reset your password.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

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
                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          focusNode: _emailFocusNode,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter your email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Enter a valid email';
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocusNode);
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _passCtrl,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          focusNode: _passwordFocusNode,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your password';
                            if (v.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          onFieldSubmitted: (_) => _keyboardHandler.handleSubmit(''),
                        ),
                        const SizedBox(height: 28),
                        _buildButton(
                          label: _isSignUpMode ? 'Create Account' : 'Login',
                          isLoading: _isLoading,
                          onPressed: _isSignUpMode ? _handleSignUp : _handleLogin,
                        ),
                        const SizedBox(height: 16),
                        if (!_isSignUpMode)
                          Center(
                            child: GestureDetector(
                              onTap: _handleForgotPassword,
                              child: const Text(
                                'Forgot password',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUpMode = !_isSignUpMode),
                            child: Text(
                              _isSignUpMode
                                  ? 'Already have an account? Login'
                                  : 'Need account? Sign up',
                              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        textInputAction: textInputAction,
        focusNode: focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
          errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent, width: 2)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );
}