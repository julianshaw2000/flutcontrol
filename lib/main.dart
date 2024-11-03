import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(GateOpenerApp(cameras: cameras));
}

class GateOpenerApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const GateOpenerApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: GateOpenerScreen(cameras: cameras),
    );
  }
}

class GateOpenerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const GateOpenerScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _GateOpenerScreenState createState() => _GateOpenerScreenState();
}

class _GateOpenerScreenState extends State<GateOpenerScreen> {
  final String gateUrl = 'http://192.168.0.40/relay/0?turn=on&timer=5';
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _capturedImage;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;

  @override
  void dispose() {
    _cameraController?.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera(CameraLensDirection direction) async {
    final camera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection == direction,
      orElse: () => widget.cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _openGate() async {
    try {
      final response = await http.get(Uri.parse(gateUrl));
      if (response.statusCode == 200) {
        print('Gate opened successfully');
      } else {
        print('Failed to open gate: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showCameraDialog() async {
    await _initializeCamera(_cameraLensDirection);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Take Picture'),
          content: _isCameraInitialized
              ? AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                )
              : const Center(child: CircularProgressIndicator()),
          actions: [
            TextButton(
              onPressed: () async {
                if (_isCameraInitialized) {
                  try {
                    final image = await _cameraController!.takePicture();
                    setState(() {
                      _capturedImage = image;
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error capturing image: $e');
                  }
                }
              },
              child: const Text('Capture'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ).then((_) {
      _cameraController?.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
    });
  }

  void _saveGuestInfo() {
    if (_formKey.currentState?.validate() ?? false) {
      final String firstName = _firstNameController.text;
      final String lastName = _lastNameController.text;
      final String apartment = _apartmentController.text;
      final String? picturePath = _capturedImage?.path;

      // Replace with actual save logic, if any
      print('Guest Info Saved:');
      print('First Name: $firstName');
      print('Last Name: $lastName');
      print('Apartment: $apartment');
      print('Picture Path: $picturePath');

      // Clear the fields, image, and validation messages after saving
      setState(() {
        _formKey.currentState?.reset();
        _firstNameController.clear();
        _lastNameController.clear();
        _apartmentController.clear();
        _capturedImage = null;
      });
    }
  }

  bool _isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding:
                const EdgeInsets.all(16.0), // Add margin around the container
            child: Container(
              color: Colors.lightBlue[100],
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: _openGate,
                  child: const Text('Open Gate'),
                ),
              ),
            ),
          ),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) {
                    return value == null || value.isEmpty
                        ? 'First name is required'
                        : null;
                  },
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) {
                    return value == null || value.isEmpty
                        ? 'Last name is required'
                        : null;
                  },
                ),
                TextFormField(
                  controller: _apartmentController,
                  decoration:
                      const InputDecoration(labelText: 'Apartment Number'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    return value == null || value.isEmpty
                        ? 'Apartment number is required'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                if (_capturedImage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Image.file(
                        File(_capturedImage!.path),
                        width: 150, // Smaller width for the image
                        fit: BoxFit
                            .contain, // Maintain aspect ratio within the width
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _showCameraDialog,
                      child: const Text('Take Picture'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isFormValid() ? _saveGuestInfo : null,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
