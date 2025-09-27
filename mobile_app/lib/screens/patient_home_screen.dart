import 'package:mobile_app/screens/pharmacy_stock_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/book_appointment_screen.dart';
import 'package:mobile_app/screens/health_records_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import '../symptom_checker_screen.dart';
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
        leading: const SizedBox.shrink(), 
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
            Text('Upcoming Appointments', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildUpcomingAppointments(context),
            const SizedBox(height: 24),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'booked', 'rejected'])
          .orderBy('appointmentTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You have no upcoming appointments.'));
        }

        final appointments = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return _buildAppointmentCard(context, appointment);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, QueryDocumentSnapshot appointment) {
    final appointmentData = appointment.data() as Map<String, dynamic>;
    final doctorName = appointmentData['doctorName'] ?? 'N/A';
    final appointmentTime = (appointmentData['appointmentTime'] as Timestamp).toDate();
    final status = appointmentData['status'] ?? 'N/A';

    Color statusColor;
    Color statusTextColor;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange.shade100;
        statusTextColor = Colors.orange.shade800;
        break;
      case 'booked':
        statusColor = Colors.green.shade100;
        statusTextColor = Colors.green.shade800;
        break;
      case 'rejected':
        statusColor = Colors.red.shade100;
        statusTextColor = Colors.red.shade800;
        break;
      default:
        statusColor = Colors.grey.shade100;
        statusTextColor = Colors.grey.shade800;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(doctorName, style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year} at ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 16),
            if (status == 'booked' || status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'booked')
                  ElevatedButton.icon(
                    onPressed: () {
                      var jitsiMeet = JitsiMeet();
                      final options = JitsiMeetConferenceOptions(
                        serverURL: "https://meet.jit.si",
                        room: appointment.id,
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
                      jitsiMeet.join(options);
                    },
                    icon: const Icon(Icons.video_call),
                    label: const Text('Join Call'),
                     style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookAppointmentScreen(
                            isReschedule: true,
                            appointmentId: appointment.id,
                          ),
                        ),
                      );
                    },
                    child: const Text('Reschedule'),
                  ),
                ],
              ),
          ],
        ),
      ),
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
        _buildQuickActionItem(context, Icons.folder_shared, 'My Health Records', () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthRecordsScreen()));
        }),
        _buildQuickActionItem(context, Icons.local_pharmacy, 'Pharmacy Stock', () {
          Navigator.pushNamed(context, '/pharmacy_stock');
        }),
        _buildQuickActionItem(context, Icons.check_circle_outline, 'Symptom Checker', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SymptomCheckerScreen()));
        }),
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
}
