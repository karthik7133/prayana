import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../home/home_screen.dart';
// Import the token service
import '../../services/token_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // Base API URL
  final String baseUrl = "http://35.200.140.65:5000/api/auth";

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await TokenService.isLoggedIn();
    if (isLoggedIn) {
      // User is already logged in, navigate to homepage
      Navigator.pushNamed(
        context,
        '/home',
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login API call
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print("Making API call to: $baseUrl/login");
      print("Email: $email");

      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        return {"success": true, "data": responseData};
      } else {
        var responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          print("Failed to decode error response: $e");
          return {"success": false, "message": "Invalid login credentials"};
        }

        String errorMessage = "Invalid login credentials";

        if (responseData != null) {
          if (responseData.containsKey("detail")) {
            if (responseData["detail"] is List && responseData["detail"].isNotEmpty) {
              errorMessage = responseData["detail"][0]["msg"] ?? "Invalid login credentials";
            } else if (responseData["detail"] is String && responseData["detail"].trim().isNotEmpty) {
              errorMessage = responseData["detail"];
            }
          } else if (responseData.containsKey("message") && responseData["message"].toString().trim().isNotEmpty) {
            errorMessage = responseData["message"];
          } else if (responseData.containsKey("error") && responseData["error"].toString().trim().isNotEmpty) {
            errorMessage = responseData["error"];
          }
        }

        // Handle server errors (500) specifically
        if (response.statusCode == 500) {
          errorMessage = "Please check your credentials and try again.";
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage = "Invalid email or password. Please try again.";
        } else if (response.statusCode == 404) {
          errorMessage = "Login service not found. Please try again later.";
        }

        // Ensure we always have a meaningful error message
        if (errorMessage.trim().isEmpty) {
          errorMessage = "Login failed. Please check your credentials and try again.";
        }

        print("Error Message: $errorMessage");
        return {"success": false, "message": errorMessage};
      }
    } catch (e) {
      print("Network Error: $e");
      return {"success": false, "message": "Network error. Please check your connection."};
    }
  }

  // Forgot Password API call
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot_password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "Password reset email sent successfully"};
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = "Failed to send reset email";

        if (error.containsKey("detail")) {
          if (error["detail"] is List) {
            errorMessage = error["detail"][0]["msg"] ?? "Validation error";
          } else if (error["detail"] is String) {
            errorMessage = error["detail"];
          }
        }

        return {"success": false, "message": errorMessage};
      }
    } catch (e) {
      return {"success": false, "message": "Network error. Please check your connection."};
    }
  }

  // Resend Verification Email API call
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/resend_verification"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "Verification email sent successfully"};
      } else {
        final error = jsonDecode(response.body);
        String errorMessage = "Failed to send verification email";

        if (error.containsKey("detail")) {
          if (error["detail"] is List) {
            errorMessage = error["detail"][0]["msg"] ?? "Validation error";
          } else if (error["detail"] is String) {
            errorMessage = error["detail"];
          }
        }

        return {"success": false, "message": errorMessage};
      }
    } catch (e) {
      return {"success": false, "message": "Network error. Please check your connection."};
    }
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    TextEditingController forgotEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Forgot Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: forgotEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String email = forgotEmailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter your email address'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                var result = await forgotPassword(email);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result["message"]),
                    backgroundColor: result["success"] ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(150,48),
              ),
              child: Text(
                'Send Reset Link',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Handle login button press - UPDATED WITH TOKEN STORAGE
  void _handleLogin() async {
    if (_isLoading) return;

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Clear previous error message
    setState(() {
      _errorMessage = '';
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var result = await loginUser(email, password);

    setState(() {
      _isLoading = false;
    });

    // Add debugging
    print("LOGIN RESULT: $result");
    print("SUCCESS: ${result["success"]}");
    print("MESSAGE: ${result["message"]}");

    if (result["success"] == true) {
      var userData = result["data"];
      var user = userData["user"];
      var accessToken = userData["access_token"];
      var refreshToken = userData["refresh_token"];

      // Check if user is verified
      if (user["is_verified"] == false) {
        // Show verification dialog
        _showVerificationDialog(email);
        return;
      }

      // Store tokens and user data using TokenService
      bool saveSuccess = await TokenService.saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userData: user,
      );

      if (saveSuccess) {
        print("Tokens and user data saved successfully");
        print("Access Token: $accessToken");
        print("Refresh Token: $refreshToken");

        // Navigate to next page immediately on success
        Navigator.pushReplacementNamed(
          context,
          '/home');
      } else {
        print("Failed to save auth data");
        setState(() {
          _errorMessage = "Failed to save login data. Please try again.";
        });
      }

    } else {
      // Show error message - Force set error message
      String finalErrorMessage = result["message"] ?? "Login failed. Please try again.";

      // Ensure error message is not empty
      if (finalErrorMessage.trim().isEmpty) {
        finalErrorMessage = "Invalid email or password. Please try again.";
      }

      print("SETTING ERROR MESSAGE: $finalErrorMessage");
      setState(() {
        _errorMessage = finalErrorMessage;
      });

      // Force rebuild to show error
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  // Show verification dialog for unverified users
  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Email Verification Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Text(
            'Your email address is not verified. Please check your email for the verification link or click below to resend it.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                var result = await resendVerificationEmail(email);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result["message"]),
                    backgroundColor: result["success"] ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Resend Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top gradient section with logo
            Container(
              height: 200 + MediaQuery.of(context).padding.top,
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
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

            // Rest of the content - made scrollable
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),

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

                    // ERROR MESSAGE DISPLAY - Above email field for better visibility
                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFFE57373),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Color(0xFFD32F2F),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Email field
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                        border: _errorMessage.isNotEmpty ? Border.all(
                          color: Color(0xFFE57373),
                          width: 1,
                        ) : null,
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          // Clear error message when user starts typing
                          if (_errorMessage.isNotEmpty) {
                            setState(() {
                              _errorMessage = '';
                            });
                          }
                        },
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
                        border: _errorMessage.isNotEmpty ? Border.all(
                          color: Color(0xFFE57373),
                          width: 1,
                        ) : null,
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        onChanged: (value) {
                          // Clear error message when user starts typing
                          if (_errorMessage.isNotEmpty) {
                            setState(() {
                              _errorMessage = '';
                            });
                          }
                        },
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

                    // Remember me + forgot password
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
                          onPressed: _showForgotPasswordDialog,
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

                    // Log In button with loading state
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Color(0xFF4CAF50).withOpacity(0.6),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
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
                        onPressed: () {
                          // TODO: Implement Google Sign In
                        },
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

                    SizedBox(height: 40),

                    // Sign up link
                    Center(
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
                              Navigator.pushNamed(
                                context,
                                '/signup',
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

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}