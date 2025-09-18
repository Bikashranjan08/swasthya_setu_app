import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // New import
import 'package:mobile_app/widgets/custom_app_bar.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _villageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _savePatient() async {
    final String name = _nameController.text.trim();
    final int? age = int.tryParse(_ageController.text.trim());
    final String village = _villageController.text.trim();

    if (name.isEmpty || age == null || village.isEmpty) {
      // Optionally show a snackbar or alert for validation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    try {
      // Add a new document to the 'patients' collection.
      // Firestore will automatically create the collection if it doesn't exist.
      await FirebaseFirestore.instance.collection('patients').add({
        'name': name,
        'age': age,
        'village': village,
        'managedBy': user.uid, // Add managedBy field
        'timestamp': FieldValue.serverTimestamp(), // Optional: add a timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient added successfully!')),
      );
      Navigator.of(context).pop(); // Go back to the previous screen
    } catch (e) {
      // Handle any errors during the save operation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add patient: $e')),
      );
      print('Error saving patient: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Add New Patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Patient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _villageController,
              decoration: const InputDecoration(
                labelText: 'Village',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _savePatient,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: const Text(
                'Save Patient',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}