import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../services/qr_service.dart';// Update with your actual path
import  '../booking/booking_screen.dart'; // Update with your actual path

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool scanning = true;
  bool isTorchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // FIXED: Direct navigation to BookingScreen with constructor parameters
  void _handleBarcode(BarcodeCapture capture) {
    if (!scanning) return;

    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() => scanning = false);
        controller.stop();

        print("QR Code detected: $code"); // Debug log

        // Try to decrypt and parse the QR code
        final decrypted = QrService.decrypt(code);
        if (decrypted != null) {
          print("QR Code decrypted: $decrypted"); // Debug log

          final data = QrService.parseJson(decrypted);
          if (data != null) {
            print("QR Data parsed: $data"); // Debug log

            // FIXED: Direct navigation to BookingScreen with data as constructor parameter
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(bookingData: data),
                ),
              );
            }
          } else {
            print("Failed to parse JSON data"); // Debug log
            _showError("Invalid QR code data format");
          }
        } else {
          print("Failed to decrypt QR code"); // Debug log

          // Try to parse as direct JSON (for testing without encryption)
          try {
            final directData = QrService.parseJson(code);
            if (directData != null) {
              print("QR Data parsed directly: $directData"); // Debug log

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(bookingData: directData),
                  ),
                );
              }
            } else {
              _showError("Invalid QR code format");
            }
          } catch (e) {
            print("Error parsing QR code: $e"); // Debug log
            _showError("Failed to read QR code");
          }
        }
        break; // Process only the first valid barcode
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _resumeScanning,
        ),
      ),
    );
    // Auto-resume scanning after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) _resumeScanning();
    });
  }

  void _resumeScanning() {
    if (mounted) {
      setState(() => scanning = true);
      controller.start();
    }
  }

  void _toggleFlash() async {
    try {
      await controller.toggleTorch();
      if (mounted) {
        setState(() => isTorchOn = !isTorchOn);
      }
    } catch (e) {
      print('Error toggling torch: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const qrSize = 250.0;
    final screenSize = MediaQuery.of(context).size;
    final qrLeft = (screenSize.width - qrSize) / 2;
    final qrTop = (screenSize.height - qrSize) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: _handleBarcode,
          ),

          // Dimmed overlay around QR box
          _dimOverlay(screenSize, qrLeft, qrTop, qrSize),

          // QR scanning area with animated border
          Positioned(
            left: qrLeft,
            top: qrTop,
            width: qrSize,
            height: qrSize,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade400, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: scanning
                  ? Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green.shade400.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              )
                  : null,
            ),
          ),

          // Instructions text
          Positioned(
            left: 0,
            right: 0,
            top: qrTop + qrSize + 30,
            child: const Center(
              child: Text(
                'Point your camera at the QR code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Scanning indicator
          if (scanning)
            Positioned(
              left: qrLeft,
              top: qrTop - 50,
              width: qrSize,
              child: const Center(
                child: Text(
                  'Scanning...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Back and Flash buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dimOverlay(
      Size screenSize, double qrLeft, double qrTop, double qrSize) {
    return Stack(
      children: [
        // Top
        Positioned(
          left: 0,
          top: 0,
          width: screenSize.width,
          height: qrTop,
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
        // Bottom
        Positioned(
          left: 0,
          top: qrTop + qrSize,
          width: screenSize.width,
          height: screenSize.height - (qrTop + qrSize),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
        // Left
        Positioned(
          left: 0,
          top: qrTop,
          width: qrLeft,
          height: qrSize,
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
        // Right
        Positioned(
          left: qrLeft + qrSize,
          top: qrTop,
          width: qrLeft,
          height: qrSize,
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
      ],
    );
  }
}