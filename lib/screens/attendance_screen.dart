import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> attendances = [];
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchAttendances();
  }

  Future<void> fetchAttendances() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://presensi.amikomcenter.com/api/attendances'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          attendances = data['data'];
        });
      }
    } catch (e) {
      print('Error fetching attendances: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Attendance',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A5867),
        centerTitle: true,
        elevation: 0,
      ),
      body: attendances.isEmpty
          ? Center(
              child: Text(
                'Not yet attendance data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: attendances.length,
              itemBuilder: (context, index) {
                final attendance = attendances[index];
                return _buildAttendanceCard(
                  date: DateTime.parse(attendance['created_at']),
                  checkIn: attendance['waktu_datang'] ?? '-',
                  checkOut: attendance['waktu_pulang'] ?? '-',
                  status: _determineStatus(attendance),
                );
              },
            ),
    );
  }

  String _determineStatus(dynamic attendance) {
    if (attendance['waktu_datang'] == null) {
      return 'Alfa';
    } else if (attendance['waktu_pulang'] == null) {
      return 'Tidak Checkout';
    }
    return 'Hadir';
  }

  Widget _buildAttendanceCard({
    required DateTime date,
    required String checkIn,
    required String checkOut,
    required String status,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'hadir':
        statusColor = Colors.green;
        break;
      case 'cuti':
        statusColor = Colors.orange;
        break;
      case 'alfa':
        statusColor = Colors.red;
        break;
      case 'tidak checkout':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A5867),
                      ),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy').format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTimeColumn('Check In', checkIn)),
              Container(height: 40, width: 1, color: Colors.grey[300]),
              Expanded(child: _buildTimeColumn('Check Out', checkOut)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2A5867),
          ),
        ),
      ],
    );
  }
}
