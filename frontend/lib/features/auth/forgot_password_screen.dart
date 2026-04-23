import 'package:flutter/material.dart';
import 'package:ai_medical_app/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool otpSent = false;
  bool otpVerified = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? message;
  bool isError = false;

  final Color primary = const Color(0xFF9C89E8);

  Future<void> sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; message = null; });

    bool success = await ApiService.forgotPassword(_emailController.text.trim());

    setState(() {
      _isLoading = false;
      if (success) {
        otpSent = true;
        isError = false;
        message = "✅ OTP sent to your email!";
      } else {
        isError = true;
        message = "❌ Email not found. Please check and try again.";
      }
    });
  }

  Future<void> verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; message = null; });

    bool success = await ApiService.verifyOtp(
      _emailController.text.trim(),
      _otpController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      if (success) {
        otpVerified = true;
        isError = false;
        message = "✅ OTP verified successfully!";
      } else {
        isError = true;
        message = "❌ Invalid OTP. Please try again.";
      }
    });
  }

  Future<void> resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; message = null; });

    bool success = await ApiService.resetPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() { _isLoading = false; });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Password reset successful! Please login."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        isError = true;
        message = "❌ Failed to reset password. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3D2C8D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Forgot Password",
            style: TextStyle(color: Color(0xFF3D2C8D), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.lock_reset, color: primary, size: 35),
                ),
                const SizedBox(height: 16),
                const Text("Reset Password",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("Enter your email to receive OTP",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 28),

                // ── Step 1: Email ──────────────────────────────
                Form(
                  key: _emailFormKey,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !otpSent,
                    decoration: _inputDecoration("Email", Icons.email),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email is required";
                      }
                      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$')
                          .hasMatch(value.trim())) {
                        return "Enter a valid email (e.g. user@gmail.com)";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                if (!otpSent)
                  _actionButton("Send OTP", sendOtp),

                // ── Step 2: OTP ────────────────────────────────
                if (otpSent && !otpVerified) ...[
                  const SizedBox(height: 16),
                  Form(
                    key: _otpFormKey,
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: _inputDecoration("Enter OTP", Icons.pin),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "OTP is required";
                        }
                        if (value.trim().length != 6) {
                          return "OTP must be 6 digits";
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                          return "OTP must contain only digits";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _actionButton("Verify OTP", verifyOtp),
                  TextButton(
                    onPressed: _isLoading ? null : sendOtp,
                    child: Text("Resend OTP", style: TextStyle(color: primary)),
                  ),
                ],

                // ── Step 3: New Password ───────────────────────
                if (otpVerified) ...[
                  const SizedBox(height: 16),
                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration("New Password", Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Password is required";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: _inputDecoration("Confirm Password", Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please confirm your password";
                            }
                            if (value != _passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _actionButton("Reset Password", resetPassword),
                ],

                // ── Message ───────────────────────────────────
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isError ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isError ? Colors.red.shade200 : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      message!,
                      style: TextStyle(
                        color: isError ? Colors.red.shade700 : Colors.green.shade700,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
