import 'package:flutter/material.dart';

class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  bool _licenseUploaded = false;

  void _uploadLicense() {
    // TEMP: mock upload
    setState(() {
      _licenseUploaded = true;
    });
  }

  void _submit() {
    if (_licenseUploaded) {
      Navigator.pushReplacementNamed(context, '/approval-pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Documents')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Driving License',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _uploadLicense,
              child: Text(
                _licenseUploaded
                    ? 'License Uploaded ✓'
                    : 'Upload License',
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _licenseUploaded ? _submit : null,
                child: const Text('Submit for Approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
