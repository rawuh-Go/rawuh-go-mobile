import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<dynamic> notifications = [];
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    fetchNotifications();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'rawuh_go_mobile_channel',
      'Rawuh Go Mobile Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> fetchNotifications() async {
    try {
      final token = await storage.read(key: 'token');

      // Fetch assignments
      final assignmentsResponse = await http.get(
        Uri.parse('https://presensi.amikomcenter.com/api/assignments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Fetch leaves
      final leavesResponse = await http.get(
        Uri.parse('https://presensi.amikomcenter.com/api/leaves'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (assignmentsResponse.statusCode == 200 &&
          leavesResponse.statusCode == 200) {
        final assignmentsData = jsonDecode(assignmentsResponse.body)['data'];
        final leavesData = jsonDecode(leavesResponse.body)['data'];

        // Get last notification timestamp from storage
        final lastNotificationTime =
            await storage.read(key: 'last_notification_time');
        final lastDateTime = lastNotificationTime != null
            ? DateTime.parse(lastNotificationTime)
            : DateTime.now().subtract(const Duration(days: 1));

        // Process new notifications
        for (var assignment in assignmentsData) {
          final updateTime = DateTime.parse(assignment['updated_at']);
          if (updateTime.isAfter(lastDateTime)) {
            showNotification('Assignment Update',
                'Assignment "${assignment['judul']}" has been updated');
          }
        }

        for (var leave in leavesData) {
          final updateTime = DateTime.parse(leave['updated_at']);
          if (updateTime.isAfter(lastDateTime)) {
            showNotification('Leave Update',
                'Leave request "${leave['type_leave']}" status has been updated');
          }
        }

        // Save current timestamp
        await storage.write(
            key: 'last_notification_time',
            value: DateTime.now().toIso8601String());

        // Combine and sort notifications
        List<Map<String, dynamic>> combinedNotifications = [];

        // Process assignments
        for (var assignment in assignmentsData) {
          combinedNotifications.add({
            'type': 'assignment',
            'title': assignment['judul'],
            'status': assignment['status'],
            'date': DateTime.parse(assignment['updated_at']),
            'feedback': assignment['feedback'],
          });
        }

        // Process leaves
        for (var leave in leavesData) {
          combinedNotifications.add({
            'type': 'leave',
            'title': leave['type_leave'],
            'status': leave['status'],
            'date': DateTime.parse(leave['updated_at']),
            'note': leave['catatan'],
          });
        }

        // Sort by date, most recent first
        combinedNotifications.sort((a, b) => b['date'].compareTo(a['date']));

        setState(() {
          notifications = combinedNotifications;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A5867),
        centerTitle: true,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'Not yet notification',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(
                  type: notification['type'],
                  title: notification['title'],
                  status: notification['status'],
                  date: notification['date'],
                  feedback: notification['feedback'],
                  note: notification['note'],
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard({
    required String type,
    required String title,
    required String status,
    required DateTime date,
    String? feedback,
    String? note,
  }) {
    IconData icon;
    Color iconColor;
    String message;

    // Configure notification appearance based on type and status
    if (type == 'assignment') {
      icon = Icons.assignment;
      switch (status.toLowerCase()) {
        case 'done':
          iconColor = Colors.green;
          message = 'Assignment "$title" has been approved';
          break;
        case 'reject':
          iconColor = Colors.red;
          message = 'Assignment "$title" needs revision';
          break;
        default:
          iconColor = Colors.orange;
          message = 'New assignment: "$title"';
      }
    } else {
      icon = Icons.event_available;
      switch (status.toLowerCase()) {
        case 'approve':
          iconColor = Colors.green;
          message = 'Leave request "$title" has been approved';
          break;
        case 'rejected':
          iconColor = Colors.red;
          message = 'Leave request "$title" has been rejected';
          break;
        default:
          iconColor = Colors.orange;
          message = 'Leave request "$title" is pending';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'assignment' ? 'Assignment Update' : 'Leave Update',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A5867),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (feedback != null || note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      feedback ?? note ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
