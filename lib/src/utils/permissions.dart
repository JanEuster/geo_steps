import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import "dart:developer";

Future<void> requestLocationAccess() async {
  while (true) {
    if (await Permission.locationAlways
        .request()
        .isGranted) {
      break;
    }
  }
}

Future<void> requestStorageAccess() async {
  while (true) {
    if (await Permission.storage
        .request()
        .isGranted) {
      break;
    }
  }
}

Future<void> requestNotificationAccess() async {
  while (true) {
    if (await Permission.notification
        .request()
        .isGranted) {
      break;
    }
  }
}


Future<void> requestAllNecessaryPermissions() async {
  await requestLocationAccess();
  await requestStorageAccess();
  await requestNotificationAccess();
}