import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../utils/constants.dart';
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
  String? _localImagePath; // Local saved image path (if available)

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard when tapping outside
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 34),
            onPressed: () => Navigator.pop(context),
          ),
          // Logout button placed in the AppBar
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Constants.screenWidth * 0.05,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileImage(),
                  const SizedBox(height: 20),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    initialValue: widget.user.name,
                    label: 'Name',
                    hintText: 'e.g., Happy Singh',
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    onSaved: (value) => APIs.me?.name = value ?? '',
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    initialValue: widget.user.about,
                    label: 'About',
                    hintText: 'e.g., Feeling Happy',
                    prefixIcon: const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    onSaved: (value) => APIs.me?.about = value ?? '',
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                          ), // Adds spacing
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ), // Proper button padding
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              minimumSize: Size(
                                Constants.screenWidth * 0.42,
                                Constants.screenHeight * 0.06,
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                APIs.updateUserInfo().then((value) {
                                  Dialogs.showSnackBar(
                                    context,
                                    'Profile updated successfully',
                                  );
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.edit,
                              size: 24, // Slightly reduced for balance
                              color: Colors.white,
                            ),
                            label: const Text(
                              "UPDATE",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                          ), // Adds spacing
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ), // Consistent padding
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              minimumSize: Size(
                                Constants.screenWidth * 0.42,
                                Constants.screenHeight * 0.06,
                              ),
                            ),
                            onPressed: _logout,
                            icon: const Icon(
                              Icons.logout,
                              size: 24, // Adjusted for consistency
                              color: Colors.white,
                            ),
                            label: const Text(
                              "LOGOUT",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: Constants.screenWidth * 0.275,
          backgroundColor: Colors.grey.shade300,
          backgroundImage:
              _localImagePath != null
                  ? FileImage(File(_localImagePath!))
                  : CachedNetworkImageProvider(widget.user.image)
                      as ImageProvider,
          onBackgroundImageError: (_, __) {},
          child:
              _localImagePath == null
                  ? CachedNetworkImage(
                    imageUrl: widget.user.image,
                    fit: BoxFit.cover,
                    imageBuilder:
                        (context, imageProvider) => CircleAvatar(
                          radius: Constants.screenWidth * 0.275,
                          backgroundImage: imageProvider,
                        ),
                    placeholder:
                        (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: CircleAvatar(
                            radius: Constants.screenWidth * 0.275,
                            backgroundColor: Colors.grey,
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person),
                        ),
                  )
                  : null,
        ),
        // Button to open bottom sheet for image selection.
        // Positioned(
        //   bottom: 0,
        //   right: 0,
        //   child: MaterialButton(
        //     elevation: 1,
        //     onPressed: _showBottomSheet,
        //     shape: const CircleBorder(),
        //     color: Colors.white,
        //     child: const Icon(Icons.edit, color: Colors.blue),
        //   ),
        // ),
      ],
    );
  }

  /// Builds a text form field with given parameters.
  Widget _buildTextFormField({
    required String initialValue,
    required String label,
    required String hintText,
    required Widget prefixIcon,
    required Function(String?) onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onSaved: onSaved,
      validator:
          (val) => (val != null && val.isNotEmpty) ? null : 'Required Field',
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: prefixIcon,
        hintText: hintText,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blue),
      ),
    );
  }

  /// Logs out the user.
  Future<void> _logout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      Dialogs.showProgressBar(context);
      await APIs.updateActiveStatus(false);
      await APIs.auth.signOut().then((value) async {
        await GoogleSignIn().signOut().then((value) {
          Navigator.pop(context); // Close progress dialog
          Navigator.pop(context); // Exit current screen
          APIs.auth = FirebaseAuth.instance;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        });
      });
    }
  }

  /// Shows the bottom sheet to pick a profile picture.
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: Constants.screenHeight * 0.05,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pick Profile Picture',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageButton(
                    'assets/images/gallery.png',
                    ImageSource.gallery,
                    'Gallery',
                  ),
                  _buildImageButton(
                    'assets/images/camera.png',
                    ImageSource.camera,
                    'Camera',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds an image button with an icon and label for the bottom sheet.
  Widget _buildImageButton(String assetPath, ImageSource source, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
            fixedSize: Size(
              Constants.screenWidth * 0.3,
              Constants.screenHeight * 0.15,
            ),
          ),
          onPressed: () async {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(
              source: source,
              imageQuality: 80,
            );
            if (image != null) {
              // Crop the image before saving.
              CroppedFile? croppedFile = await ImageCropper().cropImage(
                sourcePath: image.path,
                uiSettings: [
                  AndroidUiSettings(
                    toolbarTitle: 'Crop Image',
                    toolbarColor: Colors.blue,
                    toolbarWidgetColor: Colors.white,
                    initAspectRatio: CropAspectRatioPreset.original,
                    lockAspectRatio: false,
                  ),
                  IOSUiSettings(title: 'Crop Image'),
                ],
              );
              if (croppedFile != null) {
                CommonUtils.prints('Cropped Image Path: ${croppedFile.path}');
                // Save the cropped image to the app's documents directory.
                final Directory appDir =
                    await getApplicationDocumentsDirectory();
                final String fileName = path.basename(croppedFile.path);
                final File savedImage = await File(
                  croppedFile.path,
                ).copy('${appDir.path}/$fileName');
                setState(() => _localImagePath = savedImage.path);
                APIs.updateProfilePicture(savedImage);
              }
            }
            Navigator.pop(context);
          },
          child: Image.asset(assetPath),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.blue)),
      ],
    );
  }
}
