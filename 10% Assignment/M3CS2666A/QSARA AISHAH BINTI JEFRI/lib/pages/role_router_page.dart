import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'student_home_page.dart';
import 'lecturer_home_page.dart';
import 'admin_home_page.dart';

class RoleRouterPage extends StatelessWidget {
  RoleRouterPage({super.key, required this.userId});

  final String userId;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _authService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snapshot.data!;
        if (!doc.exists) {
          return const Scaffold(
            body: Center(child: Text('User profile not found.')),
          );
        }

        final data = doc.data()!;
        final role = data['role'] as String? ?? 'student';

        // 🔑 include uid in userData so child pages can access it
        final userDataWithUid = {
          ...data,
          'uid': userId,
        };

        if (role == 'lecturer') {
          return LecturerHomePage(userData: userDataWithUid);
        } else if (role == 'student') {
          return StudentHomePage(userData: userDataWithUid);
        } else if (role == 'admin') {
          return AdminHomePage(userData: userDataWithUid);
        }

        return const Scaffold(
          body: Center(child: Text('Unknown role.')),
        );
      },
    );
  }
}
