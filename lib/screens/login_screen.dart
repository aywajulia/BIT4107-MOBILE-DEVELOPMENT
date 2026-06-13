import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form & Controllers
  /// Global key used to validate the form before submission
  final _formKey = GlobalKey<FormState>();
  /// Controllers to read the email and password field values
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  /// Toggles password visibility (show / hide)
  bool _obscurePassword = true;
  /// Shows a loading spinner on the Login button while authenticating
  bool _isLoading = false;
  @override
  void dispose() {
    // Always dispose controllers to free memory
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  // ─── Actions ──────────────────────────────────────────────────────────────
  /// Called when the user taps the "Login" button.
  /// Validates the form, then calls your auth service.
  Future<void> _handleLogin() async {
    // Stop if any field fails validation
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Replace with your real authentication call, e.g.:
      // await AuthService.signInWithEmail(
      //   _emailController.text.trim(),
      //   _passwordController.text,
      // );

      // Simulate a network delay for now
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Navigate to the home/dashboard screen on success
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // Show an error snackbar if login fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  /// Called when the user taps "Sign in with Google".
  /// Integrate google_sign_in package here.
  Future<void> _handleGoogleSignIn() async {
    try {
      // TODO: Replace with your Google Sign-In implementation, e.g.:
      // final user = await AuthService.signInWithGoogle();

      // Simulate delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
  /// Called when the user taps "Forgot password".
  /// Navigate to a password-reset screen or show a dialog.
  void _handleForgotPassword() {
    // TODO: Replace with your forgot-password route, e.g.:
    // Navigator.of(context).pushNamed('/forgot-password');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'A password reset link will be sent to your email.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  /// Called when the user taps "Need account? Sign up".
  void _handleSignUp() {
    // TODO: Replace with your sign-up route, e.g.:
    // Navigator.of(context).pushNamed('/signup');
    Navigator.of(context).pushNamed('/signup');
  }

  // Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Full-screen light grey gradient background — matches the design
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // white at the top
              Color(0xFFB0B0B0), // medium grey at the bottom
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // Allows scrolling on small screens / when keyboard is open
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // logo
                const Text(
                  'Shredded\nSquad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Dark card container ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // dark card background
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "Login" heading
                        const Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Email field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            // Basic email format check
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value.trim())) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        // ── Password field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }

                            return null;
                          },
                          // Eye icon to toggle visibility
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(
                                      () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Login button ─────────────────────────────────
                        _buildPrimaryButton(
                          label: 'Login',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),

                        const SizedBox(height: 16),

                        // ── "Or" divider ─────────────────────────────────
                        const Center(
                          child: Text(
                            'Or',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sign in with Google button
                        _buildSecondaryButton(
                          label: 'Sign in with Google',
                          onPressed: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: 24),
                        //  Forgot password link
                        Center(
                          child: GestureDetector(
                            onTap: _handleForgotPassword,
                            child: const Text(
                              'Forgot password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        //  Sign up link
                        Center(
                          child: GestureDetector(
                            onTap: _handleSignUp,
                            child: const Text(
                              'Need account? Sign up',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
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
  //  Reusable Widgets
  /// Builds a styled text field matching the dark card design.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        // Underline-only style matching the design
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54, width: 1.2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.only(bottom: 8),
      ),
    );
  }

  /// Builds the primary filled "Login" button.
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3A3A3A), // dark grey fill
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  /// Builds the secondary outlined-style "Sign in with Google" button.
  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2C2C), // slightly lighter dark
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}