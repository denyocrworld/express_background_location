import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tutorial_background_service/background_action.dart';
import 'package:tutorial_background_service/my_app.dart';

@pragma('vm:entry-point')
onBackgroundLocation(Position position) async {
  await Dio().delete(
    "https://capekngoding.com/deny/api/user/action/delete-all",
    options: Options(
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );
  await Dio().post(
    "https://capekngoding.com/deny/api/user",
    options: Options(
      headers: {
        "Content-Type": "application/json",
      },
    ),
    data: {
      "name": "deny",
      "created_at": DateTime.now().toString(),
      "latitude": position.latitude,
      "longitude": position.longitude,
    },
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    BackgroundAction.duration = const Duration(seconds: 1);
    await BackgroundAction.runForegroundMode(
      notificationId: "my_notification",
      notificationTitle: "Background Location is Running",
      notificationDescription: "Background Location is Running",
    );
  } on Exception catch (err) {
    print(err);
  }

  runApp(const MyApp());
}
