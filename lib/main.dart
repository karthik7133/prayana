import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for status bar styling
import 'colors.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/scanner_screen.dart';
import 'screens/home/profile/edit_profile_screen.dart';
import 'screens/home/profile/my_profile_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/history_screen.dart';
import 'screens/misc/ride_activity_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayana Electric',
      debugShowCheckedModeBanner: false,

      // --- THEME IMPLEMENTATION ---
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // A clean, modern font choice (optional, add to pubspec)

        // Use the custom green color to generate the entire color scheme.
        // Material 3 will intelligently create primary, secondary, tertiary,
        // surface, and all "on" colors (e.g., onPrimary) from this seed.
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.light,
          primary: primaryGreen, // Explicitly set primary for consistency
        ),

        // --- GLOBAL COMPONENT STYLING ---

        // Style for AppBars
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // For light backgrounds
          ),
          backgroundColor: Colors.transparent, // Makes app bar transparent
          elevation: 0,
          foregroundColor: Colors.black87, // Color for icons and title
        ),

        // Style for ElevatedButtons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        // Style for TextFields
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2.0),
          ),
        ),
      ),

      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => const MainPage(),
        '/scanner': (context) => const ScannerScreen(),
        '/edit-profile': (context) => EditProfileScreen(),
        '/profile': (context) => MyProfileScreen(),
        '/ride-history': (context) => const HistoryScreen(),
        '/active-ride': (context) => const ActiveBikeRidePage(),
      },
    );
  }
}

/// Main page with bottom navigation and tabs
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // The screens are now const because their content will rebuild, but the widget itself is constant.
  final List<Widget> _tabs = [
    const HomeScreen(),
    const HistoryScreen(),
    MyProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // No need to get colorScheme here, BottomNavigationBar already uses the theme.
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // The theme automatically handles the colors for selected and unselected items.
        // `selectedItemColor` will use `colorScheme.primary` (our green).
        // `unselectedItemColor` will use `colorScheme.onSurface.withOpacity(0.6)`.
        // This provides better contrast and adheres to Material Design guidelines.
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 2,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Ride History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), label: 'Profile'),
        ],
      ),
    );
  }
}