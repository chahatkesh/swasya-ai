import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uhidController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  
  String? _selectedGender;
  bool _isLoading = false;
  bool _uhidChecked = false;
  bool _patientExists = false;
  Map<String, dynamic>? _existingPatient;

  @override
  void dispose() {
    _uhidController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _checkUHID() async {
    final uhid = _uhidController.text.trim();
    if (uhid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UHID')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.checkUHID(uhid);
      
      setState(() {
        _uhidChecked = true;
        _patientExists = response['exists'] == true;
        _existingPatient = response['patient'];
        _isLoading = false;
      });

      if (_patientExists) {
        _nameController.text = _existingPatient!['name'] ?? '';
        _phoneController.text = _existingPatient!['phone'] ?? '';
        _ageController.text = _existingPatient!['age']?.toString() ?? '';
        _selectedGender = _existingPatient!['gender'];

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${_existingPatient!['name']}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _nameController.clear();
        _phoneController.clear();
        _ageController.clear();
        _selectedGender = null;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New patient - please complete registration'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.registerPatient(
        uhid: _uhidController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
      );

      final patientId = response['patient_id'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_patient_id', patientId);
      await prefs.setString('current_patient_uhid', _uhidController.text.trim());
      await prefs.setString('current_patient_name', _nameController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient registered! ID: $patientId'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addToQueue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.addToQueue(
        uhid: _uhidController.text.trim(),
        priority: 'normal',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_patient_id', _existingPatient!['patient_id']);
      await prefs.setString('current_patient_uhid', _uhidController.text.trim());
      await prefs.setString('current_patient_name', _existingPatient!['name']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_existingPatient!['name']} added to queue!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Check-in'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.badge, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      _patientExists ? 'Welcome Back!' : 'Patient Registration',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _uhidController,
                      decoration: InputDecoration(
                        labelText: 'UHID (Unified Health ID) *',
                        hintText: 'Enter government health ID',
                        prefixIcon: const Icon(Icons.fingerprint),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _checkUHID,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      enabled: !_patientExists,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'UHID is required';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _checkUHID(),
                    ),
                    const SizedBox(height: 16),

                    if (!_uhidChecked)
                      ElevatedButton.icon(
                        onPressed: _checkUHID,
                        icon: const Icon(Icons.search),
                        label: const Text('Check UHID'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                    if (_uhidChecked) ...[
                      const Divider(height: 32),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _patientExists ? Colors.green.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _patientExists ? Colors.green : Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _patientExists ? Icons.check_circle : Icons.person_add,
                              color: _patientExists ? Colors.green : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _patientExists ? 'Existing Patient Found' : 'New Patient Registration',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _patientExists ? Colors.green.shade900 : Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(
                            _patientExists ? Icons.lock : Icons.person,
                            color: _patientExists ? Colors.grey : null,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        enabled: !_patientExists,
                        validator: (value) {
                          if (!_patientExists && (value == null || value.trim().isEmpty)) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(
                            _patientExists ? Icons.lock : Icons.phone,
                            color: _patientExists ? Colors.grey : null,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        enabled: !_patientExists,
                        validator: (value) {
                          if (!_patientExists) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                              return 'Enter valid 10-digit phone number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                prefixIcon: Icon(
                                  _patientExists ? Icons.lock : Icons.calendar_today,
                                  color: _patientExists ? Colors.grey : null,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_patientExists,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: Icon(
                                  _patientExists ? Icons.lock : Icons.wc,
                                  color: _patientExists ? Colors.grey : null,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Male')),
                                DropdownMenuItem(value: 'female', child: Text('Female')),
                                DropdownMenuItem(value: 'other', child: Text('Other')),
                              ],
                              onChanged: _patientExists ? null : (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _patientExists ? _addToQueue : _registerPatient,
                          icon: Icon(_patientExists ? Icons.playlist_add : Icons.person_add),
                          label: Text(_patientExists ? 'Add to Queue' : 'Register New Patient'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _patientExists ? Colors.green : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],

                    if (!_uhidChecked) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Enter the patient\'s UHID to check if they are already registered.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
