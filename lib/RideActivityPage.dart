import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart'; // Import your TokenService

class ActiveBikeRidePage extends StatefulWidget {
  const ActiveBikeRidePage({super.key});

  @override
  _ActiveBikeRidePageState createState() => _ActiveBikeRidePageState();
}

class _ActiveBikeRidePageState extends State<ActiveBikeRidePage> {
  int _selectedNavIndex = -1;

  // API data
  String rideTime = "00:00 mins";
  String currentFare = "₹0";
  String batteryLevel = "0%";
  String rideId = "";
  bool isLoading = true;
  bool hasError = false;

  Timer? _rideTimer;
  Timer? _apiRefreshTimer;

  // API configuration
  final String baseUrl = "http://35.200.140.65:5000";
  final String activeRideEndpoint = "/api/rides/active";

  @override
  void initState() {
    super.initState();
    _initializePageData();
  }

  @override
  void dispose() {
    _rideTimer?.cancel();
    _apiRefreshTimer?.cancel();
    super.dispose();
  }

  // Initialize page data - check authentication first
  Future<void> _initializePageData() async {
    final isLoggedIn = await TokenService.isLoggedIn();
    if (!isLoggedIn) {
      _showAuthenticationError();
      return;
    }

    _fetchActiveRideData();
    _startApiRefreshTimer();
  }

  // Fetch active ride data from API with authentication
  Future<void> _fetchActiveRideData() async {
    print('🚀 Starting authenticated API call to: $baseUrl$activeRideEndpoint');

    try {
      // Get auth headers from TokenService
      final headers = await TokenService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl$activeRideEndpoint'),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      print('📡 Response status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Parsed JSON data: $data');

        setState(() {
          // Update with actual API response structure
          rideTime = _formatDuration(data['duration'] ?? 0);
          currentFare = "₹${data['current_fare'] ?? 0}";
          batteryLevel = "${data['battery_level'] ?? 0}%";
          rideId = data['ride_id'] ?? "";
          isLoading = false;
          hasError = false;
        });

        // Start local timer for real-time updates
        _startRideTimer();
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - token might be expired');
        await TokenService.clearAuthData(); // Clear invalid token
        _showAuthenticationError();
      } else if (response.statusCode == 404) {
        print('❌ No active ride found (404)');
        setState(() {
          isLoading = false;
          hasError = true;
        });
        _showNoActiveRideDialog();
      } else {
        print('❌ API Error - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load ride data - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception during API call: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
      _showErrorDialog();
    }
  }

  // Start timer to refresh API data periodically
  void _startApiRefreshTimer() {
    _apiRefreshTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchActiveRideData();
    });
  }

  // Start local timer for UI updates
  void _startRideTimer() {
    _rideTimer?.cancel(); // Cancel existing timer
    _rideTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        // Update local time display
        var currentTime = DateTime.now();
        // You might want to calculate based on ride start time from API
        rideTime = _formatDuration(_getTotalSecondsFromTime(rideTime) + 1);
      });
    });
  }

  // Helper function to format duration
  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} mins";
  }

  // Helper function to parse time string back to seconds
  int _getTotalSecondsFromTime(String timeStr) {
    try {
      var parts = timeStr.replaceAll(' mins', '').split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  void _showNoActiveRideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Active Ride'),
          content: Text('You don\'t have any active rides at the moment.'),
          actions: [
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Unable to fetch ride data. Please check your connection and try again.'),
          actions: [
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                _fetchActiveRideData();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show authentication error dialog
  void _showAuthenticationError() {
    setState(() {
      isLoading = false;
      hasError = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Authentication Required',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Please login to continue. Your session may have expired.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF65DB47),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
                // Navigate to your login screen
                // Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
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

    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _selectedNavIndex = -1;
        });
      }
    });
  }

  // End ride API call with authentication
  Future<void> _endRide() async {
    try {
      final headers = await TokenService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/api/rides/$rideId/end'),
        headers: headers,
        body: json.encode({
          'end_time': DateTime.now().toIso8601String(),
        }),
      );

      print('End ride response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        _rideTimer?.cancel();
        _apiRefreshTimer?.cancel();
        Navigator.pop(context); // Go back to home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ride ended successfully',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xFF65DB47),
          ),
        );
      } else if (response.statusCode == 401) {
        await TokenService.clearAuthData();
        _showAuthenticationError();
      } else {
        throw Exception('Failed to end ride - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error ending ride: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to end ride. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEndRideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'End Ride',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Are you sure you want to end this ride?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF65DB47),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'End Ride',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
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
          content: Text(
            'What issue would you like to report with this bike?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _submitIssueReport();
              },
            ),
          ],
        );
      },
    );
  }

  // Submit issue report to API with authentication
  Future<void> _submitIssueReport() async {
    try {
      final headers = await TokenService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/api/rides/$rideId/report-issue'),
        headers: headers,
        body: json.encode({
          'issue_type': 'general',
          'description': 'User reported an issue during ride',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      print('Report issue response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Issue reported successfully',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      } else if (response.statusCode == 401) {
        await TokenService.clearAuthData();
        _showAuthenticationError();
      } else {
        throw Exception('Failed to report issue - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error reporting issue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to report issue. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFFFFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65DB47)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading active ride...',
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

    if (hasError) {
      return Scaffold(
        backgroundColor: Color(0xFFFFFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              SizedBox(height: 16),
              Text(
                'Unable to load ride data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    hasError = false;
                  });
                  _fetchActiveRideData();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFFFFAFA),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top - 80,
                ),
                child: Column(
                  children: [
                    // Header with back button
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
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bike Image Section
                    Container(
                      width: double.infinity,
                      height: 220,
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 140,
                          child: Image.asset(
                            'assets/images/bike.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_bike,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Electric Bike',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Stats Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SizedBox(height: 30),

                          Row(
                            children: [
                              Expanded(
                                child: _buildStatSquare(
                                  Icons.access_time,
                                  "Ride Time",
                                  rideTime,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildStatSquare(
                                  Icons.credit_card,
                                  "Current Fare",
                                  currentFare,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildStatSquare(
                                  Icons.battery_charging_full,
                                  "Battery",
                                  batteryLevel,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 30),

                          // Important Note Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFFFEFAF9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(0xFF65DB47).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Important Note',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
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

                          SizedBox(height: 30),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _reportIssue,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Color(0xFFFF4444),
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
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
                              SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _showEndRideDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF65DB47),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
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

                          SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Navigation Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNavItem(Icons.home, "Home", 0),
                    ),
                    Expanded(
                      child: _buildNavItem(Icons.history, "History", 1),
                    ),
                    Expanded(
                      child: _buildNavItem(Icons.person_outline, "Profile", 2),
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

  Widget _buildStatSquare(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Color(0xFF65DB47),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 28,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
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

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Container(
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFF65DB47) : Colors.grey.shade400,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Color(0xFF65DB47) : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}