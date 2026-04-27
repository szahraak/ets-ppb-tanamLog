import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/theme.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Mengambil UID user yang sedang login
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Garden',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserPlantsStream(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load garden data.'),
            );
          }

          final plantDocs = snapshot.data?.docs ?? [];

          if (plantDocs.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.gutter,
              crossAxisSpacing: AppSpacing.gutter,
              childAspectRatio: 0.78,
            ),
            itemCount: plantDocs.length,
            itemBuilder: (context, index) {
              final doc = plantDocs[index];
              return _GardenPlantCard(doc: doc);
            },
          );
        },
      ),
      // Tombol FAB untuk tambah tanaman dari halaman ini
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => Navigator.pushNamed(context, 'add-plant'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppSpacing.stackLg),
          Text(
            'Your garden is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Add some plants to see them here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 1,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      onDestinationSelected: (int index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, 'home');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, 'reminder');
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
          icon: Icon(Icons.local_florist, color: AppColors.primaryDark),
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

// ── Komponen Card Khusus Halaman Garden ─────────────────────────────────────
class _GardenPlantCard extends StatelessWidget {
  final DocumentSnapshot doc;

  const _GardenPlantCard({required this.doc});

  // Helper konversi periode siram
  String _waterLabel(int days) {
    if (days == 1) return 'Every day';
    if (days <= 3) return 'Every $days days';
    if (days == 7) return 'Weekly';
    return 'Every $days days';
  }

  // Helper render gambar
  Widget _buildImage(String photoUrl, String emoji, Color bgColor) {
    if (photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        try {
          final base64String = photoUrl.split(',').last;
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } catch (_) {
          return _buildFallback(emoji, bgColor);
        }
      } else {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildFallback(emoji, bgColor),
        );
      }
    }
    return _buildFallback(emoji, bgColor);
  }

  Widget _buildFallback(String emoji, Color bgColor) {
    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 52)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    
    final id = doc.id;
    final name = data['name'] as String? ?? '';
    final species = data['species'] as String? ?? '';
    final emoji = data['emoji'] as String? ?? '🌿';
    final photoUrl = data['photoUrl'] as String? ?? '';
    final location = data['location'] as String? ?? 'indoor';
    final wateringPeriod = data['wateringPeriod'] as int? ?? 7;
    final bgColor = Color(data['bgColor'] as int? ?? 0xFFE8F5E9);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          'plant-detail',
          arguments: {
            'plantId': id,
            'plantName': name,
            'plantImageUrl': photoUrl,
            'plantLocation': location,
            'plantSpecies': species,
            'plantWateringPeriod': wateringPeriod,
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildImage(photoUrl, emoji, bgColor),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(species,
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
                        Text(_waterLabel(wateringPeriod),
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