import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  final bool isCheckOut;
  const CameraScreen({super.key, this.isCheckOut = false});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  String? _imagePath;
  TextEditingController logbookController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      final image = await _controller!.takePicture();
      setState(() {
        _imagePath = image.path;
      });
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A5867),
        title:
            Text('Take Photo', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _imagePath == null
                ? CameraPreview(_controller!)
                : Image.file(File(_imagePath!)),
          ),
          if (widget.isCheckOut && _imagePath != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: logbookController,
                decoration: const InputDecoration(
                  hintText: 'Enter your logbook...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_imagePath == null)
                  ElevatedButton(
                    onPressed: _takePicture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A5867),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text('Take Photo',
                        style: GoogleFonts.poppins(color: Colors.white)),
                  )
                else ...[
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _imagePath = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text('Retake',
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.isCheckOut &&
                          logbookController.text.trim().isEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Logbook Required',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              'Please fill in your work description for today',
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
                      Navigator.pop(context, {
                        'imagePath': _imagePath,
                        'logbook':
                            widget.isCheckOut ? logbookController.text : null,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A5867),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text('Submit',
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
