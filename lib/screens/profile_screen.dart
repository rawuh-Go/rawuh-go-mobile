import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rawuh_go_mobil/screens/change_password_screen.dart';
import 'package:rawuh_go_mobil/screens/edit_profile_screen.dart';
import 'package:rawuh_go_mobil/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Loading...";
  String position = "Loading...";
  String userImage = "";
  String shiftName = "Loading...";
  String shiftTime = "Loading...";
  String email = "";
  String phoneNumber = "";
  String gender = "";
  String address = "";
  String country = "";
  bool isWfa = false;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchSchedule();
  }

  Future<void> updateProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final token = await storage.read(key: 'token');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://presensi.amikomcenter.com/api/profile/update'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        fetchProfile();
      }
    }
  }

  Future<void> fetchProfile() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://presensi.amikomcenter.com/api/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userName = data['data']['name'];
          position = data['data']['job_position'];
          userImage = data['data']['image'];
          email = data['data']['email'];
          phoneNumber = data['data']['phone_number'];
          gender = data['data']['gender'];
          address = data['data']['address'];
          country = data['data']['country'];
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> fetchSchedule() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://presensi.amikomcenter.com/api/schedules'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'].isNotEmpty) {
          final schedule = data['data'][0];
          setState(() {
            shiftName = schedule['shift']['nama'];
            shiftTime =
                '${schedule['shift']['waktu_datang']} - ${schedule['shift']['waktu_pulang']}';
            isWfa = schedule['is_wfa'];
          });
        }
      }
    } catch (e) {
      print('Error fetching schedule: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Color(0xFF2A5867), size: 28),
            const SizedBox(width: 10),
            Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = await storage.read(key: 'token');
        final response = await http.post(
          Uri.parse('https://presensi.amikomcenter.com/api/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          await storage.delete(key: 'token');
          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error during logout',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A5867),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: userImage.isNotEmpty
                            ? NetworkImage(
                                userImage.replaceAll('127.0.0.1', '10.0.2.2'),
                              )
                            : null,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: userImage.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 50,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: updateProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A5867),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A5867),
                    ),
                  ),
                  Text(
                    position,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusInfo(
                    'Status',
                    isWfa ? 'WFA' : 'WFO',
                    const Color(0xFF2A5867),
                  ),
                  Container(height: 40, width: 1, color: Colors.grey[300]),
                  _buildStatusInfo(
                    'Shift',
                    '$shiftName\n$shiftTime',
                    const Color(0xFF2A5867),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuButton('Edit Profile', Icons.person_outline, () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              if (result == true) {
                fetchProfile();
              }
            }),
            _buildMenuButton('Change Password', Icons.lock_outline, () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
              if (result == true) {
                // Optional: Show success message or perform any necessary updates
              }
            }),
            _buildMenuButton('Logout', Icons.logout, _handleLogout,
                isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF2A5867),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: isDestructive ? Colors.red : Colors.grey[800],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 20),
        onTap: onTap,
      ),
    );
  }
}
