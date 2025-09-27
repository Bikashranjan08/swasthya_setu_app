import 'package:mobile_app/screens/pharmacy_stock_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/add_patient_screen.dart';
import 'package:mobile_app/screens/appointment_details_screen.dart';
import 'package:mobile_app/screens/doctor_profile_screen.dart';
import 'package:mobile_app/screens/patient_details_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/screens/doctor_patient_list_screen.dart';
import 'package:mobile_app/screens/health_records_screen.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  final String? role;
  const HomeScreen({super.key, this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted && doc.exists) {
      final data = doc.data()!;
      setState(() {
        _userName = data['name'] ?? user.email;
        _profilePictureUrl = data['profilePictureUrl'];
      });
    }
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'Profile':
        final destination = widget.role == 'doctor' ? const DoctorProfileScreen() : const ProfileScreen();
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination))
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildRoleSpecificBody(context),
      ),
    );
  }

  Widget _buildRoleSpecificBody(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not logged in.'));

    if (widget.role == 'doctor') {
      return _buildDoctorSchedule(context, user);
    } else if (widget.role == 'patient') {
      return _buildPatientAppointments(context, user);
    } else {
      // Default to health worker view
      return _buildHealthWorkerPatients(context, user);
    }
  }

  Widget _buildDoctorSchedule(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 60.0,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorPatientListScreen())),
            icon: const Icon(Icons.people, size: 28.0),
            label: const Text('View All Patients', style: TextStyle(fontSize: 18.0)),
          ),
        ),
        const SizedBox(height: 24.0),
        const Text('My Schedule', style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('doctorId', isEqualTo: user.uid)
                .where('status', whereIn: ['pending', 'booked'])
                .orderBy('appointmentTime')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                // This is where the error is caught
                return Center(child: Text('Error: ${snapshot.error}\n\nPlease ensure the required Firestore index is created.'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('You have no upcoming appointments.'));
              }

              final appointments = snapshot.data!.docs;
              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  final appointmentData = appointment.data() as Map<String, dynamic>;
                  final patientName = appointmentData['patientName'] ?? 'N/A';
                  final appointmentTime = (appointmentData['appointmentTime'] as Timestamp).toDate();
                  final status = appointmentData['status'] ?? 'N/A';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: ListTile(
                      leading: Icon(
                        status == 'pending' ? Icons.hourglass_top : Icons.check_circle,
                        color: status == 'pending' ? Colors.orange : Colors.green,
                      ),
                      title: Text(patientName),
                      subtitle: Text('${appointmentTime.day}/${appointmentTime.month} at ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')}'),
                      trailing: Text(status, style: TextStyle(color: status == 'pending' ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetailsScreen(appointmentId: appointment.id),
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
    );
  }

  Widget _buildHealthWorkerPatients(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 60.0,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPatientScreen())),
            icon: const Icon(Icons.add, size: 28.0),
            label: const Text('Add New Patient', style: TextStyle(fontSize: 18.0)),
          ),
        ),
        const SizedBox(height: 24.0),
        const Text('My Patients', style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patients')
                .where('managedBy', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No patients found.'));
              }

              final patients = snapshot.data!.docs;
              return ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  final patientData = patient.data() as Map<String, dynamic>?;
                  final patientName = patientData?['name'] as String? ?? 'No Name';
                  final patientVillage = patientData?['village'] as String? ?? 'No Village';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(patientName),
                      subtitle: Text('Village: $patientVillage'),
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
        ),
      ],
    );
  }

    Widget _buildPatientAppointments(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 60.0,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthRecordsScreen())),
                  icon: const Icon(Icons.medical_information, size: 28.0),
                  label: const Text('My Health Records', style: TextStyle(fontSize: 18.0)),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: SizedBox(
                height: 60.0,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/pharmacy_stock'),
                  icon: const Icon(Icons.local_pharmacy, size: 28.0),
                  label: const Text('Pharmacy Stock', style: TextStyle(fontSize: 18.0)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        const Text('Upcoming Appointments', style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8.0),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('patientId', isEqualTo: user.uid)
                .orderBy('date', descending: true) // Order by date, newest first
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('You have no upcoming appointments.'));
              }

              final appointments = snapshot.data!.docs;
              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  final appointmentData = appointment.data() as Map<String, dynamic>;
                  final doctorId = appointmentData['doctorId'] as String;
                  final appointmentDate = (appointmentData['date'] as Timestamp).toDate();
                  final appointmentTime = appointmentData['time'] as String; // Assuming time is stored as a string
                  final status = appointmentData['status'] as String;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('doctors').doc(doctorId).get(),
                    builder: (context, doctorSnapshot) {
                      if (doctorSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (doctorSnapshot.hasError) {
                        return Text('Error: ${doctorSnapshot.error}');
                      }
                      final doctorName = doctorSnapshot.data?['name'] ?? 'Unknown Doctor';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: ListTile(
                          leading: _buildStatusIcon(status),
                          title: Text('Dr. $doctorName'),
                          subtitle: Text('${_formatDate(appointmentDate)} at $appointmentTime\nStatus: ${status.replaceAll('_', ' ').toUpperCase()}'),
                          trailing: status == 'confirmed' || status == 'pending'
                              ? ElevatedButton(
                                  onPressed: () => _showRescheduleDialog(context, appointment.id, appointmentDate, appointmentTime),
                                  child: const Text('Reschedule'),
                                )
                              : null,
                          onTap: () {
                            // Navigate to appointment details if needed
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Icon _buildStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'pending':
        return const Icon(Icons.hourglass_top, color: Colors.orange);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'reschedule_requested':
        return const Icon(Icons.update, color: Colors.blue);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showRescheduleDialog(BuildContext context, String appointmentId, DateTime currentAppointmentDate, String currentAppointmentTime) async {
    DateTime? pickedDate = currentAppointmentDate;
    TimeOfDay? pickedTime = TimeOfDay.fromDateTime(DateTime.parse('2023-01-01 ${currentAppointmentTime.split(' ')[0]}:00')); // Assuming time is "HH:MM AM/PM"

    await showDatePicker(
      context: context,
      initialDate: currentAppointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        pickedDate = date;
        return showTimePicker(
          context: context,
          initialTime: pickedTime!,
        );
      }
      return null;
    }).then((time) {
      if (time != null) {
        pickedTime = time;
      }
    });

    if (pickedDate != null && pickedTime != null) {
      final newDateTime = DateTime(
        pickedDate!.year,
        pickedDate!.month,
        pickedDate!.day,
        pickedTime!.hour,
        pickedTime!.minute,
      );

      // Format new date and time for the backend
      final newDateString = '${newDateTime.year}-${newDateTime.month.toString().padLeft(2, '0')}-${newDateTime.day.toString().padLeft(2, '0')}';
      final newTimeString = '${pickedTime!.hour.toString().padLeft(2, '0')}:${pickedTime!.minute.toString().padLeft(2, '0')}';

      // Call the Cloud Function
      try {
        await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
          'status': 'reschedule_requested',
          'rescheduleRequest': {
            'newDate': newDateString,
            'newTime': newTimeString,
            'status': 'pending', // Status of the reschedule request itself
            'requestedBy': FirebaseAuth.instance.currentUser!.uid,
            'requestedAt': FieldValue.serverTimestamp(),
          },
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule request sent successfully!')),
        );
        // Optionally refresh appointments or update local state
      } catch (e) {
        print('Error requesting reschedule: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }
}
