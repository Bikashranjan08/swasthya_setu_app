import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/doctor_availability_screen.dart'; 
import 'package:mobile_app/widgets/custom_app_bar.dart';

class BookAppointmentScreen extends StatefulWidget {
  final bool isReschedule;
  final String? appointmentId;

  const BookAppointmentScreen({
    super.key,
    this.isReschedule = false,
    this.appointmentId,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  Future<void> _rescheduleAppointment(String doctorId, DateTime newTime) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'appointmentTime': Timestamp.fromDate(newTime),
        'status': 'pending', // Or a new status like 'reschedule_pending'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reschedule request sent successfully!')),
      );
      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reschedule: $e')),
      );
    }
  }

  Future<void> _selectDateTimeAndReschedule(String doctorId, String doctorName) async {
    final now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (pickedTime == null) return;

    final newAppointmentTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reschedule'),
          content: Text(
              'Reschedule appointment with $doctorName to ${newAppointmentTime.toString()}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _rescheduleAppointment(doctorId, newAppointmentTime);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.isReschedule ? 'Reschedule Appointment' : 'Book an Appointment'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No doctors available at the moment.'));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              final doctorData = doctor.data() as Map<String, dynamic>?;

              final String doctorName = doctorData?['name'] ?? 'Unnamed Doctor';
              final String specialty = doctorData?['specialty'] ?? 'General Physician';
              final String profileUrl =
                  doctorData?['profilePictureUrl'] ?? 'https://via.placeholder.com/150';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(profileUrl),
                  ),
                  title: Text(doctorName),
                  subtitle: Text(specialty),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    if (widget.isReschedule) {
                      _selectDateTimeAndReschedule(doctor.id, doctorName);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorAvailabilityScreen(
                            doctorId: doctor.id,
                            doctorName: doctorName,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}