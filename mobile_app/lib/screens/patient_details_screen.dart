import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/screens/add_health_record_screen.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailsScreen({super.key, required this.patientId});

  Future<void> _launchURL(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document URL available.')),
      );
      return;
    }
    if (!await launchUrl(Uri.parse(url))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Patient Details'),
      ),
      body: Column(
        children: [
          // Fetch patient data from the 'users' collection
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
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
                    Text('Name: ${patientData['name'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Age: ${patientData['age'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Contact: ${patientData['contactNumber'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              );
            },
          ),
          const Divider(thickness: 2),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Health Records',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Fetch health records from the top-level collection
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('healthRecords')
                  .where('patientId', isEqualTo: patientId)
                  .orderBy('date', descending: true)
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final data = record.data() as Map<String, dynamic>;
                    final recordDate = (data['date'] as Timestamp).toDate();
                    final documentUrl = data['documentUrl'] as String?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          data['type'] ?? 'Health Record',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Date: ${recordDate.toLocal().toString().split(' ')[0]}'),
                            const SizedBox(height: 4),
                            Text('Doctor: ${data['doctorId'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text(data['description'] ?? 'No description', maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: documentUrl != null
                            ? IconButton(
                                icon: const Icon(Icons.attach_file, color: Colors.blue),
                                tooltip: 'View Document',
                                onPressed: () => _launchURL(context, documentUrl),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHealthRecordScreen(patientId: patientId),
            ),
          );
        },
        label: const Text('Add New Record'),
        icon: const Icon(Icons.note_add),
      ),
    );
  }
}