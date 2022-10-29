import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemapapp/current_location.dart';
import 'package:googlemapapp/location_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: CurrentLocationPage(),
    );
  }
}

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

  int _polygonIdCounter = 1;
  int _polylineIdCounter = 1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _setMarker(LatLng(37.42796133580664, -122.085749655962));
  }

  void _setMarker(LatLng point) {
    setState(
      () {
        _markers.add(
          Marker(
            markerId: MarkerId("marker"),
            position: point,
          ),
        );
      },
    );
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

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  // static final Marker _kGooglePlexMarker = Marker(
  //   markerId: MarkerId('_kGooglePlex'),
  //   // click Marker and check info of location
  //   infoWindow: InfoWindow(title: 'Google Plex'),
  //   // defaultMarker = red
  //   icon: BitmapDescriptor.defaultMarker,
  //   // select latitude and longitude
  //   position: LatLng(37.42796133580664, -122.085749655962),
  // );

  // static final CameraPosition _kLake = CameraPosition(
  //     bearing: 192.8334901395799,
  //     target: LatLng(37.43296265331129, -122.08832357078792),
  //     tilt: 59.440717697143555,
  //     zoom: 19.151926040649414);

  // static final Marker _kLakeMarker = Marker(
  //   markerId: MarkerId('_kLake'),
  //   // click Marker and check info of location
  //   infoWindow: InfoWindow(title: '_kLake'),
  //   // defaultMarker = red
  //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  //   // select latitude and longitude
  //   position: LatLng(37.43296265331129, -122.08832357078792),
  // );

  // // connect Marker with polylines
  // static final Polyline _kPolyline = Polyline(
  //   polylineId: PolylineId("_kPoyline"),
  //   // the line create with polyline widget
  //   points: [
  //     // _kGooglePlexMarker
  //     LatLng(37.42796133580664, -122.085749655962),
  //     // _kLakeMarker
  //     LatLng(37.43296265331129, -122.08832357078792),
  //   ],
  //   // change line width
  //   width: 5,
  // );

  // // polygons
  // static final Polygon _kPolygon = Polygon(
  //   polygonId: PolygonId("_kpolygon"),
  //   points: [
  //     // _kLakeMarker
  //     LatLng(37.43296265331129, -122.08832357078792),
  //     // _kGooglePlexMarker
  //     LatLng(37.42796133580664, -122.085749655962),

  //     LatLng(37.418, -122.092),
  //     LatLng(37.435, -122.092),
  //   ],
  //   strokeWidth: 5,
  //   fillColor: Colors.transparent,
  // );

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("Google Map"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
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
                        hintText: "Origin",
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
                  _goToPlace(
                    directions['start_location']['lat'],
                    directions['start_location']['lng'],
                    directions['end_location']['lat'],
                    directions['end_location']['lng'],
                    directions["bounds_ne"],
                    directions["bounds_sw"],
                  );

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
              // add Markers then show in the Map
              // markers: {
              //   _kGooglePlexMarker,
              //   // _kLakeMarker,
              // },
              // add polyline then can see the line between two Points
              // polylines: {
              //   _kPolyline,
              // },
              // polygons: {
              //   _kPolygon,
              // },
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap: (point) {
                setState(() {
                  polygonLatLngs.add(point);
                  _setPolygon();
                });
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _goToTheLake,
      //   label: Text('To the lake!'),
      //   icon: Icon(Icons.directions_boat),
      // ),
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

//direction
  Future<void> _goToPlace(
    double start_lat,
    double start_lng,
    double end_lat,
    double end_lng,
    Map<String, dynamic> boundNe,
    Map<String, dynamic> boundSw,
  ) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(start_lat, start_lng),
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

    _setMarker(LatLng(start_lat, start_lng));
    _setMarker(LatLng(end_lat, end_lng));
  }

  // Future<void> _goToTheLake() async {
  //   final GoogleMapController controller = await _controller.future;
  //   controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  // }
}
