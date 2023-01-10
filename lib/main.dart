import "package:flutter/material.dart";
import 'package:flutter/widgets.dart';

void main() => runApp(new MyWidgetsApp());

class MyWidgetsApp extends StatelessWidget {

  Route generate(RouteSettings settings){
    Route page;
    switch(settings.name){
      case "/":
        page =  new PageRouteBuilder(
            pageBuilder: (BuildContext context,Animation<double> animation,
                Animation<double> secondaryAnimation){
              return new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Home Page",textDirection: TextDirection.ltr,),
                  const Padding(padding: const EdgeInsets.all(10.0)),
                  new GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed("/first"),
                    child: new Container(
                      padding: const EdgeInsets.all(10.0),
                      color:Colors.blue,
                      child: const Text("Go to First Page"),
                    ),
                  ),
                  const Padding(padding: const EdgeInsets.all(10.0)),
                  new GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed("/abcd"),
                    child: new Container(
                      padding: const EdgeInsets.all(10.0),
                      color:Colors.blue,
                      child: const Text("Unkown Route"),
                    ),
                  )
                ],
              );
            },
            transitionsBuilder: (_, Animation<double> animation, Animation<double> second, Widget child) {
              return new FadeTransition(
                opacity: animation,
                child: new FadeTransition(
                  opacity: new Tween<double>(begin: 1.0, end: 0.0).animate(second),
                  child: child,
                ),
              );
            }
        );
        break;
      case "/first":
        page =  new PageRouteBuilder(
            pageBuilder: (BuildContext context,Animation<double> animation,
                Animation<double> secondaryAnimation){
              return new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("First Page",textDirection: TextDirection.ltr,),
                    const Padding(padding: const EdgeInsets.all(10.0)),
                    new GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: new Container(
                        padding: const EdgeInsets.all(10.0),
                        color:Colors.blue,
                        child: const Text("Back"),
                      ),
                    )
                  ]
              );
            },
            transitionsBuilder: (_, Animation<double> animation, Animation<double> second, Widget child) {
              return new FadeTransition(
                opacity: animation,
                child: new FadeTransition(
                  opacity: new Tween<double>(begin: 1.0, end: 0.0).animate(second),
                  child: child,
                ),
              );
            }
        );
        break;
      default: {
        page = unKnownRoute(settings);
      }
    }
    return page;
  }

  Route unKnownRoute(RouteSettings settings){
    return new PageRouteBuilder(
        pageBuilder: (BuildContext context,Animation<double> animation,
            Animation<double> secondaryAnimation){
          return new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text("First Page",textDirection: TextDirection.ltr,),
                const Padding(padding: const EdgeInsets.all(10.0)),
                new GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: new Container(
                    padding: const EdgeInsets.all(10.0),
                    color:Colors.blue,
                    child: const Text("Back"),
                  ),
                )
              ]
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return new WidgetsApp(
        onGenerateRoute: generate,
        onUnknownRoute: unKnownRoute,
        textStyle: const TextStyle(),
        initialRoute: "/",
        color: Colors.red
    );
  }
}