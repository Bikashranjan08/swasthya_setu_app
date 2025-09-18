import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/screens/add_health_record_screen.dart';
import 'package:mobile_app/screens/video_call_screen.dart';
import 'package:mobile_app/screens/chat_screen.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Patient Details'),
      ),
      body: Column(
        children: [
          // Use a FutureBuilder to fetch patient data once.
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Patient not found.')),
                );
              }

              final patientData = snapshot.data!.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${patientData['name']}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Age: ${patientData['age']}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Village: ${patientData['village']}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Health Records', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Use a StreamBuilder to listen for health record updates.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .doc(patientId)
                  .collection('health_records')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No health records found.'));
                }

                final records = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final symptoms = record['symptoms'] as String? ?? 'N/A';
                    final prescription = record['prescription'] as String? ?? 'N/A';
                    final timestamp = record['timestamp'] as Timestamp?;
                    final date = timestamp != null ? timestamp.toDate().toLocal().toString().split(' ')[0] : 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text('Symptoms: $symptoms'),
                        subtitle: Text('Prescription: $prescription'),
                        trailing: Text(date),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(); // Or a loading indicator
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Container(); // Handle error or patient not found
          }

          final patientData = snapshot.data!.data() as Map<String, dynamic>;
          final patientName = patientData['name'] ?? 'Patient';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'addRecord',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddHealthRecordScreen(patientId: patientId),
                      ),
                    );
                  },
                  label: const Text('Add Record'),
                  icon: const Icon(Icons.note_add),
                ),
                FloatingActionButton.extended(
                  heroTag: 'videoCall',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoCallScreen(patientId: patientId, patientName: patientName),
                      ),
                    );
                  },
                  label: const Text('Video Call'),
                  icon: const Icon(Icons.video_call),
                ),
                FloatingActionButton.extended(
                  heroTag: 'chat',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(patientId: patientId, patientName: patientName),
                      ),
                    );
                  },
                  label: const Text('Chat'),
                  icon: const Icon(Icons.chat),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
