import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class VideoCallScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const VideoCallScreen({super.key, required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text('Video Call with $patientName'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call, size: 100, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              'Video call functionality coming soon!',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Integrate a video conferencing SDK here.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}