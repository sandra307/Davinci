import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class FaceSwapScreen extends StatefulWidget {
  @override
  _FaceSwapScreenState createState() => _FaceSwapScreenState();
}

class _FaceSwapScreenState extends State<FaceSwapScreen> {
  File? _sourceImage;
  File? _croppedImage;
  final ImagePicker _picker = ImagePicker();
  Offset _position = const Offset(100, 100);
  double _scale = 1.0;
  double _rotation = 0.0;
  bool _isLoading = false; // Add loading state

  // List of Da Vinci paintings
  final List<String> _paintings = [
    'assets/leo_da1.jpg',
    'assets/leo_da2.jpg',
    'assets/leo_da3.jpg',
  ];
  String _selectedPainting = 'assets/leo_da2.jpg';

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
     
      if (image != null) {
        // Debug print
        print('Image picked: ${image.path}');
        
        setState(() {
          _sourceImage = File(image.path);
        });
        
        // Show feedback
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected, preparing to crop...')),
        );
        
        await _cropImage();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
 
  Future<void> _cropImage() async {
    if (_sourceImage == null) {
      print('Source image is null');
      return;
    }

    try {
      // Debug print
      print('Starting crop with source image: ${_sourceImage!.path}');
      print('Source image exists: ${await _sourceImage!.exists()}');

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _sourceImage!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Face',
            toolbarColor: Colors.brown,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Face',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        // Debug print
        print('Image cropped: ${croppedFile.path}');
        
        // Verify the cropped file exists
        final croppedImageFile = File(croppedFile.path);
        final exists = await croppedImageFile.exists();
        print('Cropped image exists: $exists');

        if (mounted) {
          setState(() {
            _croppedImage = croppedImageFile;
            // Center the image on the screen
            _position = Offset(
              MediaQuery.of(context).size.width / 2 - 50,
              MediaQuery.of(context).size.height / 3 - 50,
            );
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image cropped successfully')),
          );
        }
      } else {
        print('Crop cancelled by user');
      }
    } catch (e) {
      print('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Da Vinci Face Swap')),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Background painting
                    Image.asset(
                      _selectedPainting,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                    if (_croppedImage != null)
                      Positioned(
                        left: _position.dx,
                        top: _position.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _position += details.delta;
                            });
                          },
                          child: Transform.rotate(
                            angle: _rotation,
                            child: Transform.scale(
                              scale: _scale,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: FileImage(_croppedImage!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Your existing painting selection and controls code...
                    // (keeping the rest of the code the same for brevity)
                  ],
                ),
              ),
            ],
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
