import 'package:flutter/material.dart';
import 'SignUpScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  TextEditingController _emailController = TextEditingController(text: 'Loisbecket@gmail.com');
  TextEditingController _passwordController = TextEditingController(text: '••••••••');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top gradient section with logo - extends to notification bar
          Container(
            height: 200 + MediaQuery.of(context).padding.top, // Add top padding height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF90E76A),  // Light green at 0%
                  Color(0x6090E76A),  // Light green at 20% with 38% opacity
                  Color(0x00FFFFFF),  // White at 100% with 0% opacity (transparent)
                ],
                stops: [0.0, 0.20, 1.0], // Shorter gradient transition
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with text included
                    Container(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        'assets/images/prayana_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Rest of the content with white background - wrapped in SafeArea for bottom
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),

                  // Sign in title
                  Text(
                    'Sign in to your',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    'Enter your email and password to log in',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 32),

                  // Email field
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintStyle: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Password field
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Color(0xFF999999),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        hintStyle: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Remember me and forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Color(0xFF4CAF50),
                              side: BorderSide(
                                color: Color(0xFFCCCCCC),
                                width: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Password ?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Log In button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Or divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Color(0xFFE0E0E0),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Color(0xFFE0E0E0),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Continue with Google button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login,
                            color: Color(0xFF4285F4),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Spacer(),

                  // Sign up link
                  SafeArea(
                    top: false, // Don't apply safe area to top
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SignUpScreen()),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}