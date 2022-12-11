import 'dart:convert' as convert;

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  final String key = 'AIzaSyAX0FkkQbK_i7fHeqXvO1kcn34PZrlL0Zo';

  // get the city what user type in the city textformfield
  getPlaceId(String input) async {
    // url from Place API doc
    final String url =
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var placeId = json['candidates'][0]['place_id'] as String;

    print(placeId);

    return placeId;
  }

  // return the place id base on the place API
  // use Place Id to get all the info about the place
  Future<Map<String, dynamic>> getPlace(String input) async {
    final placeId = await getPlaceId(input);
    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key";
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json['result'] as Map<String, dynamic>;

    print(results);
    return results;
  }

  Future<Map<String, dynamic>> getDirection(
      String origin, String destination) async {
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$key";
    var response = await http.get(Uri.parse(url));
    var json = await convert.jsonDecode(response.body);
    // print(json['routes'][0]['bounds']);

    var results = {
      'distance': json['routes'][0]['legs'][0]['distance'],
      'duration': json['routes'][0]['legs'][0]['duration'],
      'bounds_ne': json['routes'][0]['bounds']['northeast'],
      'bounds_sw': json['routes'][0]['bounds']['southwest'],
      'start_location': json['routes'][0]['legs'][0]['start_location'],
      'end_location': json['routes'][0]['legs'][0]['end_location'],
      'polyline': json['routes'][0]['overview_polyline']['points'],
      'polyline_decode': PolylinePoints()
          .decodePolyline(json['routes'][0]['overview_polyline']['points']),
    };
    print(
      results,
    );

    if (results.isEmpty) {
      print("error");
    }
    return results;
  }

  Future<Position> getCurrentPosition() async {
    // check user gps enable or not
    bool serviceEnable;

    LocationPermission permission;

    serviceEnable = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnable) {
      return Future.error("location service are disabled");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error("location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("location permission are permanently denied");
    }

    Position position = await Geolocator.getCurrentPosition();

    return position;
  }
}
