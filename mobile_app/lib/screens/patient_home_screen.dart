import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/book_appointment_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  String? _userName;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? user.email;
          _profilePictureUrl = data['profilePictureUrl'];
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'Profile':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
            .then((_) => _loadUserData());
        break;
      case 'Settings':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
        break;
      case 'Logout':
        FirebaseAuth.instance.signOut();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        leading: const SizedBox.shrink(), // equivalent to automaticallyImplyLeading: false,
        title: Text(_userName != null ? 'Welcome, ${_userName!}' : 'Welcome!'),
        actions: [
          CircleAvatar(
            backgroundImage: _profilePictureUrl != null
                ? NetworkImage(_profilePictureUrl!)
                : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuSelection(context, value),
            itemBuilder: (BuildContext context) {
              return {'Profile', 'Settings', 'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUpcomingAppointmentCard(context),
            const SizedBox(height: 24),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(context),
            const SizedBox(height: 24),
            _buildRecentPrescriptionsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'booked'])
          .orderBy('appointmentTime')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('You have no upcoming appointments.')),
            ),
          );
        }

        final appointment = snapshot.data!.docs.first;
        final appointmentData = appointment.data() as Map<String, dynamic>;
        final doctorName = appointmentData['doctorName'] ?? 'N/A';
        final appointmentTime = (appointmentData['appointmentTime'] as Timestamp).toDate();
        final status = appointmentData['status'] ?? 'N/A';

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upcoming Appointment', style: Theme.of(context).textTheme.titleLarge),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'pending' ? Colors.orange.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'pending' ? Colors.orange.shade800 : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: NetworkImage('https://via.placeholder.com/150/92c952'),
                  ),
                  title: Text(doctorName),
                  subtitle: Text('${appointmentTime.day}/${appointmentTime.month} at ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')}'),
                ),
                if (status == 'booked')
                  const SizedBox(height: 16),
                if (status == 'booked')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async { // Added async here
                          try {
                            var jitsiMeet = JitsiMeet(); // Instantiated JitsiMeet
                            final options = JitsiMeetConferenceOptions(
                              serverURL: "https://meet.jit.si", // Corrected parameter name
                              room: "SwasthyaSetuAppointment123", // Use a unique ID here in a real app
                              configOverrides: {
                                "startWithAudioMuted": false,
                                "startWithVideoMuted": false,
                              },
                              featureFlags: {
                                "add-people.enabled": false,
                                "invite.enabled": false,
                                "welcomepage.enabled": false,
                              },
                            );
                            
                            await jitsiMeet.join(options); // Corrected call
                          } catch (error) {
                            // Handle error, e.g., show a snackbar
                            debugPrint("Error joining Jitsi meeting: $error");
                          }
                        },
                        icon: const Icon(Icons.video_call),
                        label: const Text('Join Video Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Reschedule'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildQuickActionItem(context, Icons.calendar_today, 'Book Appointment', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BookAppointmentScreen()));
        }),
        _buildQuickActionItem(context, Icons.folder_shared, 'My Health Records', () {}),
        _buildQuickActionItem(context, Icons.local_pharmacy, 'Pharmacy Stock', () {}),
        _buildQuickActionItem(context, Icons.check_circle_outline, 'Symptom Checker', () {}),
      ],
    );
  }

  Widget _buildQuickActionItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPrescriptionsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Prescriptions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildPrescriptionItem('15 Sep 2025', 'Prescription for fever'),
            const Divider(),
            _buildPrescriptionItem('28 Aug 2025', 'Follow-up medication'),
            const Divider(),
            _buildPrescriptionItem('10 Jul 2025', 'General check-up prescription'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionItem(String date, String description) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.receipt_long),
      title: Text(description),
      subtitle: Text(date),
      trailing: TextButton(
        onPressed: () {},
        child: const Text('View Details'),
      ),
    );
  }
}