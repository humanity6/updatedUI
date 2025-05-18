import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camerakit_flutter/camerakit_flutter.dart';
import 'package:camerakit_flutter/lens_model.dart';
import 'package:video_player/video_player.dart';
import '../models/constants.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  _TryOnScreenState createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> implements CameraKitFlutterEvents {
  late final CameraKitFlutterImpl _cameraKitFlutterImpl;
  String _filePath = '';
  String _fileType = '';
  List<Lens> _lenses = [];
  bool _isLoading = true;
  Lens? _selectedLens;
  bool _showMediaPreview = false;
  late VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = null;
    _cameraKitFlutterImpl = CameraKitFlutterImpl(cameraKitFlutterEvents: this);
    _loadLenses();
  }

  void _loadLenses() {
    setState(() {
      _isLoading = true;
    });
    _cameraKitFlutterImpl.getGroupLenses(
      groupIds: Constants.groupIdList,
    );
  }

  void _openCameraKit({String? lensId, String? groupId}) {
    setState(() {
      _showMediaPreview = false;
    });
    
    if (lensId != null && groupId != null) {
      _cameraKitFlutterImpl.openCameraKitWithSingleLens(
        lensId: lensId,
        groupId: groupId,
        isHideCloseButton: false,
      );
    } else {
      _cameraKitFlutterImpl.openCameraKit(
        groupIds: Constants.groupIdList,
        isHideCloseButton: false,
      );
    }
  }

  void _selectLens(Lens lens) {
    setState(() {
      _selectedLens = lens;
    });
    
    if (lens.id != null && lens.groupId != null) {
      _openCameraKit(lensId: lens.id!, groupId: lens.groupId!);
    }
  }

  void _setupVideoController() {
    if (_fileType == 'video' && _filePath.isNotEmpty) {
      _videoController = VideoPlayerController.file(File(_filePath))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SafeArea(
            child: Stack(
              children: [
                // Main content - camera preview or media preview
                _showMediaPreview
                  ? _buildMediaPreviewFullScreen()
                  : _buildCameraPlaceholder(),
                
                // Top controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          _showMediaPreview ? 'Preview' : 'Try On',
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 18
                          ),
                        ),
                        _showMediaPreview
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _showMediaPreview = false;
                                  if (_videoController != null && _videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  }
                                });
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.flash_on, color: Colors.white),
                              onPressed: () {
                                // Toggle flash - would normally be implemented with CameraKit
                              },
                            ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom lens carousel
                if (!_showMediaPreview)
                Positioned(
                  bottom: 90,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 110,
                    child: _lenses.isNotEmpty
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _lenses.length,
                          itemBuilder: (context, index) {
                            final lens = _lenses[index];
                            final isSelected = _selectedLens?.id == lens.id;
                            return _buildLensItem(lens, isSelected);
                          },
                        )
                      : const Center(
                          child: Text(
                            'No lenses available',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                  ),
                ),
                
                // Capture button
                if (!_showMediaPreview)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_lenses.isEmpty) {
                            _openCameraKit();
                          } else if (_selectedLens != null && _selectedLens!.id != null && _selectedLens!.groupId != null) {
                            _openCameraKit(lensId: _selectedLens!.id!, groupId: _selectedLens!.groupId!);
                          } else if (_lenses.isNotEmpty && _lenses[0].id != null && _lenses[0].groupId != null) {
                            _openCameraKit(lensId: _lenses[0].id!, groupId: _lenses[0].groupId!);
                          } else {
                            _openCameraKit();
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Media controls for video playback
                if (_showMediaPreview && _fileType == 'video')
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        onPressed: () {
                          if (_videoController != null) {
                            setState(() {
                              _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                            });
                          }
                        },
                        child: Icon(
                          _videoController?.value.isPlaying ?? false
                            ? Icons.pause
                            : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
  
  Widget _buildCameraPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Tap the button below to\nopen the camera with lenses',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildLensItem(Lens lens, bool isSelected) {
    final thumbnail = lens.thumbnail?.isNotEmpty == true ? lens.thumbnail![0] : '';
    
    return GestureDetector(
      onTap: () => _selectLens(lens),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade800,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnail.isNotEmpty
                  ? Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error, color: Colors.white)
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.blur_circular, color: Colors.white)
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lens.name ?? 'Lens',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreviewFullScreen() {
    if (_fileType == 'video') {
      if (_videoController == null) {
        _setupVideoController();
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }
      
      if (!(_videoController?.value.isInitialized ?? false)) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }
      
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }
    
    return _filePath.isNotEmpty
        ? Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.file(
              File(_filePath),
              fit: BoxFit.contain,
            ),
          )
        : const Center(
            child: Text(
              'No media available',
              style: TextStyle(color: Colors.white),
            ),
          );
  }

  // CameraKitFlutterEvents implementation
  @override
  void onCameraKitError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $errorMessage')),
    );
  }

  @override
  void onCameraKitResult(Map<dynamic, dynamic> result) {
    setState(() {
      _filePath = result["path"] as String;
      _fileType = result["type"] as String;
      _showMediaPreview = true;
      
      if (_fileType == 'video') {
        _videoController = null; // Reset so we can create a new one
        _setupVideoController();
      }
    });
  }

  @override
  void receivedLenses(List<Lens> lensList) {
    setState(() {
      _lenses = lensList;
      _isLoading = false;
      
      if (_lenses.isNotEmpty) {
        _selectedLens = _lenses[0]; // Select the first lens by default
      }
    });
    
    if (_lenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No lenses found. Check your group IDs and credentials.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_videoController != null) {
      _videoController!.dispose();
    }
    super.dispose();
  }
}