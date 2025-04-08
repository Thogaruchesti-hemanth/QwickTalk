import 'dart:io';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:chat_app/utils/constants.dart';
import 'package:chat_app/utils/dailogs.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimated = false;

  bool _isLoggingIn = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimated = true;
      });
    });
  }

  Future<void> _handleLoginClick() async {
    if (_isLoggingIn) return;

    setState(() => _isLoggingIn = true);

    // Show loading indicator
    Dialogs.showProgressBar(context);

    final userCredential = await _signInWithGoogle();

    // Close loading indicator
    Navigator.pop(context);
    setState(() => _isLoggingIn = false);

    if (userCredential != null && userCredential.user != null) {
      CommonUtils.prints("User: ${userCredential.user}");

      bool userExists = await APIs.userExists();
      if (!userExists) await APIs.createUser();

      // Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      Dialogs.showSnackBar(context, "Login Failed! Please try again.");
    }
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      // Check internet connection
      if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
        Dialogs.showAlertDialog(
          context,
          "No Internet",
          "Please check your connection and try again.",
        );
        return null;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await FirebaseAuth.instance.signInWithPopup(authProvider);
      } else {
        googleUser = await googleSignIn.signIn();
      }

      if (googleUser == null) {
        CommonUtils.prints("Google Sign-In canceled");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      CommonUtils.prints("Google Sign-In error: $e");
      Dialogs.showSnackBar(context, "Something went wrong. Try again.");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(),
            const SizedBox(height: 30),
            _buildGoogleLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedSwitcher(
      duration: const Duration(seconds: 1),
      child:
          _isAnimated
              ? Image.asset(
                'assets/images/app_logo.png',
                width: Constants.screenWidth * 0.5,
                key: const ValueKey("logo"),
              )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildGoogleLoginButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade100,
        shape: const StadiumBorder(),
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: _isLoggingIn ? null : _handleLoginClick,
      icon:
          _isLoggingIn
              ? CircularProgressIndicator(color: Colors.black87)
              : Image.asset(
                'assets/images/google.png',
                height: Constants.screenHeight * 0.03,
              ),
      label: Text(
        _isLoggingIn ? "logging in...." : "Login with Google",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
