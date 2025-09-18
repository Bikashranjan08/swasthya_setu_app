import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Select Your Role'),
        // No leading or actions in original, so none here.
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Button for Patient role
            ElevatedButton(
              onPressed: () {
                // Navigate to login/register screen, passing 'patient' role
                Navigator.of(context).pushNamed('/login', arguments: 'patient');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'I am a Patient',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            const SizedBox(height: 20.0),
            // Button for Health Worker role
            ElevatedButton(
              onPressed: () {
                // Navigate to login/register screen, passing 'health_worker' role
                Navigator.of(context).pushNamed('/login', arguments: 'health_worker');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'I am a Health Worker',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            const SizedBox(height: 20.0),
            // Button for Doctor role
            ElevatedButton(
              onPressed: () {
                // Navigate to login/register screen, passing 'doctor' role
                Navigator.of(context).pushNamed('/login', arguments: 'doctor');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'I am a Doctor',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
