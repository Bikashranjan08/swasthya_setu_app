import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/patient_details_screen.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class DoctorPatientListScreen extends StatefulWidget {
  const DoctorPatientListScreen({super.key});

  @override
  State<DoctorPatientListScreen> createState() => _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends State<DoctorPatientListScreen> {
  Future<List<DocumentSnapshot>>? _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = _fetchPatients();
  }

  Future<List<DocumentSnapshot>> _fetchPatients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // 1. Find all appointments for the current doctor
    final appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: user.uid)
        .get();

    if (appointmentsSnapshot.docs.isEmpty) return [];

    // 2. Get a unique set of patient IDs
    final patientIds = appointmentsSnapshot.docs
        .map((doc) => doc.data()['patientId'] as String?)
        .where((id) => id != null)
        .toSet();

    if (patientIds.isEmpty) return [];

    // 3. Fetch the user document for each unique patient ID
    // Note: Firestore 'whereIn' query is limited to 30 items per query.
    // For larger lists, this would need to be broken into multiple queries.
    final patientsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: patientIds.toList())
        .get();

    return patientsSnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('My Patients'),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No patients with past or present appointments found.'));
          }

          final patients = snapshot.data!;
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              final patientData = patient.data() as Map<String, dynamic>?;
              final patientName = patientData?['name'] as String? ?? 'No Name';
              final profilePictureUrl = patientData?['profilePictureUrl'] as String?;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                        ? NetworkImage(profilePictureUrl)
                        : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                  ),
                  title: Text(patientName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailsScreen(patientId: patient.id),
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