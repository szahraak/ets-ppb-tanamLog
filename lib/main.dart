import 'package:firebase_core/firebase_core.dart';
import 'package:tanamlog/screens/register.dart';
import 'package:tanamlog/screens/homepage.dart';
import 'package:tanamlog/screens/form_plant.dart';
import 'package:tanamlog/screens/plant_detail.dart';
import 'package:tanamlog/theme.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:tanamlog/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: 'home', 
      routes: {
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        'home': (context) => const HomeScreen(),
        'add-plant': (context) => const FormPlantScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == 'plant-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PlantDetailScreen(
              plantId: args['plantId'],
              plantName: args['plantName'],
              plantImageUrl: args['plantImageUrl'],
            ),
          );
        }
        return null;
      },
    );
  }
}