import 'package:cloud_firestore/cloud_firestore.dart';

class HealthJournal {
  final String id;
  final String plantId;
  final String currentHealth; // 'excellent', 'good', 'fair', 'poor'
  final String observation;
  final String? photoUrl;
  final DateTime dateTime;
  final Timestamp createdAt;

  HealthJournal({
    required this.id,
    required this.plantId,
    required this.currentHealth,
    required this.observation,
    this.photoUrl,
    required this.dateTime,
    required this.createdAt,
  });

  factory HealthJournal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthJournal(
      id: doc.id,
      plantId: data['plantId'] ?? '',
      currentHealth: data['currentHealth'] ?? 'good',
      observation: data['observation'] ?? '',
      photoUrl: data['photoUrl'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plantId': plantId,
      'currentHealth': currentHealth,
      'observation': observation,
      'photoUrl': photoUrl,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': createdAt,
    };
  }
}
