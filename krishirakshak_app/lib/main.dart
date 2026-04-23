import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const KrishiRakshakApp());
}

class KrishiRakshakApp extends StatelessWidget {
  const KrishiRakshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KrishiRakshak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;
  final ImagePicker _picker = ImagePicker();

  // ⚠️ Replace with your laptop's IP address
  final String apiUrl = 'https://lily-coyness-caramel.ngrok-free.dev/predict';

  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo == null) return;
    setState(() {
      _image = File(photo.path);
      _result = null;
    });
    await _predict();
  }

  Future<void> _predict() async {
    if (_image == null) return;
    setState(() => _loading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      var response = await request.send();
      var body = await response.stream.bytesToString();
      setState(() {
        _result = json.decode(body);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = {'error': 'Could not connect to server. Make sure Flask is running.'};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('🌿 KrishiRakshak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('AI Crop Disease Detector', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green)),
            const SizedBox(height: 20),

            // Image display
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: _image == null
                  ? const Center(child: Text('No image selected', style: TextStyle(color: Colors.grey)))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Loading
            if (_loading)
              const Column(
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 12),
                  Text('Analyzing leaf...'),
                ],
              ),

            // Result
            if (_result != null && !_loading) ...[
              if (_result!.containsKey('error'))
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                  child: Text(_result!['error'], style: const TextStyle(color: Colors.red)),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _result!['is_healthy'] ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _result!['is_healthy'] ? Colors.green : Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_result!['is_healthy'] ? Icons.check_circle : Icons.warning,
                              color: _result!['is_healthy'] ? Colors.green : Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _result!['disease'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Confidence: ${_result!['confidence']}%',
                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const Divider(height: 20),
                      const Text('Treatment Advice:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_result!['treatment'], style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}