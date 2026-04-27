import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:tanamlog/theme.dart';
import 'package:tanamlog/firestore.dart'; 

class RemindersScreen extends StatefulWidget {
  final String uid;

  const RemindersScreen({super.key, required this.uid});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSmartGpsEnabled = true;

  // ── State Cuaca ───────────────────────────────────────────────────────────
  bool _isLoadingWeather = true;
  bool _isRaining = false;
  String _weatherDesc = "Fetching weather...";
  IconData _weatherIcon = Icons.cloud;
  Color _weatherColor = Colors.grey;
  Color _weatherBgColor = AppColors.surfaceContainer;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  // ── Fungsi Mengambil Cuaca via API Open-Meteo ───────────────────────────
  Future<void> _fetchWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'GPS disabled';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission denied';
      }

      // Ambil kordinat
      Position pos = await Geolocator.getCurrentPosition();

      // Panggil API Open-Meteo (Gratis, tanpa API Key)
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=${pos.latitude}&longitude=${pos.longitude}&current_weather=true';
      final res = await http.get(Uri.parse(url));
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        int code = data['current_weather']['weathercode'];

        if (mounted) {
          setState(() {
            _isLoadingWeather = false;
            // WMO Weather interpretation codes
            // Hujan/Gerimis/Badai (51-67, 80-82, 95-99)
            if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95) {
              _isRaining = true;
              _weatherDesc = "Rainy";
              _weatherIcon = Icons.water_drop;
              _weatherColor = const Color(0xFF1976D2);
              _weatherBgColor = const Color(0xFFD6E8FC);
            } 
            // Cerah (0-1)
            else if (code <= 1) {
              _isRaining = false;
              _weatherDesc = "Sunny";
              _weatherIcon = Icons.wb_sunny;
              _weatherColor = Colors.orange;
              _weatherBgColor = const Color(0xFFFFF3E0);
            } 
            // Berawan (2-48)
            else {
              _isRaining = false;
              _weatherDesc = "Cloudy";
              _weatherIcon = Icons.cloud;
              _weatherColor = Colors.blueGrey;
              _weatherBgColor = const Color(0xFFF5F7F5);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _weatherDesc = "Weather unavailable";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reminders', style: textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(
              'Smart scheduling for your garden', 
              style: textTheme.bodyMedium?.copyWith(color: AppColors.outline)
            ),
          ],
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getTodayTasksStream(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final taskDocs = snapshot.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot>(
            // Mengambil data tanaman untuk mendapatkan foto asli
            stream: _firestoreService.getUserPlantsStream(widget.uid),
            builder: (context, plantSnapshot) {
              // Buat Map untuk mencari photoUrl berdasarkan plantId
              Map<String, String> plantImages = {};
              if (plantSnapshot.hasData) {
                for (var doc in plantSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  plantImages[doc.id] = data['photoUrl'] as String? ?? '';
                }
              }

              int skippedCount = 0;
              List<Widget> taskWidgets = [];

              for (var doc in taskDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final plantId = data['plantId'] as String? ?? '';
                final action = (data['action'] as String? ?? '').toLowerCase();
                
                // Ambil foto asli dari Map, jika tidak ada akan jadi string kosong
                final plantPhoto = plantImages[plantId] ?? '';

                bool isWateringTask = action.contains('water');
                bool isSkipped = _isSmartGpsEnabled && _isRaining && isWateringTask;

                if (isSkipped) skippedCount++;

                taskWidgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    child: _TaskCard(
                      title: data['action'] ?? 'Unknown Task',
                      subtitle: 'Today',
                      // Gunakan foto asli tanaman
                      imageUrl: plantPhoto, 
                      status: isSkipped ? TaskStatus.skipped : TaskStatus.pending,
                      onActionTap: () {
                        if (isSkipped) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task automatically skipped due to rain.')),
                          );
                        } else {
                          _firestoreService.completeSchedule(docId);
                        }
                      },
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.stackXl),
                    _buildWeatherCard(textTheme, skippedCount),
                    const SizedBox(height: AppSpacing.stackLg),
                    _buildGpsToggleCard(textTheme),
                    const SizedBox(height: AppSpacing.stackXxl),
                    Text('Upcoming Tasks', style: textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.stackLg),
                    if (taskDocs.isEmpty)
                      _buildEmptyState(textTheme)
                    else
                      ...taskWidgets,
                    const SizedBox(height: AppSpacing.stackXxl),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Weather Card Dinamis ──────────────────────────────────────────────────
  Widget _buildWeatherCard(TextTheme textTheme, int skippedCount) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: _weatherBgColor,
        borderRadius: AppRadius.mdBR,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: _isLoadingWeather
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_weatherIcon, color: _weatherColor),
          ),
          const SizedBox(width: AppSpacing.stackLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Weather: $_weatherDesc', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.stackXs),
                Text(
                  _isLoadingWeather
                      ? 'Fetching local weather data...'
                      : (_isRaining && _isSmartGpsEnabled && skippedCount > 0)
                          ? '$skippedCount watering task(s) skipped automatically.'
                          : 'No tasks skipped. Perfect weather for your garden!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GPS Toggle Card ───────────────────────────────────────────────────────
  Widget _buildGpsToggleCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stackLg,
        vertical: AppSpacing.stackMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.stackLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart GPS Skip', style: textTheme.titleMedium),
                Text('Auto-adjust tasks based on weather', style: textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: _isSmartGpsEnabled,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primaryDark,
            onChanged: (val) {
              setState(() {
                _isSmartGpsEnabled = val;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── Empty State Widget ────────────────────────────────────────────────────
  Widget _buildEmptyState(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSpacing.containerMargin),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.lgBR,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.done_all, size: 36, color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text(
            'All caught up!',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.stackXs),
          Text(
            'No tasks scheduled for today.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 2, 
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      onDestinationSelected: (int index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, 'home');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, 'garden');
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, 'profile');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_filled, color: AppColors.outline),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_florist, color: AppColors.outline),
          label: 'Garden',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month, color: AppColors.primaryDark),
          label: 'Reminders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person, color: AppColors.outline),
          label: 'Profile',
        ),
      ],
    );
  }
}

// ── Widget Komponen Pendukung ─────────────────────────────────────────────────

enum TaskStatus { skipped, pending, future }

class _TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final TaskStatus status;
  final VoidCallback onActionTap;

  const _TaskCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.status,
    required this.onActionTap,
  });

  Widget _buildTaskImage() {
    if (imageUrl.isEmpty) {
      return _buildPlaceholderIcon();
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: 56, height: 56, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
        );
      } catch (e) {
        return _buildPlaceholderIcon();
      }
    }

    return Image.network(
      imageUrl,
      width: 56, height: 56, fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 56, height: 56,
      color: AppColors.surfaceContainer,
      child: const Icon(Icons.local_florist, color: AppColors.outline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.mdBR,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.defBR,
            child: _buildTaskImage(), // Menggunakan helper image baru
          ),
          const SizedBox(width: AppSpacing.stackLg),
          
          // Detail Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: status == TaskStatus.skipped ? AppColors.outline : AppColors.onSurface,
                        decoration: status == TaskStatus.skipped ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (status == TaskStatus.skipped) ...[
                      const SizedBox(width: AppSpacing.stackSm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(alpha: 0.3),
                          borderRadius: AppRadius.defBR,
                        ),
                        child: Text('Skipped - Rain', style: textTheme.bodySmall),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: AppSpacing.stackXs),
                Row(
                  children: [
                    if (status != TaskStatus.skipped) ...[
                      Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: status == TaskStatus.pending ? AppColors.primary : AppColors.outline,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: status == TaskStatus.pending ? AppColors.primaryDark : AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Button
          const SizedBox(width: AppSpacing.stackSm),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (status) {
      case TaskStatus.skipped:
        return IconButton(
          icon: const Icon(Icons.undo, color: AppColors.outline),
          onPressed: onActionTap, // Memunculkan notifikasi skip (sudah diatur di atas)
        );
      case TaskStatus.pending:
        return IconButton(
          icon: const CircleAvatar(
            backgroundColor: AppColors.surfaceContainer,
            radius: 16,
            child: Icon(Icons.check_circle, color: AppColors.primary, size: 28),
          ),
          onPressed: onActionTap,
        );
      case TaskStatus.future:
        return IconButton(
          icon: const CircleAvatar(
            backgroundColor: AppColors.surfaceContainer,
            radius: 16,
            child: Icon(Icons.more_horiz, color: AppColors.onSurface, size: 20),
          ),
          onPressed: onActionTap,
        );
    }
  }
}