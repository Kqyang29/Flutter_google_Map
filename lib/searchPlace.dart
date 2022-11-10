import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:googlemapapp/location_service.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:location/location.dart';

class SearchPlace extends StatefulWidget {
  const SearchPlace({super.key});

  @override
  State<SearchPlace> createState() => _SearchPlaceState();
}

class _SearchPlaceState extends State<SearchPlace> {
  late GoogleMapController googleMapController;
  // Set<Marker> _markers = {};

  List<Marker> _markers = [];

  List<Marker> _list = [];

  Position? position;

  final Mode _mode = Mode.overlay;

  final homeScaffoldKey = GlobalKey<ScaffoldState>();

  //current location
  void _determinePosition() async {
    // check user gps enable or not
    bool serviceEnable;

    LocationPermission permission;

    Position position;

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

    await Geolocator.getCurrentPosition().then((position) {
      _list.add(
        Marker(
          markerId: MarkerId("currentLocation"),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(
            title: "currentLocation",
          ),
        ),
      );
      _markers.addAll(_list);
    });
  }

  @override
  void initState() {
    _determinePosition();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffoldKey,
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            markers: Set<Marker>.of(_markers),
            initialCameraPosition: CameraPosition(
                target: LatLng(position!.latitude, position!.longitude),
                zoom: 14.4746),
            onMapCreated: (GoogleMapController controller) {
              googleMapController = controller;
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: ElevatedButton(
              onPressed: _handlePressButton,
              child: Text("search"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePressButton() async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      offset: 0,
      radius: 1000,
      apiKey: LocationService().key,
      onError: onError,
      mode: _mode,
      language: 'en',
      strictbounds: false,
      types: [],
      components: [
        Component(
          Component.country,
          "US",
        ),
      ],
    );

    displayPrediction(p!, homeScaffoldKey.currentState);
  }

  void onError(PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Message',
          message: response.errorMessage!,
          contentType: ContentType.failure,
        ),
      ),
    );
  }

  Future<void> displayPrediction(
      Prediction p, ScaffoldState? currentState) async {
    GoogleMapsPlaces places = GoogleMapsPlaces(
      apiKey: LocationService().key,
      apiHeaders: await GoogleApiHeaders().getHeaders(),
    );

    PlacesDetailsResponse detail = await places.getDetailsByPlaceId(p.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId("0"),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: detail.result.name,
        ),
      ),
    );

    setState(() {});

    googleMapController
        .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0));
  }
}
