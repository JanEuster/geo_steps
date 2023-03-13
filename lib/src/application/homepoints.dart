import 'dart:async';
import 'dart:io';
import 'dart:async';
import "dart:developer";
import "dart:convert";

import 'package:external_path/external_path.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class HomepointManager {
  final Uuid _uuid = const Uuid();
  late Map<String, Homepoint> _homepoints = {};
  late Directory _appDir;
  late File _homepointFile;

  HomepointManager() {}

  Map<String, Homepoint> get homepoints {
    return _homepoints;
  }

  Future<void> init() async {
    var dirs = await ExternalPath.getExternalStorageDirectories();
    _appDir = Directory("${dirs.first}/geo_steps");
    _appDir.create();
    _homepointFile = File("${_appDir.path}/homepoints.json");
    var exists = await _homepointFile.exists();
    log("homepoints.json.exists() = $exists");
    if (!exists) {
      await _homepointFile.create();
      await save();
    } else {
      await load();
    }
  }

  Future<void> save() async {
    var json = jsonEncode(
        _homepoints.map((key, value) => MapEntry(key, value.toJson())));
    _homepointFile.writeAsString(json);
  }

  Future<void> load() async {
    var json = await _homepointFile.readAsString();
    log("loaded json: $json");
    Map<String, dynamic> jsonMap = jsonDecode(json);
    _homepoints =
        jsonMap.map((key, value) => MapEntry(key, Homepoint.fromJson(value)));
  }

  addPoint(Homepoint point) {
    _homepoints.putIfAbsent(_uuid.v4(), () => point);
    log("$_homepoints");
    save();
  }

  updatePoint(String key, Homepoint point) {
    _homepoints.update(key, (value) => point);
    save();
  }

  removePoint(String key) {
    _homepoints.remove(key);
    save();
  }
}

class Homepoint {
  final String name;
  final LatLng position;
  final double radius;

  Homepoint(this.name, this.position, {this.radius = 50});

  static fromJson(Map<String, dynamic> json) {
    var position =
        LatLng(json["position"]["lat"] as double, json["position"]["lng"]);
    return Homepoint(json["name"], position, radius: json["radius"] as double);
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "position": {"lat": position.latitude, "lng": position.longitude},
      "radius": radius,
    };
  }

  @override
  String toString() {
    return "Homepoint '$name' at $position within $radius m";
  }
}

double getCoordDiff(double foo, double bar) {
  double calcDiff(double smaller, double bigger) {
    return bigger - smaller;
  }

  if (foo < bar) {
    return calcDiff(foo, bar);
  } else {
    return calcDiff(bar, foo);
  }
}
