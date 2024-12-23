import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  List<dynamic> assignments = [];
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
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
        setState(() {
          assignments = data['data'];
        });
      }
    } catch (e) {
      print('Error fetching assignments: $e');
    }
  }

  Future<void> _openReport(String? fileUrl, String? linkUrl) async {
    final url = Uri.parse(
        (fileUrl ?? linkUrl ?? '').replaceAll('127.0.0.1', '10.0.2.2'));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitReport(int assignmentId, String description, String? link,
      PlatformFile? file) async {
    try {
      final token = await storage.read(key: 'token');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://presensi.amikomcenter.com/api/assignments/$assignmentId/submit'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['laporan'] = description;
      if (link != null && link.isNotEmpty) {
        request.fields['link_laporan'] = link;
      }

      if (file != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file_laporan',
              file.bytes!,
              filename: file.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file_laporan',
              file.path!,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        fetchAssignments(); // Refresh the assignments list
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report submitted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to submit report: ${response.body}');
      }
    } catch (e) {
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit report: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitRevision(int assignmentId, String description,
      String? link, PlatformFile? file) async {
    try {
      final token = await storage.read(key: 'token');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://presensi.amikomcenter.com/api/assignments/$assignmentId/revise'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['laporan'] = description;
      if (link != null && link.isNotEmpty) {
        request.fields['link_laporan'] = link;
      }

      if (file != null) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file_laporan',
              file.bytes!,
              filename: file.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file_laporan',
              file.path!,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        fetchAssignments(); // Refresh the assignments list
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Revision submitted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to submit revision: ${response.body}');
      }
    } catch (e) {
      print('Error submitting revision: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit revision: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAssignmentDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assignment Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A5867),
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow('Title', data['judul']),
                _detailRow('Project Type', data['jenis_project']),
                _detailRow('Description', data['deskripsi']),
                _detailRow(
                  'Deadline',
                  DateFormat('yyyy-MM-dd HH:mm')
                      .format(DateTime.parse(data['tanggal_deadline'])),
                ),
                _detailRow('Status', data['status']),
                if (data['feedback'] != null)
                  _detailRow('Feedback', data['feedback']),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A5867),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubmitReport(int assignmentId, String status) {
    final descController = TextEditingController();
    final linkController = TextEditingController();
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status.toLowerCase() == 'reject'
                        ? 'Submit Revision'
                        : 'Submit Report',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A5867),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose one of the following options:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2A5867),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Link',
                      hintText: 'Enter URL or choose file below',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'OR',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          selectedFile?.name ?? 'Upload your document',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Supported formats: PDF, PNG, JPG, JPEG',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                            );
                            if (result != null) {
                              setState(() {
                                selectedFile = result.files.first;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2A5867),
                            side: const BorderSide(color: Color(0xFF2A5867)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Choose File',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2A5867),
                            side: const BorderSide(color: Color(0xFF2A5867)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Cancel', style: GoogleFonts.poppins()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (descController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Please enter a description')),
                              );
                              return;
                            }

                            if (linkController.text.isEmpty &&
                                selectedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Please provide either a link or file')),
                              );
                              return;
                            }

                            if (status.toLowerCase() == 'reject') {
                              _submitRevision(
                                assignmentId,
                                descController.text,
                                linkController.text.isEmpty
                                    ? null
                                    : linkController.text,
                                selectedFile,
                              );
                            } else {
                              _submitReport(
                                assignmentId,
                                descController.text,
                                linkController.text.isEmpty
                                    ? null
                                    : linkController.text,
                                selectedFile,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A5867),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            status.toLowerCase() == 'reject'
                                ? 'Submit Revision'
                                : 'Submit',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentCard({
    required String title,
    required String description,
    required String status,
    required String dueDate,
    required Map<String, dynamic> fullData,
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

    final submission = fullData['submission'];
    final bool isDone = status.toLowerCase() == 'done';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A5867),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Container(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: 150),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: Text(
                          'Due: $dueDate',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _showAssignmentDetails(fullData),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2A5867),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isDone && submission != null)
                      TextButton(
                        onPressed: () => _showReport(submission),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF28A745),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View Report',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (!isDone)
                      ElevatedButton(
                        onPressed: () =>
                            _showSubmitReport(fullData['id'], status),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A5867),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          status.toLowerCase() == 'reject'
                              ? 'Submit Revision'
                              : 'Submit',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showReport(Map<String, dynamic> submission) {
    if (submission['file_laporan'] != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: double.infinity,
            child: Image.network(
              submission['file_laporan']
                  .toString()
                  .replaceAll('127.0.0.1', '10.0.2.2'),
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
    } else if (submission['link_laporan'] != null) {
      launchUrl(
        Uri.parse(submission['link_laporan']),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Assignment',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A5867),
        centerTitle: true,
        elevation: 0,
      ),
      body: assignments.isEmpty
          ? Center(
              child: Text(
                'Not yet assignment data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return _buildAssignmentCard(
                  title: assignment['judul'],
                  description: assignment['deskripsi'],
                  status: assignment['status'],
                  dueDate: DateFormat('yyyy-MM-dd')
                      .format(DateTime.parse(assignment['tanggal_deadline'])),
                  fullData: assignment,
                );
              },
            ),
    );
  }
}
