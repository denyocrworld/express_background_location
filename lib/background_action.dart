import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tutorial_background_service/main.dart';
import 'fluter_background_core.dart';

@pragma('vm:entry-point')
onStart(service) async {
// Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(BackgroundAction.duration, (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        Position position = await Geolocator.getCurrentPosition();
        // BackgroundAction.onForegroundLocation!(position);
        onBackgroundLocation(position);

        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        flutterLocalNotificationsPlugin.show(
          888,
          'COOL SERVICE',
          'Awesome ${DateTime.now()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        // if you don't using custom notification, uncomment this
        // service.setForegroundNotificationInfo(
        //   title: "My App Service",
        //   content: "Updated at ${DateTime.now()}",
        // );
      }
    }
  });
}

class BackgroundAction {
  static Duration duration = const Duration(seconds: 1);
  static late Function(Position position)? onForegroundLocation;

  static runForegroundMode({
    required String notificationId,
    required String notificationTitle,
    required String notificationDescription,
  }) async {
    try {
      AndroidNotificationChannel channel = AndroidNotificationChannel(
        notificationId,
        notificationTitle,
        description: notificationDescription,
        importance: Importance.low,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await checkPermissions();
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          // this will be executed when app is in foreground or background in separated isolate
          onStart: onStart,
          // auto start service
          autoStart: true,
          isForegroundMode: true,

          notificationChannelId: notificationId,
          initialNotificationTitle: notificationTitle,
          initialNotificationContent: notificationDescription,
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(),
      );

      service.startService();
    } on Exception catch (err) {
      print(err);
    }
  }

  static Future<bool?>? checkPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw ('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw ('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw ('Location permissions are permanently denied, we cannot request permissions.');
      }
      return true;
    } on Exception {
      rethrow;
    }
  }

  static handler() async {
    await Dio().delete(
      "https://capekngoding.com/demo/api/users/action/delete-all",
      options: Options(
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );

    Position position = await Geolocator.getCurrentPosition();
    var response = await Dio().post(
      "https://capekngoding.com/demo/api/users",
      options: Options(
        headers: {
          "Content-Type": "application/json",
        },
      ),
      data: {
        "name": "Deny",
        "created_at": DateTime.now().toString(),
        "latitude": position.latitude,
        "longitude": position.longitude,
      },
    );
    Map obj = response.data;
    print(">>>>");
    print("RESPONSE: $obj");
    print(">>>>");
  }
}
