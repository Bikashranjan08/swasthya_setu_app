import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: true, // Placeholder value
            onChanged: (bool value) {
              // Handle change
            },
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: false, // Placeholder value
            onChanged: (bool value) {
              // Handle change
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English'),
            leading: const Icon(Icons.language),
            onTap: () {
              // Open language selection
            },
          ),
          ListTile(
            title: const Text('About Us'),
            leading: const Icon(Icons.info),
            onTap: () {
              // Navigate to about us page
            },
          ),
        ],
      ),
    );
  }
}