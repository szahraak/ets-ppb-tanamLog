import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tanamlog/theme.dart';
import 'package:tanamlog/firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;
  String _errorCode = "";
  
  final FirestoreService firestoreService = FirestoreService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void navigateLogin() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  void navigateHome() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'home');
  }

  void register() async {
    setState(() {
      _isLoading = true;
      _errorCode = "";
    });
    
    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // Update user display name
      await firestoreService.createUser(userCredential.user!.uid, _nameController.text, null);
      
      navigateLogin();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorCode = e.code;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top spacing
              const SizedBox(height: 60),

              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.eco,
                    size: 60,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                'TanamLog',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Tend to your digital garden',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.outline,
                ),
              ),

              const SizedBox(height: AppSpacing.stackXl),

              // Full Name field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display Name',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'John Doe',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.outline.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: const BorderSide(
                          color: AppColors.primaryDark,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                        vertical: AppSpacing.stackSm,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.stackLg),

              // Email/Username field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'plantlover@example.com',
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: AppColors.outline.withValues(alpha:0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: const BorderSide(
                          color: AppColors.primaryDark,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                        vertical: AppSpacing.stackSm,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.stackLg),

              // Password field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.outline.withValues(alpha: 0.6),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.outline.withValues(alpha:0.6),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdBR,
                        borderSide: const BorderSide(
                          color: AppColors.primaryDark,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                        vertical: AppSpacing.stackSm,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.stackXl),

              // Error code display
              if (_errorCode != "")
                Column(
                  children: [
                    Text(
                      _errorCode,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.error,
                      ), 
                    ),
                    const SizedBox(height: AppSpacing.stackLg)
                  ]
                ),

              // Register button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBR,
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _isLoading 
                      ? [const CircularProgressIndicator(color: Colors.white,)]
                      : [
                      Text(
                        'Register',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.stackXl),

              // Sign in link
              GestureDetector(
                onTap: navigateLogin,
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
