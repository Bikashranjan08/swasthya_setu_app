import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class VideoConsultationQueueScreen extends StatefulWidget {
  const VideoConsultationQueueScreen({super.key});

  @override
  State<VideoConsultationQueueScreen> createState() => _VideoConsultationQueueScreenState();
}

class _VideoConsultationQueueScreenState extends State<VideoConsultationQueueScreen> {

  Stream<QuerySnapshot>? _todayAppointmentsStream;

  @override
  void initState() {
    super.initState();
    _setupAppointmentsStream();
  }

  void _setupAppointmentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Calculate the start and end of the current day
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    setState(() {
      _todayAppointmentsStream = FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'booked') // Only show booked appointments
          .where('appointmentTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('appointmentTime')
          .snapshots();
    });
  }

  void _joinMeeting(String appointmentId) {
    var jitsiMeet = JitsiMeet();
    final options = JitsiMeetConferenceOptions(
      serverURL: "https://meet.jit.si",
      room: appointmentId, // Use the unique appointment ID for the room name
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Today\'s Consultation Queue'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _todayAppointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}\n\nPlease ensure the required Firestore index is created.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No appointments scheduled for today.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final data = appointment.data() as Map<String, dynamic>;
              final patientName = data['patientName'] ?? 'N/A';
              final appointmentTime = (data['appointmentTime'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    child: Text(DateFormat('hh:mm a').format(appointmentTime)),
                    radius: 40,
                  ),
                  title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Ready for consultation'),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _joinMeeting(appointment.id),
                    icon: const Icon(Icons.video_call),
                    label: const Text('Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
