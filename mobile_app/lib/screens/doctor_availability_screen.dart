import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class DoctorAvailabilityScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;

  const DoctorAvailabilityScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  // Placeholder for available slots
  List<DateTime> _getAvailableSlots() {
    final now = DateTime.now();
    return [
      DateTime(now.year, now.month, now.day, 10, 0),
      DateTime(now.year, now.month, now.day, 11, 0),
      DateTime(now.year, now.month, now.day, 14, 0),
      DateTime(now.year, now.month, now.day + 1, 9, 0),
    ];
  }

  Future<void> _bookAppointment(BuildContext context, DateTime slot) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to book.')));
      return;
    }

    // Show a confirmation dialog
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Appointment'),
        content: Text('Book an appointment with $doctorName at ${slot.hour}:${slot.minute.toString().padLeft(2, '0')}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('appointments').add({
          'patientId': user.uid,
          'patientName': user.displayName ?? 'Unknown Patient',
          'doctorId': doctorId,
          'doctorName': doctorName,
          'appointmentTime': Timestamp.fromDate(slot),
          'status': 'pending',
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booked successfully!')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to book appointment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _getAvailableSlots();

    return Scaffold(
      appBar: CustomAppBar(
        title: Text('Availability for $doctorName'),
      ),
      body: ListView.builder(
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('${slot.day}/${slot.month}/${slot.year}'),
              subtitle: Text('${slot.hour}:${slot.minute.toString().padLeft(2, '0')}'),
              trailing: ElevatedButton(
                onPressed: () => _bookAppointment(context, slot),
                child: const Text('Book'),
              ),
            ),
          );
        },
      ),
    );
  }
}
