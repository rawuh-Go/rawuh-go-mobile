import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String userName = "Loading...";
  String position = "Loading...";
  String userImage = "";
  String shiftName = "Loading...";
  String shiftTime = "Loading...";
  String officeName = "Loading...";
  bool isWfa = false;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchSchedule();
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
            officeName = schedule['office']['nama'];
            isWfa = schedule['is_wfa'];
          });
        }
      }
    } catch (e) {
      print('Error fetching schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Schedules',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A5867),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A5867),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
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
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          position,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.access_time_rounded,
                      'Shift',
                      '$shiftName ($shiftTime)',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.business, 'Office', officeName),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.work,
                      'Work Type',
                      isWfa
                          ? 'Work From Anywhere (WFA)'
                          : 'Work From Office (WFO)',
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2A5867).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2A5867), size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color:
                    isHighlighted ? const Color(0xFF2A5867) : Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
