import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "dart:developer";

import 'package:geo_steps/main.dart';

class PageWithNav extends StatelessWidget {
  PageWithNav(
      {super.key,
      this.title = "",
      this.navItems = const <AppRoute>[],
      this.child,
      this.color});

  String title;
  Widget? child;
  Color? color;
  List<AppRoute> navItems;

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    EdgeInsets padding = media.viewPadding;
    return Stack(children: [
      Positioned(
          top: padding.top + 46,
          width: media.size.width,
          height: media.size.height - 46 - padding.vertical,
          child: Container(
            color: color,
            child: child,
          )),
      Positioned(
          top: padding.top,
          width: media.size.width,
          child: Navbar(
            title: title,
            navItems: navItems,
          )),
    ]);
  }
}

class Navbar extends StatefulWidget {
  Navbar({super.key, this.title = "", this.navItems = const <AppRoute>[]});

  String title;
  List<AppRoute> navItems;

  @override
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  bool menuOpen = false;

  @override
  void initState() {
    menuOpen = false;
  }

  void setMenu(bool state) {
    setState(() {
      menuOpen = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          color: Colors.white,
          height: 45,
          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(
              children: [
                GestureDetector(
                    onTap: () {
                        setMenu(menuOpen ? false : true);
                    },
                    child: const Icon(Icons.menu)),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    widget.title,
                    style: const TextStyle(),
                  ),
                ),
              ],
            ),
            GestureDetector(onTap: () {}, child: const Icon(Icons.settings)),
          ])),
      Container(height: 1, color: Colors.black),
      if (menuOpen) NavMenu(setMenu, navItems: widget.navItems),
    ]);
  }
}

class NavMenu extends StatelessWidget {
  NavMenu(this.setMenu, {super.key, this.navItems = const <AppRoute>[]});

  List<AppRoute> navItems;
  Function(bool) setMenu;

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    return SizedBox(
        height: media.size.height - media.viewPadding.vertical,
        child: Column(
          children: [
            Container(
                width: media.size.width,
                // color: const Color(0xFFFFFFFF),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(75),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]),
                child: Column(
                  children: [
                    ...List.generate(navItems.length, (index) {
                      AppRoute item = navItems[index];
                      return NavMenuItem(
                        name: item.title,
                        route: item.route,
                        icon: item.icon,
                      );
                    })
                  ],
                )),
            Expanded(child: GestureDetector(onTap: () {setMenu(false);},child: Container(color: Colors.white.withAlpha(125))))
          ],
        ));
  }
}

class NavMenuItem extends StatelessWidget {
  NavMenuItem(
      {super.key,
      this.name = "home",
      this.route = "/",
      this.icon = Icons.nordic_walking});

  String name;
  String route;
  IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Container(
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.centerLeft,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(children: [
              Icon(icon, size: 40),
              const Padding(padding: EdgeInsets.only(left: 10)),
              Text(route == "/" ? "home" : name,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w500))
            ])));
  }
}
