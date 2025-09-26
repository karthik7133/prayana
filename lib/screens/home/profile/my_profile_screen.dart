import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_profile_screen.dart';
import '../../../services/token_service.dart';
import '../../auth/login_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String? errorMessage;

  final String baseUrl = "http://35.200.140.65:5000/api/user";

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorMessage = null; // Clear previous errors on refresh attempt
      });

      final headers = await TokenService.getAuthHeaders();
      if (headers.isEmpty) {
        throw Exception("Authentication token is not available.");
      }

      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => userProfile = jsonDecode(response.body));
      } else {
        // Handle server errors but still show the UI
        setState(() => errorMessage = "Failed to load profile data.");
      }
    } catch (e) {
      // This catch block is crucial for network errors (no internet)
      if (mounted) {
        setState(() => errorMessage = "You are currently offline.");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final cs = Theme.of(context).colorScheme;
        final ts = Theme.of(context).textTheme;
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: cs.primary),
                const SizedBox(width: 20),
                Text("Logging out...", style: ts.bodyLarge),
              ],
            ),
          ),
        );
      },
    );

    await TokenService.clearAuthData();
    if (!mounted) return;
    Navigator.pop(context); // Close dialog

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.background,
        elevation: 0,
        title: Text(
          "My Profile",
          style: ts.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onBackground,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onBackground),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: cs.onBackground),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserProfile,
        color: cs.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (isLoading)
                Container(
                  height: 200,
                  color: cs.surface,
                  child: Center(child: CircularProgressIndicator(color: cs.primary)),
                )
              else
              // Always build the profile content, even on error
                Column(
                  children: [
                    // MODIFICATION: Show an offline indicator if there's an error
                    if (errorMessage != null)
                      _buildOfflineIndicator(cs, ts),

                    _buildProfileContent(cs, ts),
                  ],
                ),

              if (!isLoading) ...[
                const SizedBox(height: 40),
                Text(
                  "App Version 2.3",
                  style: ts.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 30),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET TO SHOW WHEN OFFLINE
  Widget _buildOfflineIndicator(ColorScheme cs, TextTheme ts) {
    return Container(
      width: double.infinity,
      color: cs.secondaryContainer,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 20, color: cs.onSecondaryContainer),
          const SizedBox(width: 12),
          Text(
            errorMessage!, // Displays "You are currently offline."
            style: ts.bodyMedium?.copyWith(color: cs.onSecondaryContainer, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // PROFILE CONTENT WIDGET WITH STATIC FALLBACKS
  Widget _buildProfileContent(ColorScheme cs, TextTheme ts) {
    return Column(
      children: [
        // Profile Section
        Container(
          color: cs.surface,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outlineVariant, width: 1),
                    ),
                    child: ClipOval(
                      child: userProfile?['profile_image'] != null
                          ? Image.network(
                        userProfile!['profile_image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: cs.primaryContainer, child: Icon(Icons.person, size: 40, color: cs.onPrimaryContainer)),
                      )
                          : Container(color: cs.primaryContainer, child: Icon(Icons.person, size: 40, color: cs.onPrimaryContainer)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant, width: 1),
                      ),
                      child: Icon(Icons.camera_alt, size: 16, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userProfile?['name'] ?? "Guest User", style: ts.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(userProfile?['email'] ?? "---", style: ts.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/edit-profile').then((result) {
                          if (result == true) _fetchUserProfile();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text("Edit Profile", style: ts.labelLarge),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // User Stats Section
        Container(
          color: cs.surface,
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(cs, ts, "Total Rides", userProfile?['total_rides']?.toString() ?? "---"),
              _buildStatItem(cs, ts, "Wallet Balance", "₹${userProfile?['wallet_balance']?.toString() ?? "---"}"),
              _buildStatItem(cs, ts, "User Type", userProfile?['user_type'] ?? "---"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Menu Items
        Container(
          color: cs.surface,
          child: Column(
            children: [
              _buildMenuItem(cs: cs, ts: ts, icon: Icons.credit_card_outlined, title: "Payment Methods", onTap: () {}),
              _buildDivider(),
              _buildMenuItem(cs: cs, ts: ts,
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Ride Credits",
                  subtitle: "₹${userProfile?['wallet_balance']?.toString() ?? "---"}",
                  onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          color: cs.surface,
          child: Column(
            children: [
              _buildMenuItem(cs: cs, ts: ts, icon: Icons.language_outlined, title: "Languages", onTap: () {}),
              _buildDivider(),
              _buildMenuItem(cs: cs, ts: ts, icon: Icons.location_on_outlined, title: "Location", onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          color: cs.surface,
          child: Column(
            children: [
              _buildMenuItem(cs: cs, ts: ts, icon: Icons.help_outline, title: "Help and Support", onTap: () {}),
              _buildDivider(),
              _buildMenuItem(cs: cs, ts: ts, icon: Icons.logout, title: "Log Out", onTap: () => _showLogoutDialog(context, cs, ts)),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods below are unchanged but will now display the static data when userProfile is null.

  Widget _buildStatItem(ColorScheme cs, TextTheme ts, String label, String value) {
    return Column(
      children: [
        Text(value, style: ts.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
        const SizedBox(height: 4),
        Text(label, style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildMenuItem({
    required ColorScheme cs,
    required TextTheme ts,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: cs.onSurfaceVariant, size: 24),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ts.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: ts.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
  );

  void _showLogoutDialog(BuildContext context, ColorScheme cs, TextTheme ts) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.logout, color: cs.onErrorContainer, size: 30),
                ),
                const SizedBox(height: 20),
                Text("Do you want to logout?", style: ts.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  "You won't be able to make any payments until you login again.",
                  style: ts.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: cs.outlineVariant)),
                          child: Text("Cancel", style: ts.labelLarge?.copyWith(color: cs.onSurface)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleLogout();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary, elevation: 0),
                          child: Text("Logout", style: ts.labelLarge?.copyWith(color: cs.onPrimary)),
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