import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/carry_mark_service.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final AuthService _authService = AuthService();
  final CarryMarkService _carryService = CarryMarkService();

  String _selectedGrade = 'A';
  double _carryMark = 0;
  double? _requiredFinal;

  @override
  Widget build(BuildContext context) {
    final name = widget.userData['name'] ?? widget.userData['email'] ?? 'Student';
    final String? uid = widget.userData['uid'] as String?;

    // ✅ Safety: if uid missing, show clear error instead of using empty path
    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Portal')),
        body: const Center(
          child: Text(
            'Error: Missing user ID.\nPlease re-login or contact the system admin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FB),
      appBar: AppBar(
        title: const Text('Student Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // ✅ Now always a non-empty document path
        stream: _carryService.watchCarryMark(uid),
        builder: (context, snapshot) {
          Map<String, dynamic>? markData;
          if (snapshot.hasData && snapshot.data!.data() != null) {
            markData = snapshot.data!.data();
            _carryMark = (markData?['total'] ?? 0).toDouble();
          } else {
            _carryMark = 0;
          }

          final test = (markData?['test'] ?? 0).toDouble();
          final assignment = (markData?['assignment'] ?? 0).toDouble();
          final project = (markData?['project'] ?? 0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ICT602 – Carry Mark Overview\nTotal carry mark: ${_carryMark.toStringAsFixed(1)} / 50',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Marks breakdown cards
                Row(
                  children: [
                    Expanded(
                      child: _scoreCard(
                        title: 'Test',
                        score: test,
                        max: 20,
                        icon: Icons.assignment_turned_in,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _scoreCard(
                        title: 'Assignment',
                        score: assignment,
                        max: 10,
                        icon: Icons.description_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _scoreCard(
                        title: 'Project',
                        score: project,
                        max: 20,
                        icon: Icons.devices_other,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Target grade calculator
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Grade Calculator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use this tool to see how many marks you need in the final exam (out of 50%) to achieve your target grade.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGrade,
                          decoration: const InputDecoration(
                            labelText: 'Target Grade',
                            border: OutlineInputBorder(),
                          ),
                          items: CarryMarkService.gradeMinOverall.keys.map((grade) {
                            final min = CarryMarkService.gradeMinOverall[grade]!;
                            return DropdownMenuItem(
                              value: grade,
                              child: Text('$grade (min ${min.toInt()}%)'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGrade = value ?? 'A';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              final req = _carryService.requiredFinalForGrade(
                                carryMark: _carryMark,
                                grade: _selectedGrade,
                              );
                              setState(() {
                                _requiredFinal = req;
                              });
                            },
                            child: const Text('Calculate Required Final Mark'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_requiredFinal != null) _buildResultText(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _scoreCard({
    required String title,
    required double score,
    required double max,
    required IconData icon,
  }) {
    final percent = max == 0 ? 0 : (score / max) * 100;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Icon(icon, color: const Color(0xFF0EA5E9)),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${score.toStringAsFixed(1)} / $max',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultText() {
    if (_requiredFinal == -1) {
      return const Text(
        'It is not possible to achieve this grade even with full marks in the final exam.',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
      );
    }
    if (_requiredFinal == 0) {
      return const Text(
        'You already secure this grade even if you get 0 in the final exam (theoretically).',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
      );
    }
    final percent = (_requiredFinal! / 50) * 100;
    return Text(
      'You must score at least ${_requiredFinal!.toStringAsFixed(1)} / 50 '
      '(${percent.toStringAsFixed(1)}%) in the final exam to get grade $_selectedGrade.',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
