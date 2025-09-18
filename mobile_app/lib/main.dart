import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // New import
import 'package:mobile_app/auth_gate.dart'; // New import for AuthGate
import 'package:mobile_app/role_selection_screen.dart'; // New import for RoleSelectionScreen
import 'package:mobile_app/screens/login_screen.dart'; // Keep login screen for routing from role selection
import 'package:mobile_app/screens/add_patient_screen.dart'; // Keep add patient screen for routing
import 'package:mobile_app/screens/home_screen.dart'; // Keep home screen for routing
import 'package:mobile_app/screens/welcome_screen.dart'; // Keep welcome screen for routing
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Enable Firestore offline data persistence
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swasthya Setu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomeScreen(), // Set WelcomeScreen as the home widget
      routes: {
        '/welcome': (context) => const WelcomeScreen(), // Keep for consistency, though home handles it
        '/auth_gate': (context) => const AuthGate(), // New route for AuthGate
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return LoginScreen(selectedRole: args ?? 'unknown');
        },
        '/add_patient': (context) => const AddPatientScreen(),
        '/home': (context) => const HomeScreen(), // Explicit route for home screen
      },
    );
  }
}                       