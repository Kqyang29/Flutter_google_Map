import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemapapp/current_location.dart';
import 'package:googlemapapp/live_tracker.dart';
import 'package:googlemapapp/location_service.dart';
import 'package:googlemapapp/multi_user.dart';
import 'package:googlemapapp/searchPlace.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

// get address name using geocode base on lat and log

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  TextEditingController _searchController = TextEditingController();
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

  //dynamic markers setting and polygons setting
  Set<Marker> _markers = Set<Marker>();
  Set<Polyline> _polylines = Set<Polyline>();
  Set<Polygon> _polygons = Set<Polygon>();
  List<LatLng> polygonLatLngs = <LatLng>[];
  Placemark _address = Placemark();
  late LatLng _currentPostion;
  bool _isLoading = true;
  String totalDistance = "null";
  String totalDuration = "null";

  int _polygonIdCounter = 1;
  int _polylineIdCounter = 1;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  void _setMarker(LatLng point) {
    setState(
      () {
        _markers.add(
          Marker(
            markerId: MarkerId("marker ${_markers.length}"),
            position: point,
            infoWindow: InfoWindow(
              title: _address == null
                  ? 'Position ${_markers.length + 1}'
                  : '${_address.street}',
              snippet: _address == null
                  ? 'Latitude: ${point.latitude}, Longitude: ${point.longitude}'
                  : '${_address.street},${_address.postalCode},${_address.locality}, ${_address.administrativeArea},${_address.country},',
            ),
          ),
        );
        // print(
        //     '${_address.street},${_address.postalCode},${_address.locality}, ${_address.administrativeArea},${_address.country},');
      },
    );
  }

  getCurrentLocation() async {
    Position position = await LocationService().getCurrentPosition();

    LatLng location = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentPostion = location;
      _isLoading = false;
      _setMarker(location);
    });
  }

  void _setPolylines(List<PointLatLng> points) {
    final String polylineIdVal = 'polyline_$_polygonIdCounter';
    _polylineIdCounter++;

    _polylines.add(
      Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 2,
        color: Colors.blue,
        points: points
            .map(
              (point) => LatLng(point.latitude, point.longitude),
            )
            .toList(),
      ),
    );
  }

  void _setPolygon() {
    final String polygonIdVal = 'polygon_$_polygonIdCounter';
    _polygonIdCounter++;

    _polygons.add(
      Polygon(
        polygonId: PolygonId(polygonIdVal),
        points: polygonLatLngs,
        strokeWidth: 2,
        fillColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("Google Map"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // direction
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _originController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: "Your Current Location",
                            ),
                            onChanged: (value) {
                              print(value);
                            },
                          ),
                          TextFormField(
                            controller: _destinationController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: "Destination",
                            ),
                            onChanged: (value) {
                              print(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        var directions = await LocationService().getDirection(
                          _originController.text,
                          _destinationController.text,
                        );

                        // // get distance
                        // double distance = Geolocator.distanceBetween(
                        //   directions['start_location']['lat'],
                        //   directions['start_location']['lng'],
                        //   directions['end_location']['lat'],
                        //   directions['end_location']['lng'],
                        // );
                        // totalDistance = distance;
                        // // in meter
                        // print(distance);

                        _goToPlace(
                          directions['start_location']['lat'],
                          directions['start_location']['lng'],
                          directions['end_location']['lat'],
                          directions['end_location']['lng'],
                          directions["bounds_ne"],
                          directions["bounds_sw"],
                        );

                        String distance =
                            directions['distance']['text'].toString();
                        totalDistance = distance;

                        String duration =
                            directions['duration']['text'].toString();
                        totalDuration = duration;

                        // print(directions['duration']['text']);
                        // print(directions['distance']['text']);
                        _setPolylines(
                          directions['polyline_decode'],
                        );
                      },
                      icon: Icon(Icons.search),
                    ),
                  ],
                ),
                // search city
                // Row(
                //   children: [
                //     Expanded(
                //       child: TextFormField(
                //         controller: _searchController,
                //         textCapitalization: TextCapitalization.words,
                //         decoration: InputDecoration(
                //           hintText: "Search by City",
                //         ),
                //         onChanged: (value) {
                //           print(value);
                //         },
                //       ),
                //     ),
                //     IconButton(
                //       onPressed: () async {
                //         var place = await LocationService().getPlace(
                //           _searchController.text,
                //         );
                //         _goToPlace(place);
                //       },
                //       icon: Icon(Icons.search),
                //     ),
                //   ],
                // ),
                Expanded(
                  child: GoogleMap(
                    // Type of Map: normal = terrain, satellite
                    mapType: MapType.normal,
                    markers: _markers,
                    polygons: _polygons,
                    polylines: _polylines,
                    initialCameraPosition: CameraPosition(
                      target: _currentPostion,
                      zoom: 13.5,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    onTap: (point) async {
                      // display street name postal code
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                              point.latitude, point.longitude);
                      _address = placemarks[0];
                      _setMarker(point);
                      // print(placemarks[0].toString());
                      // setState(() {
                      //   polygonLatLngs.add(point);
                      //   _setPolygon();
                      // });
                    },
                  ),
                ),
                Positioned(
                  bottom: 200,
                  left: 50,
                  child: Container(
                    child: Card(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "Total Distance: " + totalDistance + " Mile",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "Total Duration: " + totalDuration + " Min",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Position getCurrentPosition =
              await LocationService().getCurrentPosition();
          // _goCurrentPostion(
          //     getCurrentPosition.latitude, getCurrentPosition.longitude);

          LatLng location =
              LatLng(getCurrentPosition.latitude, getCurrentPosition.longitude);

          // display street name postal code
          List<Placemark> placemarks = await placemarkFromCoordinates(
              location.latitude, location.longitude);

          _address = placemarks[0];

          setState(() {
            _currentPostion = location;
            _isLoading = false;
            _originController.text = '${_address.street}';
            _setMarker(location);
          });

          //  setState(() {
          //    _originController.text==
          //  });
        },
        child: Icon(Icons.pin_drop),
      ),
    );
  }

  //search
  // Future<void> _goToPlace(Map<String, dynamic> place) async {
  //   final double lat = place['geometry']['location']['lat'];
  //   final double lng = place['geometry']['location']['lng'];
  //   final GoogleMapController controller = await _controller.future;
  //   controller.animateCamera(
  //     CameraUpdate.newCameraPosition(
  //       CameraPosition(
  //         target: LatLng(lat, lng),
  //         zoom: 12,
  //       ),
  //     ),
  //   );
  //   _setMarker(LatLng(lat, lng));
  // }

  //_goCurrentPostion
  Future<void> _goCurrentPostion(
    double clat,
    double clng,
  ) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(clat, clng),
          zoom: 12,
        ),
      ),
    );
    _setMarker(LatLng(clat, clng));
  }

//direction
  Future<void> _goToPlace(
    double slat,
    double slng,
    double elat,
    double elng,
    Map<String, dynamic> boundNe,
    Map<String, dynamic> boundSw,
  ) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(slat, slng),
          zoom: 12,
        ),
      ),
    );

    // 完成路线定位后自动缩放地图看清整条路线
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            boundSw['lat'],
            boundSw['lng'],
          ),
          northeast: LatLng(
            boundNe['lat'],
            boundNe['lng'],
          ),
        ),
        25,
      ),
    );

    _markers.clear();

    _setMarker(LatLng(slat, slng));
    _setMarker(LatLng(elat, elng));
  }

  // Future<void> _goToTheLake() async {
  //   final GoogleMapController controller = await _controller.future;
  //   controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  // }
}
