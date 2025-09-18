import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class ChatScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const ChatScreen({super.key, required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text('Chat with $patientName'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Secure messaging functionality coming soon!',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Integrate a real-time messaging solution here.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
