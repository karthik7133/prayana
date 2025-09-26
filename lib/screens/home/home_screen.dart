import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart'; // Added for Lottie animations
import 'dart:convert';

import 'scanner_screen.dart';
import '../../../services/token_service.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    // As it is evening in Amaravati, the greeting will be "Good Evening!"
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
    // This function remains the same, handling user authentication and data fetching.
    try {
      setState(() {
        isLoading = true;
      });

      final isLoggedIn = await TokenService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/login',
          );
        }
        return;
      }

      final headers = await TokenService.getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userProfile = data;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await TokenService.clearAuthData();
        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Homepage profile load error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- Helper methods for the "Recent Activity" section ---

  IconData _getActivityIcon(int index) {
    final icons = [
      Icons.electric_bike,
      Icons.location_on,
      Icons.battery_charging_full,
      Icons.timer,
      Icons.route,
      Icons.eco,
    ];
    return icons[index % icons.length];
  }

  String _getActivityTitle(int index) {
    final titles = [
      'Last Ride',
      'Favorite Station',
      'Battery Status',
      'Ride Duration',
      'Distance Covered',
      'Eco Impact',
    ];
    return titles[index % titles.length];
  }

  String _getActivitySubtitle(int index) {
    final subtitles = [
      '2 hours ago - AB-1 to MH',
      'AB-1 Station - Most visited',
      '85% charged - Ready to ride',
      'Average 25 minutes per ride',
      'Total 150 km this month',
      'Saved 12 kg CO2 this month',
    ];
    return subtitles[index % subtitles.length];
  }

  // --- Helper widget for the "Discover" section ---

  Widget _buildPlaceholderCard(
      {required String location, required int bikesAvailable}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Station $location',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '$bikesAvailable bikes available',
            style: TextStyle(
              color: Colors.green.shade700, // Kept for strong contrast
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Kept the gradient background
        decoration: const BoxDecoration(
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Top bar with greeting and notification icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLoading
                                  ? 'Loading...'
                                  : 'Welcome, ${userProfile?['name']?.split(' ')[0] ?? 'User'}!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black.withOpacity(0.7),
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
                          border:
                          Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Main card with Lottie animation
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
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
                        // Scanner Lottie animation
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/scanner',
                            );
                          },
                          child: Container(
                            width: 220,
                            height: 220,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: Colors.grey[200]!, width: 1),
                            ),
                            child: Lottie.asset(
                              'assets/animations/scanner.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                        ),

                        // MODIFICATION: Added visible guide text below the scanner
                        const SizedBox(height: 20),
                        Text(
                          'Tap to scan the QR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bottom card with Discover & Recent Activity
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Discover Section
                        Text(
                          'Discover',
                          style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPlaceholderCard(
                            location: 'AB-1', bikesAvailable: 5),
                        const SizedBox(height: 12),
                        _buildPlaceholderCard(
                            location: 'AB-2', bikesAvailable: 3),
                        const SizedBox(height: 12),
                        _buildPlaceholderCard(
                            location: 'MH', bikesAvailable: 8),
                        const SizedBox(height: 20),

                        // Recent Activity Section
                        Text(
                          'Recent Activity',
                          style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Activity list items
                        for (int i = 0; i < 6; i++) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Icon(
                                _getActivityIcon(i),
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                            ),
                            title: Text(_getActivityTitle(i)),
                            subtitle: Text(_getActivitySubtitle(i)),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.withOpacity(0.6),
                            ),
                            onTap: () {},
                          ),
                          if (i < 5) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}