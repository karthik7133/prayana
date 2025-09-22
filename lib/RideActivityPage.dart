import 'package:flutter/material.dart';
import 'dart:async';

class ActiveBikeRidePage extends StatefulWidget {
  const ActiveBikeRidePage({super.key});

  @override
  _ActiveBikeRidePageState createState() => _ActiveBikeRidePageState();
}

class _ActiveBikeRidePageState extends State<ActiveBikeRidePage> {
  int _selectedNavIndex = -1; // No nav item selected on this page

  // Ride data that would come from Bluetooth connection
  String rideTime = "00:12 mins";
  String currentFare = "₹70";
  String batteryLevel = "99%";

  Timer? _rideTimer;
  int _totalSeconds = 12 * 60; // Starting with 12 minutes

  @override
  void initState() {
    super.initState();
    _startRideTimer();
  }

  @override
  void dispose() {
    _rideTimer?.cancel();
    super.dispose();
  }

  void _startRideTimer() {
    _rideTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _totalSeconds++;
        int minutes = _totalSeconds ~/ 60;
        int seconds = _totalSeconds % 60;
        rideTime = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} mins";

        // Update fare based on time (example calculation)
        int fareAmount = 50 + (minutes * 2); // Base 50 + 2 rupees per minute
        currentFare = "₹$fareAmount";
      });
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
      // Home
        Navigator.pop(context);
        break;
      case 1:
      // History
        print('History tapped');
        break;
      case 2:
      // Profile
        print('Profile tapped');
        break;
    }

    // Reset selection after a delay
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _selectedNavIndex = -1;
        });
      }
    });
  }

  void _endRide() {
    _rideTimer?.cancel();
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
                Navigator.pop(context); // Go back to home
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
                // Handle issue reporting
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Issue reported successfully',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.red[600],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFAFA), // Off-white background
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top - 80, // Account for nav bar
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
                        color: Color(0xFFF5F5F5), // Light gray background
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 140,
                          child: Image.asset(
                            'assets/images/bike.png', // Your bike image
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

                          // Three square stats with white borders
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
                              color: Color(0xFFFEFAF9), // Very light green background
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
                                        color: Color(0xFFFF4444), // Red border color
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Report Issue',
                                      style: TextStyle(
                                        color: Color(0xFFFF4444), // Red text color
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
                                    onPressed: _endRide,
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

                          SizedBox(height: 100), // Space for bottom navigation
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Navigation Bar - Completely flush to bottom
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
                top: false, // Don't add safe area padding on top
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
            borderRadius: BorderRadius.circular(20), // Rounded square shape like reference
            border: Border.all(
              color: Colors.white, // White border like in reference
              width: 8, // Thicker white border
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
            color: Colors.black, // Black icons
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