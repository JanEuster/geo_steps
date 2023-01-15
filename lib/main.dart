import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "dart:developer";

// local imports
import 'package:geo_steps/src/presentation/home.dart';
import 'package:geo_steps/src/presentation/nav.dart';
import 'package:geo_steps/src/presentation/map.dart';
import 'package:geo_steps/src/utils/notification.dart';
import 'package:geo_steps/src/utils/permissions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {

    // test notifcation on today route load
    Position? p = await Geolocator.getLastKnownPosition();
    log("pos: $p");
    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      title: 'background notification',
      body: "now longitude: ${p!.longitude} latitude: ${p!.latitude}",
      actionType: ActionType.Default,
    ));

    return Future.value(true);
  });
}

void main() async {
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null, // default icon
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            playSound: false,
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);

  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );

  Workmanager().registerOneOffTask("dev.janeuster.geo_steps.test", "test",
      tag: "testing", initialDelay: const Duration(seconds: 30));

  runApp(MyWidgetsApp());
}

class AppRoute {
  String title;
  String route;
  IconData icon;
  StatelessWidget page;

  AppRoute(this.title, this.route, this.icon, this.page);
}

class MyWidgetsApp extends StatefulWidget {
  String title = "geo_steps";
  late Map<String, AppRoute> routes = {
    "/": AppRoute(title, "/", Icons.nordic_walking, const MyHomePage()),
    "/today": AppRoute(
        "today",
        "/today",
        Icons.bar_chart,
        ListView(children: const [
          SimpleMap(),
        ])),
    "/overviews":
        AppRoute("overviews", "/overviews", Icons.leaderboard, Container()),
    "/places": AppRoute("home⋅points", "/places", Icons.push_pin, Container()),
  };
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  MyWidgetsApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyWidgetsAppState();
}

class _MyWidgetsAppState extends State<MyWidgetsApp> {
  @override
  void initState() {
    requestAllNecessaryPermissions();

    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);

    super.initState();
  }

  Route generate(RouteSettings settings) {
    Route page;
    if (widget.routes[settings.name] != null) {
      widget.title = widget.routes[settings.name]!.title;
      page = PageRouteBuilder(pageBuilder: (BuildContext context,
          Animation<double> animation, Animation<double> secondaryAnimation) {
        EdgeInsets insets = MediaQuery.of(context).viewInsets;
        EdgeInsets padding = MediaQuery.of(context).viewPadding;
        log("device insets || insets: $insets, padding: $padding");
        return PageWithNav(
            title: widget.title,
            color: const Color(0xFFFFFFFF),
            navItems: widget.routes.values.toList(),
            child: widget.routes[settings.name]?.page);
      }, transitionsBuilder: (_, Animation<double> animation,
          Animation<double> second, Widget child) {
        return FadeTransition(
          opacity: animation,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(second),
            child: child,
          ),
        );
      });
    } else {
      page = unKnownRoute(settings);
    }

    return page;
  }

  Route unKnownRoute(RouteSettings settings) {
    return PageRouteBuilder(pageBuilder: (BuildContext context,
        Animation<double> animation, Animation<double> secondaryAnimation) {
      return PageWithNav(
          title: "error",
          color: const Color(0xFFFFFFFF),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "Error!",
                  textDirection: TextDirection.ltr,
                ),
                const Padding(padding: EdgeInsets.all(10.0)),
                GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          color: const Color(0xFFAAAAFF),
                          child: const Text("Return to Home Page"),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          color: const Color(0xFFBBAAFF),
                          child: const Text("Return to Home Page"),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          color: const Color(0xFFCCAAFF),
                          child: const Text("Return to Home Page"),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          color: const Color(0xFFDDAAFF),
                          child: const Text("Return to Home Page"),
                        ),
                      ],
                    ))
              ]));
    });
  }

  @override
  Widget build(BuildContext context) {
    log("target: ${Theme.of(context).platform}");
    return WidgetsApp(
      navigatorKey: MyWidgetsApp.navigatorKey,
      onGenerateRoute: generate,
      onUnknownRoute: unKnownRoute,
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
      initialRoute: "/",
      color: const Color.fromRGBO(255, 0, 0, 1.0),
      title: widget.title,
    );
  }
}

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here

    // Navigate into pages, avoiding to open the notification details page over another details page already opened
    // MyWidgetsApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/notification-page',
    //         (route) => (route.settings.name != '/notification-page') || route.isFirst,
    //     arguments: receivedAction);
  }
}
