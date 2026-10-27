import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsReady = false;

  Future<void> _ensureLocalNotificationsReady() async {
    if (_localNotificationsReady) return;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {}
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotificationsPlugin.initialize(settings);
    final android = _localNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    _localNotificationsReady = true;
  }

  Future<void> initialize() async {
    // 1. Khởi tạo Firebase
    await Firebase.initializeApp();

    // 2. Yêu cầu quyền Notification
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Khởi tạo Local Notifications
    await _ensureLocalNotificationsReady();

    // 4. Lắng nghe FCM background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Lắng nghe FCM foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        showLocalNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Thông báo',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureLocalNotificationsReady();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'eatgym_channel',
      'EatGym Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }

  /// Lịch nhắc được hệ điều hành giữ lại, kể cả khi người dùng đóng app.
  Future<void> scheduleThawReminder({
    required int id,
    required DateTime thawAt,
    required String mealName,
  }) async {
    await _ensureLocalNotificationsReady();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'eatgym_thaw_channel',
        'Nhắc rã đông EatGym',
        channelDescription: 'Nhắc lấy đồ ăn Meal Prep từ ngăn đông',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _localNotificationsPlugin.zonedSchedule(
      id,
      'Đến lúc rã đông: $mealName',
      'Chuyển phần ăn từ ngăn đông xuống ngăn mát để sẵn sàng cho bữa tiếp theo.',
      tz.TZDateTime.from(thawAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _ensureLocalNotificationsReady();
    await _localNotificationsPlugin.cancel(id);
  }

  Future<void> scheduleTimerNotification(int durationInSeconds) async {
    Future.delayed(Duration(seconds: durationInSeconds), () {
      showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Hết giờ!',
        body: 'Thời gian Timer của bạn đã kết thúc.',
      );
    });
  }
}
