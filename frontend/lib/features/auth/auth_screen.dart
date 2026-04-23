import 'package:flutter/material.dart';
import 'package:ai_medical_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {

  bool isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'patient';

  // ✅ Admin credentials hardcoded
  static const String _adminEmail    = 'admin12@gmail.com';
  static const String _adminPassword = 'admin123';

  int _currentVideoIndex = 0;
  final List<Map<String, dynamic>> _medicalSlides = [
    {
      'icon': Icons.favorite,
      'color': const Color(0xFFE53935),
      'title': 'Heart Health',
      'subtitle': 'Monitor your cardiac wellness 24/7',
    },
    {
      'icon': Icons.psychology,
      'color': const Color(0xFF8E24AA),
      'title': 'Mental Wellness',
      'subtitle': 'Talk to certified therapists online',
    },
    {
      'icon': Icons.medical_services,
      'color': const Color(0xFF1E88E5),
      'title': 'Expert Doctors',
      'subtitle': 'Connect with 500+ specialists',
    },
    {
      'icon': Icons.vaccines,
      'color': const Color(0xFF43A047),
      'title': 'Lab & Diagnostics',
      'subtitle': 'Book tests from home, get reports fast',
    },
    {
      'icon': Icons.local_pharmacy,
      'color': const Color(0xFFF4511E),
      'title': 'Medicine Delivery',
      'subtitle': 'Get medicines delivered in 2 hours',
    },
  ];

  late AnimationController _gradientController;
  late Animation<Alignment> _beginAnimation;
  late Animation<Alignment> _endAnimation;

  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();

  final Color primary = const Color(0xFF9C89E8);

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _beginAnimation = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(_gradientController);

    _endAnimation = AlignmentTween(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).animate(_gradientController);

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      setState(() {
        _currentVideoIndex =
            (_currentVideoIndex + 1) % _medicalSlides.length;
      });
      return true;
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _isAdminCredentials =>
      _emailController.text.trim() == _adminEmail &&
      _passwordController.text == _adminPassword;

  Future<void> _redirectByRole() async {
    if (_isAdminCredentials) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'admin');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final role  = prefs.getString('user_role') ?? 'patient';
    final email = prefs.getString('user_email') ?? '';

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (role == 'doctor') {
      final status = prefs.getString('doctor_status_$email') ?? 'pending';
      if (status == 'approved') {
        Navigator.pushReplacementNamed(context, '/doctor-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/doctor-verification-pending');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    if (isLogin && _isAdminCredentials) {
      setState(() => _isLoading = false);
      await _redirectByRole();
      return;
    }

    bool success = false;

    if (isLogin) {
      success = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (success) await ApiService.fetchUserProfile();
    } else {
      success = await ApiService.signupWithRole(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedRole,
      );
      if (success) {
        success = await ApiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (success) await ApiService.fetchUserProfile();
      }
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      await _redirectByRole();
    } else {
      setState(() {
        _errorMessage = isLogin
            ? "Login failed. Check your email and password."
            : "Signup failed. This email may already be registered.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _beginAnimation.value,
                end: _endAnimation.value,
                colors: const [
                  Color(0xFFB39DDB),
                  Color(0xFF9C89E8),
                  Color(0xFF7E6AD6),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                // ✅ Poori screen center — mobile + web dono pe
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 480, // ✅ Max width — web pe square jaisa
                  ),
                  child: Column(
                    children: [
                      // ── Banner ───────────────────────────────
                      SizedBox(
                        height: size.height * 0.28,
                        child: _buildMedicalBanner(),
                      ),

                      // ── Auth Card ────────────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _buildAuthCard(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicalBanner() {
    final slide = _medicalSlides[_currentVideoIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(_currentVideoIndex),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 2),
                ),
                child: Icon(
                  slide['icon'] as IconData,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              slide['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              slide['subtitle'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _medicalSlides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentVideoIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentVideoIndex
                        ? Colors.white
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggle(),
            const SizedBox(height: 20),

            Text(
              isLogin ? "Welcome Back!" : "Create Account",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isLogin ? "Sign in to continue" : "Fill in the details below",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),

            // Name (signup only)
            if (!isLogin) ...[
              _buildTextField(
                _nameController,
                "Full Name",
                Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return "Full name is required";
                  if (value.trim().length < 2)
                    return "Name must be at least 2 characters";
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim()))
                    return "Name can only contain letters";
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],

            // Email
            _buildTextField(
              _emailController,
              "Email Address",
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return "Email is required";
                if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$')
                    .hasMatch(value.trim()))
                  return "Enter a valid email";
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            _buildTextField(
              _passwordController,
              "Password",
              Icons.lock_outline,
              obscure: true,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return "Password is required";
                if (!isLogin && value.length < 6)
                  return "Password must be at least 6 characters";
                return null;
              },
            ),

            // Forgot Password
            if (isLogin) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],

            // Role Selection (signup only)
            if (!isLogin) ...[
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Register as:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _roleButton('patient', Icons.person, 'Patient'),
                  const SizedBox(width: 12),
                  _roleButton('doctor', Icons.medical_services, 'Doctor'),
                ],
              ),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  disabledBackgroundColor: primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  shadowColor: primary.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isLogin ? "Sign In" : "Sign Up",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(String role, IconData icon, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primary : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey,
                  size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _toggleButton("Login", true),
          const SizedBox(width: 4),
          _toggleButton("Register", false),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          isLogin       = selected;
          _errorMessage = null;
          _formKey.currentState?.reset();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isLogin == selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isLogin == selected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isLogin == selected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: primary, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator ??
          (value) =>
              value == null || value.isEmpty ? "Required field" : null,
    );
  }
}