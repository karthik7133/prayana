import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import your EditProfilePage
import 'EditProfileScreen.dart';

class MyProfilePage extends StatelessWidget {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
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
                          child: Container(
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
                  // Profile Info with Edit Profile button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sabrina Aryan",
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "SabrinaAry208@gmail.com",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 12),
                        // Edit Profile Button - UPDATED WITH NAVIGATION
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to EditProfilePage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(),
                              ),
                            );
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
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
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
            // Title
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16, // H1 size
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
        return AlertDialog(
          title: Text(
            "Log Out",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                "Log Out",
                style: GoogleFonts.montserrat(color: Color(0xFF65DB47)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Handle actual logout logic here
              },
            ),
          ],
        );
      },
    );
  }
}