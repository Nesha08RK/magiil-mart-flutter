import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class OSMAddressPicker extends StatefulWidget {
  final LatLng? initialLocation;

  const OSMAddressPicker({super.key, this.initialLocation});

  @override
  State<OSMAddressPicker> createState() => _OSMAddressPickerState();
}

/* ================== ERODE BOUNDARY ================== */

class _ErodeServiceBoundary {
  static const double northBound = 11.60;
  static const double southBound = 11.00;
  static const double eastBound = 78.00;
  static const double westBound = 77.40;
  static const LatLng center = LatLng(11.3441, 77.7064);

  static bool isWithinBounds(LatLng location) {
    return location.latitude >= southBound &&
        location.latitude <= northBound &&
        location.longitude >= westBound &&
        location.longitude <= eastBound;
  }

  static LatLng snapToBounds(LatLng location) {
    final lat = location.latitude.clamp(southBound, northBound);
    final lng = location.longitude.clamp(westBound, eastBound);
    return LatLng(lat, lng);
  }
}

/* ================== STATE ================== */

class _OSMAddressPickerState extends State<OSMAddressPicker> {
  late final MapController _mapController;
  late LatLng _selectedLocation;

  String _selectedAddress = "Loading address...";
  bool _isLoadingAddress = false;
  bool _isOutOfBounds = false;

  DateTime? _lastGeocodeRequest;
  static const _debounceMs = 800;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _selectedLocation = widget.initialLocation != null &&
            _ErodeServiceBoundary.isWithinBounds(widget.initialLocation!)
        ? widget.initialLocation!
        : _ErodeServiceBoundary.center;

    _reverseGeocode(_selectedLocation);
  }

  /* ================== REVERSE GEOCODING ================== */

  Future<void> _reverseGeocode(LatLng location) async {
    setState(() => _isLoadingAddress = true);

    try {
      // 1️⃣ Try device geocoder
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final parts = [
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode
        ].where((e) => e != null && e!.isNotEmpty).join(', ');

        if (parts.isNotEmpty) {
          setState(() {
            _selectedAddress = parts;
            _isLoadingAddress = false;
          });
          return;
        }
      }
    } catch (_) {}

    // 2️⃣ Fallback to Nominatim (Web-safe)
    try {
      final url =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&addressdetails=1";

      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "magiil-mart-app"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data["display_name"];

        if (displayName != null && displayName.isNotEmpty) {
          setState(() {
            _selectedAddress = displayName;
            _isLoadingAddress = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Final fallback
    setState(() {
      _selectedAddress = "Location in Erode, Tamil Nadu";
      _isLoadingAddress = false;
    });
  }

  /* ================== LIVE LOCATION ================== */

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingAddress = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingAddress = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingAddress = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final newLocation = LatLng(position.latitude, position.longitude);

    if (!_ErodeServiceBoundary.isWithinBounds(newLocation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("📍 Delivery available only in Erode district")),
      );
      setState(() => _isLoadingAddress = false);
      return;
    }

    _mapController.move(newLocation, 17);

    setState(() => _selectedLocation = newLocation);

    await _reverseGeocode(newLocation);
  }

  /* ================== MAP MOVE ================== */

  void _onMapMove(MapPosition position, bool hasGesture) {
    final center = position.center;
    if (center == null) return;

    if (!_ErodeServiceBoundary.isWithinBounds(center)) {
      final snapped =
          _ErodeServiceBoundary.snapToBounds(center);

      _mapController.move(
        snapped,
        position.zoom ?? _mapController.camera.zoom,
      );

      if (!_isOutOfBounds) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "📍 Delivery available only in Erode district")),
        );
      }

      setState(() => _isOutOfBounds = true);
      return;
    }

    setState(() {
      _selectedLocation = center;
      _isOutOfBounds = false;
    });

    _lastGeocodeRequest = DateTime.now();

    Future.delayed(const Duration(milliseconds: _debounceMs), () {
      if (_lastGeocodeRequest != null &&
          DateTime.now()
                  .difference(_lastGeocodeRequest!)
                  .inMilliseconds >=
              _debounceMs) {
        _reverseGeocode(center);
      }
    });
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      "address": _selectedAddress,
      "lat": _selectedLocation.latitude,
      "lng": _selectedLocation.longitude,
    });
  }

  /* ================== UI ================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Delivery Location"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 17,
              minZoom: 12,
              maxZoom: 19,
              onPositionChanged: _onMapMove,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png",
                userAgentPackageName: "com.magiil.mart",
              ),
            ],
          ),

          /* Center Pin with Glow */
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOutOfBounds
                        ? Colors.orange.withAlpha(30)
                        : Colors.red.withAlpha(30),
                  ),
                ),
                Icon(Icons.location_on,
                    size: 45,
                    color:
                        _isOutOfBounds ? Colors.orange : Colors.red),
              ],
            ),
          ),

          /* Instruction Overlay */
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                "Move the map to place the pin on your delivery location",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),

          /* Live Location Button */
          Positioned(
            bottom: 200,
            right: 16,
            child: FloatingActionButton(
              onPressed: _useCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          /* Bottom Panel */
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Selected Address",
                      style:
                          TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _isLoadingAddress
                      ? const CircularProgressIndicator()
                      : Text(_selectedAddress),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      child: const Text("Confirm Location"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
