import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "dart:developer";

void main() => runApp(const MyWidgetsApp());

class MyWidgetsApp extends StatelessWidget {
  const MyWidgetsApp({super.key});

  final String title = "geo_steps";

  Route generate(RouteSettings settings) {
    Route page;
    switch (settings.name) {
      case "/":
        page = PageRouteBuilder(pageBuilder: (BuildContext context,
            Animation<double> animation, Animation<double> secondaryAnimation) {
          EdgeInsets insets = MediaQuery.of(context).viewInsets;
          EdgeInsets padding = MediaQuery.of(context).viewPadding;
          log("device insets || insets: $insets, padding: $padding");

          return PageWithNav(
              title: title,
              color: const Color(0xFFFFFFFF),
              child: const MyHomePage());
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
        break;
      case "/today":
        page = PageRouteBuilder(pageBuilder: (BuildContext context,
            Animation<double> animation, Animation<double> secondaryAnimation) {
          EdgeInsets insets = MediaQuery.of(context).viewInsets;
          EdgeInsets padding = MediaQuery.of(context).viewPadding;
          log("device insets || insets: $insets, padding: $padding");

          return PageWithNav(
              title: title, color: const Color(0xFFFFFFFF), child: Container());
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
        break;
      case "/overviews":
        page = PageRouteBuilder(pageBuilder: (BuildContext context,
            Animation<double> animation, Animation<double> secondaryAnimation) {
          EdgeInsets insets = MediaQuery.of(context).viewInsets;
          EdgeInsets padding = MediaQuery.of(context).viewPadding;
          log("device insets || insets: $insets, padding: $padding");

          return PageWithNav(
              title: title, color: const Color(0xFFFFFFFF), child: Container());
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
        break;
      case "/places":
        page = PageRouteBuilder(pageBuilder: (BuildContext context,
            Animation<double> animation, Animation<double> secondaryAnimation) {
          EdgeInsets insets = MediaQuery.of(context).viewInsets;
          EdgeInsets padding = MediaQuery.of(context).viewPadding;
          log("device insets || insets: $insets, padding: $padding");

          return PageWithNav(
              title: title, color: const Color(0xFFFFFFFF), child: Container());
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
        break;
      default:
        {
          page = unKnownRoute(settings);
        }
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
      initialRoute: "/",
      color: const Color.fromRGBO(255, 0, 0, 1.0),
      title: title,
    );
  }
}
