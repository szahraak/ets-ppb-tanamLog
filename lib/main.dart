import 'package:firebase_core/firebase_core.dart';
import 'package:tanamlog/screens/register.dart';
import 'package:tanamlog/screens/login.dart';
import 'package:tanamlog/screens/homepage.dart';
import 'package:tanamlog/screens/form_plant.dart';
import 'package:tanamlog/screens/plant_detail.dart';
import 'package:tanamlog/screens/profile.dart';
import 'package:tanamlog/screens/reminder.dart';
import 'package:tanamlog/screens/garden.dart';
import 'package:tanamlog/theme.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Awesome Notifications
  AwesomeNotifications().initialize(
    null, // icon default (null pakai icon app)
    [
      NotificationChannel(
        channelKey: 'watering_channel',
        channelName: 'Watering Reminders',
        channelDescription: 'Notification channel for plant watering schedules',
        defaultColor: const Color(0xFF2D6A4F),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      )
    ],
    debug: true
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TanamLog',
      theme: appTheme(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Selama Firebase masih mengecek status, tampilkan loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Jika ada data user (berarti sudah login), arahkan ke HomeScreen
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          
          // Jika tidak ada data user (berarti belum login / sudah logout), arahkan ke LoginScreen
          return const LoginScreen();
        },
      ),

      routes: {
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        'home': (context) => const HomeScreen(),
        'garden': (context) => const GardenScreen(),
        'profile': (context) => ProfileScreen(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
        'reminder': (context) => RemindersScreen(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
      },
      onGenerateRoute: (settings) {
        if (settings.name == 'add-plant') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => FormPlantScreen(
              plantId: args?['plantId'],
              plantName: args?['plantName'],
              plantSpecies: args?['plantSpecies'],
              plantLocation: args?['plantLocation'],
              plantWateringPeriod: args?['plantWateringPeriod'],
              plantImageUrl: args?['plantImageUrl'],
            ),
          );
        }
        if (settings.name == 'plant-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PlantDetailScreen(
              plantId: args['plantId'],
              plantName: args['plantName'],
              plantImageUrl: args['plantImageUrl'],
              plantLocation: args['plantLocation'],
              plantSpecies: args['plantSpecies'],
              plantWateringPeriod: args['plantWateringPeriod'],
            ),
          );
        }
        return null;
      },
    );
  }
}