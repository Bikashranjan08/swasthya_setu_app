
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final String patientId;

  const AddHealthRecordScreen({super.key, required this.patientId});

  @override
  _AddHealthRecordScreenState createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _symptomsController = TextEditingController();
  final _prescriptionController = TextEditingController();

  /// Adds a new health record to the patient's sub-collection.
  Future<void> _addHealthRecord() async {
    if (_symptomsController.text.isEmpty) {
      print('Please enter symptoms.');
      return;
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      await firestore
          .collection('patients')
          .doc(widget.patientId)
          .collection('health_records')
          .add({
        'symptoms': _symptomsController.text.trim(),
        'prescription': _prescriptionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Health record added successfully for patient: ${widget.patientId}');
      Navigator.pop(context); // Go back after saving.

    } catch (e) {
      print('Error adding health record: $e');
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Health Record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _symptomsController,
              decoration: const InputDecoration(labelText: 'Symptoms'),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _prescriptionController,
              decoration: const InputDecoration(labelText: 'Prescription'),
              maxLines: 3,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _addHealthRecord,
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }
}
