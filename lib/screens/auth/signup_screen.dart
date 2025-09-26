import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:prayana_electric/colors.dart';
import 'dart:convert';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isPasswordVisible = false;
  bool _isTermsAccepted = false;
  bool _isLoading = false;
  String _selectedCountryCode = '+91';
  String _errorMessage = ''; // General error message
  Map<String, String> _fieldErrors = {}; // Field-specific errors

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'India');
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // API Base URL
  final String baseUrl = "http://35.200.140.65:5000/api/auth";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // Clear all error messages
  void _clearErrors() {
    setState(() {
      _errorMessage = '';
      _fieldErrors.clear();
    });
  }

  // Set field-specific error
  void _setFieldError(String field, String message) {
    setState(() {
      _fieldErrors[field] = message;
    });
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password strength validation
  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password);
  }

  // Phone number validation
  bool _isValidPhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  // Form validation
  bool _validateForm() {
    _clearErrors();
    bool isValid = true;

    if (_nameController.text.trim().isEmpty) {
      _setFieldError('name', 'Please enter your full name');
      isValid = false;
    } else if (_nameController.text.trim().length < 2) {
      _setFieldError('name', 'Name must be at least 2 characters long');
      isValid = false;
    }

    if (_emailController.text.trim().isEmpty) {
      _setFieldError('email', 'Please enter your email address');
      isValid = false;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      _setFieldError('email', 'Please enter a valid email address');
      isValid = false;
    }

    if (_phoneController.text.trim().isEmpty) {
      _setFieldError('phone', 'Please enter your phone number');
      isValid = false;
    } else if (!_isValidPhone(_phoneController.text.trim())) {
      _setFieldError('phone', 'Please enter a valid 10-digit phone number');
      isValid = false;
    }

    if (_passwordController.text.trim().isEmpty) {
      _setFieldError('password', 'Please set a password');
      isValid = false;
    } else if (!_isStrongPassword(_passwordController.text.trim())) {
      _setFieldError('password', 'Password must be at least 8 characters with uppercase, lowercase, and number');
      isValid = false;
    }

    if (!_isTermsAccepted) {
      setState(() {
        _errorMessage = 'Please accept the Terms and Conditions';
      });
      isValid = false;
    }

    return isValid;
  }

  // Sign Up API call
  Future<Map<String, dynamic>> signUpUser() async {
    try {
      print("Making signup API call to: $baseUrl/signup");

      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim().toLowerCase(),
          "password": _passwordController.text.trim(),
          "mobile": _phoneController.text.trim(),
          "address": _addressController.text.trim().isEmpty ? "Not provided" : _addressController.text.trim(),
          "country": _countryController.text.trim(),
          "state": _stateController.text.trim().isEmpty ? "Not provided" : _stateController.text.trim(),
          "city": _cityController.text.trim().isEmpty ? "Not provided" : _cityController.text.trim(),
          "pincode": _pincodeController.text.trim().isEmpty ? "000000" : _pincodeController.text.trim(),
          "user_type": "individual",
          "organization_name": ""
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
          return {"success": false, "message": "Registration failed. Please try again."};
        }

        String errorMessage = "Registration failed";

        if (responseData != null) {
          if (responseData.containsKey("detail")) {
            if (responseData["detail"] is List && responseData["detail"].isNotEmpty) {
              var details = responseData["detail"] as List;
              errorMessage = details[0]["msg"] ?? "Validation error";
            } else if (responseData["detail"] is String && responseData["detail"].trim().isNotEmpty) {
              errorMessage = responseData["detail"];
            }
          } else if (responseData.containsKey("message") && responseData["message"].toString().trim().isNotEmpty) {
            errorMessage = responseData["message"];
          }
        }

        // Handle specific error cases
        if (response.statusCode == 400) {
          if (errorMessage.toLowerCase().contains("email")) {
            errorMessage = "This email is already registered. Please use a different email.";
          } else if (errorMessage.toLowerCase().contains("phone") || errorMessage.toLowerCase().contains("mobile")) {
            errorMessage = "This phone number is already registered.";
          }
        } else if (response.statusCode == 500) {
          errorMessage = "Server error. Please try again later.";
        }

        // Ensure we always have a meaningful error message
        if (errorMessage.trim().isEmpty) {
          errorMessage = "Registration failed. Please check your information and try again.";
        }

        print("Error Message: $errorMessage");
        return {"success": false, "message": errorMessage};
      }
    } catch (e) {
      print("Network Error: $e");
      return {"success": false, "message": "Network error. Please check your connection."};
    }
  }

  // Handle registration
  void _handleSignUp() async {
    if (_isLoading) return;

    // Validate form first
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    var result = await signUpUser();

    setState(() {
      _isLoading = false;
    });

    if (result["success"]) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully! Please check your email for verification.'),
          backgroundColor: primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to login after successful registration
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/login');
        }
      });
    } else {
      // Show error message
      String finalErrorMessage = result["message"] ?? "Registration failed. Please try again.";

      if (finalErrorMessage.trim().isEmpty) {
        finalErrorMessage = "Registration failed. Please check your information and try again.";
      }

      setState(() {
        _errorMessage = finalErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 40),

              // Title
              Text(
                'Sign up',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 8),

              // Subtitle
              Text(
                'Create an account to continue!',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 40),

              // General error message
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
                SizedBox(height: 20),
              ],

              // Full Name Field
              _buildInputField(
                label: 'Full Name',
                controller: _nameController,
                hintText: 'Enter your full name',
                fieldKey: 'name',
              ),

              SizedBox(height: 24),

              // Email Field
              _buildInputField(
                label: 'Email',
                controller: _emailController,
                hintText: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                fieldKey: 'email',
              ),

              SizedBox(height: 24),

              // Phone Number Field
              _buildPhoneField(),

              SizedBox(height: 24),

              // Password Field
              _buildPasswordField(),

              SizedBox(height: 24),

              // Optional Fields Section
              Text(
                'Additional Information (Optional)',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),

              SizedBox(height: 16),

              // Address Field
              _buildInputField(
                label: 'Address',
                controller: _addressController,
                hintText: 'Enter your address (optional)',
                fieldKey: 'address',
              ),

              SizedBox(height: 16),

              // Country, State, City Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'State',
                      controller: _stateController,
                      hintText: 'State',
                      fieldKey: 'state',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      label: 'City',
                      controller: _cityController,
                      hintText: 'City',
                      fieldKey: 'city',
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Pincode Field
              _buildInputField(
                label: 'Pincode',
                controller: _pincodeController,
                hintText: 'Enter pincode',
                keyboardType: TextInputType.number,
                fieldKey: 'pincode',
              ),

              SizedBox(height: 32),

              // Terms and Conditions Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isTermsAccepted = !_isTermsAccepted;
                        if (_isTermsAccepted && _errorMessage.contains('Terms and Conditions')) {
                          _errorMessage = '';
                        }
                      });
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _isTermsAccepted ? Color(0xFF4CAF50) : Colors.transparent,
                        border: Border.all(
                          color: _isTermsAccepted ? Color(0xFF4CAF50) : Colors.grey[400]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _isTermsAccepted
                          ? Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      )
                          : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I agree to the Terms and Conditions',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Register Button
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                    'Register',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Login Link
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/login',
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account?  ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey[600],
                      ),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build input fields with error handling
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    required String fieldKey,
  }) {
    bool hasError = _fieldErrors.containsKey(fieldKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Color(0xFFE57373) : Colors.grey[200]!,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (value) {
              // Clear field error when user starts typing
              if (hasError) {
                setState(() {
                  _fieldErrors.remove(fieldKey);
                });
              }
            },
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintStyle: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ),
        // Error message for this field
        if (hasError) ...[
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              _fieldErrors[fieldKey]!,
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Phone field with country code and error handling
  Widget _buildPhoneField() {
    bool hasError = _fieldErrors.containsKey('phone');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Color(0xFFE57373) : Colors.grey[200]!,
              width: hasError ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Country Code
              Container(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇮🇳', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 4),
                    Text(
                      _selectedCountryCode,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              // Phone Number
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    // Clear field error when user starts typing
                    if (hasError) {
                      setState(() {
                        _fieldErrors.remove('phone');
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Error message for phone field
        if (hasError) ...[
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              _fieldErrors['phone']!,
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Password field with visibility toggle and error handling
  Widget _buildPasswordField() {
    bool hasError = _fieldErrors.containsKey('password');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Password',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Color(0xFFE57373) : Colors.grey[200]!,
              width: hasError ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {
                    // Clear field error when user starts typing
                    if (hasError) {
                      setState(() {
                        _fieldErrors.remove('password');
                      });
                    }
                    // Trigger rebuild for password strength indicator
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[500],
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        // Password error message
        if (hasError) ...[
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              _fieldErrors['password']!,
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ]
        // Password strength indicator (only when no error and password is not empty)
        else if (_passwordController.text.isNotEmpty) ...[
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              _isStrongPassword(_passwordController.text)
                  ? 'Strong password ✓'
                  : 'Password must be 8+ chars with uppercase, lowercase, and number',
              style: TextStyle(
                fontSize: 12,
                color: _isStrongPassword(_passwordController.text)
                    ? Colors.green
                    : Colors.orange[700],
              ),
            ),
          ),
        ],
      ],
    );
  }
}