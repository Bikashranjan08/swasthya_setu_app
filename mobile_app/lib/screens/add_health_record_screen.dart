import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:mobile_app/services/image_upload_service.dart';
import 'package:mobile_app/widgets/custom_app_bar.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final String? patientId;
  final Map<String, dynamic>? initialData;

  const AddHealthRecordScreen({super.key, this.patientId, this.initialData});

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  XFile? _pickedFile;
  String? _documentUrl;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _doctorController.text = widget.initialData!['doctorId'] ?? '';
      _typeController.text = widget.initialData!['type'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _selectedDate = (widget.initialData!['date'] as Timestamp?)?.toDate();
      _documentUrl = widget.initialData!['documentUrl'];
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (mounted) {
      setState(() {
        _pickedFile = pickedFile;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? newDocumentUrl = _documentUrl;

    if (_pickedFile != null) {
      newDocumentUrl = await ImageUploadService().uploadImage(_pickedFile!); 
    }

    setState(() {
      _isUploading = false;
    });

    if (newDocumentUrl == null && _pickedFile != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload document. Please try again.')),
        );
      }
      return;
    }

    try {
      final recordData = {
        'doctorId': _doctorController.text,
        'type': _typeController.text,
        'description': _descriptionController.text,
        'date': Timestamp.fromDate(_selectedDate!),
        'documentUrl': newDocumentUrl,
      };

      if (widget.initialData != null) {
        await FirebaseFirestore.instance
            .collection('healthRecords')
            .doc(widget.initialData!['id'])
            .update(recordData);
      } else {
        final patientId = widget.patientId ?? FirebaseAuth.instance.currentUser!.uid;
        recordData['patientId'] = patientId;
        recordData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('healthRecords').add(recordData);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save record: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.initialData != null ? 'Edit Health Record' : 'Add Health Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Record Type (e.g., Prescription)'),
                validator: (value) => value!.isEmpty ? 'Please enter a record type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(labelText: 'Doctor Name'),
                 validator: (value) => value!.isEmpty ? 'Please enter a doctor name' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildFileUploadSection(),
              const SizedBox(height: 32),
              if (_isUploading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.initialData != null ? 'Update Record' : 'Add Record'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), // Full width
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supporting Document', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_pickedFile != null)
          Row(
            children: [
              const Icon(Icons.file_present, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_pickedFile!.name, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _pickedFile = null),
              )
            ],
          )
        else if (_documentUrl != null)
          Row(
            children: [
              const Icon(Icons.file_present, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Current document exists.', overflow: TextOverflow.ellipsis),
              ),
               IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _documentUrl = null),
              )
            ],
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_file),
          label: Text(_documentUrl != null || _pickedFile != null ? 'Change Document' : 'Upload Document'),
        ),
      ],
    );
  }
}
