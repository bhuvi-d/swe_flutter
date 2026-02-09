import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';

/// LoginScreen - OTP-based authentication
/// Matches React's LoginScreen.jsx
class LoginScreen extends StatefulWidget {
  final Function() onLogin;
  final VoidCallback onSkip;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onSkip,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  String _step = 'phone'; // 'phone' or 'otp'
  bool _loading = false;
  String? _verificationId;
  
  // US1: OTP Expiry Timer
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    // Speak welcome message
    audioService.speakGuidance('welcome');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showMessage('Please enter a valid 10-digit number');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await authService.sendOtp(
        phoneNumber: phone,
        onCodeSent: (vid, token) {
          setState(() {
            _loading = false;
            _step = 'otp';
            _verificationId = vid;
          });
          _startResendTimer(); // Start expiry timer
          _showMessage('OTP has been sent ${vid == 'mock_verification_id' ? '(Demo: 123456)' : ''}');
          audioService.speakGuidance('otp');
        },
        onVerificationFailed: (e) {
          setState(() => _loading = false);
          _showMessage('Verification failed: ${e.message}');
          audioService.confirmAction('error', message: 'Verification failed');
        },
        onVerificationCompleted: (credential) async {
          // Auto-resolution (on Android)
          setState(() => _loading = false);
          _showMessage('Phone number verified automatically');
          widget.onLogin();
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      _showMessage('Error: $e');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showMessage('Please enter 6-digit OTP');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      
      setState(() => _loading = false);
      _showMessage('Login successful');
      audioService.confirmAction('success', message: 'Welcome to Crop AId');
      widget.onLogin();
    } catch (e) {
      setState(() => _loading = false);
      _showMessage('Invalid OTP. Please try again.');
      audioService.confirmAction('error', message: 'Invalid code');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Section - Brand Info
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGreen,
                  AppColors.secondaryGreen,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CropAid 🌾',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Smart Crop Diagnosis & Farmer Support Platform.\n\nGet expert help, insights, and grow better.',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Section - Login Form
        Expanded(
          child: Container(
            color: AppColors.gray50,
            child: Center(
              child: _buildLoginCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.secondaryGreen,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Brand Info
                const Text(
                  'CropAid 🌾',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Smart Crop Diagnosis & Farmer Support Platform.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Login Card
                _buildLoginCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Farmer Login',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 35),

          // Phone Input
          if (_step == 'phone') ...[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: 'Enter Mobile Number',
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.secondaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                // Only allow digits
                final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (cleaned != value) {
                  _phoneController.text = cleaned;
                  _phoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: cleaned.length),
                  );
                }
              },
            ),
            const SizedBox(height: 22),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _loading ? 'Sending...' : 'Send OTP',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // OTP Input
          if (_step == 'otp') ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode], // US1: Auto-read support
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.secondaryGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 22),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _loading ? 'Verifying...' : 'Verify & Login',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            // US1: Resend Logic with Timer
            Center(
              child: _resendSeconds > 0
                  ? Text(
                      'Resend OTP in ${_resendSeconds}s',
                      style: TextStyle(color: AppColors.gray500),
                    )
                  : TextButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: const Text('Resend OTP'),
                    ),
            ),
          ],

          // Skip Login
          const SizedBox(height: 20),
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Skip Login →',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
