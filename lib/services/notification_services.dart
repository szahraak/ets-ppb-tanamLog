import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:tanamlog/firestore.dart';
import 'package:tanamlog/main.dart'; 
import 'package:bot_toast/bot_toast.dart';

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
  static Future<void> scheduleWatering({
    required int id,
    required String plantName,
    required DateTime nextDate, // Tanggal spesifik hasil perhitungan waterPeriod
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'watering_channel',
        title: 'Time to water $plantName! 💧',
        body: 'Your plant needs some love today.',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        payload: {'plantId': id.toString()},
      ),
      schedule: NotificationCalendar(
        year: nextDate.year,
        month: nextDate.month,
        day: nextDate.day,
        hour: 7,
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: false, // Kita buat false agar kita bisa kontrol manual setiap penyiraman
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> initializeNotificationListeners() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        // Ambil plantId dari payload (pastikan saat scheduleWatering Anda mengirim payload)
        final String? plantId = receivedAction.payload?['plantId'];
        
        if (plantId != null) {
          // Cek ke Firestore apakah hari ini sudah ada log 'watered'
          final hasWateredToday = await FirestoreService().checkIfAlreadyWateredToday(plantId);
          
          if (hasWateredToday) {
            BotToast.showText(
              text: "Tanaman ini sudah disiram hari ini. Terima kasih! 🌿",
              contentColor: Colors.green.withValues(alpha: 0.9),
              duration: const Duration(seconds: 3),
            );
          } else {
            // Jika belum, arahkan ke halaman detail tanaman atau reminder
            // Gunakan GlobalKey<NavigatorState> untuk navigasi tanpa context
            MyApp.navigatorKey.currentState?.pushNamed('plant-detail', arguments: {'plantId': plantId});
          }
        }
      },
    );
  }
}