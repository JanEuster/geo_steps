import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/utils/sizing.dart';

class OverviewTotals extends StatelessWidget {
  final String timeFrameString;
  final int totalSteps;
  /// total distance in meters
  final double totalDistance;

  OverviewTotals({super.key, required this.timeFrameString, required this.totalSteps, required this.totalDistance});

  @override
  Widget build(BuildContext context) {
    var textStyle = const TextStyle(fontWeight: FontWeight.w500, fontSize: 24);
    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: SizedBox(
            width: 140,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "Totals - $timeFrameString",
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const Padding(
                  padding: EdgeInsets.only(top: 5, bottom: 10),
                  child: Line(
                    height: 2,
                  )),
              Text(
                "$totalSteps steps",
                style: textStyle,
              ),
              Text(
                "${(totalDistance/1000).toStringAsFixed(1)} km",
                style: textStyle,
              ),
            ]),
          ),
        ));
  }
}
