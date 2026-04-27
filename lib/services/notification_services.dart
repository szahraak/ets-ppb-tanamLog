import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Minta izin notifikasi
  static Future<void> requestPermission(BuildContext context) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    
    if (!isAllowed) {
      if (!context.mounted) return; 
      
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog( // Menggunakan dialogContext untuk builder
          title: const Text('Allow Notifications'),
          content: const Text('TanamLog needs to send you watering reminders.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text('Don\'t Allow'),
            ),
            TextButton(
              onPressed: () async {
                // PERBAIKAN: Gunakan await daripada .then untuk alur yang lebih aman
                await AwesomeNotifications().requestPermissionToSendNotifications();
                
                // Cek kembali apakah context dialog masih valid sebelum menutup
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Allow'),
            ),
          ],
        ),
      );
    }
  }

  // Buat jadwal notifikasi berulang berdasarkan hari
  static Future<void> scheduleWatering(int id, String plantName, int days) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'watering_channel',
        title: 'Time to water $plantName! 💧',
        body: 'Your plant needs some love today.',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationInterval(
        // PERBAIKAN 1: Gunakan Duration, bukan int detik
        interval: Duration(days: days), 
        repeats: true,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }
}