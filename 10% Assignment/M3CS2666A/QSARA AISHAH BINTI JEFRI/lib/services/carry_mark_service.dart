import 'package:cloud_firestore/cloud_firestore.dart';

class CarryMarkService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'carryMarks';

  /// Save or update carry mark for a student
  Future<void> saveCarryMark({
    required String studentUid,
    required double test,
    required double assignment,
    required double project,
    required String lecturerUid,
  }) async {
    final total = test + assignment + project; // out of 50

    await _db.collection(collection).doc(studentUid).set({
      'test': test,
      'assignment': assignment,
      'project': project,
      'total': total,
      'updatedBy': lecturerUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Watch a single student’s carry mark (for Student screen)
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCarryMark(String studentUid) {
    return _db.collection(collection).doc(studentUid).snapshots();
  }

  /// Grade minimum overall score (out of 100)
  static const Map<String, double> gradeMinOverall = {
    'A+': 90,
    'A' : 80,
    'A-': 75,
    'B+': 70,
    'B' : 65,
    'B-': 60,
    'C+': 55,
    'C' : 50,
  };

  /// Required final exam mark out of 50
  double requiredFinalForGrade({
    required double carryMark, // 0–50
    required String grade,
  }) {
    final minOverall = gradeMinOverall[grade] ?? 0;
    final required = minOverall - carryMark;

    if (required <= 0) return 0;    // already secure
    if (required > 50) return -1;   // impossible
    return required;                // out of 50
  }
}
