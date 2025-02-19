// lib/screens/tryon_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  _TryOnScreenState createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  CameraController? _controller;
  int _selectedFilter = 0;
  final List<String> _filters = ['Classic', 'Modern', 'Trendy', 'Casual'];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Try On Hairstyles'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller!),
          ),
          Container(
            height: 100,
            color: Colors.black87,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = index;
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedFilter == index
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.face,
                          color: Colors.white,
                        ),
                        Text(
                          _filters[index],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
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