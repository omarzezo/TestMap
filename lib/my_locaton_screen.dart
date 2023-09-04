import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocode/geocode.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as lct;
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'dart:ui' as ui;


class MyLocationScreen extends StatefulWidget {
  @override
  _MyLocationScreenState createState() => _MyLocationScreenState();
}

class _MyLocationScreenState extends State<MyLocationScreen> {

  @override
  void initState() {
    super.initState();
    requestPerms();
  }
  LatLng currentLocation = const LatLng(0.0, 0.0);
  GoogleMapController? _mapController;
  lct.Location? location;
  BitmapDescriptor? icon;
  String? street,locality,administrativeArea,country;


  double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    // print("THeDistance>>"+(12742 * asin(sqrt(a))).toString());//1300.2253619108983
    // double.parse((12742 * asin(sqrt(a))).toStringAsFixed(0));
    // print("Neeeeeeeeee>>"+(12742 * asin(sqrt(a))).toStringAsFixed(0));
    return 1000 * 12742 * asin(sqrt(a));
  }

  getUserLocation() async {//call this async method from whereever you need
    final coordinates = new Coordinates(latitude: currentLocation.latitude,longitude: currentLocation.longitude);
    // var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    List<Placemark> placemarks = await placemarkFromCoordinates(currentLocation.latitude,currentLocation.longitude);
    Placemark first  = placemarks[0];
    // first = first.name;
    print(' ${first.locality}, ${first.administrativeArea},${first.subLocality}, ${first.subAdministrativeArea},${first.thoroughfare}, ${first.subThoroughfare}');
    return "NewMethod"+first.toString();
  }

  getLocation() async{
    var currentLocation = await location!.getLocation();
    locationUpdate(currentLocation);
    getLocationAddress(currentLocation.latitude??0, currentLocation.longitude??0);
    // final coordinates = new Coordinates(latitude: currentLocation.latitude,longitude: currentLocation.longitude);
    // var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);

    List<Placemark> placemarks = await placemarkFromCoordinates(currentLocation.latitude??0,currentLocation.longitude??0);
    Placemark first  = placemarks[0];

    // var first = addresses.first;
    print(' ${first.name}');
  }






  locationUpdate(currentLocation){
    if(currentLocation!= null){
      setState(() {
        this.currentLocation =
            LatLng(currentLocation.latitude, currentLocation.longitude);
        if(this._mapController!=null) {
          this._mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: this.currentLocation, zoom: 14),
          ));
        }
        _createMarker();
      });
    }
  }
  Future<String> getLocationAddress(double latitude, double longitude) async {
    // en_US
    List<Placemark> newPlace = await placemarkFromCoordinates(latitude, longitude, localeIdentifier: "ar_EG");
    Placemark placeMark = newPlace[0];
    street = placeMark.street!=null? placeMark.street:"";
    // print("streetIs1"+ placeMark.subLocality);
    // print("streetIs2"+ placeMark.subAdministrativeArea);
    // print("streetIs3"+ placeMark.subThoroughfare);
    locality =placeMark.locality!=null? placeMark.locality:"";
    administrativeArea =placeMark.administrativeArea!=null? placeMark.administrativeArea:"";
    country = placeMark.country!=null?placeMark.country:"";
    // String sub =placeMark.subAdministrativeArea!=null?placeMark.subAdministrativeArea:"";
    // print("streetIs4"+ "$street, $locality,$sub ,$administrativeArea, $country");
    return "$street, $locality ,$administrativeArea, $country";
  }

  void _onMapCreated(GoogleMapController controller){
    _mapController = controller;
  }

  changedLocation(){
    location!.onLocationChanged.listen((lct.LocationData cLoc) {
      if(cLoc != null) locationUpdate(cLoc);
    });
  }

  Future requestPerms() async {
    Future.delayed(const Duration(seconds: 1), () async {
      Map<Permission, PermissionStatus> statuses = await[
        Permission.location,
        // **Permission.locationAlways,
        Permission.locationWhenInUse,
      ].request();

      // Map<Permission, PermissionStatus> statuses = await [Permission.locationAlways].request();

      // var status = statuses[Permission.location,Permission.locationWhenInUse,];
      // var status = statuses[Permission.locationAlways,Permission.location,Permission.locationWhenInUse,];
      if (statuses == PermissionStatus.denied) {
        requestPerms();
      } else {
        gpsAnable();
      }
    });
  }

//Activar GPS
  gpsAnable() async {
    location = lct.Location();
    bool statusResult = await location!.requestService();

    if (!statusResult) {
      gpsAnable();
    } else {
      getLocation();
      changedLocation();
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
// icon Marker
  Future getIcons() async {
    Future.delayed(const Duration(seconds: 0), () async {
      final Uint8List markerIcon = await getBytesFromAsset(
          'assets/images/attendance-icon.jpg', 100);
      // var icon = await BitmapDescriptor.fromAssetImage(
      //     ImageConfiguration(devicePixelRatio: 3.0 ,size:  Size(4, 4)),
      //     // "assets/images/holiday.png");
      //     "assets/images/attendance-icon.jpg");
      var icon = await BitmapDescriptor.fromBytes(markerIcon);
      setState(() {
        this.icon = icon;
      });
    });
  }

//crear Marker
  Set<Marker> _createMarker() {

    var marker = Set<Marker>();

    marker.add(Marker(
      markerId: MarkerId("MarkerCurrent"),
      position: currentLocation,
      // icon:  icon,
      icon:  BitmapDescriptor.defaultMarker,
      // await setCustomMapPin.setCustomMapPin();
      infoWindow: InfoWindow(
        onTap: () {
        },
        title: "$locality , $administrativeArea ,$country",
        snippet: "Lat ${currentLocation.latitude} - Lng ${currentLocation.longitude} ",
      ),
      draggable: true,
      onDragEnd: onDragEnd,

    ));

    // marker.add(Marker(
    //   markerId: MarkerId("MarkerCurrent"),
    //   position: currentLocation,
    //   icon: icon,
    //   infoWindow: InfoWindow(
    //     onTap: () {
    //     },
    //     title: "$locality , $administrativeArea ,$country",
    //     snippet: "Lat ${currentLocation.latitude+1} - Lng ${currentLocation.longitude+1} ",
    //   ),
    //   draggable: true,
    //   onDragEnd: onDragEnd,
    //
    // ));
    return marker;
  }



  onDragEnd(LatLng position)  {
    print("nueva posicion $position");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            bottom:0,
            left: 0,
            right: 0,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation,
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              // compassEnabled: true,
              // mapToolbarEnabled: true,
              minMaxZoomPreference: MinMaxZoomPreference(12, 18.6),
              markers: _createMarker(),
              onMapCreated: _onMapCreated,
            ),
          ),
        ],
      )
    );
  }
}
