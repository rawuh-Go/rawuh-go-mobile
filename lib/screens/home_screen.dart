import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/attendance_screen.dart';
import '../screens/leave_screen.dart';
import '../screens/assignment_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/todo_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String officeName = "Loading...";
  String userName = "Loading...";
  String position = "Loading...";
  String userImage = "";
  String checkInTime = "-";
  String checkOutTime = "-";
  String assignmentTitle = "Loading...";
  String assignmentDescription = "Loading...";
  String assignmentStatus = "Loading...";
  String assignmentDueDate = "Loading...";
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchSchedule();
    fetchAttendance();
    fetchLatestAssignment();
  }

  Future<void> fetchLatestAssignment() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://presensi.amikomcenter.com/api/assignments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'].isNotEmpty) {
          final latestAssignment = data['data'][0];
          setState(() {
            assignmentTitle = latestAssignment['judul'];
            assignmentDescription = latestAssignment['deskripsi'];
            assignmentStatus = latestAssignment['status'];
            assignmentDueDate = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.parse(latestAssignment['tanggal_deadline']));
          });
        }
      }
    } catch (e) {
      print('Error fetching assignment: $e');
    }
  }

  Future<void> fetchAttendance() async {
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
        if (data['data'].isNotEmpty) {
          final today = DateTime.now();
          final attendanceData = data['data'].firstWhere((attendance) {
            final attendanceDate = DateTime.parse(attendance['created_at']);
            return attendanceDate.year == today.year &&
                attendanceDate.month == today.month &&
                attendanceDate.day == today.day;
          }, orElse: () => null);

          setState(() {
            checkInTime = attendanceData != null
                ? attendanceData['waktu_datang'] ?? '-'
                : '-';
            checkOutTime = attendanceData != null
                ? attendanceData['waktu_pulang'] ?? '-'
                : '-';
          });
        }
      }
    } catch (e) {
      print('Error fetching attendance: $e');
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
          setState(() {
            officeName = data['data'][0]['office']['nama'];
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
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                color: const Color(0xFF212A2E),
              ),
              Expanded(child: Container(color: Colors.white)),
            ],
          ),
          Column(
            children: [
              // Static Top Section
              Container(
                color: Colors.transparent,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    officeName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.white,
                                    child: Image.asset(
                                      'assets/img/main_page/company_logo.png',
                                      height: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: userImage.isNotEmpty
                                  ? NetworkImage(
                                      userImage.replaceAll(
                                        '127.0.0.1',
                                        '10.0.2.2',
                                      ),
                                    )
                                  : const AssetImage(
                                      'assets/img/main_page/absen.jpg',
                                    ) as ImageProvider,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    position,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A5867),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, d MMMM yyyy',
                              ).format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildTimeCard(
                                  'Check In',
                                  'assets/img/main_page/checkin.png',
                                  checkInTime,
                                ),
                                _buildTimeCard(
                                  'Check Out',
                                  'assets/img/main_page/checkout.png',
                                  checkOutTime,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scrollable Bottom Section
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.only(top: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Office Services',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildServiceItem(
                                    'Attendance',
                                    'assets/img/main_page/attendance.png',
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AttendanceScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildServiceItem(
                                    'Leave',
                                    'assets/img/main_page/leave.png',
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LeaveScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildServiceItem(
                                    'Assignment',
                                    'assets/img/main_page/assigment.png',
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AssignmentScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildServiceItem(
                                    'Todo List',
                                    'assets/img/main_page/todo_list.png',
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TodoListScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/img/main_page/list.png',
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Assignment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildAssignmentCard(
                                title: assignmentTitle,
                                description: assignmentDescription,
                                status: assignmentStatus,
                                dueDate: assignmentDueDate,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String title, String imagePath, String time) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A5867).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                height: 20,
                color: const Color(0xFF2A5867),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A5867),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A5867).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(imagePath, height: 50, width: 50),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard({
    required String title,
    required String description,
    required String status,
    required String dueDate,
  }) {
    Color statusColor;
    Color statusBgColor;
    switch (status.toLowerCase()) {
      case 'done':
        statusColor = const Color(0xFF28A745);
        statusBgColor = const Color(0xFFE7F5EA);
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC3545);
        statusBgColor = const Color(0xFFFFE9E9);
        break;
      default:
        statusColor = const Color(0xFFFF9800);
        statusBgColor = const Color(0xFFFFF3E0);
    }

    if (title == "Loading..." || description == "Loading...") {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A5867).withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            'Not yet assignment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A5867).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A5867).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/img/main_page/calendar.png',
                  height: 16,
                  color: const Color(0xFF2A5867),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Due: $dueDate',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
