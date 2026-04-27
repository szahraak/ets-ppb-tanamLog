import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/theme.dart';

class FormPlantScreen extends StatefulWidget {
  const FormPlantScreen({super.key});

  @override
  State<FormPlantScreen> createState() => _FormPlantScreenState();
}

class _FormPlantScreenState extends State<FormPlantScreen> {
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();

  final List<int> wateringPeriods = [1, 3, 7, 14, 30];

  String? _selectedLocation;
  int? _selectedWateringPeriod;

  bool _isLoading = false;
  String _errorCode = "";

  final FirestoreService firestoreService = FirestoreService();

  // ── IMAGE ─────────────────────────
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    super.dispose();
  }

  // ── UNSAVED CHANGES ─────────────────
  bool get _hasUnsavedChanges {
    return _nameController.text.isNotEmpty ||
        _speciesController.text.isNotEmpty ||
        _selectedLocation != null ||
        _selectedWateringPeriod != null ||
        _imageFile != null;
  }

  Future<bool> _showExitConfirmation() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Discard changes?"),
          content: const Text(
              "If you leave, your current input will not be saved."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Stay"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Leave"),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _handleExit() async {
    final shouldExit = await _showExitConfirmation();
    if (shouldExit && mounted) {
      Navigator.pop(context);
    }
  }

  // ── IMAGE PICK ─────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = FirebaseStorage.instance
        .ref()
        .child('plants')
        .child(uid)
        .child('$fileName.jpg');

    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  // ── SUBMIT ─────────────────────────
  Future<void> submit() async {
    final name = _nameController.text.trim();
    final species = _speciesController.text.trim();

    if (name.isEmpty ||
        _selectedLocation == null ||
        _selectedWateringPeriod == null) {
      setState(() => _errorCode = "Please fill all required fields");
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _errorCode = "You must be logged in");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorCode = "";
    });

    try {
      final imageUrl = await _uploadImage(uid);

      final plantRef = await firestoreService.addPlant(
        uid,
        name,
        species.isEmpty ? null : species,
        imageUrl ?? '',
        _selectedLocation!,
        _selectedWateringPeriod!,
      );

      await firestoreService.addSchedule(
        uid,
        plantRef.id,
        'Water',
        DateTime.now(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorCode = "Failed to save plant");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _showExitConfirmation();

        if (shouldExit && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                FormHeader(
                  title: "Add New Plant",
                  onClose: _handleExit,
                ),

                const SizedBox(height: 20),

                // IMAGE
                GestureDetector(
                  onTap: _showImageSourceActionSheet,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgBR,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: AppRadius.lgBR,
                            child:
                                Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, size: 40),
                              SizedBox(height: 8),
                              Text('Take a photo'),
                              Text('or select from gallery',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // NAME
                const Text('Plant Name'),
                TextField(controller: _nameController),

                const SizedBox(height: 20),

                // SPECIES
                const Text('Species (optional)'),
                TextField(controller: _speciesController),

                const SizedBox(height: 20),

                // LOCATION
                const Text('Location'),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _selectedLocation = "indoor"),
                        child: const Text("Indoor"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _selectedLocation = "outdoor"),
                        child: const Text("Outdoor"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // WATERING
                DropdownButtonFormField<int>(
                  hint: const Text("Watering period"),
                  initialValue: 1,
                  items: wateringPeriods
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text("$e days"),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedWateringPeriod = value),
                ),

                const SizedBox(height: 20),

                if (_errorCode.isNotEmpty)
                  Text(_errorCode,
                      style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text('Add Plant'),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── HEADER COMPONENT ─────────────────────────
class FormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const FormHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }
}