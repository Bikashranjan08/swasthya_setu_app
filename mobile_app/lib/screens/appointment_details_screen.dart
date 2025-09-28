import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/health_records_screen.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Future<void> _updateAppointmentStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({'status': status});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment has been $status.')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating appointment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Appointment Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error loading appointment details.'));
          }

          final appointmentData = snapshot.data!.data() as Map<String, dynamic>;
          final patientId = appointmentData['patientId'];
          final appointmentTime = (appointmentData['appointmentTime'] as Timestamp).toDate();
          final status = appointmentData['status'] ?? 'N/A';

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
            builder: (context, patientSnapshot) {
              if (patientSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (patientSnapshot.hasError || !patientSnapshot.hasData || !patientSnapshot.data!.exists) {
                return const Center(child: Text('Error loading patient details.'));
              }

              final patientData = patientSnapshot.data!.data() as Map<String, dynamic>;
              final patientName = patientData['name'] ?? 'N/A';
              final patientAge = patientData['age'] ?? 'N/A';
              final patientContact = patientData['contact'] ?? 'N/A';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: $patientName', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Age: $patientAge', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Contact: $patientContact', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Time: ${appointmentTime.day}/${appointmentTime.month} at ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Status: $status', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HealthRecordsScreen(patientId: patientId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.medical_information),
                      label: const Text('View Health Records'),
                    ),
                    const Spacer(),
                    if (status == 'pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _updateAppointmentStatus('booked'),
                            icon: const Icon(Icons.check),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _updateAppointmentStatus('rejected'),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
