
import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/map.dart';

class TodayPage extends StatefulWidget {
 const TodayPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
        children: [
      TodaysMap(),
    ]);
  }

}