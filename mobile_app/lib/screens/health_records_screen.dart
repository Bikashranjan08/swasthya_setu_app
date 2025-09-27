import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/add_health_record_screen.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    if (result == true) {
      setState(() {}); // This will trigger a rebuild and fetch the latest data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('My Health Records'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('healthRecords')
            .where('patientId', isEqualTo: _auth.currentUser!.uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have no health records yet.\nAdd one using the button below.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final records = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final data = record.data() as Map<String, dynamic>;
              final recordDate = (data['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
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
                      Text(data['description'] ?? 'No description'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data['documentUrl'] != null)
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.blue),
                          onPressed: () => _launchURL(data['documentUrl']!),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () {
                          final initialData = data;
                          initialData['id'] = record.id; // Pass document ID for updates
                           _navigateAndRefresh(AddHealthRecordScreen(initialData: initialData));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(const AddHealthRecordScreen()),
        child: const Icon(Icons.add),
        tooltip: 'Add Health Record',
      ),
    );
  }
}