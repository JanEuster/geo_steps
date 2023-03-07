import 'package:flutter/material.dart';

import 'package:geo_steps/main.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/utils/sizing.dart';

class PageWithNav extends StatelessWidget {
  const PageWithNav(
      {super.key,
      this.title = "",
      this.navItems = const <AppRoute>[],
      this.child,
      this.color});

  final String title;
  final Widget? child;
  final Color? color;
  final List<AppRoute> navItems;

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    EdgeInsets padding = sizer.pad;
    return Stack(children: [
      Positioned(
          top: sizer.padTopWithNav,
          width: sizer.width,
          height: sizer.heightWithoutNav,
          child: Container(
            color: color,
            child: child,
          )),
      Positioned(
          top: padding.top,
          width: sizer.width,
          child: Navbar(
            title: title,
            navItems: navItems,
          )),
    ]);
  }
}

class PageWithBackNav extends StatelessWidget {
  String title;
  String backRoute;
  Widget? child;
  Color? color;

  PageWithBackNav({super.key,
    this.title = "modal", this.backRoute = "/", this.color, this.child});

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    EdgeInsets padding = sizer.pad;
    return Stack(children: [
      Positioned(
          top: sizer.padTopWithNav,
          width: sizer.width,
          height: sizer.heightWithoutNav,
          child: Container(
            color: color,
            child: child,
          )),
      Positioned(
          top: padding.top,
          width: sizer.width,
          child: BackNav(backRoute,
              title
          )),
    ]);
  }
}

class BackNav extends StatelessWidget {
  String backRoute;
  String title;

  BackNav(this.backRoute, this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          color: Colors.white,
          height: SizeHelper.navHeight - 1,
          //-1 for separate border bottom container
          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
          child:
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(backRoute);
                    },
                    child: const Icon(Icons.menu, size: 26)),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    title,
                    style: const TextStyle(),
                  ),
                ),
              ],
            ),
            GestureDetector(
                onTap: () {}, child: const Icon(Icomoon.settings, size: 26)),
          ])),
      const Line()
    ]);
  }
}


class Navbar extends StatefulWidget {
  const Navbar({super.key, this.title = "", this.navItems = const <AppRoute>[]});

  final String title;
  final List<AppRoute> navItems;

  @override
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  bool menuOpen = false;

  @override
  void initState() {
    super.initState();
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
          height: SizeHelper.navHeight - 1,
          //-1 for separate border bottom container
          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
          child:
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(
              children: [
                GestureDetector(
                    onTap: () {
                      setMenu(menuOpen ? false : true);
                    },
                    child: const Icon(Icons.menu, size: 26)),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    widget.title,
                    style: const TextStyle(),
                  ),
                ),
              ],
            ),
            GestureDetector(
                onTap: () {}, child: const Icon(Icomoon.settings, size: 26)),
          ])),
      const Line(),
      if (menuOpen) NavMenu(setMenu, navItems: widget.navItems),
    ]);
  }
}

class NavMenu extends StatelessWidget {
  const NavMenu(this.setMenu, {super.key, this.navItems = const <AppRoute>[]});

  final List<AppRoute> navItems;
  final Function(bool) setMenu;

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    return SizedBox(
        height: sizer.size.height - sizer.pad.vertical,
        child: Column(
          children: [
            Container(
                width: sizer.width,
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
            Expanded(child: GestureDetector(onTap: () {
              setMenu(false);
            }, child: Container(color: Colors.white.withAlpha(125))))
          ],
        ));
  }
}

class NavMenuItem extends StatelessWidget {
  const NavMenuItem(
      {super.key,
      this.name = "home",
      this.route = "/",
      this.icon = Icons.nordic_walking});

  final String name;
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
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
