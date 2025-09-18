import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController firstNameController = TextEditingController(text: "Sabrina");
  final TextEditingController lastNameController = TextEditingController(text: "Aryan");
  final TextEditingController usernameController = TextEditingController(text: "@Sabrina");
  final TextEditingController emailController = TextEditingController(text: "@SabrinaAry208@gmail.com");
  final TextEditingController phoneController = TextEditingController(text: "904 6470");

  String selectedCountryCode = "+234";
  String selectedBirth = "Birth";
  String selectedGender = "Gender";

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
                                child: Image.asset(
                                  'assets/images/profile.jpg', // Replace with your image asset
                                  fit: BoxFit.cover,
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

                  // Username
                  _buildInputField("Username", usernameController),
                  SizedBox(height: 20),

                  // Email
                  _buildInputField("Email", emailController),
                  SizedBox(height: 20),

                  // Phone Number
                  _buildPhoneField(),
                  SizedBox(height: 20),

                  // Birth dropdown
                  _buildDropdownField("Birth", selectedBirth, ["Birth", "1990", "1991", "1992", "1993", "1994", "1995"]),
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

  Widget _buildInputField(String label, TextEditingController controller) {
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
          height: 55,
          child: TextFormField(
            controller: controller,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: Color(0xFF7ED321), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

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
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
            color: Colors.white,
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
                  items: ["+234", "+1", "+91", "+44"].map((String value) {
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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

  Widget _buildDropdownField(String label, String selectedValue, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              border: InputBorder.none,
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
}
