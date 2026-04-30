import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../utils/dailogs.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWideScreen = size.width > 900;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: isWideScreen ? _buildWebLayout(size) : _buildMobileLayout(size),
      ),
    );
  }

  // --- WEB LAYOUT: High-End Dashboard Style ---
  Widget _buildWebLayout(Size size) {
    return Row(
      children: [
        // Left Side: Profile Preview
        Container(
          width: size.width * 0.35,
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProfileImage(size, isWeb: true),
              const SizedBox(height: 24),
              Text(widget.user.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text(widget.user.email, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
              const SizedBox(height: 48),
              _buildWebLogoutButton(),
            ],
          ),
        ),

        // Right Side: Settings Form
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(FeatherIcons.arrowLeft)),
                    const SizedBox(width: 12),
                    const Text("Account Settings", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Update your personal information and status below.", style: TextStyle(color: Color(0xFF64748B), fontSize: 18)),
                const SizedBox(height: 60),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputField(
                        initialValue: widget.user.name,
                        label: 'Display Name',
                        icon: FeatherIcons.user,
                        onSaved: (val) => APIs.me.name = val ?? '',
                      ),
                      const SizedBox(height: 32),
                      _buildInputField(
                        initialValue: widget.user.about,
                        label: 'About / Status',
                        icon: FeatherIcons.info,
                        onSaved: (val) => APIs.me.about = val ?? '',
                      ),
                      const SizedBox(height: 64),
                      _buildActionButton(
                        label: "UPDATE SETTINGS",
                        icon: FeatherIcons.checkCircle,
                        color: const Color(0xFF7C3AED),
                        onPressed: _saveProfile,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  // --- MOBILE LAYOUT: Sleek Minimalist ---
  Widget _buildMobileLayout(Size size) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(FeatherIcons.chevronLeft, color: Colors.black)),
          title: const Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileImage(size, isWeb: false),
                  const SizedBox(height: 24),
                  Text(widget.user.email, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 48),
                  _buildInputField(
                    initialValue: widget.user.name,
                    label: 'Display Name',
                    icon: FeatherIcons.user,
                    onSaved: (val) => APIs.me.name = val ?? '',
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    initialValue: widget.user.about,
                    label: 'Status',
                    icon: FeatherIcons.info,
                    onSaved: (val) => APIs.me.about = val ?? '',
                  ),
                  const SizedBox(height: 56),
                  _buildActionButton(
                    label: "SAVE PROFILE",
                    icon: FeatherIcons.save,
                    color: const Color(0xFF7C3AED),
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    label: "LOGOUT",
                    icon: FeatherIcons.logOut,
                    color: Colors.redAccent,
                    onPressed: _logout,
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildProfileImage(Size size, {required bool isWeb}) {
    double imgSize = isWeb ? size.height * 0.25 : size.width * 0.45;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.15), width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(imgSize),
            child: CachedNetworkImage(
              width: imgSize,
              height: imgSize,
              fit: BoxFit.cover,
              imageUrl: widget.user.image,
              errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person)),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: isWeb ? 30 : 10,
          child: InkWell(
            onTap: _showBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: const Icon(FeatherIcons.camera, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({required String initialValue, required String label, required IconData icon, required Function(String?) onSaved}) {
    return TextFormField(
      initialValue: initialValue,
      onSaved: onSaved,
      validator: (val) => val != null && val.isNotEmpty ? null : 'Required Field',
      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed, bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withOpacity(0.4), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
            ),
    );
  }

  Widget _buildWebLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(FeatherIcons.logOut, size: 18),
        label: const Text("SIGNOUT SESSION", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      APIs.updateUserInfo().then((value) => Dialogs.showSnackBar(context, 'Settings Saved'));
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Sign Out', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your current session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      Dialogs.showProgressBar(context);
      await APIs.updateActiveStatus(false);
      await APIs.auth.signOut();
      await GoogleSignIn().signOut();
      if (mounted) {
        Navigator.pop(context); // close progress
        Navigator.pop(context); // exit profile
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
            const Text('Change Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(FeatherIcons.image, 'Gallery', () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) _processImage(File(image.path));
                }),
                _buildOption(FeatherIcons.camera, 'Camera', () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) _processImage(File(image.path));
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF7C3AED), size: 28),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Future<void> _processImage(File file) async {
    APIs.updateProfilePicture(file);
    setState(() => _image = file.path);
  }
}
