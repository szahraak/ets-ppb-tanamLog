import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tanamlog/services/notification_services.dart';

class FirestoreService {
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  final CollectionReference plants = FirebaseFirestore.instance.collection('plants');
  final CollectionReference schedules = FirebaseFirestore.instance.collection('schedules');

  // ── User Methods ──────────────────────────────────────────────────────────
  // Add a new user
  Future<void> createUser(String uid, String displayName, String? profilePicture) async {
    return await users.doc(uid).set({
      'displayName': displayName,
      'profilePicture': profilePicture,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user data
  Future<DocumentSnapshot> getUser(String uid) async {
    return await users.doc(uid).get();
  }

  // Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    return await users.doc(uid).update(data);
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    return await users.doc(uid).delete();
  }

  // ── Plant Methods ─────────────────────────────────────────────────────────
  // Add a new plant
  Future<DocumentReference> addPlant(String uid, String name, String? species, String photoUrl, String location, int wateringPeriod) async {
    return await plants.add({
      'uid': uid,
      'name': name,
      'species': species,
      'photoUrl': photoUrl,
      'location': location,
      'wateringPeriod': wateringPeriod, // default watering period in days
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all plants for a user
  Future<QuerySnapshot> getUserPlants(String uid) async {
    return await plants.where('uid', isEqualTo: uid).get();
  }

  // Stream plants for real-time updates
  Stream<QuerySnapshot> getUserPlantsStream(String uid) {
    return plants.where('uid', isEqualTo: uid).snapshots();
  }

  // Get single plant
  Future<DocumentSnapshot> getPlant(String plantId) async {
    return await plants.doc(plantId).get();
  }

  // Update plant
  Future<void> updatePlant(String plantId, Map<String, dynamic> data) async {
    return await plants.doc(plantId).update(data);
  }

  // Delete plant
  Future<void> deletePlant(String plantId) async {
    final associatedSchedules = await schedules
        .where('plantId', isEqualTo: plantId)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in associatedSchedules.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(plants.doc(plantId));

    return await batch.commit();
  }

  Future<bool> checkIfAlreadyWateredToday(String plantId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final snapshot = await plants
        .doc(plantId)
        .collection('careLogs')
        .where('activityType', isEqualTo: 'watered')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ── Schedule Methods ──────────────────────────────────────────────────────
  // Add a schedule
  Future<DocumentReference> addSchedule(
    String uid,
    String plantId,
    String action,
    DateTime dueDate,
  ) async {
    return await schedules.add({
      'uid': uid,
      'plantId': plantId,
      'action': action,
      'dueDate': Timestamp.fromDate(dueDate),
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all schedules for a user
  Future<QuerySnapshot> getUserSchedules(String uid) async {
    return await schedules
        .where('uid', isEqualTo: uid)
        .orderBy('dueDate')
        .get();
  }

  // Stream today's tasks for real-time updates
  Stream<QuerySnapshot> getTodayTasksStream(String uid) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return schedules
        .where('uid', isEqualTo: uid)
        .where('completed', isEqualTo: false)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dueDate')
        .snapshots();
  }

  // Mark schedule as completed and automatically create a care log entry
  Future<void> completeSchedule(String scheduleId) async {
    // 1. Ambil data schedule terlebih dahulu
    final scheduleDoc = await schedules.doc(scheduleId).get();
    if (!scheduleDoc.exists) return;

    final data = scheduleDoc.data() as Map<String, dynamic>;
    final plantId = data['plantId'] as String;
    final action = data['action'] as String;
    final uid = data['uid'] as String;

    // 2. Tentukan activityType berdasarkan teks action (Mapping)
    String activityType = 'watered'; 
    final a = action.toLowerCase();
    bool isWatering = a.contains('water');
    
    if (a.contains('fertiliz')) {
      activityType = 'fertilized';
    } else if (a.contains('repot')) {
      activityType = 'repotted';
    } else if (a.contains('prun')) {
      activityType = 'pruned';
    }

    // 3. Ambil data tanaman untuk mendapatkan wateringPeriod (Strategi A)
    final plantDoc = await plants.doc(plantId).get();
    final plantData = plantDoc.data() as Map<String, dynamic>;
    final int wateringPeriod = plantData['wateringPeriod'] ?? 7;
    final String plantName = plantData['name'] ?? 'Tanaman';

    // 4. Gunakan WriteBatch agar semua perubahan data konsisten
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Buat log aktivitas
    DocumentReference logRef = plants.doc(plantId).collection('careLogs').doc();
    batch.set(logRef, {
      'plantId': plantId,
      'activityType': activityType,
      'dateTime': FieldValue.serverTimestamp(),
      'note': 'Completed via smart reminder',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Tandai schedule lama sebagai completed
    batch.update(schedules.doc(scheduleId), {
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Jika aktivitasnya adalah menyiram, buat jadwal baru otomatis
    if (isWatering) {
      DateTime nextDate = DateTime.now().add(Duration(days: wateringPeriod));
      
      // Tambah jadwal baru ke Firestore
      DocumentReference nextScheduleRef = schedules.doc();
      batch.set(nextScheduleRef, {
        'uid': uid,
        'plantId': plantId,
        'action': 'Watering',
        'dueDate': Timestamp.fromDate(nextDate),
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Jadwalkan notifikasi lokal di HP (Jam 7 Pagi)
      await NotificationService.scheduleWatering(
        id: plantId.hashCode, // Menggunakan hash plantId agar ID notifikasi unik per tanaman
        plantName: plantName,
        nextDate: nextDate,
      );
    }

    // 5. Eksekusi semua perintah database dalam satu waktu
    return await batch.commit();
  }

  // Delete schedule
  Future<void> deleteSchedule(String scheduleId) async {
    return await schedules.doc(scheduleId).delete();
  }

  // ── Care Log Methods ──────────────────────────────────────────────────────
  // Add a care log entry
  Future<DocumentReference> addCareLog(
    String plantId,
    String activityType,
    DateTime dateTime,
    String? note,
  ) async {
    return await plants.doc(plantId).collection('careLogs').add({
      'plantId': plantId,
      'activityType': activityType,
      'dateTime': Timestamp.fromDate(dateTime),
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all care logs for a plant
  Future<QuerySnapshot> getCareLogsForPlant(String plantId) async {
    return await plants
        .doc(plantId)
        .collection('careLogs')
        .orderBy('dateTime', descending: true)
        .get();
  }

  // Stream care logs for real-time updates
  Stream<QuerySnapshot> streamCareLogsForPlant(String plantId) {
    return plants
        .doc(plantId)
        .collection('careLogs')
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  // Update care log
  Future<void> updateCareLog(
    String plantId, 
    String careLogId, 
    String activityType, 
    DateTime dateTime, 
    String? note
  ) async {
    return await plants.doc(plantId).collection('careLogs').doc(careLogId).update({
      'activityType': activityType,
      'dateTime': Timestamp.fromDate(dateTime),
      'note': note,
    });
  }

  // Delete care log
  Future<void> deleteCareLog(String plantId, String careLogId) async {
    return await plants
        .doc(plantId)
        .collection('careLogs')
        .doc(careLogId)
        .delete();
  }

  Future<void> handleManualWatering(String uid, String plantId) async {
    // 1. Ambil data tanaman
    final plantDoc = await plants.doc(plantId).get();
    if (!plantDoc.exists) return;
    final plantData = plantDoc.data() as Map<String, dynamic>;
    
    // 2. Batalkan notifikasi yang sudah ada agar tidak double
    await NotificationService.cancelNotification(plantId.hashCode);

    // 3. Cari jika ada schedule 'Watering' yang pending untuk tanaman ini, lalu hapus/selesaikan
    final pendingSchedules = await schedules
        .where('plantId', isEqualTo: plantId)
        .where('completed', isEqualTo: false)
        .where('action', isEqualTo: 'Watering')
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in pendingSchedules.docs) {
      batch.update(doc.reference, {'completed': true, 'completedAt': FieldValue.serverTimestamp()});
    }

    // 4. Buat jadwal baru untuk masa depan
    int period = plantData['wateringPeriod'] ?? 7;
    DateTime nextDate = DateTime.now().add(Duration(days: period));
    
    DocumentReference nextScheduleRef = schedules.doc();
    batch.set(nextScheduleRef, {
      'uid': uid,
      'plantId': plantId,
      'action': 'Watering',
      'dueDate': Timestamp.fromDate(nextDate),
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Jadwalkan notifikasi HP baru
    await NotificationService.scheduleWatering(
      id: plantId.hashCode,
      plantName: plantData['name'],
      nextDate: nextDate,
    );
  }

  // ── Health Journal Methods ────────────────────────────────────────────────
  // Add a health journal entry
  Future<DocumentReference> addHealthJournal(
    String plantId,
    String currentHealth,
    String observation,
    String? photoUrl,
    DateTime dateTime,
  ) async {
    return await plants.doc(plantId).collection('healthJournal').add({
      'plantId': plantId,
      'currentHealth': currentHealth,
      'observation': observation,
      'photoUrl': photoUrl,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all health journal entries for a plant
  Future<QuerySnapshot> getHealthJournalForPlant(String plantId) async {
    return await plants
        .doc(plantId)
        .collection('healthJournal')
        .orderBy('dateTime', descending: true)
        .get();
  }

  // Stream health journal for real-time updates
  Stream<QuerySnapshot> streamHealthJournalForPlant(String plantId) {
    return plants
        .doc(plantId)
        .collection('healthJournal')
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  // Update health journal entry
  Future<void> updateHealthJournal(
    String plantId, 
    String journalId, 
    String currentHealth, 
    String observation, 
    String? photoUrl, 
    DateTime dateTime
  ) async {
    return await plants.doc(plantId).collection('healthJournal').doc(journalId).update({
      'currentHealth': currentHealth,
      'observation': observation,
      'photoUrl': photoUrl,
      'dateTime': Timestamp.fromDate(dateTime),
    });
  }

  // Delete health journal entry
  Future<void> deleteHealthJournal(String plantId, String journalId) async {
    return await plants
        .doc(plantId)
        .collection('healthJournal')
        .doc(journalId)
        .delete();
  }
}