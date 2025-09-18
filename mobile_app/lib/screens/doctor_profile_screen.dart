import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();

  XFile? _profileImage;
  String? _profileImageUrl;
  XFile? _licenseImage;
  String? _licenseImageUrl;
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
      _specialtyController.text = data['specialty'] ?? '';
      setState(() {
        _profileImageUrl = data['profilePictureUrl'];
        _licenseImageUrl = data['licenseImageUrl'];
      });
    }
  }

  Future<XFile?> _pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  Future<String?> _uploadImage(XFile image, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
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
    String? newProfileUrl = _profileImageUrl;
    String? newLicenseUrl = _licenseImageUrl;

    if (_profileImage != null) {
      newProfileUrl = await _uploadImage(_profileImage!, 'user_profiles/${user.uid}.jpg');
    }
    if (_licenseImage != null) {
      newLicenseUrl = await _uploadImage(_licenseImage!, 'doctor_licenses/${user.uid}.jpg');
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameController.text,
      'specialty': _specialtyController.text,
      'email': user.email,
      'profilePictureUrl': newProfileUrl,
      'licenseImageUrl': newLicenseUrl,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Edit Doctor Profile'),
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
                      controller: _specialtyController,
                      decoration: const InputDecoration(labelText: 'Specialty'),
                      validator: (value) => value!.isEmpty ? 'Please enter your specialty' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildLicenseUpload(context),
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
          onPressed: () async {
            final image = await _pickImage();
            if (image != null) setState(() => _profileImage = image);
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('Change Picture'),
        ),
      ],
    );
  }

  Widget _buildLicenseUpload(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Doctor License Verification', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_licenseImageUrl != null && _licenseImage == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Image.network(_licenseImageUrl!, height: 100),
          ),
        if (_licenseImage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Image.file(File(_licenseImage!.path), height: 100),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final image = await _pickImage();
            if (image != null) setState(() => _licenseImage = image);
          },
          icon: const Icon(Icons.upload_file),
          label: Text(_licenseImageUrl != null || _licenseImage != null ? 'Change License' : 'Upload License'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }
}
