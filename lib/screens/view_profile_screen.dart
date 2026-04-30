import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class ViewProfileScreen extends StatelessWidget {
  final ChatUser user;
  const ViewProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(FeatherIcons.chevronLeft, color: Color(0xFF0F172A)),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: size.width > 600 ? 500 : size.width,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Profile Image with ring
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.15), width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(size.height * .1),
                    child: CachedNetworkImage(
                      width: size.height * .18,
                      height: size.height * .18,
                      fit: BoxFit.cover,
                      imageUrl: user.image,
                      errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user.email, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                
                const SizedBox(height: 48),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(FeatherIcons.info, "About", user.about),
                      const Divider(height: 40),
                      _buildInfoRow(
                        FeatherIcons.calendar, 
                        "Member Since", 
                        CommonUtils.getLastMessageTime(context: context, time: user.createAt, showYear: true)
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 56),

                // Message Button
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(FeatherIcons.messageCircle, size: 20),
                  label: const Text("SEND MESSAGE", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    minimumSize: const Size(double.infinity, 60),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }
}
