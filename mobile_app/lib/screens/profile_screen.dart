import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _contactController = TextEditingController();

  XFile? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _fatherNameController.text = data['fatherName'] ?? '';
      _contactController.text = data['contactNumber'] ?? '';
      setState(() {
        _profileImageUrl = data['profilePictureUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _profileImage = pickedFile;
      }
    });
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseStorage.instance.ref().child('user_profiles').child('${user.uid}.jpg');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser!;
    String? imageUrl = _profileImageUrl;

    if (_profileImage != null) {
      imageUrl = await _uploadImage(_profileImage!); 
    }

    if (imageUrl != null || _profileImage == null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _nameController.text,
            'age': int.tryParse(_ageController.text) ?? 0,
            'fatherName': _fatherNameController.text,
            'contactNumber': _contactController.text,
            'email': user.email, // Save email for reference
            'profilePictureUrl': imageUrl,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
    } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile could not be saved. Image upload failed.')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfilePicture(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Please enter your age' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fatherNameController,
                      decoration: const InputDecoration(labelText: 'Father\'s Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Contact Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePicture() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _profileImage != null
              ? FileImage(File(_profileImage!.path))
              : (_profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : const NetworkImage('https://via.placeholder.com/150')) as ImageProvider,
        ),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Change Picture'),
        ),
      ],
    );
  }

   @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _fatherNameController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}
