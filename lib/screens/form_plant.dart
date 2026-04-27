import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/theme.dart';
import 'package:tanamlog/services/notification_services.dart';

class FormPlantScreen extends StatefulWidget {
  final String? plantId; // null for add mode, plantId for edit mode
  final String? plantName;
  final String? plantSpecies;
  final String? plantLocation;
  final int? plantWateringPeriod;
  final String? plantImageUrl;

  const FormPlantScreen({
    super.key,
    this.plantId,
    this.plantName,
    this.plantSpecies,
    this.plantLocation,
    this.plantWateringPeriod,
    this.plantImageUrl,
  });

  @override
  State<FormPlantScreen> createState() => _FormPlantScreenState();
}

class _FormPlantScreenState extends State<FormPlantScreen> {
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();

  final List<int> wateringPeriods = [1, 3, 7, 14, 30];

  String? _selectedLocation;
  int _selectedWateringPeriod = 1; // Initialize with default value

  bool _isLoading = false;
  String _errorCode = "";

  final FirestoreService firestoreService = FirestoreService();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditMode => widget.plantId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Pre-fill form with existing plant data
      _nameController.text = widget.plantName ?? '';
      _speciesController.text = widget.plantSpecies ?? '';
      _selectedLocation = widget.plantLocation ?? 'indoor';
      _selectedWateringPeriod = widget.plantWateringPeriod ?? 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return _nameController.text.isNotEmpty ||
        _speciesController.text.isNotEmpty ||
        _selectedLocation != null ||
        _selectedWateringPeriod != 1 ||
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

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 60, 
      maxWidth: 800,    
      maxHeight: 800,   
    );

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

  Future<String?> _imageToBase64() async {
    if (_imageFile == null) return null;

    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to convert image: $e');
    }
  }

  Future<void> submit() async {
    final name = _nameController.text.trim();
    final species = _speciesController.text.trim();

    if (name.isEmpty || _selectedLocation == null) {
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
      final imageData = await _imageToBase64();

      if (_isEditMode) {
        // Update existing plant
        final updateData = {
          'name': name,
          'species': species.isEmpty ? null : species,
          'location': _selectedLocation,
          'wateringPeriod': _selectedWateringPeriod,
        };
        
        // Only update image if a new one was selected
        if (imageData != null) {
          updateData['photoUrl'] = imageData;
        }

        await firestoreService.updatePlant(widget.plantId!, updateData);
    
        // Update Notifikasi: Cancel yang lama, buat yang baru
        int notifId = widget.plantId.hashCode;
        await NotificationService.cancelNotification(notifId);
        await NotificationService.scheduleWatering(id: notifId, plantName: name, nextDate: DateTime.now().add(Duration(days:_selectedWateringPeriod)));
      } else {
        // Add new plant
        final plantRef = await firestoreService.addPlant(
          uid,
          name,
          species.isEmpty ? null : species,
          imageData ?? '',
          _selectedLocation!,
          _selectedWateringPeriod,
        );

        await NotificationService.scheduleWatering(id: plantRef.id.hashCode, plantName: name, nextDate: DateTime.now().add(Duration(days:_selectedWateringPeriod)));

        await firestoreService.addSchedule(
          uid,
          plantRef.id,
          'Water',
          DateTime.now(),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorCode = "Failed to save plant: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                  title: _isEditMode ? "Edit Plant" : "Add New Plant",
                  onClose: _handleExit,
                ),

                const SizedBox(height: 20),

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

                const Text('Plant Name'),
                TextField(controller: _nameController),

                const SizedBox(height: 20),

                const Text('Species (optional)'),
                TextField(controller: _speciesController),

                const SizedBox(height: 20),

                // ✅ FIXED LOCATION (ChoiceChip)
                const Text('Location'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Indoor"),
                      selected: _selectedLocation == "indoor",
                      onSelected: (_) =>
                          setState(() => _selectedLocation = "indoor"),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text("Outdoor"),
                      selected: _selectedLocation == "outdoor",
                      onSelected: (_) =>
                          setState(() => _selectedLocation = "outdoor"),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<int>(
                  initialValue: _selectedWateringPeriod,
                  items: wateringPeriods
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text("$e days"),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedWateringPeriod = value);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Watering period',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                        : Text(_isEditMode ? 'Save Plant' : 'Add Plant'),
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