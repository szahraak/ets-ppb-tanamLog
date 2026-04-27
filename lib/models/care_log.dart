import 'package:cloud_firestore/cloud_firestore.dart';

class CareLog {
  final String id;
  final String plantId;
  final String activityType; // 'watered', 'fertilized', 'repotted', 'pruned', etc.
  final DateTime dateTime;
  final String? note;
  final Timestamp createdAt;

  CareLog({
    required this.id,
    required this.plantId,
    required this.activityType,
    required this.dateTime,
    this.note,
    required this.createdAt,
  });

  factory CareLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CareLog(
      id: doc.id,
      plantId: data['plantId'] ?? '',
      activityType: data['activityType'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      note: data['note'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plantId': plantId,
      'activityType': activityType,
      'dateTime': Timestamp.fromDate(dateTime),
      'note': note,
      'createdAt': createdAt,
    };
  }
}
