import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/theme.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  bool _isUpdatingImage = false;

  // ── Image Picker Properties ───────────────────────────────────────────────
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile', style: textTheme.headlineSmall),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load profile'));
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final displayName = userData['displayName'] ?? 'TanamLog User';
                final photoUrl = userData['profilePicture'];
                final email = _auth.currentUser?.email ?? 'user@email.com';

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.stackLg),
                      _buildProfileHeader(displayName, email, photoUrl, textTheme),
                      const SizedBox(height: AppSpacing.stackXxl),
                      _buildMenuSection(textTheme, displayName),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Profile Header (Avatar, Name, Email) ──────────────────────────────────
  Widget _buildProfileHeader(String name, String email, String? photoUrl, TextTheme textTheme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surfaceContainer,
              // Gunakan helper untuk mendeteksi apakah ini File lokal, Base64, atau URL biasa
              backgroundImage: _getAvatarProvider(photoUrl),
              child: (_imageFile == null && (photoUrl == null || photoUrl.isEmpty))
                  ? const Icon(Icons.person, size: 50, color: AppColors.outlineVariant)
                  : _isUpdatingImage 
                      ? const CircularProgressIndicator(color: AppColors.primary) 
                      : null,
            ),
            GestureDetector(
              onTap: _showImageSourceActionSheet,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.stackXs),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.onPrimary, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text(name, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.stackXs),
        Text(email, style: textTheme.bodyMedium?.copyWith(color: AppColors.outline)),
      ],
    );
  }

  // ── Helper: Mendapatkan Image Provider ────────────────────────────────────
  ImageProvider? _getAvatarProvider(String? photoUrl) {
    // 1. Jika user baru saja memilih gambar, prioritaskan file lokal
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    
    // 2. Jika ada photoUrl dari Firestore
    if (photoUrl != null && photoUrl.isNotEmpty) {
      // Jika datanya adalah string Base64 (seperti yang disimpan di FormPlantScreen)
      if (photoUrl.startsWith('data:image')) {
        try {
          final base64String = photoUrl.split(',').last;
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          return null; // Fallback jika decode gagal
        }
      }
      // Jika datanya URL internet standar
      return NetworkImage(photoUrl);
    }
    
    // 3. Fallback jika tidak ada gambar
    return null; 
  }

  // ── Image Picker Logic ────────────────────────────────────────────────────
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

  Future<void> _pickImage(ImageSource source) async {
    try {
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
        
        // Otomatis simpan ke Firestore setelah gambar dipilih
        await _saveProfilePictureToFirestore();
      }
    } catch (e) {
      // PERBAIKAN: Tambahkan cek mounted
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveProfilePictureToFirestore() async {
    if (_imageFile == null) return;

    setState(() => _isUpdatingImage = true);

    try {
      // Convert ke base64 (Sama persis seperti di FormPlantScreen)
      final bytes = await _imageFile!.readAsBytes();
      final base64String = base64Encode(bytes);
      final imageData = 'data:image/jpeg;base64,$base64String';

      // Update document user di Firestore
      await _firestoreService.updateUser(widget.uid, {
        'profilePicture': imageData,
      });
      
      // Memicu rebuild untuk menyegarkan FutureBuilder jika perlu
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update picture: $e')),
        );
      }
    } finally {
      setState(() => _isUpdatingImage = false);
    }
  }

  // ── Menu Section ──────────────────────────────────────────────────────────
  Widget _buildMenuSection(TextTheme textTheme, String currentName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Settings', style: textTheme.titleSmall?.copyWith(color: AppColors.outline)),
        const SizedBox(height: AppSpacing.stackMd),
        
        _ProfileMenuTile(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          subtitle: 'Change your name',
          onTap: () => _showEditProfileDialog(currentName),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        _ProfileMenuTile(
          icon: Icons.email_outlined,
          title: 'Change Email',
          subtitle: 'Update your email address',
          onTap: () => _showChangeEmailDialog(),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        _ProfileMenuTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your security credentials',
          onTap: () => _showChangePasswordDialog(),
        ),
        
        const SizedBox(height: AppSpacing.stackXxl),
        Text('Action', style: textTheme.titleSmall?.copyWith(color: AppColors.outline)),
        const SizedBox(height: AppSpacing.stackMd),
        
        _ProfileMenuTile(
          icon: Icons.logout,
          title: 'Logout',
          iconColor: AppColors.error,
          textColor: AppColors.error,
          hideArrow: true,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  // ── Logic & Dialogs ───────────────────────────────────────────────────────

  Future<void> _reauthenticateUser(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Melakukan re-auth
      await user.reauthenticateWithCredential(credential);
    }
  }

  void _showEditProfileDialog(String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      // PERBAIKAN: Ganti nama parameter menjadi dialogContext
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); // Tutup pakai dialogContext
              setState(() => _isLoading = true);
              try {
                await _firestoreService.updateUser(widget.uid, {
                  'displayName': nameController.text.trim(),
                });
                
                // PERBAIKAN: Cek mounted
                if (!mounted) return;
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              } catch (e) {
                // PERBAIKAN: Cek mounted
                if (!mounted) return;
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true; // State untuk toggle visibility password

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.outline,
                    ),
                    onPressed: () {
                      // Gunakan setDialogState khusus untuk me-rebuild dialog
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'New Email Address',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: () async {
                final newEmail = emailController.text.trim();
                final currentPassword = passwordController.text;

                if (newEmail.isEmpty || currentPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email dan password tidak boleh kosong.')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);

                try {
                  await _reauthenticateUser(currentPassword);
                  await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification link sent to new email. Please check your inbox.')),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = 'Failed to update email.';
                  if (e.code == 'wrong-password') message = 'Password saat ini salah.';
                  if (e.code == 'invalid-email') message = 'Format email tidak valid.';
                  if (e.code == 'email-already-in-use') message = 'Email sudah digunakan oleh akun lain.';
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                } finally {
                  if (context.mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    
    // State terpisah untuk masing-masing field password
    bool obscureOldPassword = true;
    bool obscureNewPassword = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: obscureOldPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.outline,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureOldPassword = !obscureOldPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.outline,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureNewPassword = !obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: () async {
                final oldPw = oldPasswordController.text;
                final newPw = newPasswordController.text;
                
                if (oldPw.isEmpty || newPw.isEmpty) return;

                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);

                try {
                  await _reauthenticateUser(oldPw);
                  await _auth.currentUser?.updatePassword(newPw);
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully.')),
                  );
                } on FirebaseAuthException catch (e) {
                  String message = e.code == 'wrong-password' 
                      ? 'Password lama salah.' 
                      : 'Error: ${e.message}';
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    try {
      await _auth.signOut();
      
      // PERBAIKAN: Cek mounted sebelum navigasi
      if (!mounted) return;
      
      // Navigate ke login setelah sign out
      Navigator.of(context).pushReplacementNamed('login');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    } catch (e) {
      // PERBAIKAN: Cek mounted sebelum SnackBar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 3,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      onDestinationSelected: (int index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, 'home');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, 'garden');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, 'reminder');
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
          icon: Icon(Icons.calendar_month, color: AppColors.outline),
          label: 'Reminders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person, color: AppColors.primaryDark),
          label: 'Profile',
        ),
      ],
    );
  }
}

// ── Custom Widget: Profile Menu Tile ────────────────────────────────────────
class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final bool hideArrow;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.primaryDark,
    this.textColor = AppColors.onSurface,
    this.hideArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBR,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.stackSm),
              decoration: BoxDecoration(
                color: hideArrow ? AppColors.errorContainer : AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.stackLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium?.copyWith(color: textColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: textTheme.bodySmall),
                  ]
                ],
              ),
            ),
            if (!hideArrow) const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}