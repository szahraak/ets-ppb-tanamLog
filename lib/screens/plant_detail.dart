import 'package:flutter/material.dart';
import 'package:tanamlog/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/models/care_log.dart';
import 'package:tanamlog/models/health_journal.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:tanamlog/screens/form_log.dart';
import 'package:tanamlog/screens/form_journal.dart';

class PlantDetailScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final String? plantLocation; 
  final String? plantSpecies; 
  final String? plantImageUrl;
  final int? plantWateringPeriod;

  const PlantDetailScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.plantLocation,
    required this.plantSpecies,
    this.plantImageUrl,
    this.plantWateringPeriod,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final FirestoreService firestoreService = FirestoreService();
  int _selectedTabIndex = 0;
  
  // ── Stream untuk memantau perubahan data tanaman secara real-time ──
  late Stream<DocumentSnapshot> _plantStream;
  
  // Variabel untuk menyimpan data tanaman terbaru
  late String _currentName;
  late String? _currentLocation;
  late String? _currentSpecies;
  late String? _currentImageUrl;
  late int? _currentWateringPeriod;

  @override
  void initState() {
    super.initState();
    // Menggunakan data awal dari argumen navigator saat pertama kali dibuka
    _currentName = widget.plantName;
    _currentLocation = widget.plantLocation;
    _currentSpecies = widget.plantSpecies;
    _currentImageUrl = widget.plantImageUrl;
    _currentWateringPeriod = widget.plantWateringPeriod;
    
    // Inisialisasi stream listener ke dokumen Firestore tanaman ini
    _plantStream = FirebaseFirestore.instance.collection('plants').doc(widget.plantId).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      // ── Membungkus CustomScrollView dengan StreamBuilder ──
      body: StreamBuilder<DocumentSnapshot>(
        stream: _plantStream,
        builder: (context, snapshot) {
          
          // Jika ada data baru yang masuk dari Firestore (misal setelah diedit),
          // Perbarui variabel lokal dengan data tersebut
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            _currentName = data['name'] as String? ?? widget.plantName;
            _currentSpecies = data['species'] as String?;
            _currentLocation = data['location'] as String? ?? widget.plantLocation;
            _currentImageUrl = data['photoUrl'] as String? ?? '';
            _currentWateringPeriod = data['wateringPeriod'] as int? ?? widget.plantWateringPeriod;
          }

          return CustomScrollView(
            slivers: [
              // ── App Bar ──
              SliverAppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.outline),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _currentName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        'add-plant',
                        arguments: {
                          'plantId': widget.plantId,
                          'plantName': _currentName,
                          'plantSpecies': _currentSpecies,
                          'plantLocation': _currentLocation,
                          'plantWateringPeriod': _currentWateringPeriod ?? 1,
                          'plantImageUrl': _currentImageUrl,
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context),
                  ),
                ],
                backgroundColor: AppColors.surfaceContainerLowest,
                elevation: 0,
                pinned: true,
              ),
              
              // ── Plant Image Banner ──
              SliverToBoxAdapter(
                child: Container(
                  height: 250,
                  margin: const EdgeInsets.all(AppSpacing.containerMargin),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.lgBR,
                    color: AppColors.surfaceContainer,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image background
                      if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                        _buildPlantImage(_currentImageUrl!)
                      else
                        Container(color: AppColors.surfaceContainer),
                      // Gradient overlay
                      Container(
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
                      ),
                      // Text overlay
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.containerMargin),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _currentLocation == "outdoor"
                                      ? 'OUTDOOR PLANT'
                                      : 'INDOOR PLANT',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (_currentSpecies != null && _currentSpecies!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentSpecies!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ],
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
                    ],
                  ),
                ),
              ),
              
              // ── Tab Navigation ──
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
              
              // ── Content based on selected tab ──
              SliverToBoxAdapter(
                child: _buildTabContent(),
              ),
              
              // ── Action Buttons ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.containerMargin),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LogActivityScreen(
                                  plantId: widget.plantId,
                                  plantName: _currentName,
                                  plantLocation: _currentLocation,
                                  plantImageUrl: _currentImageUrl,
                                ),
                              ),
                            );
                          },
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

                      const SizedBox(width: AppSpacing.stackLg),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddHealthJournalScreen(
                                  plantId: widget.plantId,
                                  plantName: _currentName,
                                  plantLocation: _currentLocation,
                                  plantImageUrl: _currentImageUrl,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainer,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_add, color: AppColors.onSurface),
                              SizedBox(width: AppSpacing.stackSm),
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
          );
        }
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
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.stackXxl),
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
                      const Icon(Icons.history, size: 48, color: AppColors.outline),
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
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D6A4F),
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
                  const Icon(Icons.water_drop, size: 48, color: AppColors.outline),
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
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.stackXxl),
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
                  const Icon(Icons.health_and_safety,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.2)),
                child: Center(child: Icon(icon, color: color, size: 20)),
              ),
              const SizedBox(width: AppSpacing.containerMargin),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: Theme.of(context).textTheme.titleSmall),
                    Text(DateFormat('d MMM yyyy, HH:mm').format(log.dateTime), style: Theme.of(context).textTheme.bodySmall),
                    if (log.note != null && log.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.stackXs),
                        child: Text(log.note!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              ),
              // Menu Edit & Delete
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.outline),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LogActivityScreen(
                      plantId: widget.plantId,
                      plantName: _currentName, // <-- Menggunakan nama terbaru
                      careLogId: log.id, 
                      initialActivity: log.activityType,
                      initialDate: log.dateTime,
                      initialNote: log.note,
                    )));
                  } else if (value == 'delete') {
                    _confirmDeleteCareLog(log.id); 
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
        if (index < totalItems - 1)
          const Padding(padding: EdgeInsets.only(left: 35, right: 16), child: Divider(color: AppColors.outlineVariant, height: 1)),
      ],
    );
  }

  Widget _buildHealthJournalItem(HealthJournal journal, int index, int totalItems) {
    final healthColor = _getHealthColor(journal.currentHealth);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: AppSpacing.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: healthColor.withValues(alpha: 0.2)),
                    child: Center(child: Icon(Icons.health_and_safety, color: healthColor, size: 20)),
                  ),
                  const SizedBox(width: AppSpacing.containerMargin),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Health: ${journal.currentHealth.substring(0, 1).toUpperCase()}${journal.currentHealth.substring(1)}', style: Theme.of(context).textTheme.titleSmall),
                        Text(DateFormat('d MMM yyyy').format(journal.dateTime), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  // Menu Edit & Delete
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.outline),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AddHealthJournalScreen(
                          plantId: widget.plantId,
                          plantName: _currentName, // <-- Menggunakan nama terbaru
                          journalId: journal.id,
                          initialHealth: journal.currentHealth,
                          initialObservation: journal.observation,
                          initialPhotoUrl: journal.photoUrl,
                          initialDate: journal.dateTime,
                        )));
                      } else if (value == 'delete') {
                        _confirmDeleteHealthJournal(journal.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              if (journal.photoUrl != null && journal.photoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: ClipRRect(borderRadius: AppRadius.defBR, child: SizedBox(height: 150, width: double.infinity, child: _buildPlantImage(journal.photoUrl!))),
                ),
              if (journal.observation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 56, top: AppSpacing.stackSm),
                  child: Text(journal.observation, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurface)),
                ),
            ],
          ),
        ),
        if (index < totalItems - 1)
          const Padding(padding: EdgeInsets.only(left: 35, right: AppSpacing.containerMargin), child: Divider(color: AppColors.outlineVariant, height: 1)),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Plant'),
        content: const Text('Are you sure you want to delete this plant? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                await firestoreService.deletePlant(widget.plantId);
                
                if (!context.mounted) return;
                  
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plant deleted successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete plant: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCareLog(String logId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity log?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await firestoreService.deleteCareLog(widget.plantId, logId);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log deleted')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHealthJournal(String journalId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Journal'),
        content: const Text('Are you sure you want to delete this health journal entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await firestoreService.deleteHealthJournal(widget.plantId, journalId);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journal deleted')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'watered': return Icons.water_drop;
      case 'fertilized': return Icons.eco;
      case 'repotted': return Icons.local_florist;
      case 'pruned': return Icons.cut;
      default: return Icons.check_circle;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'watered': return Colors.blue;
      case 'fertilized': return Colors.green;
      case 'repotted': return Colors.brown;
      case 'pruned': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getActivityDisplayName(String activityType) {
    switch (activityType) {
      case 'watered': return 'Watered';
      case 'fertilized': return 'Fertilized';
      case 'repotted': return 'Repotted';
      case 'pruned': return 'Pruned';
      default: return activityType;
    }
  }

  Color _getHealthColor(String health) {
    switch (health) {
      case 'excellent': return AppColors.primary;
      case 'good': return Colors.green;
      case 'fair': return Colors.orange;
      case 'poor': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildPlantImage(String imageData) {
    if (imageData.startsWith('data:image')) {
      try {
        final base64String = imageData.split(',').last;
        final decodedBytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: AppRadius.lgBR,
          child: Image.memory(
            decodedBytes,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        return Container(color: AppColors.surfaceContainer);
      }
    } else if (imageData.isNotEmpty) {
      return ClipRRect(
        borderRadius: AppRadius.lgBR,
        child: Image.network(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: AppColors.surfaceContainer);
          },
        ),
      );
    } else {
      return Container(color: AppColors.surfaceContainer);
    }
  }
}