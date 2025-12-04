import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/carry_mark_service.dart';

class LecturerHomePage extends StatefulWidget {
  const LecturerHomePage({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  State<LecturerHomePage> createState() => _LecturerHomePageState();
}

class _LecturerHomePageState extends State<LecturerHomePage> {
  final AuthService _authService = AuthService();
  final CarryMarkService _carryService = CarryMarkService();
  final _formKey = GlobalKey<FormState>();

  String? _selectedStudentUid;
  String? _selectedStudentName;
  double _test = 0;
  double _assignment = 0;
  double _project = 0;
  bool _saving = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final name = widget.userData['name'] ?? widget.userData['email'] ?? 'Lecturer';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FB),
      appBar: AppBar(
        title: const Text('Lecturer Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ICT602 – Mobile Application Development\nCarry Mark Management Portal',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick info cards (mock institutional-feel)
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.assignment,
                    title: 'Assessment Breakdown',
                    subtitle: 'Test 20% • Assignment 10% • Project 20%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    icon: Icons.info_outline,
                    title: 'Tip',
                    subtitle:
                        'Students see real-time marks & can plan their final exam target.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Carry mark entry section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter / Update ICT602 Carry Marks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select a student and enter their marks. Total carry mark is out of 50% (20 + 10 + 20).',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 🔽 Student dropdown with better handling
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'student')
                          // .orderBy('name') // you can re-enable after index created
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                            'Failed to load student list.',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData) {
                          return const Text(
                            'No data received from Firestore.',
                            style: TextStyle(color: Colors.black54),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return const Text(
                            'No students found.\n\n'
                            'Hint: Make sure you have at least one document\n'
                            'in the "users" collection with role = "student".',
                            style: TextStyle(color: Colors.black54),
                            textAlign: TextAlign.center,
                          );
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedStudentUid,
                          decoration: const InputDecoration(
                            labelText: 'Select Student',
                            border: OutlineInputBorder(),
                          ),
                          items: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final studentName =
                                data['name'] ?? data['email'] ?? 'Unnamed Student';
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(studentName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStudentUid = value;
                              final studentDoc =
                                  docs.firstWhere((d) => d.id == value);
                              final data =
                                  studentDoc.data() as Map<String, dynamic>;
                              _selectedStudentName =
                                  data['name'] ?? data['email'] ?? 'Student';
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a student' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _numberField(
                                  label: 'Test (out of 20)',
                                  onSaved: (v) => _test = v,
                                  max: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _numberField(
                                  label: 'Assignment (out of 10)',
                                  onSaved: (v) => _assignment = v,
                                  max: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _numberField(
                            label: 'Project (out of 20)',
                            onSaved: (v) => _project = v,
                            max: 20,
                          ),
                          const SizedBox(height: 16),

                          // Live total preview
                          if (_selectedStudentName != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Updating marks for: $_selectedStudentName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),

                          if (_message != null)
                            Text(
                              _message!,
                              style: TextStyle(
                                color: _message!.startsWith('Error')
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: const Text('Save Carry Mark'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE0E7FF),
              child: Icon(icon, color: const Color(0xFF4F46E5)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required String label,
    required void Function(double) onSaved,
    required double max,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        final val = double.tryParse(value);
        if (val == null) return 'Invalid number';
        if (val < 0 || val > max) return '0 – $max only';
        return null;
      },
      onSaved: (value) {
        onSaved(double.tryParse(value ?? '0') ?? 0);
      },
    );
  }

  Future<void> _save() async {
    if (_selectedStudentUid == null) {
      setState(() {
        _message = 'Error: Please select a student first.';
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final String? lecturerUid = widget.userData['uid'] as String?;
      await _carryService.saveCarryMark(
        studentUid: _selectedStudentUid!,
        test: _test,
        assignment: _assignment,
        project: _project,
        lecturerUid: lecturerUid ?? '',
      );
      final total = _test + _assignment + _project;
      setState(() {
        _message =
            'Carry mark saved successfully. Total = ${total.toStringAsFixed(1)} / 50';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }
}
