import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// Import your EditProfilePage and TokenService
import 'EditProfileScreen.dart';
import 'token_service.dart'; // Add this import
import 'LoginScreen.dart'; // Add this import for your login page

class MyProfilePage extends StatefulWidget {
  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  // User profile data
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String? errorMessage;
  String? accessToken;

  // Base API URL
  final String baseUrl = "http://35.200.140.65:5000/api/user";

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProfile();
  }

  // Load stored token and fetch profile
  Future<void> _loadTokenAndFetchProfile() async {
    await _loadStoredToken();
    await _fetchUserProfile();
  }

  // Load access token from storage
  Future<void> _loadStoredToken() async {
    try {
      accessToken = await TokenService.getAccessToken();
      print("Loaded Access Token: $accessToken");
    } catch (e) {
      print("Error loading token: $e");
    }
  }

  // Fetch user profile from API
  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (accessToken == null) {
        setState(() {
          errorMessage = "Authentication required. Please log in again.";
          isLoading = false;
        });
        return;
      }

      print("Making API call to: $baseUrl/profile");
      print("Using token: $accessToken");

      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: await TokenService.getAuthHeaders(),
      );

      print("Profile API Response Status: ${response.statusCode}");
      print("Profile API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userProfile = data;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = "Authentication required. Please log in again.";
          isLoading = false;
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          errorMessage = error["detail"] ?? "Failed to load profile";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Profile fetch error: $e");
      setState(() {
        errorMessage = "Network error. Please check your connection.";
        isLoading = false;
      });
    }
  }

  // Refresh profile data
  Future<void> _refreshProfile() async {
    await _fetchUserProfile();
  }

  // Handle logout functionality
  Future<void> _handleLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65DB47)),
                  ),
                  SizedBox(width: 20),
                  Text(
                    "Logging out...",
                    style: GoogleFonts.montserrat(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Clear all authentication data
      bool isCleared = await TokenService.clearAuthData();

      // Close loading dialog
      Navigator.of(context).pop();

      if (isCleared) {
        // Navigate back to login page and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()), // Replace with your actual login page
              (Route<dynamic> route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Logged out successfully",
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: Color(0xFF65DB47),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error message if logout failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error logging out. Please try again.",
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();

      print("Logout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error logging out. Please try again.",
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFAFA), // Off-white background
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFAFA), // Same background
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Profile",
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 24, // GH size from your image
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black, size: 24),
            onPressed: () {
              // Handle settings tap
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Loading or Error State
              if (isLoading)
                Container(
                  height: 200,
                  color: Colors.white,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65DB47)),
                    ),
                  ),
                )
              else if (errorMessage != null)
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF65DB47),
                        ),
                        child: Text(
                          "Retry",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
              // Profile Section with API data
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Profile Image with overlapping camera icon
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            child: ClipOval(
                              child: userProfile?['profile_image'] != null
                                  ? Image.network(
                                userProfile!['profile_image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.blue.shade200,
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              )
                                  : Container(
                                color: Colors.blue.shade200,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Camera/Edit Icon positioned at bottom-right
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 16),
                      // Profile Info with Edit Profile button - Using API data
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile?['name'] ?? "User Name",
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              userProfile?['email'] ?? "user@example.com",
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 12),
                            // Edit Profile Button - UPDATED WITH NAVIGATION
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to EditProfilePage with user data
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(),
                                  ),
                                ).then((result) {
                                  // Refresh profile when returning from edit page
                                  if (result == true) {
                                    _refreshProfile();
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF65DB47), // Green color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                minimumSize: Size(0, 36), // Compact height
                              ),
                              child: Text(
                                "Edit Profile",
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 20),

              // User Stats Section (if available in API)
              if (userProfile != null && !isLoading)
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                          "Total Rides",
                          userProfile?['total_rides']?.toString() ?? "0"
                      ),
                      _buildStatItem(
                          "Wallet Balance",
                          "₹${userProfile?['wallet_balance']?.toString() ?? "0"}"
                      ),
                      _buildStatItem(
                          "User Type",
                          userProfile?['user_type'] ?? "Standard"
                      ),
                    ],
                  ),
                ),

              if (userProfile != null && !isLoading)
                SizedBox(height: 20),

              // Menu Items Section 1
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.credit_card_outlined,
                      title: "Payment Methods",
                      onTap: () {
                        // Handle Payment Methods tap
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Ride Credits",
                      subtitle: userProfile != null
                          ? "₹${userProfile!['wallet_balance']?.toString() ?? "0"}"
                          : null,
                      onTap: () {
                        // Handle Ride Credits tap
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Menu Items Section 2
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.language_outlined,
                      title: "Languages",
                      onTap: () {
                        // Handle Languages tap
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      title: "Location",
                      onTap: () {
                        // Handle Location tap
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Menu Items Section 3
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: "Help and Support",
                      onTap: () {
                        // Handle Help and Support tap
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: "Log Out",
                      onTap: () {
                        // Handle Log Out tap
                        _showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // App Version
              Text(
                "App Version 2.3",
                style: GoogleFonts.montserrat(
                  fontSize: 14, // P1/H2 size
                  color: Colors.black54,
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF65DB47),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44, // Increased size
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.black87, size: 24), // Increased icon size
            ),
            SizedBox(width: 24), // Increased spacing between icon and text
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16, // H1 size
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Color(0xFF65DB47),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),

                // Title
                Text(
                  "Do you want to logout?",
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                // Subtitle
                Text(
                  "You won't be able to make any payments until you login again.",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // Buttons row
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: Container(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Logout button
                    Expanded(
                      child: Container(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog first
                            _handleLogout(); // Then handle logout
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF65DB47),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Logout",
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}