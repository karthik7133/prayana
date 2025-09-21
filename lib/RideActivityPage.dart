import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class RideActivityPage extends StatefulWidget {
  const RideActivityPage({Key? key}) : super(key: key);

  @override
  State<RideActivityPage> createState() => _RideActivityPageState();
}

class _RideActivityPageState extends State<RideActivityPage> {
  // Theme Colors
  static const Color primaryGreen = Color(0xFF65DB47);
  static const Color primaryWhite = Color(0xFFFFFAFA);
  static const Color primaryGray = Color(0xFF808080);
  static const Color secondaryGray = Color(0xFFD3D3D3);
  static const Color blackColor = Color(0xFF101010);

  // Map Controller
  final MapController _mapController = MapController();

  // State Variables
  LatLng _currentLocation = const LatLng(0.0, 0.0); // Will be updated with real location
  List<BikeMarker> _availableBikes = [];
  BikeMarker? _selectedBike;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  double _distance = 0.0;
  int _estimatedTime = 0;
  bool _isRideActive = false;
  bool _locationLoaded = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedForeverDialog();
        return;
      }

      // Get high accuracy location with longer timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });

      // Move map to current location with animation
      _mapController.move(_currentLocation, 17.0);

      // Generate mock bikes around current location
      _generateMockBikesAroundLocation();

    } catch (e) {
      print('Error getting location: $e');
      // Try with lower accuracy as fallback
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _locationLoaded = true;
        });
        _mapController.move(_currentLocation, 16.0);
        _generateMockBikesAroundLocation();
      } catch (e2) {
        // Final fallback to default location
        setState(() {
          _currentLocation = const LatLng(17.3850, 78.4867);
          _locationLoaded = true;
        });
        _mapController.move(_currentLocation, 15.0);
        _fetchAvailableBikes();
      }
    }
  }

  void _zoomIn() {
    double currentZoom = _mapController.zoom;
    if (currentZoom < 18.0) {
      _mapController.move(_mapController.center, currentZoom + 1);
    }
  }

  void _zoomOut() {
    double currentZoom = _mapController.zoom;
    if (currentZoom > 3.0) {
      _mapController.move(_mapController.center, currentZoom - 1);
    }
  }

  void _goToMyLocation() {
    if (_locationLoaded) {
      _mapController.move(_currentLocation, 17.0);
    } else {
      _initializeLocation(); // Try to get location again
    }
  }

  Widget _buildZoomButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: primaryWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: blackColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: primaryGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _goToMyLocation,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Only move map if we're tracking during ride
      if (_isRideActive) {
        _mapController.move(_currentLocation, _mapController.zoom);
      }
    }, onError: (error) {
      print('Location tracking error: $error');
    });
  }

  void _generateMockBikesAroundLocation() {
    // Generate bikes within 500m radius of current location
    List<BikeMarker> mockBikes = [];

    for (int i = 1; i <= 5; i++) {
      // Random offset within 500m (approximately 0.005 degrees)
      double latOffset = (Random().nextDouble() - 0.5) * 0.01;
      double lngOffset = (Random().nextDouble() - 0.5) * 0.01;

      mockBikes.add(BikeMarker(
        id: 'bike_$i',
        location: LatLng(
          _currentLocation.latitude + latOffset,
          _currentLocation.longitude + lngOffset,
        ),
        batteryLevel: 60 + Random().nextInt(40), // 60-100%
        isAvailable: Random().nextBool() || i <= 3, // Ensure at least 3 bikes available
      ));
    }

    setState(() {
      _availableBikes = mockBikes;
    });
  }

  Future<void> _fetchAvailableBikes() async {
    // Fallback method for when GPS fails
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      List<BikeMarker> mockBikes = [
        BikeMarker(
          id: 'bike_1',
          location: LatLng(_currentLocation.latitude + 0.002, _currentLocation.longitude + 0.001),
          batteryLevel: 85,
          isAvailable: true,
        ),
        BikeMarker(
          id: 'bike_2',
          location: LatLng(_currentLocation.latitude - 0.001, _currentLocation.longitude + 0.002),
          batteryLevel: 92,
          isAvailable: true,
        ),
        BikeMarker(
          id: 'bike_3',
          location: LatLng(_currentLocation.latitude + 0.001, _currentLocation.longitude - 0.002),
          batteryLevel: 67,
          isAvailable: false,
        ),
      ];

      setState(() {
        _availableBikes = mockBikes;
      });
    } catch (e) {
      print('Error fetching bikes: $e');
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('This app needs location permission to show your current location and nearby bikes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text('Location permission has been permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _selectBike(BikeMarker bike) {
    if (!bike.isAvailable) return;

    setState(() {
      _selectedBike = bike;
    });

    _showDestinationDialog();
  }

  void _showDestinationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Destination'),
        content: const Text('Tap on the map to set your destination point.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setDestination(LatLng destination) {
    setState(() {
      _destination = destination;
      _isRideActive = true;
    });
    _calculateRoute();
  }

  void _calculateRoute() {
    if (_selectedBike == null || _destination == null) return;

    // Mock route calculation - replace with actual routing API
    List<LatLng> mockRoute = [
      _selectedBike!.location,
      LatLng(
        (_selectedBike!.location.latitude + _destination!.latitude) / 2,
        (_selectedBike!.location.longitude + _destination!.longitude) / 2,
      ),
      _destination!,
    ];

    double distance = _calculateDistance(_selectedBike!.location, _destination!);
    int estimatedTime = (distance * 4).round(); // 4 minutes per km

    setState(() {
      _routePoints = mockRoute;
      _distance = distance;
      _estimatedTime = estimatedTime;
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }

  Future<void> _endRide() async {
    if (!_isRideActive) return;

    // Check if user is at a valid stall location
    bool isAtValidStall = await _validateStallLocation();

    if (isAtValidStall) {
      _showSuccessDialog('Ride ended successfully!');
      setState(() {
        _isRideActive = false;
        _selectedBike = null;
        _destination = null;
        _routePoints.clear();
        _distance = 0.0;
        _estimatedTime = 0;
      });
    } else {
      _showWarningDialog('Please drop the bike at a valid stall location.');
    }
  }

  Future<bool> _validateStallLocation() async {
    // Mock stall validation - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 300));

    // For demo, randomly return true/false
    return DateTime.now().millisecondsSinceEpoch % 2 == 0;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: primaryGreen, size: 48),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning, color: Colors.orange, size: 48),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Alert'),
          ],
        ),
        content: const Text('Emergency alert has been sent to our support team. Help is on the way.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: AppBar(
        title: const Text('Ride Activity', style: TextStyle(color: blackColor)),
        backgroundColor: primaryWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: blackColor),
      ),
      body: Column(
        children: [
          // Top Info Cards
          _buildInfoCards(),

          // Map Section
          Expanded(
            child: _buildMap(),
          ),

          // Bottom Buttons
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.straighten, color: primaryGray),
                    const SizedBox(height: 8),
                    Text(
                      '${_distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                    ),
                    const Text(
                      'Distance',
                      style: TextStyle(color: primaryGray),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.access_time, color: primaryGray),
                    const SizedBox(height: 8),
                    Text(
                      '$_estimatedTime min',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                    ),
                    const Text(
                      'Est. Time',
                      style: TextStyle(color: primaryGray),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child:         FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _locationLoaded ? _currentLocation : const LatLng(17.3850, 78.4867),
            zoom: _locationLoaded ? 16.0 : 6.0,
            onTap: (tapPosition, point) {
              if (_selectedBike != null && _destination == null) {
                _setDestination(point);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.bikeapp',
              additionalOptions: const {
                'attribution': '© OpenStreetMap contributors',
              },
              maxZoom: 18,
              subdomains: const ['a', 'b', 'c'],
            ),

            // Route Polyline
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: primaryGreen,
                  ),
                ],
              ),

            // Markers
            MarkerLayer(
              markers: [
                // Current Location
                Marker(
                  width: 40.0,
                  height: 40.0,
                  point: _currentLocation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Available Bikes
                ..._availableBikes.map((bike) => Marker(
                  width: 40.0,
                  height: 40.0,
                  point: bike.location,
                  child: GestureDetector(
                    onTap: () => _selectBike(bike),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bike.isAvailable ? primaryGreen : primaryGray,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedBike?.id == bike.id ? blackColor : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.directions_bike,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                )),

                // Destination Marker
                if (_destination != null)
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: _destination!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),

            // Attribution
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.white70,
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isRideActive ? _endRide : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'End Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleEmergency,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Emergency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class BikeMarker {
  final String id;
  final LatLng location;
  final int batteryLevel;
  final bool isAvailable;

  BikeMarker({
    required this.id,
    required this.location,
    required this.batteryLevel,
    required this.isAvailable,
  });
}

// API Service (Mock Implementation)
class ApiService {
  static const String baseUrl = 'https://your-api-domain.com';

  static Future<List<BikeMarker>> fetchAvailableBikes(String pickupStallId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/bikes/availability'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pickup_stall_id': pickupStallId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Parse response and return BikeMarker list
        return []; // Implement parsing logic
      } else {
        throw Exception('Failed to fetch bikes');
      }
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchStallDetails(String stallId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stalls/$stallId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch stall details');
      }
    } catch (e) {
      print('API Error: $e');
      return {};
    }
  }
}