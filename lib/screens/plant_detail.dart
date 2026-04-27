import 'package:flutter/material.dart';
import 'package:tanamlog/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/models/care_log.dart';
import 'package:tanamlog/models/health_journal.dart';
import 'package:intl/intl.dart';

class PlantDetailScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final String? plantImageUrl;

  const PlantDetailScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    this.plantImageUrl,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final FirestoreService firestoreService = FirestoreService();
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.outline),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.plantName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
            backgroundColor: AppColors.surfaceContainerLowest,
            elevation: 0,
            pinned: true,
          ),
          // Plant Image Banner
          SliverToBoxAdapter(
            child: Container(
              height: 250,
              margin: const EdgeInsets.all(AppSpacing.containerMargin),
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgBR,
                image: widget.plantImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.plantImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: AppColors.surfaceContainer,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgBR,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.containerMargin),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INDOOR TROPICAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Care & Health History',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tab Navigation
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: AppSpacing.stackMd),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppRadius.mdBR,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildTabButton('All Activity', 0),
                    _buildTabButton('Care Log', 1),
                    _buildTabButton('Health Journal', 2),
                  ],
                ),
              ),
            ),
          ),
          // Content based on selected tab
          SliverToBoxAdapter(
            child: _buildTabContent(),
          ),
          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showLogCareDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppColors.onPrimary),
                          SizedBox(width: AppSpacing.stackSm),
                          Text(
                            'Log Care',
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: AppSpacing.stackLg),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAddJournalDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_add, color: AppColors.onSurface),
                          const SizedBox(width: AppSpacing.stackSm),
                          Text(
                            'Add Note',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.stackXl)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected ? AppColors.primary : AppColors.outline,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAllActivityTab();
      case 1:
        return _buildCareLogTab();
      case 2:
        return _buildHealthJournalTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAllActivityTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.streamCareLogsForPlant(widget.plantId),
      builder: (context, careSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream:
              firestoreService.streamHealthJournalForPlant(widget.plantId),
          builder: (context, healthSnapshot) {
            if (careSnapshot.connectionState == ConnectionState.waiting ||
                healthSnapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.stackXxl),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            List<dynamic> allActivities = [];

            if (careSnapshot.hasData) {
              allActivities.addAll(careSnapshot.data!.docs
                  .map((doc) => CareLog.fromFirestore(doc))
                  .toList());
            }

            if (healthSnapshot.hasData) {
              allActivities.addAll(healthSnapshot.data!.docs
                  .map((doc) => HealthJournal.fromFirestore(doc))
                  .toList());
            }

            // Sort by date
            allActivities.sort((a, b) {
              final dateA = a is CareLog ? a.dateTime : (a as HealthJournal).dateTime;
              final dateB = b is CareLog ? b.dateTime : (b as HealthJournal).dateTime;
              return dateB.compareTo(dateA);
            });

            if (allActivities.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.stackXxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: AppColors.outline),
                      const SizedBox(height: AppSpacing.containerMargin),
                      Text(
                        'No activities yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                )
              );
            }

            return _buildActivityTimeline(allActivities);
          },
        );
      },
    );
  }

  Widget _buildCareLogTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.streamCareLogsForPlant(widget.plantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF2D6A4F),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.stackXxl),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.water_drop, size: 48, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.containerMargin),
                  Text(
                    'No care logs yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final careLogs = snapshot.data!.docs
            .map((doc) => CareLog.fromFirestore(doc))
            .toList();

        return _buildActivityTimeline(careLogs);
      },
    );
  }

  Widget _buildHealthJournalTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.streamHealthJournalForPlant(widget.plantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.stackXxl),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.stackXxl),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.health_and_safety,
                      size: 48, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.containerMargin),
                  Text(
                    'No health journals yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final journals = snapshot.data!.docs
            .map((doc) => HealthJournal.fromFirestore(doc))
            .toList();

        return _buildActivityTimeline(journals);
      },
    );
  }

  Widget _buildActivityTimeline(List<dynamic> activities) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: AppSpacing.stackSm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.mdBR,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityItem(activity, index, activities.length);
          },
        ),
      ),
    );
  }

  Widget _buildActivityItem(dynamic activity, int index, int totalItems) {
    if (activity is CareLog) {
      return _buildCareLogItem(activity, index, totalItems);
    } else {
      return _buildHealthJournalItem(activity as HealthJournal, index, totalItems);
    }
  }

  Widget _buildCareLogItem(CareLog log, int index, int totalItems) {
    final icon = _getActivityIcon(log.activityType);
    final color = _getActivityColor(log.activityType);
    final displayName = _getActivityDisplayName(log.activityType);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: AppSpacing.stackMd),
          child: Row(
            children: [
              // Timeline dot
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.containerMargin),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      DateFormat('d MMM yyyy, HH:mm').format(log.dateTime),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (log.note != null && log.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.stackXs),
                        child: Text(
                          log.note!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (index < totalItems - 1)
          Padding(
            padding: const EdgeInsets.only(left: 35, right: 16),
            child: Divider(
              color: AppColors.outlineVariant,
              height: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildHealthJournalItem(
      HealthJournal journal, int index, int totalItems) {
    final healthColor = _getHealthColor(journal.currentHealth);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: AppSpacing.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Timeline dot
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: healthColor.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Icon(Icons.health_and_safety,
                          color: healthColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.containerMargin),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health: ${journal.currentHealth.substring(0, 1).toUpperCase()}${journal.currentHealth.substring(1)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          DateFormat('d MMM yyyy').format(journal.dateTime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              if (journal.photoUrl != null && journal.photoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: ClipRRect(
                    borderRadius: AppRadius.defBR,
                    child: Image.network(
                      journal.photoUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (journal.observation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 56, top: AppSpacing.stackSm),
                  child: Text(
                    journal.observation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (index < totalItems - 1)
          Padding(
            padding: const EdgeInsets.only(left: 35, right: AppSpacing.containerMargin),
            child: Divider(
              color: AppColors.outlineVariant,
              height: 1,
            ),
          ),
      ],
    );
  }

  void _showLogCareDialog(BuildContext context) {
    String selectedActivity = 'watered';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Log Care Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Type Dropdown
                const Text('Activity Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedActivity,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'watered',
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop,
                              color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          const Text('Watered'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'fertilized',
                      child: Row(
                        children: [
                          const Icon(Icons.eco,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          const Text('Fertilized'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'repotted',
                      child: Row(
                        children: [
                          const Icon(Icons.local_florist,
                              color: Colors.brown, size: 18),
                          const SizedBox(width: 8),
                          const Text('Repotted'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'pruned',
                      child: Row(
                        children: [
                          const Icon(Icons.cut,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          const Text('Pruned'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedActivity = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.containerMargin),
                // Date Picker
                Text('Date & Time', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.stackSm),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(selectedDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setState(() => selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.stackMd),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant),
                            borderRadius: AppRadius.defBR,
                          ),
                          child: Text(
                            selectedTime.format(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.containerMargin),
                // Note
                Text('Note (Optional)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.stackSm),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes...',
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.defBR,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                await firestoreService.addCareLog(
                  widget.plantId,
                  selectedActivity,
                  dateTime,
                  noteController.text.isEmpty ? null : noteController.text,
                );

                if (!context.mounted) return;
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Care log added successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save', style: TextStyle(color: AppColors.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddJournalDialog(BuildContext context) {
    String selectedHealth = 'good';
    DateTime selectedDate = DateTime.now();
    final observationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Health Journal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health Status
                Text('Current Health', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.stackSm),
                DropdownButton<String>(
                  value: selectedHealth,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'excellent',
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackSm),
                          const Text('Excellent'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'good',
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackSm),
                          const Text('Good'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'fair',
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackSm),
                          const Text('Fair'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'poor',
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackSm),
                          const Text('Poor'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedHealth = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.containerMargin),
                // Date
                Text('Date', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.stackSm),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outlineVariant),
                      borderRadius: AppRadius.defBR,
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.containerMargin),
                // Observation
                Text('Observation & Notes',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.stackSm),
                TextField(
                  controller: observationController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe the plant health, observations...',
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.defBR,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await firestoreService.addHealthJournal(
                  widget.plantId,
                  selectedHealth,
                  observationController.text,
                  null, // photoUrl for now, can be extended with image picker
                  selectedDate,
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Health journal added successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save', style: TextStyle(color: AppColors.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'watered':
        return Icons.water_drop;
      case 'fertilized':
        return Icons.eco;
      case 'repotted':
        return Icons.local_florist;
      case 'pruned':
        return Icons.cut;
      default:
        return Icons.check_circle;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'watered':
        return Colors.blue;
      case 'fertilized':
        return Colors.green;
      case 'repotted':
        return Colors.brown;
      case 'pruned':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getActivityDisplayName(String activityType) {
    switch (activityType) {
      case 'watered':
        return 'Watered';
      case 'fertilized':
        return 'Fertilized';
      case 'repotted':
        return 'Repotted';
      case 'pruned':
        return 'Pruned';
      default:
        return activityType;
    }
  }

  Color _getHealthColor(String health) {
    switch (health) {
      case 'excellent':
        return AppColors.primary;
      case 'good':
        return Colors.green;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
