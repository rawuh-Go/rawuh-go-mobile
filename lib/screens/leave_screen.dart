import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../screens/create_leave_screen.dart';
import '../screens/edit_leave_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<dynamic> leaves = [];
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchLeaves();
  }

  Future<void> fetchLeaves() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://presensi.amikomcenter.com/api/leaves'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          leaves = data['data'];
        });
      }
    } catch (e) {
      print('Error fetching leaves: $e');
    }
  }

  void _showAttachment(String attachment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          child: Image.network(
            'https://presensi.amikomcenter.com/storage/$attachment',
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Text('Error loading image'));
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Leave',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A5867),
        centerTitle: true,
        elevation: 0,
      ),
      body: leaves.isEmpty
          ? Center(
              child: Text(
                'Not yet leave data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                final leave = leaves[index];
                final startDate = DateTime.parse(leave['tanggal_mulai']);
                final endDate = DateTime.parse(leave['tanggal_selesai']);

                return _buildLeaveCard(
                  leave: leave,
                  submissionDate: DateTime.parse(leave['created_at']),
                  reason: leave['type_leave'],
                  description: leave['reason'],
                  leaveDate:
                      '${DateFormat('d').format(startDate)}-${DateFormat('d MMM yyyy').format(endDate)}',
                  status: leave['status'],
                  attachment: leave['attachment'],
                  approvedBy: leave['approved_by'],
                  catatan: leave['catatan'],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateLeaveScreen()),
          );
          if (result == true) {
            fetchLeaves();
          }
        },
        backgroundColor: const Color(0xFF2A5867),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLeaveCard({
    required Map<String, dynamic> leave,
    required DateTime submissionDate,
    required String reason,
    required String description,
    required String leaveDate,
    required String status,
    required String attachment,
    String? approvedBy,
    String? catatan,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submitted on ${DateFormat('d MMMM yyyy').format(submissionDate)}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A5867),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          if (status.toLowerCase() == 'approve' && approvedBy != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Approved by: $approvedBy',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF28A745),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (catatan != null && catatan.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Note: $catatan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                leaveDate,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showAttachment(attachment),
                  icon: const Icon(Icons.attachment, size: 20),
                  label: Text(
                    'View Attachment',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2A5867),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF2A5867)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (status.toLowerCase() == 'pending')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditLeaveScreen(
                              leaveId: leave['id'].toString(),
                              currentStartDate:
                                  DateTime.parse(leave['tanggal_mulai']),
                              currentEndDate:
                                  DateTime.parse(leave['tanggal_selesai']),
                              currentType: leave['type_leave'],
                              currentReason: leave['reason'],
                              currentAttachment: leave['attachment'],
                            ),
                          ),
                        ).then((value) {
                          if (value == true) {
                            fetchLeaves();
                          }
                        });
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(
                        'Edit Leave',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF2A5867),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2A5867)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

Widget _buildStatusBadge(String status) {
  Color backgroundColor;
  Color textColor;

  switch (status.toLowerCase()) {
    case 'approve':
      backgroundColor = const Color(0xFFE7F5EA);
      textColor = const Color(0xFF28A745);
      break;
    case 'rejected':
      backgroundColor = const Color(0xFFFFE9E9);
      textColor = const Color(0xFFDC3545);
      break;
    default:
      backgroundColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFFF9800);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
  );
}
