import 'package:flutter/material.dart';
import 'scanner_page.dart';
import 'my_profile_page.dart';
import 'token_service.dart';
import 'LoginScreen.dart';
import 'RideActivityPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String greeting = 'Good Morning!';

  // Base API URL
  final String baseUrl = "http://35.200.140.65:5000/api/user";

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadUserProfile();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning!';
    } else if (hour < 17) {
      greeting = 'Good Afternoon!';
    } else {
      greeting = 'Good Evening!';
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Check if user is authenticated
      final isLoggedIn = await TokenService.isLoggedIn();
      if (!isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      // Get auth headers with token
      final headers = await TokenService.getAuthHeaders();

      print("Loading profile for homepage with headers: $headers");

      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: headers,
      );

      print("Homepage Profile API Response Status: ${response.statusCode}");
      print("Homepage Profile API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userProfile = data;
          isLoading = false;
        });
        print("Profile loaded for homepage: $userProfile");
      } else if (response.statusCode == 401) {
        // Token is invalid, clear auth data and redirect to login
        await TokenService.clearAuthData();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Homepage profile load error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
      // Home - already here
        break;
      case 1:
      // History -> Navigate to ActiveBikeRidePage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ActiveBikeRidePage(),
          ),
        );
        break;
      case 2:
      // Profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyProfilePage(),
          ),
        ).then((_) {
          // Refresh profile when returning from profile page
          _loadUserProfile();
          // Reset selected index to home
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
    }

    // Reset selection after a delay
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _selectedIndex = 0; // Reset to home
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF90E76A),
              Color(0x6090E76A),
              Color(0x00FFFFFF),
            ],
            stops: [0.0, 0.20, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Main content with bottom padding for navigation
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Top bar with greeting and notification - FIXED TEXT COLOR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting 👋',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87, // Changed from white to black
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isLoading
                                      ? 'Loading...'
                                      : 'Welcome, ${userProfile?['name']?.split(' ')[0] ?? 'User'}!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withOpacity(0.7), // Changed from white to black
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Main QR Code Card with user profile picture
                      Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 350),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Profile Avatar with user data
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glow effect
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF90E76A).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(45),
                                    ),
                                  ),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(color: Color(0xFF90E76A), width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF90E76A).withOpacity(0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(37),
                                      child: isLoading
                                          ? Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                      )
                                          : userProfile?['profile_image'] != null
                                          ? Image.network(
                                        userProfile!['profile_image'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.blue.shade300, Colors.purple.shade300],
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      )
                                          : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFF90E76A), Color(0xFF65DB47)],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Camera icon overlay
                                  Positioned(
                                    right: 0,
                                    bottom: 5,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF90E76A),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // QR Code Image - FIXED TO SHOW IMAGE PROPERLY
                              Center(
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: Colors.grey[200]!, width: 1),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Image.asset(
                                      'assets/images/qr_code.png', // Your QR code image
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Clean fallback with QR icon instead of hardcoded text
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.qr_code_2,
                                                  size: 60,
                                                  color: Colors.grey[400],
                                                ),
                                                SizedBox(height: 10),
                                                Text(
                                                  'QR Code',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Enhanced Scan QR Button
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScannerPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFF90E76A),
                                    Color(0xFF65DB47),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF90E76A).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'scan the qr',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Enhanced Bottom Action Cards
                      Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 350),
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Action Buttons Row
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        print('Booking History tapped');
                                      },
                                      child: Container(
                                        height: 95,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Icon(
                                                  Icons.history,
                                                  color: Color(0xFF90E76A),
                                                  size: 22,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF90E76A).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward,
                                                    color: Color(0xFF90E76A),
                                                    size: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Booking\nHistory',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        print('Active Bike tapped');
                                      },
                                      child: Container(
                                        height: 95,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Icon(
                                                  Icons.directions_bike,
                                                  color: Colors.orange.shade600,
                                                  size: 22,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.orange.shade600,
                                                    size: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Active\nBike',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Total Kilometer Card with user data
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        Icons.analytics,
                                        color: Colors.blue.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Total rides',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isLoading
                                              ? '...'
                                              : '${userProfile?['total_rides'] ?? 0} rides',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 100), // Space for fixed bottom navigation
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Bottom Navigation Bar - Same as ActiveBikeRidePage
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
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;

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