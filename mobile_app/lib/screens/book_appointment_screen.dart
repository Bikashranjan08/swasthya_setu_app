import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// A placeholder for the next step
import 'package:mobile_app/screens/doctor_availability_screen.dart'; 
import 'package:mobile_app/widgets/custom_app_bar.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Book an Appointment'),
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
              final String profileUrl = doctorData?['profilePictureUrl'] ?? 'https://via.placeholder.com/150';

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
                    // Navigate to a screen showing this doctor's availability
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorAvailabilityScreen(
                          doctorId: doctor.id,
                          doctorName: doctorName,
                        ),
                      ),
                    );
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
