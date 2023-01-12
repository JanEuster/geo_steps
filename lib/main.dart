import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "dart:developer";

// local imports
import 'package:geo_steps/src/presentation/home.dart';
import 'package:geo_steps/src/presentation/nav.dart';

void main() => runApp(MyWidgetsApp());

class AppRoute {
  String title;
  String route;
  IconData icon;
  StatelessWidget page;
  AppRoute(this.title, this.route, this.icon, this.page);
}

class MyWidgetsApp extends StatelessWidget {
  MyWidgetsApp({super.key}) {
    routes = {
      "/": AppRoute("geo_steps", "/", Icons.nordic_walking, const MyHomePage()),
      "/today": AppRoute("today", "/today", Icons.bar_chart, Container()),
      "/overviews": AppRoute("overviews", "/overviews", Icons.leaderboard, Container()),
      "/places": AppRoute("home⋅points", "/places", Icons.push_pin, Container()),
    };
  }

  late Map<String, AppRoute> routes;
  String title = "geo_steps";

  Route generate(RouteSettings settings) {
    Route page;
    if (routes[settings.name] != null) {
      title = routes[settings.name]!.title;
      page = PageRouteBuilder(pageBuilder: (BuildContext context,
          Animation<double> animation, Animation<double> secondaryAnimation) {
        EdgeInsets insets = MediaQuery.of(context).viewInsets;
        EdgeInsets padding = MediaQuery.of(context).viewPadding;
        log("device insets || insets: $insets, padding: $padding");
        return PageWithNav(
            title: title,
            color: const Color(0xFFFFFFFF),
            navItems: routes.values.toList(),
            child: routes[settings.name]?.page);
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
    return WidgetsApp(
      onGenerateRoute: generate,
      onUnknownRoute: unKnownRoute,
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
      initialRoute: "/today",
      color: const Color.fromRGBO(255, 0, 0, 1.0),
      title: title,
    );
  }
}
