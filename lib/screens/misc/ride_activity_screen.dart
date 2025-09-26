import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/token_service.dart';

class ActiveBikeRidePage extends StatefulWidget {
  final Map<String, dynamic>? bookingData;

  const ActiveBikeRidePage({super.key, this.bookingData});

  @override
  State<ActiveBikeRidePage> createState() => _ActiveBikeRidePageState();
}

class _ActiveBikeRidePageState extends State<ActiveBikeRidePage> {
  int _selectedNavIndex = -1;

  // Booking/Ride data
  String rideTime = "00:00 mins";
  String currentFare = "₹0";
  String batteryLevel = "85%";
  String bookingId = "";
  String bikeId = "";
  String pickupStall = "";
  String dropStall = "";
  DateTime? bookingStartTime;
  DateTime? pickupTime;
  DateTime? returnTime;
  bool isLoading = false;
  bool hasError = false;

  Timer? _rideTimer;
  Timer? _locationUpdateTimer;

  // API configuration
  final String baseUrl = "http://35.200.140.65:5000";
  final String locationUpdateEndpoint = "/api/bikes/location/update";
  final String cancelBookingEndpoint = "/api/bookings/";

  @override
  void initState() {
    super.initState();
    _initializePageData();
  }

  @override
  void dispose() {
    _rideTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializePageData() {
    if (widget.bookingData != null) {
      _loadBookingData(widget.bookingData!);
    } else {
      _loadStaticData();
    }
  }

  void _loadBookingData(Map<String, dynamic> data) {
    setState(() {
      bookingId = data['booking_id']?.toString() ?? "BK${DateTime.now().millisecondsSinceEpoch}";
      bikeId = data['bike_id']?.toString() ?? "PY001";
      pickupStall = data['pickup_stall_id']?.toString() ?? "1";
      dropStall = data['drop_stall_id']?.toString() ?? "2";

      if (data['pickup_time'] != null) {
        pickupTime = DateTime.parse(data['pickup_time']);
      }
      if (data['return_time'] != null) {
        returnTime = DateTime.parse(data['return_time']);
      }

      bookingStartTime = DateTime.now();
      if (pickupTime != null && returnTime != null) {
        final durationHours = returnTime!.difference(pickupTime!).inHours;
        final baseFare = durationHours * 25;
        currentFare = "₹$baseFare";
      }

      batteryLevel = "${data['battery_level'] ?? 85}%";
      isLoading = false;
      hasError = false;
    });

    _startRideTimer();
    _startLocationUpdates();
  }

  void _loadStaticData() {
    setState(() {
      bookingId = "BK${DateTime.now().millisecondsSinceEpoch}";
      bikeId = "PY001";
      pickupStall = "Guntur Railway Station";
      dropStall = "Amaravati Secretariat";
      bookingStartTime = DateTime.now();
      pickupTime = DateTime.now();
      returnTime = DateTime.now().add(const Duration(hours: 2));
      batteryLevel = "85%";
      currentFare = "₹50";
      isLoading = false;
      hasError = false;
    });

    _startRideTimer();
    _startLocationUpdates();
  }

  void _startRideTimer() {
    _rideTimer?.cancel();
    _rideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && bookingStartTime != null) {
        setState(() {
          final duration = DateTime.now().difference(bookingStartTime!);
          rideTime = _formatDuration(duration.inSeconds);
          final minutes = duration.inMinutes;
          final timeFare = (minutes / 30).ceil() * 25;
          final baseFare = pickupTime != null && returnTime != null ?
          returnTime!.difference(pickupTime!).inHours * 25 : 50;
          final totalFare = baseFare + timeFare;
          currentFare = "₹$totalFare";
        });
      }
    });
  }

  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && bikeId.isNotEmpty) {
        _updateBikeLocation();
      }
    });
  }

  Future<void> _updateBikeLocation() async {
    try {
      final headers = await TokenService.getAuthHeaders();
      final locationData = {
        'bike_id': bikeId,
        'latitude': 16.3067 + (DateTime.now().millisecond / 100000),
        'longitude': 80.4365 + (DateTime.now().millisecond / 100000),
        'speed': 15.5,
        'battery_level': int.tryParse(batteryLevel.replaceAll('%', '')) ?? 85,
        'status': 'riding'
      };

      final response = await http.post(
        Uri.parse('$baseUrl$locationUpdateEndpoint'),
        headers: headers,
        body: json.encode(locationData),
      );
      print('Location update response: ${response.statusCode}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _cancelBookingApiCall() async {
    try {
      final headers = await TokenService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$cancelBookingEndpoint$bookingId/cancel'),
        headers: headers,
      );

      print('Cancel booking API response: ${response.statusCode}');
      print('Cancel booking API body: ${response.body}');

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Ride canceled successfully!');
      } else {
        _showErrorSnackBar('Failed to cancel ride. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: ${e.toString()}');
    }
  }

  String _formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} hrs";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} mins";
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        print('History tapped');
        break;
      case 2:
        print('Profile tapped');
        break;
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _selectedNavIndex = -1;
        });
      }
    });
  }

  // Modified _endRide to handle both end and cancel logic
  Future<void> _endRide() async {
    print('🛑 Ending booking: $bookingId');

    try {
      _rideTimer?.cancel();
      _locationUpdateTimer?.cancel();

      // Call the API to cancel the booking
      await _cancelBookingApiCall();

      // Navigate back to the previous screen
      Navigator.pop(context);

    } catch (e) {
      print('Error ending ride: $e');
      _showErrorSnackBar('Failed to end ride. Please try again.');
    }
  }

  void _showEndRideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'End Ride',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to end this ride?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Current fare: $currentFare',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Duration: $rideTime',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Drop Location: $dropStall',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65DB47),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'End Ride',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _endRide();
              },
            ),
          ],
        );
      },
    );
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Report Issue',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.red[700],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What issue would you like to report with this bike?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bike ID: $bikeId',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Booking ID: $bookingId',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _submitIssueReport();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitIssueReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Issue reported successfully. Our team will contact you soon.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error reporting issue: $e');
      _showErrorSnackBar('Failed to report issue. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65DB47)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading ride details...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Booking ID: $bookingId',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              'Bike ID: $bikeId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 220,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_bike,
                          size: 60,
                          color: Color(0xFF65DB47),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Active Ride',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bike ID: $bikeId',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF65DB47), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'From: $pickupStall',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'To: $dropStall',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatSquare(
                        Icons.access_time,
                        "Ride Time",
                        rideTime,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatSquare(
                        Icons.credit_card,
                        "Current Fare",
                        currentFare,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatSquare(
                        Icons.battery_charging_full,
                        "Battery",
                        batteryLevel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFAF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF65DB47).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Important Note',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'For everyone\'s safety, kindly return the bike to the assigned parking stall. Misuse or improper parking could lead to strict action.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _reportIssue,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFFF4444),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Report Issue',
                            style: TextStyle(
                              color: Color(0xFFFF4444),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _showEndRideDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF65DB47),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'End Ride',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatSquare(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF65DB47),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}