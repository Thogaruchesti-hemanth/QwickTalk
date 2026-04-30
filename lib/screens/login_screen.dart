import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:chat_app/utils/dailogs.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _isLoggingIn = false;
  String _loadingMessage = "Continue with Google";
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLoginClick() async {
    if (_isLoggingIn) return;
    if (!kIsWeb) HapticFeedback.mediumImpact();

    setState(() {
      _isLoggingIn = true;
      _loadingMessage = "Authenticating...";
    });
    
    try {
      final userCredential = await _signInWithGoogle();
      if (userCredential != null && userCredential.user != null) {
        setState(() => _loadingMessage = "Verifying...");
        bool userExists = await APIs.userExists();
        if (!userExists) await APIs.createUser();
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } catch (e) {
      Dialogs.showSnackBar(context, "Login failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Future<UserCredential?> _signInWithGoogle() async {
    if (kIsWeb) {
      return await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      return await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWideScreen = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: isWideScreen ? 450 : size.width * 0.9,
            padding: const EdgeInsets.all(32),
            decoration: isWideScreen ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24)],
            ) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/app_logo.png', width: 100),
                const SizedBox(height: 32),
                const Text("Qwick Talk", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                const SizedBox(height: 12),
                const Text("Fast, secure, and short-term messaging.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                const SizedBox(height: 48),
                _buildProfessionalGoogleButton(),
                const SizedBox(height: 32),
                const Text("Conversations expire after 7 days", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalGoogleButton() {
    return InkWell(
      onTap: _isLoggingIn ? null : _handleLoginClick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        ),
        child: _isLoggingIn 
          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED))))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/google.png', height: 24),
                const SizedBox(width: 12),
                const Text("Continue with Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ],
            ),
      ),
    );
  }
}
