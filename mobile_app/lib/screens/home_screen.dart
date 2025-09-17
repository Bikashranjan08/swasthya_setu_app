import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/add_patient_screen.dart';
import 'package:mobile_app/screens/patient_details_screen.dart'; // Assuming this screen exists

/// A reusable stateless widget for displaying action cards on the home screen.
class HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48.0,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The main dashboard screen for a logged-in health worker.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Function to handle user logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate back to the login screen after logout
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // Function to navigate to the AddPatientScreen
  void _navigateToAddPatient() {
    Navigator.pushNamed(context, '/add_patient');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String workerName = user?.displayName ?? user?.email ?? 'Health Worker';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swasthya-Setu'),
        actions: [
          // Notification bell icon
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notification functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Welcome, $workerName!',
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),
            // Button to add new patient
            SizedBox(
              width: double.infinity,
              height: 60.0,
              child: ElevatedButton.icon(
                onPressed: _navigateToAddPatient,
                icon: const Icon(Icons.add, size: 28.0),
                label: const Text(
                  'Add New Patient',
                  style: TextStyle(fontSize: 18.0),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            // Grid of action cards
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Query Firestore for patients managed by the current user.
                stream: FirebaseFirestore.instance
                    .collection('patients')
                    .where('managedBy', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Show a loading indicator while waiting for data.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Show an error message if something goes wrong.
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  // If there's no data, show a message.
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      children: [
                        HomeActionCard(
                          icon: Icons.people_outline,
                          title: 'My Patients',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No patients yet. Add one!')),
                            );
                          },
                        ),
                        HomeActionCard(
                          icon: Icons.video_call_outlined,
                          title: 'Start Consultation',
                          onTap: () {
                            // TODO: Implement consultation logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Consultation feature coming soon!')),
                            );
                          },
                        ),
                        HomeActionCard(
                          icon: Icons.medical_services_outlined,
                          title: 'Symptom Checker',
                          onTap: () {
                            // TODO: Implement symptom checker logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Symptom checker coming soon!')),
                            );
                          },
                        ),
                        HomeActionCard(
                          icon: Icons.local_pharmacy_outlined,
                          title: 'Find Medicines',
                          onTap: () {
                            // TODO: Implement medicine finder logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Medicine finder coming soon!')),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  // If data is available, display it in a ListView.
                  final patients = snapshot.data!.docs;

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: [
                      HomeActionCard(
                        icon: Icons.people_outline,
                        title: 'My Patients (${patients.length})',
                        onTap: () {
                          // Navigate to a screen that lists all patients
                          // For now, we'll just show a snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Displaying all patients below!')),
                          );
                        },
                      ),
                      HomeActionCard(
                        icon: Icons.video_call_outlined,
                        title: 'Start Consultation',
                        onTap: () {
                          // TODO: Implement consultation logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Consultation feature coming soon!')),
                          );
                        },
                      ),
                      HomeActionCard(
                        icon: Icons.medical_services_outlined,
                        title: 'Symptom Checker',
                        onTap: () {
                          // TODO: Implement symptom checker logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Symptom checker coming soon!')),
                          );
                        },
                      ),
                      HomeActionCard(
                        icon: Icons.local_pharmacy_outlined,
                        title: 'Find Medicines',
                        onTap: () {
                          // TODO: Implement medicine finder logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Medicine finder coming soon!')),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24.0),
            // Displaying the list of patients below the grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('patients')
                    .where('managedBy', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No patients found. Add one using the + button.'));
                  }

                  final patients = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      final patientName = patient['name'] as String? ?? 'No Name';
                      final patientVillage = patient['village'] as String? ?? 'No Village';
                      final patientAge = patient['age'] as int? ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        elevation: 2.0,
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: Text('$patientName ($patientAge years)'),
                          subtitle: Text('Village: $patientVillage'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Navigate to patient details screen
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
            ),
          ],
        ),
      ),
    );
  }
}