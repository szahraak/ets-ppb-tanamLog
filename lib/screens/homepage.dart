import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/theme.dart';
import 'dart:convert';
import 'package:tanamlog/services/notification_services.dart';

// ── Models ────────────────────────────────────────────────────────────────────
class Plant {
  final String id, name, species, emoji, waterLabel, photoUrl, location;
  final Color bgColor;
  final int wateringPeriod;
  const Plant({required this.id, required this.name, required this.species,
      required this.emoji, required this.photoUrl, required this.waterLabel, required this.bgColor, required this.location, required this.wateringPeriod});

  /// Construct a Plant from a Firestore document.
  factory Plant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final wateringPeriod = data['wateringPeriod'] as int? ?? 7;
    return Plant(
      id: doc.id,
      name: data['name'] as String? ?? '',
      species: data['species'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '🌿',
      photoUrl: data['photoUrl'] as String? ?? '',
      waterLabel: _waterLabel(wateringPeriod),
      bgColor: Color(data['bgColor'] as int? ?? 0xFFE8F5E9),
      location: data['location'] as String? ?? 'indoor',
      wateringPeriod: wateringPeriod,
    );
  }

  static String _waterLabel(int days) {
    if (days == 1) return 'Every day';
    if (days <= 3) return 'Every $days days';
    if (days == 7) return 'Weekly';
    return 'Every $days days';
  }
}

class Task {
  final String id, plant, action, icon;
  final Color iconBg;
  const Task({required this.id, required this.plant, required this.action,
      required this.icon, required this.iconBg});

  /// Construct a Task by joining a schedule doc with its plant name.
  factory Task.fromFirestore(DocumentSnapshot doc, String plantName) {
    final data = doc.data() as Map<String, dynamic>;
    final action = data['action'] as String? ?? '';
    return Task(
      id: doc.id,
      plant: plantName,
      action: action,
      icon: _actionIcon(action),
      iconBg: _actionColor(action),
    );
  }

  static String _actionIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains('water')) return '💧';
    if (a.contains('fertiliz')) return '🌿';
    if (a.contains('prun')) return '✂️';
    if (a.contains('repot')) return '🪴';
    return '📋';
  }

  static Color _actionColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('water')) return const Color(0xFFE3F2FD);
    if (a.contains('fertiliz')) return const Color(0xFFE8F5E9);
    if (a.contains('prun')) return const Color(0xFFFFF9C4);
    if (a.contains('repot')) return const Color(0xFFFBE9E7);
    return const Color(0xFFF3E5F5);
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Current Firebase Auth user (null while loading)
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // Greeting based on device time
  String get _greeting {
    final hour = TimeOfDay.now().hour;
    if (hour < 12) return 'Good Morning 🌿';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  // ── Location ──────────────────────────────────────────────────────────────
  
  // 1. Gunakan variabel static agar nilainya bertahan selama aplikasi tidak ditutup sepenuhnya
  static String _cachedLocationLabel = 'Location not detected';

  // Inisialisasi label dengan nilai cache
  late String _locationLabel = _cachedLocationLabel;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    // 2. Cek izin secara otomatis saat halaman Home dimuat
    _autoFetchLocationIfPermitted();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermission(context);
    });
  }

  Future<void> _autoFetchLocationIfPermitted() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      // Jika izin sudah pernah diberikan (WhileInUse atau Always), ambil lokasi diam-diam
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        await _requestLocation();
      }
    } catch (_) {
      // Abaikan error jika berjalan di background
    }
  }

  Future<void> _requestLocation() async {
    if (!mounted) return; 
    setState(() => _locationLoading = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) { // <--- Tambahkan kurung kurawal di sini
          setState(() {
            _locationLabel = 'Location services disabled';
            _locationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) { // <--- Tambahkan kurung kurawal di sini
          setState(() {
            _locationLabel = 'Location permission denied';
            _locationLoading = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _locationLabel = '${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°';
          _cachedLocationLabel = _locationLabel; 
          _locationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationLabel = 'Could not get location';
          _locationLoading = false;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final uid = _currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _HomeAppBar(greeting: _greeting, user: _currentUser),
          SliverToBoxAdapter(
            child: _WeatherBanner(
              locationLabel: _locationLabel,
              locationLoading: _locationLoading,
              onRequestLocation: _requestLocation,
            ),
          ),

          // ── My Garden — header ──────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getUserPlantsStream(uid),
            builder: (context, snapshot) {
              final plants = _parsePlants(snapshot);

              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.containerMargin, AppSpacing.stackLg,
                        AppSpacing.containerMargin, AppSpacing.stackSm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('My Garden',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: AppColors.onSurface)),
                                
                          // PERBAIKAN 1: Tombol 'See all' hanya muncul jika tanaman > 6
                          if (plants.length > 6)
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/garden'),
                              child: const Text('See all',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── My Garden — body ──────────────────────────────────
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.containerMargin),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (plants.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.containerMargin),
                        child: _EmptyGarden(
                          onAddPlant: () =>
                              Navigator.pushNamed(context, 'add-plant'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.containerMargin),
                      sliver: SliverGrid(
                        delegate: SliverChildListDelegate(
                          // PERBAIKAN 2: Gunakan .take(6) agar maksimal hanya 6 card yang dirender
                          plants.take(6).map((p) => _PlantCard(plant: p)).toList(),
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.gutter,
                          crossAxisSpacing: AppSpacing.gutter,
                          childAspectRatio: 0.78,
                        ),
                      ),
                    ),

                  // ── Today's Tasks — only shown if user has plants ──────
                  if (plants.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.containerMargin, AppSpacing.stackLg,
                          AppSpacing.containerMargin, AppSpacing.stackSm,
                        ),
                        child: Text("Today's Tasks",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.onSurface)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.containerMargin, 0,
                          AppSpacing.containerMargin, 0),
                      sliver: _TodayTasksSliver(
                        uid: uid,
                        firestoreService: _firestoreService,
                        plantDocs: snapshot.data?.docs ?? [],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, 'add-plant'),
        child: Icon(Icons.add_rounded, size: 18),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<Plant> _parsePlants(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) return [];
    return snapshot.data!.docs
        .map((doc) => Plant.fromFirestore(doc))
        .toList();
  }

  // ── Bottom Navigation (Material 3) ────────────────────────────────────────
  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 0, // 'Reminders' aktif
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      onDestinationSelected: (int index) {
        if (index == 1) {
          Navigator.pushReplacementNamed(context, 'garden');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, 'reminder');
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, 'profile');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_filled, color: AppColors.primaryDark),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_florist, color: AppColors.outline),
          label: 'Garden',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month, color: AppColors.outline),
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

// ── Today's Tasks Sliver ──────────────────────────────────────────────────────
/// Separate widget so it can hold its own StreamBuilder without forcing
/// the entire screen to rebuild on every task update.
class _TodayTasksSliver extends StatelessWidget {
  final String uid;
  final FirestoreService firestoreService;
  final List<DocumentSnapshot> plantDocs; // from parent stream

  const _TodayTasksSliver({
    required this.uid,
    required this.firestoreService,
    required this.plantDocs,
  });

  /// Build a name-lookup map from already-fetched plant docs.
  Map<String, String> get _plantNames => {
    for (final doc in plantDocs)
      doc.id: (doc.data() as Map<String, dynamic>)['name'] as String? ?? '',
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getTodayTasksStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final names = _plantNames;
        final tasks = (snapshot.data?.docs ?? [])
            .map((doc) => Task.fromFirestore(
                doc, names[(doc.data() as Map)['plantId']] ?? 'Plant'))
            .toList();

        if (tasks.isEmpty) {
          return SliverToBoxAdapter(child: _EmptyTasks());
        }

        return SliverList(
          delegate: SliverChildListDelegate(
            tasks
                .map((t) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.stackSm),
                      child: _TaskTile(
                        task: t,
                        onComplete: () =>
                            firestoreService.completeSchedule(t.id),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  final String greeting;
  final User? user;
  
  const _HomeAppBar({required this.greeting, required this.user});

  // Helper untuk membaca format foto (Base64 atau URL biasa)
  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        try {
          final base64String = photoUrl.split(',').last;
          return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
        } catch (e) {
          return const Center(child: Icon(Icons.person_rounded, color: AppColors.onPrimary, size: 20));
        }
      }
      return Image.network(
        photoUrl, 
        fit: BoxFit.cover, 
        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.person_rounded, color: AppColors.onPrimary, size: 20))
      );
    }
    return const Center(child: Icon(Icons.person_rounded, color: AppColors.onPrimary, size: 20));
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      flexibleSpace: SafeArea(
        child: user == null 
          ? const SizedBox.shrink()
          : StreamBuilder<DocumentSnapshot>(
              // Mendengarkan perubahan data profil user dari Firestore secara real-time
              stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                // Fallback awal jika data masih loading
                String displayName = user?.displayName?.split(' ').first ?? 'there';
                String? photoUrl = user?.photoURL;

                // Jika data Firestore sudah masuk, gunakan data tersebut
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final nameFromDb = data['displayName'] as String?;
                  if (nameFromDb != null && nameFromDb.isNotEmpty) {
                    displayName = nameFromDb.split(' ').first;
                  }
                  photoUrl = data['profilePicture'] as String?;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerMargin, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(greeting,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: AppColors.outline)),
                            const SizedBox(height: 2),
                            Text('Hi, $displayName!',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 20, fontWeight: FontWeight.w700,
                                color: AppColors.onSurface)),
                          ],
                        ),
                      ),
                      
                      // ── Tombol Foto Profil ──
                      GestureDetector(
                        onTap: () {
                          // Menggunakan pushReplacementNamed agar sinkron dengan perilaku Bottom Navigation
                          Navigator.pushReplacementNamed(context, 'profile');
                        },
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: AppRadius.fullBR,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildAvatar(photoUrl),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}

// ── Weather Banner ────────────────────────────────────────────────────────────
class _WeatherBanner extends StatelessWidget {
  final String locationLabel;
  final bool locationLoading;
  final VoidCallback onRequestLocation;

  const _WeatherBanner({
    required this.locationLabel,
    required this.locationLoading,
    required this.onRequestLocation,
  });

  bool get _hasLocation =>
      locationLabel.contains('°') || locationLabel.contains(',');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin, AppSpacing.stackMd,
        AppSpacing.containerMargin, 0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF006E1C), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.xlBR,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locationLabel,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 4),
                  Text(
                    _hasLocation
                        ? 'Location detected!'
                        : 'Enable GPS for smart reminders',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                  if (!_hasLocation) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: locationLoading ? null : onRequestLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.fullBR,
                        ),
                        child: locationLoading
                            ? const SizedBox(
                                width: 12, height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Allow location access',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(_hasLocation ? '📍' : '📍',
                style: const TextStyle(fontSize: 44)),
          ],
        ),
      ),
    );
  }
}

// ── Empty States ──────────────────────────────────────────────────────────────
class _EmptyGarden extends StatelessWidget {
  final VoidCallback onAddPlant;
  const _EmptyGarden({required this.onAddPlant});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.stackXl, horizontal: AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.xlBR,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.fullBR,
            ),
            child: const Center(
              child: Text('🌱', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text('No plants yet',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text(
            'Add your first plant to start\ntracking its care and health',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13, color: AppColors.outline, height: 1.5)),
          const SizedBox(height: AppSpacing.stackLg),
          ElevatedButton.icon(
            onPressed: onAddPlant,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Your First Plant'),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.lgBR,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.mdBR,
            ),
            child: const Center(
              child: Text('✅', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All caught up!',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.onSurface)),
              const SizedBox(height: 2),
              Text('No tasks scheduled for today',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12, color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Plant Card ────────────────────────────────────────────────────────────────
class _PlantCard extends StatelessWidget {
  final Plant plant;
  const _PlantCard({required this.plant});

  // Helper untuk merender gambar (Base64, Network, atau Fallback Emoji)
  Widget _buildImage() {
    if (plant.photoUrl.isNotEmpty) {
      if (plant.photoUrl.startsWith('data:image')) {
        try {
          final base64String = plant.photoUrl.split(',').last;
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } catch (e) {
          return _buildFallback();
        }
      } else {
        return Image.network(
          plant.photoUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      }
    }
    return _buildFallback();
  }

  // Fallback jika tanaman tidak memiliki foto atau foto gagal dimuat
  Widget _buildFallback() {
    return Container(
      color: plant.bgColor,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text(plant.emoji, style: const TextStyle(fontSize: 52)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          'plant-detail',
          arguments: {
            'plantId': plant.id,
            'plantName': plant.name,
            'plantImageUrl': plant.photoUrl,
            'plantLocation': plant.location,
            'plantSpecies': plant.species,
            'plantWateringPeriod': plant.wateringPeriod,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.xlBR,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12, 
                offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildImage(), // Memanggil helper gambar di sini
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(plant.species,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11, color: AppColors.outline)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.fullBR,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💧', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(plant.waterLabel,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.tertiary)),
                      ],
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
}

// ── Task Tile ─────────────────────────────────────────────────────────────────
class _TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;
  const _TaskTile({required this.task, required this.onComplete});
  @override State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _done = false;

  void _toggle() {
    setState(() => _done = !_done);
    if (_done) {
      // Delay Firestore write slightly so the animation plays first
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _done ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.lgBR,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: widget.task.iconBg, borderRadius: AppRadius.mdBR),
              child: Center(
                child: Text(widget.task.icon,
                    style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.task.plant,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                      decoration: _done ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 2),
                  Text(widget.task.action,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12, color: AppColors.outline)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: _done ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: _done ? AppColors.primary : AppColors.outlineVariant,
                    width: 1.5,
                  ),
                  borderRadius: AppRadius.defBR,
                ),
                child: _done
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}