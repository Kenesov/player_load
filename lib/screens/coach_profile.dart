import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_auth_service.dart';
import 'login_screen.dart';

class CoachProfile extends StatefulWidget {
  final User user;

  CoachProfile({required this.user});

  @override
  _CoachProfileState createState() => _CoachProfileState();
}

class _CoachProfileState extends State<CoachProfile> {
  late User currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  void _onProfileUpdated(User updatedUser) {
    setState(() {
      currentUser = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        backgroundImage: currentUser.profilePicture != null && currentUser.profilePicture!.isNotEmpty
                            ? NetworkImage(currentUser.profilePicture!)
                            : null,
                        child: currentUser.profilePicture == null || currentUser.profilePicture!.isEmpty
                            ? Text(
                          _getInitials(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    currentUser.fullName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'MURABBIY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shaxsiy ma\'lumotlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.person, 'Username', currentUser.username),
                  _buildInfoRow(Icons.email, 'Email', currentUser.email),
                  if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty)
                    _buildInfoRow(Icons.phone, 'Telefon', currentUser.phoneNumber!),
                  if (currentUser.dateOfBirth != null)
                    _buildInfoRow(
                      Icons.cake,
                      'Tug\'ilgan sana',
                      DateFormat('dd/MM/yyyy').format(currentUser.dateOfBirth!),
                    ),
                  if (currentUser.bio != null && currentUser.bio!.isNotEmpty)
                    _buildInfoRow(Icons.info, 'Bio', currentUser.bio!),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: Icon(Icons.logout),
                  label: Text('Chiqish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    if (currentUser.firstName.isNotEmpty && currentUser.lastName.isNotEmpty) {
      return '${currentUser.firstName[0]}${currentUser.lastName[0]}';
    } else if (currentUser.firstName.isNotEmpty) {
      return currentUser.firstName[0];
    } else if (currentUser.lastName.isNotEmpty) {
      return currentUser.lastName[0];
    } else {
      return currentUser.username.isNotEmpty ? currentUser.username[0].toUpperCase() : 'U';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'Kiritilmagan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galereyadan tanlash'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _uploadProfilePicture(File(image.path));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Kameradan olish'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    _uploadProfilePicture(File(image.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _uploadProfilePicture(File imageFile) async {
    try {
      // Loading dialog ko'rsatish
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Rasm yuklanmoqda...'),
              ],
            ),
          );
        },
      );

      final success = await ApiAuthService().updateUser(
        currentUser.id,
        {},
        profilePicture: imageFile,
      );

      Navigator.pop(context); // Loading dialog ni yopish

      if (success) {
        // Yangilangan user ma'lumotlarini olish
        final updatedUser = await ApiAuthService().getCurrentUser();
        if (updatedUser != null) {
          setState(() {
            currentUser = updatedUser;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil rasmi muvaffaqiyatli yangilandi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rasm yuklashda xatolik yuz berdi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Loading dialog ni yopish
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  _logout(BuildContext context) async {
    await AuthService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
