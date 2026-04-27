import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogActivityScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final String? plantLocation;
  final String? plantImageUrl;
  
  // Parameter tambahan untuk mode Edit
  final String? careLogId;
  final String? initialActivity;
  final DateTime? initialDate;
  final String? initialNote;

  const LogActivityScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    this.plantLocation,
    this.plantImageUrl,
    this.careLogId,
    this.initialActivity,
    this.initialDate,
    this.initialNote,
  });

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _noteController = TextEditingController();

  late String _selectedActivity;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data (jika edit, pakai data lama. Jika baru, pakai data default)
    _selectedActivity = widget.initialActivity ?? 'watered';
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDate ?? DateTime.now());
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _getDateText(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    return DateFormat('dd MMM yyyy').format(date);
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditMode = widget.careLogId != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text(isEditMode ? 'Edit Activity' : 'Log Activity', style: textTheme.headlineSmall),
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
                              widget.plantLocation != null && widget.plantLocation!.isNotEmpty
                                  ? '${widget.plantLocation![0].toUpperCase()}${widget.plantLocation!.substring(1)}'
                                  : 'Unknown Location',
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

            Text('Activity Type', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.stackSm),
            Column(
              children: [
                Row(
                  children: [
                    _buildActivityCard('watered', 'Watering', Icons.water_drop),
                    const SizedBox(width: AppSpacing.stackSm),
                    _buildActivityCard('fertilized', 'Fertilizing', Icons.eco),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Row(
                  children: [
                    _buildActivityCard('repotted', 'Repotting', Icons.local_florist),
                    const SizedBox(width: AppSpacing.stackSm),
                    _buildActivityCard('pruned', 'Pruning', Icons.content_cut),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackXxl),

            Text('Date & Time', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    borderRadius: AppRadius.mdBR,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd, vertical: AppSpacing.stackLg),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: AppRadius.mdBR, color: AppColors.surfaceContainerLowest),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_getDateText(_selectedDate), style: textTheme.bodyMedium), const Icon(Icons.calendar_today, size: 18, color: AppColors.outline)]),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.stackSm),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                      if (picked != null) setState(() => _selectedTime = picked);
                    },
                    borderRadius: AppRadius.mdBR,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd, vertical: AppSpacing.stackLg),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: AppRadius.mdBR, color: AppColors.surfaceContainerLowest),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_selectedTime.format(context), style: textTheme.bodyMedium), const Icon(Icons.schedule, size: 18, color: AppColors.outline)]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackXxl),

            Text('Notes (Optional)', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.stackSm),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add observations...',
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
            onPressed: _isLoading ? null : _saveLogActivity,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullBR),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: AppSpacing.stackSm),
                      Text(isEditMode ? 'Update Log' : 'Save Log', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(String type, String title, IconData icon) {
    final isSelected = _selectedActivity == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedActivity = type),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.mdBR,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? AppColors.onPrimary : AppColors.outline, size: 28),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveLogActivity() async {
    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
      final note = _noteController.text.isEmpty ? null : _noteController.text.trim();
      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (widget.careLogId == null) {
        // Mode Tambah Baru
        await _firestoreService.addCareLog(widget.plantId, _selectedActivity, dateTime, note);

        // Jika aktivitas adalah menyiram, panggil Orchestrator
        if (_selectedActivity == 'watered' && uid != null) {
          await _firestoreService.handleManualWatering(uid, widget.plantId);
        }
      } else {
        // Mode Edit
        await _firestoreService.updateCareLog(widget.plantId, widget.careLogId!, _selectedActivity, dateTime, note);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.careLogId == null ? 'Care log added successfully' : 'Care log updated successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}