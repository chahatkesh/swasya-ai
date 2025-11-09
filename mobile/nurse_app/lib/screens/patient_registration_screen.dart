import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';
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
      final queueId = response['queue_id'];  // NEW: Get queue_id from registration
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_patient_id', patientId);
      await prefs.setString('current_queue_id', queueId);  // NEW: Store queue_id
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
      final response = await ApiService.addToQueue(
        uhid: _uhidController.text.trim(),
        priority: 'normal',
      );

      final queueId = response['queue_entry']['queue_id'];  // NEW: Extract queue_id from response

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_patient_id', _existingPatient!['patient_id']);
      await prefs.setString('current_queue_id', queueId);  // NEW: Store queue_id
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Check-in',
          style: AppTypography.h3Card.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.badge_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    
                    // Title
                    Text(
                      _patientExists ? 'Welcome Back!' : 'Patient Registration',
                      style: AppTypography.h2Section.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      _patientExists 
                          ? 'Patient found in system' 
                          : 'Enter UHID to check registration',
                      style: AppTypography.bodyRegular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xxxl),

                    // UHID Field
                    TextFormField(
                      controller: _uhidController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'UHID (Unified Health ID)',
                        hintText: 'Enter government health ID',
                        prefixIcon: Icon(
                          Icons.fingerprint,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        suffixIcon: _uhidController.text.isNotEmpty && !_patientExists
                            ? IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                onPressed: _checkUHID,
                              )
                            : null,
                      ),
                      enabled: !_patientExists,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'UHID is required';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}),
                      onFieldSubmitted: (_) => _checkUHID(),
                    ),
                    SizedBox(height: AppSpacing.lg),

                    // Check UHID Button
                    if (!_uhidChecked)
                      ElevatedButton.icon(
                        onPressed: _checkUHID,
                        icon: Icon(Icons.search, size: 20, color: AppColors.secondary),
                        label: const Text('Check UHID'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.secondary,
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                    // Patient Status Banner
                    if (_uhidChecked) ...[
                      Container(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: _patientExists 
                              ? AppColors.success.withOpacity(0.12)
                              : AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _patientExists ? AppColors.success : AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: _patientExists 
                                    ? AppColors.success
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _patientExists ? Icons.check : Icons.person_add_outlined,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _patientExists 
                                    ? 'Existing Patient Found' 
                                    : 'New Patient Registration',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(
                            _patientExists ? Icons.lock_outline : Icons.person_outline,
                            color: _patientExists ? AppColors.textTertiary : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        enabled: !_patientExists,
                        validator: (value) {
                          if (!_patientExists && (value == null || value.trim().isEmpty)) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.lg),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(
                            _patientExists ? Icons.lock_outline : Icons.phone_outlined,
                            color: _patientExists ? AppColors.textTertiary : AppColors.primary,
                            size: 22,
                          ),
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
                      SizedBox(height: AppSpacing.lg),

                      // Age and Gender Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Age',
                                prefixIcon: Icon(
                                  _patientExists ? Icons.lock_outline : Icons.calendar_today_outlined,
                                  color: _patientExists ? AppColors.textTertiary : AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_patientExists,
                            ),
                          ),
                          SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: Icon(
                                  _patientExists ? Icons.lock_outline : Icons.wc_outlined,
                                  color: _patientExists ? AppColors.textTertiary : AppColors.primary,
                                  size: 22,
                                ),
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
                      SizedBox(height: AppSpacing.xxxl),

                      // Submit Button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _patientExists ? _addToQueue : _registerPatient,
                          icon: Icon(
                            _patientExists ? Icons.playlist_add : Icons.person_add_outlined,
                            size: 20,
                            color: AppColors.secondary,
                          ),
                          label: Text(
                            _patientExists ? 'Add to Queue' : 'Register New Patient',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _patientExists ? AppColors.success : AppColors.primary,
                            foregroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Helper text
                    if (!_uhidChecked) ...[
                      SizedBox(height: AppSpacing.xxl),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Enter the patient\'s UHID to check if they are already registered.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
