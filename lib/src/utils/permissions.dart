import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import "dart:developer";

Future<void> requestLocationAccess() async {
  // you need to request normal location access first, before being able to request locationAlways
  while (true) {
    if ((await Permission.location
        .request())
        .isGranted) {
      break;
    }
  }
  while (true) {
    if ((await Permission.locationAlways
        .request())
        .isGranted) {
      break;
    }
  }
}

Future<void> requestStorageAccess() async {
  while (true) {
    if ((await Permission.storage
        .request())
        .isGranted) {
      break;
    }
  }
  // on android 11+ access to all files is necessary for creating files in emulated storage folders
  while (true) {
    if ((await Permission.manageExternalStorage
        .request())
        .isGranted) {
      break;
    }
  }
}

Future<void> requestNotificationAccess() async {
  while (true) {
    if ((await Permission.notification
        .request())
        .isGranted) {
      break;
    }
  }
}


Future<void> requestAllNecessaryPermissions() async {
  log("request all necessary permissions");
  await requestLocationAccess();
  await requestStorageAccess();
  await requestNotificationAccess();
}