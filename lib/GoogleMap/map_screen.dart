import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../jh_custom_marker.dart';
import '../jh_logger.dart';

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({Key? key}) : super(key: key);

  @override
  State<GoogleMapScreen> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMapScreen>
    with SingleTickerProviderStateMixin {
  String mapTheme = '';

  late GoogleMapController? mapController;
  TextEditingController _searchController = TextEditingController();

  Map<String, Marker> _markers = {};
  Set<Polyline> polylines = {};
  bool loadingLocation = true;
  bool isLocationEnabled = false;
  bool trafficEnabled = false;
  late Geolocator geolocator;
  LatLng? _initialPosition;
  LatLng? _searchedLocation;

  @override
  void initState() {
    super.initState();

    ///Load map theme
    ///You can add different theme by changing the asset file
    DefaultAssetBundle.of(context)
        .loadString('assets/maptheme/nighttheme.json')
        .then((value) {
      mapTheme = value;
    });
    _loadInitialPosition();
    logger.d('initial position detected');
    _getCurrentLocation();
    logger.d('current location detected');
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? cachedLatitude = prefs.getDouble('latitude');
    double? cachedLongitude = prefs.getDouble('longitude');

    if (cachedLatitude != null && cachedLongitude != null) {
      setState(() {
        _initialPosition = LatLng(cachedLatitude, cachedLongitude);
      });
    }
    _getCurrentLocation();
  }

  void _toggleLocation() {
    setState(() {
      isLocationEnabled = !isLocationEnabled;
    });

    if (isLocationEnabled) {
      _getCurrentLocation();
    } else {
      _initialPosition = null;
    }
  }

  void _getCurrentLocation() async {
    try {
      /// Request location permissions explicitly
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        /// Handle the case where permissions are denied
        /// You can show a dialog to inform the user or take any other action
        setState(() {
          loadingLocation = false;
        });
        return;
      }

      /// Permissions are granted or allowed while using the app, proceed with fetching the location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      ///store the initial position in cache
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setDouble('latitude', position.latitude);
      prefs.setDouble('longitude', position.longitude);

      String userAddress = placemarks.isNotEmpty
          ? "${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first.administrativeArea}"
          : "Unknown Location";

      /// Center the map on the current location
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14,
          ),
        ),
      );

      /// Update the search bar text with the user's address
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _searchController.text = userAddress;
        loadingLocation = false;
        //isLocationEnabled = true;
      });
      _addCircle(position);
      double markerOffset = 0.0002;
      addMarker(
        'USER',
        LatLng(position.latitude + markerOffset, position.longitude),
      );
      Polyline polyline = Polyline(
        polylineId: PolylineId('polyline_1'),
        color: Colors.blue,
        width: 5,
        points: [LatLng(position.latitude, position.longitude)],
      );

      setState(() {
        polylines = {polyline};
      });
    } on PlatformException catch (e) {
      /// Handle errors that might occur when fetching the current location
      logger.e("Error: ${e.message}");
      setState(() {
        loadingLocation = false;
      });
    }
  }

  void _searchLocation() async {
    String searchText = _searchController.text;
    if (searchText.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(searchText);
      if (locations.isNotEmpty) {
        setState(() {
          _searchedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _searchedLocation!,
                zoom: 14,
              ),
            ),
          );
        });
      }
    } catch (e) {
      logger.d("Error searching location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context).size.height;
    MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            rotateGesturesEnabled: true,
            myLocationEnabled: isLocationEnabled,
            myLocationButtonEnabled: false,
            fortyFiveDegreeImageryEnabled: true,
            trafficEnabled: trafficEnabled,
            circles: _circle,
            polylines: polylines,
            onMapCreated: (controller) {
              controller.setMapStyle(mapTheme);
              mapController = controller;

              /// After fetching the location this [SETSTATE] we set the isLocationEnabled to true meaning the button is on
              setState(() {
                isLocationEnabled = true;
              });
            },
            markers: _markers.values.toSet(),
            initialCameraPosition: _initialPosition != null
                ? CameraPosition(target: _initialPosition!, zoom: 14)
                : CameraPosition(target: LatLng(0, 0), zoom: 14),
          ),
          if (loadingLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 61 * 2,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search location here?",
                      hintStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      fillColor: Colors.grey.withOpacity(0.8),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2.0,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          weight: 30,
                          size: 30,
                        ),
                        onPressed: _searchLocation,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    onSubmitted: (_) {
                      _searchLocation();
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 36,
            right: 20,
            child: InkWell(
              onTap: _toggleLocation,
              child: CircleAvatar(
                backgroundColor: Colors.black,
                radius: 20,
                child: Icon(
                    isLocationEnabled ? Icons.location_on : Icons.location_off),
              ),
            ),
          ),
          Positioned(
            top: 36,
            left: 16,
            child: Switch(
              value: trafficEnabled,
              onChanged: (value) {
                setState(() {
                  trafficEnabled = value;
                });
              },
              activeColor: Colors.green,
              activeTrackColor: Colors.lightGreen,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Set<Circle> _circle = {};

  void _addCircle(Position position) {
    _circle.add(
      Circle(
        circleId: CircleId('circle_1'),
        center: LatLng(position.latitude, position.longitude),
        radius: 900,
        fillColor: Colors.grey.withOpacity(0.5),
        strokeWidth: 2,
        strokeColor: Colors.redAccent,
      ),
    );
    setState(() {});
  }

  addMarker(String id, LatLng location) async {
    var customMarkerIcon = CustomMarkerIcon(
      size: 120,
      imagePath: 'assets/images/Ellipse 365.png',
      backgroundColor: Colors.grey.withOpacity(0.5),
    );
    var marker = Marker(
      markerId: MarkerId(id),
      position: location,
      infoWindow:
          const InfoWindow(title: 'Anthonycodes', snippet: 'Hello friend'),
      icon: await customMarkerIcon.createMarkerIcon(),
    );
    _markers[id] = marker;
    setState(() {});
  }
}
