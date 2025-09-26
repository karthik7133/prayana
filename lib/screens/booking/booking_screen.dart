import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
// Import your TokenService and ActiveBikeRidePage
import 'package:prayana_electric/services/token_service.dart'; // Update with your actual path
import 'package:prayana_electric/screens/misc/ride_activity_screen.dart'; // Update with your actual path

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const BookingScreen({super.key, required this.bookingData});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _modelController;
  late final TextEditingController _idController;
  late final TextEditingController _pickupTimeController;

  // Stalls and selection
  final List<String> _stallIds = ['AB-1', 'AB-2', 'MH', 'LH'];
  final String _pickupStall = 'AB-1'; // dummy/stable pickup stall UI
  String? _selectedDropStall;

  Timer? _timer;
  bool _isBooking = false;

  // API Configuration
  static const String baseUrl = 'http://35.200.140.65:5000';
  static const String createBookingEndpoint = '/api/bookings/create';

  // Shared max width for top card & form (keeps them aligned)
  static const double _maxContentWidth = 520;

  // text style used across rows and dropdown (keeps everything uniform)
  static const TextStyle _valueTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87);
  static const TextStyle _labelTextStyle = TextStyle(fontSize: 12, color: Colors.black54);

  @override
  void initState() {
    super.initState();

    print("BookingScreen initialized with data: ${widget.bookingData}"); // Debug log

    _modelController =
        TextEditingController(text: widget.bookingData['model'] ?? 'Electric Bike');
    _idController = TextEditingController(text: widget.bookingData['id'] ?? widget.bookingData['bike_id'] ?? '');
    _pickupTimeController =
        TextEditingController(text: DateFormat('hh:mm a').format(DateTime.now()));

    // Auto-select a drop stall: prefer bookingData dropStall (if valid),
    // otherwise pick first stall != pickup.
    final providedDrop = widget.bookingData['dropStall'] as String? ?? widget.bookingData['drop_stall_id'] as String?;
    if (providedDrop != null && _stallIds.contains(providedDrop) && providedDrop != _pickupStall) {
      _selectedDropStall = providedDrop;
    } else {
      _selectedDropStall = _stallIds.firstWhere((s) => s != _pickupStall, orElse: () => _stallIds.last);
    }

    // Update pickup time every second (controller updates field directly)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _pickupTimeController.text = DateFormat('hh:mm a').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _modelController.dispose();
    _idController.dispose();
    _pickupTimeController.dispose();
    super.dispose();
  }

  // Get stored access token using TokenService
  Future<String?> _getAccessToken() async {
    return await TokenService.getAccessToken();
  }

  // Get authorization headers using TokenService
  Future<Map<String, String>> _getAuthHeaders() async {
    return await TokenService.getAuthHeaders();
  }

  // Create booking via API - FIXED TO PROPERLY HANDLE RESPONSE
  // Create booking via API - FIXED TO PROPERLY HANDLE RESPONSE
  Future<Map<String, dynamic>?> _createBooking() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await TokenService.isLoggedIn();
      if (!isLoggedIn) {
        _showErrorSnackBar('Please login to continue booking.');
        return null;
      }

      // Calculate return time (assuming 2 hours from pickup time)
      final now = DateTime.now();
      final returnTime = now.add(const Duration(hours: 2));

      final requestBody = {
        'bike_id': _idController.text,
        'pickup_stall_id': _pickupStall,
        'drop_stall_id': _selectedDropStall,
        'pickup_time': now.toUtc().toIso8601String(),
        'return_time': returnTime.toUtc().toIso8601String(),
      };

      print("🚀 Creating booking with data: $requestBody"); // Debug log

      // Get headers with authentication
      final headers = await _getAuthHeaders();
      print("📡 Request headers: $headers"); // Debug log

      final response = await http.post(
        Uri.parse('$baseUrl$createBookingEndpoint'),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print("📊 Booking API Response Status: ${response.statusCode}");
      print("📋 Booking API Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Booking created successfully: $responseData');

        // Extract booking ID from response
        String? bookingId;
        if (responseData.containsKey('booking_id')) {
          bookingId = responseData['booking_id'].toString();
        } else if (responseData.containsKey('id')) {
          bookingId = responseData['id'].toString();
        } else if (responseData.containsKey('data') && responseData['data'].containsKey('booking_id')) {
          bookingId = responseData['data']['booking_id'].toString();
        } else if (responseData.containsKey('data') && responseData['data'].containsKey('id')) {
          bookingId = responseData['data']['id'].toString();
        }

        print("🎯 EXTRACTED BOOKING ID: $bookingId");

        // Create complete booking data for ActiveBikeRidePage
        final completeBookingData = {
          'booking_id': bookingId ?? 'BK_${DateTime.now().millisecondsSinceEpoch}',
          'bike_id': _idController.text,
          'pickup_stall_id': _pickupStall,
          'drop_stall_id': _selectedDropStall,
          'pickup_time': now.toIso8601String(),
          'return_time': returnTime.toIso8601String(),
          'battery_level': 85,
          'status': 'active',
          // Include original response data
          ...responseData,
        };

        print("📦 Complete booking data being passed: $completeBookingData");

        return completeBookingData;
      } else if (response.statusCode == 422) {
        // Validation error
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = _extractValidationError(errorData);
        _showErrorSnackBar('Validation Error: $errorMessage');
        return null;
      } else if (response.statusCode == 401) {
        // Unauthorized - token might be expired
        _showErrorSnackBar('Session expired. Please login again.');
        // Optionally clear auth data and redirect to login
        await TokenService.clearAuthData();
        return null;
      } else {
        _showErrorSnackBar('Failed to create booking. Status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      _showErrorSnackBar('Network error: ${e.toString()}');
      print('💥 Booking creation error: $e');
      return null;
    }
  }

// ... other methods and widget code ...

  // Extract validation error message from API response
  String _extractValidationError(Map<String, dynamic> errorData) {
    if (errorData.containsKey('detail') && errorData['detail'] is List) {
      final details = errorData['detail'] as List;
      if (details.isNotEmpty && details.first is Map) {
        final firstError = details.first as Map<String, dynamic>;
        return firstError['msg'] ?? 'Unknown validation error';
      }
    }
    return 'Validation failed';
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Do you want to cancel Booking?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );
    if (shouldCancel == true && mounted){
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  void _bookNow() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDropStall == null || _selectedDropStall == _pickupStall) {
      _showErrorSnackBar('Please select a valid drop stall.');
      return;
    }

    setState(() => _isBooking = true);

    try {
      // Create booking via API
      final bookingData = await _createBooking();

      if (bookingData != null) {
        _showSuccessSnackBar('Bike booked successfully!');

        // Navigate to ActiveBikeRidePage with complete booking data
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveBikeRidePage(bookingData: bookingData),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _confirmCancel,
        ),
        title: const Text('Booking', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top bike card: DOUBLE height reserved, model REMOVED from top per request
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 280, // doubled height
                      constraints: BoxConstraints(maxWidth: _maxContentWidth),
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.motorcycle, size: 120, color: Colors.green),
                            SizedBox(height: 12),
                            // model removed here intentionally
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Main card: use the SAME max width as top container
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: _maxContentWidth - 145),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Row-style: label (left) and value (right)
                            _buildKeyValueRow(label: 'Model', value: _modelController.text, icon: Icons.directions_bike),
                            const SizedBox(height: 12),

                            _buildKeyValueRow(label: 'Bike ID', value: _idController.text, icon: Icons.confirmation_number),
                            const SizedBox(height: 12),

                            _buildKeyValueRow(label: 'Pickup Stall', value: _pickupStall, icon: Icons.storefront),
                            const SizedBox(height: 12),

                            // Drop stall: dropdown but styled same and fits without extra space
                            _buildKeyValueDropdown(
                              label: 'Drop Stall',
                              icon: Icons.place,
                              value: _selectedDropStall,
                              items: _stallIds.where((s) => s != _pickupStall).toList(),
                              onChanged: (v) => setState(() => _selectedDropStall = v),
                              validator: (v) => v == null || v.isEmpty ? 'Select drop stall' : null,
                            ),
                            const SizedBox(height: 12),

                            _buildKeyValueRow(label: 'Pickup Time', value: _pickupTimeController.text, icon: Icons.access_time),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons row: Book Now only (green background, black text)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isBooking ? null : _bookNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400], // green background
                              foregroundColor: Colors.black, // black text & icon color
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isBooking
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                                : const Text('Start Ride', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // KEY-VALUE ROW: left label (fixed width) and right value (expanded)
  Widget _buildKeyValueRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: _labelTextStyle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: _valueTextStyle),
          ),
        ],
      ),
    );
  }

  // KEY-VALUE DROPDOWN: label left and dropdown right, styled to match rows and avoid extra space
  Widget _buildKeyValueDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    // Ensure the dropdown items and selected text use the same style to avoid size jumps.
    final dropdownTextStyle = _valueTextStyle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: _labelTextStyle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              items: items.map((id) {
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(id, style: dropdownTextStyle),
                );
              }).toList(),
              onChanged: onChanged,
              validator: validator,
              isExpanded: true,
              // Force uniform selected item style and remove internal padding that causes shifts
              style: dropdownTextStyle,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}