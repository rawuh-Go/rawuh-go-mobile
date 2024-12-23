import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rawuh_go_mobil/screens/camera_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  MapController mapController = MapController();
  Position? currentPosition;
  LatLng? officeLocation;
  DateTime? shiftStart;
  DateTime? shiftEnd;
  double officeRadius = 100;
  bool isWfa = false;
  final storage = const FlutterSecureStorage();
  bool isWithinRadius = false;
  bool isLocationChecked = false;
  bool hasCheckedIn = false;
  bool isNonWorkingDay = false;
  Map<String, dynamic>? currentAttendance;
  List<dynamic> holidays = [];
  List<dynamic> leaves = [];

  @override
  void initState() {
    super.initState();
    checkDayStatus();
    mapController = MapController();
  }

  Future<void> checkDayStatus() async {
    await Future.wait([
      fetchHolidays(),
      fetchLeaves(),
    ]);

    final today = DateTime.now();
    String message = '';

    // Check non-working days
    if (today.weekday == DateTime.sunday) {
      message = 'Today is Sunday (Weekend)';
      isNonWorkingDay = true;
    }

    for (var holiday in holidays) {
      final holidayDate = DateTime.parse(holiday['tanggal_mulai']);
      if (isSameDay(today, holidayDate)) {
        message = 'Today is a Holiday: ${holiday['description']}';
        isNonWorkingDay = true;
        break;
      }
    }

    for (var leave in leaves) {
      if (leave['status'].toLowerCase() == 'approve') {
        final startDate = DateTime.parse(leave['tanggal_mulai']);
        final endDate = DateTime.parse(leave['tanggal_selesai']);
        final today = DateTime.now();

        // Convert dates to local time for accurate comparison
        if (today.isAfter(startDate.subtract(const Duration(days: 1))) &&
            today.isBefore(endDate.add(const Duration(days: 1)))) {
          message = 'You are currently on approved leave';
          isNonWorkingDay = true;
          break;
        }
      }
    }

    if (message.isNotEmpty && mounted) {
      showStatusDialog(message);
    }

    // Always load office data for display
    await fetchOfficeData();
    await checkTodayAttendance();
  }

  void showStatusDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A5867).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    size: 40,
                    color: const Color(0xFF2A5867),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Notice',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A5867),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A5867),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Understood',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchHolidays() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('https://presensi.amikomcenter.com/api/holidays'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        holidays = data['data'];
      }
    } catch (e) {
      print('Error fetching holidays: $e');
    }
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
        leaves = data['data'];
      }
    } catch (e) {
      print('Error fetching leaves: $e');
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAtSameMomentAs(start) ||
        date.isAtSameMomentAs(end) ||
        (date.isAfter(start) && date.isBefore(end));
  }

  Future<void> checkTodayAttendance() async {
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
        final data = jsonDecode(response.body)['data'];
        if (data.isNotEmpty) {
          final today = DateTime.now();
          final latestAttendance = data.first;
          final attendanceDate = DateTime.parse(latestAttendance['created_at']);

          if (today.year == attendanceDate.year &&
              today.month == attendanceDate.month &&
              today.day == attendanceDate.day) {
            setState(() {
              hasCheckedIn = true;
              currentAttendance = latestAttendance;
            });
          }
        }
      }
    } catch (e) {
      print('Error checking attendance: $e');
    }
  }

  Future<void> fetchOfficeData() async {
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
        final data = jsonDecode(response.body)['data'][0];

        // Parse shift times
        final today = DateTime.now();
        final startTime = data['shift']['waktu_datang'].split(':');
        final endTime = data['shift']['waktu_pulang'].split(':');

        shiftStart = DateTime(
          today.year,
          today.month,
          today.day,
          int.parse(startTime[0]),
          int.parse(startTime[1]),
        );

        shiftEnd = DateTime(
          today.year,
          today.month,
          today.day,
          int.parse(endTime[0]),
          int.parse(endTime[1]),
        );

        setState(() {
          officeLocation = LatLng(
            data['office']['latitude'],
            data['office']['longitude'],
          );
          officeRadius = data['office']['radius'].toDouble();
          isWfa = data['is_wfa'];
        });
        mapController.move(officeLocation!, 18);
      }
    } catch (e) {
      print('Error fetching office data: $e');
    }
  }

  bool isWithinAllowedTimeRange() {
    if (shiftStart == null || shiftEnd == null) return false;

    final now = DateTime.now();
    final checkInStart = shiftStart!.subtract(const Duration(minutes: 30));
    final checkInEnd = shiftStart!.add(const Duration(minutes: 30));
    final checkOutStart = shiftEnd!.subtract(const Duration(minutes: 30));
    final checkOutEnd = shiftEnd!.add(const Duration(minutes: 30));

    if (!hasCheckedIn) {
      // Check-in time validation
      return now.isAfter(checkInStart) && now.isBefore(checkInEnd);
    } else {
      // Check-out time validation
      return now.isAfter(checkOutStart) && now.isBefore(checkOutEnd);
    }
  }

  String getTimeValidationMessage() {
    if (shiftStart == null || shiftEnd == null) return '';

    if (currentAttendance != null &&
        currentAttendance!['waktu_pulang'] != null) {
      return 'You have completed your attendance for today';
    }

    final checkInStart = shiftStart!.subtract(const Duration(minutes: 30));
    final checkInEnd = shiftStart!.add(const Duration(minutes: 30));
    final checkOutStart = shiftEnd!.subtract(const Duration(minutes: 30));
    final checkOutEnd = shiftEnd!.add(const Duration(minutes: 30));

    if (!hasCheckedIn) {
      return 'Check-in available from ${_formatTime(checkInStart)} to ${_formatTime(checkInEnd)}';
    } else {
      return 'Check-out available from ${_formatTime(checkOutStart)} to ${_formatTime(checkOutEnd)}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permissions are permanently denied. Please enable in app settings.')),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Getting precise location...'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 170,
            right: 20,
            left: 20,
          ),
        ),
      );

      // Configure location settings for maximum accuracy
      LocationSettings locationSettings = AndroidSettings(
        accuracy:
            LocationAccuracy.bestForNavigation, // Highest possible accuracy
        distanceFilter: 0, // Notify on any movement
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 1), // Frequent updates
      );

      // Get initial high-accuracy position
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit:
            const Duration(seconds: 10), // Longer timeout for initial position
      );

      StreamSubscription<Position>? positionStreamSubscription;

      // Start listening to location updates
      positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (_isPositionAccurate(position)) {
          setState(() {
            currentPosition = position;
            isLocationChecked = true;

            if (officeLocation != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                officeLocation!.latitude,
                officeLocation!.longitude,
              );
              isWithinRadius = isWfa || distanceInMeters <= officeRadius;

              // Show WFA message
              if (isWfa) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Anda WFA bisa bekerja dimana saja',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF2A5867),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 170,
                      right: 20,
                      left: 20,
                    ),
                  ),
                );
              }
            }
          });
        }

        // Validate the position
        if (_isPositionAccurate(position)) {
          setState(() {
            currentPosition = position;
            isLocationChecked = true;

            // Calculate distance to office
            if (officeLocation != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                officeLocation!.latitude,
                officeLocation!.longitude,
              );
              isWithinRadius = isWfa || distanceInMeters <= officeRadius;
            }
          });

          // Update map
          mapController.move(
            LatLng(position.latitude, position.longitude),
            18,
          );

          // Cancel the stream subscription after getting an accurate position
          positionStreamSubscription?.cancel();
        }
      }, onError: (error) {
        print('Location tracking error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get precise location')),
        );
        // Cancel subscription in case of error
        positionStreamSubscription?.cancel();
      });
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location error. Please try again in an open area')),
      );
    }
  }

// Helper method to validate position accuracy
  bool _isPositionAccurate(Position position) {
    // Check multiple accuracy criteria
    return position.accuracy <=
            20 && // Very precise location (20 meters or less)
        position.speedAccuracy <= 5 && // Low speed variance
        position.speed >= 0; // Valid speed reading
  }

  void _showOutOfRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Out of Range',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Please move closer to the office to take attendance.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: const Color(0xFF2A5867)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> submitAttendance(String imagePath, [String? logbook]) async {
    try {
      final token = await storage.read(key: 'token');
      final uri = hasCheckedIn
          ? 'https://presensi.amikomcenter.com/api/attendances/clock-out'
          : 'https://presensi.amikomcenter.com/api/attendances';

      var request = http.MultipartRequest('POST', Uri.parse(uri));
      request.headers['Authorization'] = 'Bearer $token';

      // Add location data
      if (hasCheckedIn) {
        request.fields['pulang_latitude'] =
            currentPosition!.latitude.toString();
        request.fields['pulang_longitude'] =
            currentPosition!.longitude.toString();
        request.fields['logbook'] = logbook ?? '';
        request.files.add(
          await http.MultipartFile.fromPath('foto_absen_pulang', imagePath),
        );
      } else {
        request.fields['datang_latitude'] =
            currentPosition!.latitude.toString();
        request.fields['datang_longitude'] =
            currentPosition!.longitude.toString();
        request.files.add(
          await http.MultipartFile.fromPath('foto_absen_datang', imagePath),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          hasCheckedIn = !hasCheckedIn;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasCheckedIn ? 'Check-in successful' : 'Check-Out successful',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(responseBody);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Presensi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A5867),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: officeLocation ??
                  const LatLng(-6.8702582554142, 108.89511543608),
              initialZoom: 18,
              interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: true,
                enableScrollWheel: true,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              if (isLocationChecked)
                CircleLayer(
                  circles: officeLocation != null
                      ? [
                          CircleMarker(
                            point: officeLocation!,
                            radius: officeRadius,
                            useRadiusInMeter: true,
                            color: const Color(0xFF2A5867).withOpacity(0.2),
                            borderColor: const Color(0xFF2A5867),
                            borderStrokeWidth: 2,
                          ),
                        ]
                      : [],
                ),
              MarkerLayer(
                markers: [
                  if (officeLocation != null)
                    Marker(
                      point: officeLocation!,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF2A5867),
                        size: 40,
                      ),
                    ),
                  if (currentPosition != null && isLocationChecked)
                    Marker(
                      point: LatLng(
                        currentPosition!.latitude,
                        currentPosition!.longitude,
                      ),
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (hasCheckedIn && currentAttendance != null)
            Positioned(
              top: 16, // Position right below AppBar
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Check In',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currentAttendance!['waktu_datang'] ?? '-',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Column(
                      children: [
                        Text(
                          'Check Out',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currentAttendance!['waktu_pulang'] ?? '-',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 20,
            bottom: 150,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  backgroundColor: const Color(0xFF2A5867),
                  onPressed: () {
                    final newZoom = mapController.zoom + 1;
                    mapController.move(mapController.center, newZoom);
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  backgroundColor: const Color(0xFF2A5867),
                  onPressed: () {
                    final newZoom = mapController.zoom - 1;
                    mapController.move(mapController.center, newZoom);
                  },
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (isNonWorkingDay) {
                      return; // Disable button on non-working days
                    }

                    if (currentAttendance != null &&
                        currentAttendance!['waktu_pulang'] != null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Attendance Complete',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            'You have completed your attendance for today',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'OK',
                                style: GoogleFonts.poppins(
                                    color: const Color(0xFF2A5867)),
                              ),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    if (currentAttendance != null &&
                        currentAttendance!['waktu_pulang'] != null) {
                      return;
                    }

                    if (!isWithinAllowedTimeRange()) {
                      return;
                    }

                    if (!isLocationChecked) {
                      _getCurrentLocation();
                    } else if (isWithinRadius) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(
                            isCheckOut: hasCheckedIn,
                          ),
                        ),
                      );
                      if (result != null) {
                        await submitAttendance(
                          result['imagePath'],
                          result['logbook'],
                        );
                      }
                    } else {
                      _showOutOfRangeDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A5867),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF2A5867).withOpacity(0.5),
                  ),
                  child: Container(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          !isLocationChecked
                              ? Icons.location_searching
                              : (isWithinRadius
                                  ? (hasCheckedIn ? Icons.logout : Icons.login)
                                  : Icons.location_off),
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          !isLocationChecked
                              ? 'Get Location'
                              : (isWithinRadius
                                  ? (hasCheckedIn ? 'Check Out' : 'Check In')
                                  : 'Check Location'),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    getTimeValidationMessage(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
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
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF2A5867),
          ),
        ),
      ],
    );
  }
}
