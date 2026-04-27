import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/theme.dart';

class AddHealthJournalScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final String? plantLocation;
  final String? plantImageUrl;

  // Parameter tambahan untuk mode Edit
  final String? journalId;
  final String? initialHealth;
  final String? initialObservation;
  final String? initialPhotoUrl;
  final DateTime? initialDate;

  const AddHealthJournalScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    this.plantLocation,
    this.plantImageUrl,
    this.journalId,
    this.initialHealth,
    this.initialObservation,
    this.initialPhotoUrl,
    this.initialDate,
  });

  @override
  State<AddHealthJournalScreen> createState() => _AddHealthJournalScreenState();
}

class _AddHealthJournalScreenState extends State<AddHealthJournalScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _observationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late String _selectedHealth;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedHealth = widget.initialHealth ?? 'thriving';
    if (widget.initialObservation != null) {
      _observationController.text = widget.initialObservation!;
    }
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<String?> _imageToBase64() async {
    if (_imageFile == null) return null;
    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      return null;
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.primary), title: const Text('Take Photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
              ListTile(leading: const Icon(Icons.photo, color: AppColors.primary), title: const Text('Choose from Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 60, maxWidth: 800, maxHeight: 800);
      if (picked != null) setState(() => _imageFile = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Widget _buildPlantAvatar() {
    if (widget.plantImageUrl == null || widget.plantImageUrl!.isEmpty) {
      return const CircleAvatar(radius: 24, backgroundColor: AppColors.surfaceContainer, child: Icon(Icons.local_florist, color: AppColors.outline));
    }
    if (widget.plantImageUrl!.startsWith('data:image')) {
      try {
        final base64String = widget.plantImageUrl!.split(',').last;
        return CircleAvatar(radius: 24, backgroundImage: MemoryImage(base64Decode(base64String)));
      } catch (e) {
        return const CircleAvatar(radius: 24, backgroundColor: AppColors.surfaceContainer);
      }
    }
    return CircleAvatar(radius: 24, backgroundImage: NetworkImage(widget.plantImageUrl!));
  }

  Widget _buildExistingImage(String imageData) {
    if (imageData.startsWith('data:image')) {
      try {
        final decodedBytes = base64Decode(imageData.split(',').last);
        return Image.memory(decodedBytes, height: 150, width: 150, fit: BoxFit.cover);
      } catch (e) { return const SizedBox.shrink(); }
    }
    return Image.network(imageData, height: 150, width: 150, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditMode = widget.journalId != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text(isEditMode ? 'Edit Journal' : 'Health Journal', style: textTheme.headlineSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppRadius.lgBR,
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  _buildPlantAvatar(),
                  const SizedBox(width: AppSpacing.stackLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.plantName, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.outline),
                            const SizedBox(width: 4),
                            Text(
                              widget.plantLocation != null && widget.plantLocation!.isNotEmpty ? '${widget.plantLocation![0].toUpperCase()}${widget.plantLocation!.substring(1)}' : 'Unknown Location',
                              style: textTheme.bodySmall?.copyWith(color: AppColors.outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackXxl),

            GestureDetector(
              onTap: _showImageSourceActionSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: AppRadius.lgBR, border: Border.all(color: AppColors.outlineVariant, width: 1.5)),
                child: _imageFile != null
                    ? Column(
                        children: [
                          ClipRRect(borderRadius: AppRadius.mdBR, child: Image.file(_imageFile!, height: 150, width: 150, fit: BoxFit.cover)),
                          const SizedBox(height: AppSpacing.stackMd),
                          const Text('Tap to change photo', style: TextStyle(color: AppColors.outline, fontSize: 12)),
                        ],
                      )
                    : (widget.initialPhotoUrl != null && widget.initialPhotoUrl!.isNotEmpty)
                        ? Column(
                            children: [
                              ClipRRect(borderRadius: AppRadius.mdBR, child: _buildExistingImage(widget.initialPhotoUrl!)),
                              const SizedBox(height: AppSpacing.stackMd),
                              const Text('Tap to change photo', style: TextStyle(color: AppColors.outline, fontSize: 12)),
                            ],
                          )
                        : Column(
                            children: [
                              Container(padding: const EdgeInsets.all(AppSpacing.stackMd), decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle), child: const Icon(Icons.add_a_photo, color: AppColors.primaryDark)),
                              const SizedBox(height: AppSpacing.stackLg),
                              Text('Add Current Photo', style: textTheme.titleSmall?.copyWith(color: AppColors.primaryDark)),
                              const SizedBox(height: AppSpacing.stackXs),
                              Text('Capture today\'s growth or issues', style: textTheme.bodySmall),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackXxl),

            Text('Current Health', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                _buildHealthCard('thriving', 'Thriving', Icons.sentiment_very_satisfied, AppColors.primary),
                const SizedBox(width: AppSpacing.stackSm),
                _buildHealthCard('needs_tlc', 'Needs TLC', Icons.sentiment_dissatisfied, Colors.orange),
                const SizedBox(width: AppSpacing.stackSm),
                _buildHealthCard('critical', 'Critical', Icons.coronavirus_outlined, Colors.red),
              ],
            ),
            const SizedBox(height: AppSpacing.stackXxl),

            Text('Observations & Notes', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.stackSm),
            TextField(
              controller: _observationController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe new growth, pests spotted...',
                hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.outlineVariant),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.mdBR, borderSide: BorderSide(color: AppColors.outlineVariant)),
                focusedBorder: const OutlineInputBorder(borderRadius: AppRadius.mdBR, borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)))),
          child: ElevatedButton(
            onPressed: _isLoading ? _saveJournalEntry : _saveJournalEntry, // Fix disable mechanism
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, size: 20),
                      const SizedBox(width: AppSpacing.stackSm),
                      Text(isEditMode ? 'Update Entry' : 'Save Entry', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCard(String type, String title, IconData icon, Color baseColor) {
    final isSelected = _selectedHealth == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedHealth = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
          decoration: BoxDecoration(
            color: isSelected ? baseColor.withValues(alpha: 0.1) : AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.mdBR,
            border: Border.all(color: isSelected ? baseColor : AppColors.outlineVariant.withValues(alpha: 0.5), width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? baseColor : AppColors.outline, size: 28),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected ? baseColor : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveJournalEntry() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Jika pengguna memilih gambar baru, akan jadi base64. Jika tidak, pakai yang lama.
      final photoBase64 = await _imageToBase64() ?? widget.initialPhotoUrl;
      final observation = _observationController.text.trim();
      final entryDate = widget.initialDate ?? DateTime.now();

      if (widget.journalId == null) {
        await _firestoreService.addHealthJournal(widget.plantId, _selectedHealth, observation.isEmpty ? 'No notes provided.' : observation, photoBase64, entryDate);
      } else {
        await _firestoreService.updateHealthJournal(widget.plantId, widget.journalId!, _selectedHealth, observation.isEmpty ? 'No notes provided.' : observation, photoBase64, entryDate);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.journalId == null ? 'Health journal added successfully' : 'Health journal updated successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}