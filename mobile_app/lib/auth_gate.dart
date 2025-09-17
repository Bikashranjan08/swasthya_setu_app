import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/role_selection_screen.dart'; // Import the new role selection screen
import 'package:mobile_app/screens/home_screen.dart'; // Import the home screen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the user is logged in, show the HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          // If the user is NOT logged in, show the RoleSelectionScreen
          return const RoleSelectionScreen();
        }
      },
    );
  }
}
