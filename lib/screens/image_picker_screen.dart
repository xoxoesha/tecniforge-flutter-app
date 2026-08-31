import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// Lets the user capture a photo with the camera or choose one from the
// gallery. image_picker triggers Android's runtime permission prompt
// automatically the first time each is used; we just need to catch the
// case where the user denies it and show a clear message instead of
// crashing or silently doing nothing.
class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});
  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _statusMessage;
  bool _isError = false;

  static const _prefsKey = 'business_photo_path';

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_prefsKey);
    if (savedPath != null && await File(savedPath).exists()) {
      setState(() => _selectedImage = File(savedPath));
    }
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path);
  }

  Future<void> _clearSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _statusMessage = null;
      _isError = false;
    });
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) {
        setState(() => _statusMessage = 'No image selected.');
        return;
      }
      // image_picker's own path points into a temporary cache directory
      // that Android can clear at any time — copying it into the app's
      // permanent documents directory is what actually makes it stick
      // around, not just saving the raw picked path.
      final docsDir = await getApplicationDocumentsDirectory();
      final permanentPath = '${docsDir.path}/business_photo.jpg';
      final savedFile = await File(picked.path).copy(permanentPath);

      await _saveImagePath(savedFile.path);
      setState(() {
        _selectedImage = savedFile;
        _statusMessage = source == ImageSource.camera
            ? 'Photo captured and saved.'
            : 'Image selected and saved.';
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _statusMessage = 'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. '
            'Please check app permissions in your device Settings.';
      });
    }
  }

  Future<void> _removeImage() async {
    await _clearSavedImage();
    setState(() {
      _selectedImage = null;
      _statusMessage = 'Photo removed.';
      _isError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Business Photo', subtitle: 'Attach a photo of a receipt or product', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined, size: 48, color: Color(0xFFC4CAD6)),
                          SizedBox(height: 8),
                          Text('No image selected yet', style: TextStyle(color: AppTheme.slate, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(_isError ? Icons.error_outline : Icons.check_circle, size: 16, color: _isError ? AppTheme.errorRed : AppTheme.successGreen),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_statusMessage!, style: TextStyle(fontSize: 12, color: _isError ? AppTheme.errorRed : AppTheme.successGreen))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppButton(label: 'Take Photo', onPressed: () => _pickImage(ImageSource.camera), icon: Icons.camera_alt),
                  const SizedBox(height: 10),
                  AppButton(label: 'Choose from Gallery', onPressed: () => _pickImage(ImageSource.gallery), variant: AppButtonVariant.secondary, icon: Icons.photo_library_outlined),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Remove Photo',
                      onPressed: _removeImage,
                      variant: AppButtonVariant.danger,
                      icon: Icons.delete_outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
