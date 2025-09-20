import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_service.dart';
import 'LoginScreen.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers for form fields
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedCountryCode = "+91";
  String selectedBirth = "Birth";
  String selectedGender = "Gender";

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  Map<String, dynamic>? userProfile;

  // Base API URL
  final String baseUrl = "http://35.200.140.65:5000/api/user";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Load user profile from API
  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
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

      print("Loading profile for edit with headers: $headers");

      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: headers,
      );

      print("Edit Profile API Response Status: ${response.statusCode}");
      print("Edit Profile API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userProfile = data;
          _populateFormFields(data);
          isLoading = false;
        });
        print("Profile loaded for editing: $userProfile");
      } else if (response.statusCode == 401) {
        // Token is invalid, clear auth data and redirect to login
        await TokenService.clearAuthData();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          errorMessage = error["detail"] ?? "Failed to load profile";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Profile load error: $e");
      setState(() {
        errorMessage = "Network error. Please check your connection.";
        isLoading = false;
      });
    }
  }

  // Populate form fields with user data
  void _populateFormFields(Map<String, dynamic> userData) {
    // Split name into first and last name if it exists
    String fullName = userData['name'] ?? '';
    List<String> nameParts = fullName.split(' ');

    firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
    lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    emailController.text = userData['email'] ?? '';

    // Handle phone number
    String phone = userData['mobile'] ?? '';
    if (phone.startsWith('+91')) {
      selectedCountryCode = '+91';
      phoneController.text = phone.substring(3);
    } else if (phone.startsWith('+1')) {
      selectedCountryCode = '+1';
      phoneController.text = phone.substring(2);
    } else if (phone.startsWith('+234')) {
      selectedCountryCode = '+234';
      phoneController.text = phone.substring(4);
    } else if (phone.startsWith('+44')) {
      selectedCountryCode = '+44';
      phoneController.text = phone.substring(3);
    } else {
      phoneController.text = phone;
    }

    // Set username (you might want to make this editable or not based on your API)
    usernameController.text = userData['user_id'] ?? '';

    // Set other fields if available in your API response
    selectedGender = userData['gender'] ?? 'Gender';
    selectedBirth = userData['birth_year']?.toString() ?? 'Birth';
  }

  // Save profile changes
  Future<void> _saveProfile() async {
    try {
      setState(() {
        isSaving = true;
        errorMessage = null;
      });

      // Get auth headers with token
      final headers = await TokenService.getAuthHeaders();

      // Prepare update data
      Map<String, dynamic> updateData = {
        'name': '${firstNameController.text.trim()} ${lastNameController.text.trim()}'.trim(),
        'mobile': '$selectedCountryCode${phoneController.text.trim()}',
      };

      // Add optional fields if they're not default values
      if (selectedGender != 'Gender') {
        updateData['gender'] = selectedGender;
      }
      if (selectedBirth != 'Birth') {
        updateData['birth_year'] = int.tryParse(selectedBirth);
      }

      print("Saving profile with data: $updateData");

      final response = await http.put(
        Uri.parse("$baseUrl/profile"),
        headers: headers,
        body: jsonEncode(updateData),
      );

      print("Update Profile API Response Status: ${response.statusCode}");
      print("Update Profile API Response Body: ${response.body}");

      setState(() {
        isSaving = false;
      });

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF7ED321),
            duration: Duration(seconds: 2),
          ),
        );

        // Return to previous screen with success indicator
        Navigator.pop(context, true);
      } else if (response.statusCode == 401) {
        // Token is invalid, clear auth data and redirect to login
        await TokenService.clearAuthData();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        final error = jsonDecode(response.body);
        String errorMsg = "Failed to update profile";

        if (error.containsKey("detail")) {
          if (error["detail"] is List && error["detail"].isNotEmpty) {
            errorMsg = error["detail"][0]["msg"] ?? errorMsg;
          } else if (error["detail"] is String) {
            errorMsg = error["detail"];
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("Profile save error: $e");
      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top gradient section with profile image
            Container(
              height: 320,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF65DB47),  // #65DB47 at 0%
                    Color(0xA046C963),  // #46C963 at 37% with 63% opacity
                    Color(0x00D9D9D9),  // #D9D9D9 at 100% with 0% opacity (transparent)
                  ],
                  stops: [0.0, 0.37, 1.0], // Exact gradient stops from your image
                ),
              ),
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    top: 60,
                    left: 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Save button
                  Positioned(
                    top: 60,
                    right: 20,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: isSaving ? null : _saveProfile,
                        child: isSaving
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Profile image with edit button
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
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
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                )
                                    : Container(
                                  color: Colors.blue.shade200,
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(0xFF7ED321),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading or Error State
            if (isLoading)
              Container(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7ED321)),
                  ),
                ),
              )
            else if (errorMessage != null)
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7ED321),
                      ),
                      child: Text(
                        "Retry",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
            // Form section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 30),

                    // First Name
                    _buildInputField("First Name", firstNameController),
                    SizedBox(height: 20),

                    // Last Name
                    _buildInputField("Last Name", lastNameController),
                    SizedBox(height: 20),

                    // Username (Read-only for user_id)
                    _buildInputField("User ID", usernameController, readOnly: true),
                    SizedBox(height: 20),

                    // Email (Read-only typically)
                    _buildInputField("Email", emailController, readOnly: true),
                    SizedBox(height: 20),

                    // Phone Number
                    _buildPhoneField(),
                    SizedBox(height: 20),

                    // Birth dropdown
                    _buildDropdownField("Birth", selectedBirth, ["Birth", "1990", "1991", "1992", "1993", "1994", "1995", "1996", "1997", "1998", "1999", "2000", "2001", "2002", "2003", "2004", "2005"]),
                    SizedBox(height: 20),

                    // Gender dropdown
                    _buildDropdownField("Gender", selectedGender, ["Gender", "Male", "Female", "Other"]),
                    SizedBox(height: 40),

                    // Change Password Button
                    Container(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle change password
                          _showChangePasswordDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7ED321),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Change Password",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Updated input field to match login page styling with subtle border
  Widget _buildInputField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Color(0xFFF8F8F8) : Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: readOnly ? Colors.grey[500] : Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: Color(0xFF999999),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Updated phone field to match login page styling with subtle border
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Country code dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: DropdownButton<String>(
                  value: selectedCountryCode,
                  underline: SizedBox(),
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  items: ["+91", "+1", "+234", "+44"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCountryCode = newValue!;
                    });
                  },
                ),
              ),
              Container(width: 1, height: 20, color: Colors.grey[300]),
              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Updated dropdown field to match login page styling with subtle border
  Widget _buildDropdownField(String label, String selectedValue, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                if (label == "Birth") selectedBirth = newValue!;
                if (label == "Gender") selectedGender = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Change Password",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Text(
            "Password change functionality will be implemented here.",
          ),
          actions: [
            TextButton(
              child: Text(
                "Close",
                style: TextStyle(color: Color(0xFF7ED321)),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}