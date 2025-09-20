import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool scanning = true;
  bool isTorchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!scanning) return;

    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() => scanning = false);
        controller.stop();

        final decrypted = QrService.decrypt(code);
        if (decrypted != null) {
          final data = QrService.parseJson(decrypted);
          if (data != null) {
            _showResultDialog(data);
          } else {
            _showError("Invalid JSON data");
          }
        } else {
          _showError("Failed to decrypt QR code");
        }
        break;
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.directions_bike,
              color: Colors.green.shade400,
            ),
            const SizedBox(width: 8),
            const Text(
              "Vehicle Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${e.key}: ",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${e.value}",
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text("Scan Again"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    _resumeScanning();
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

          // Back button
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
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Flash button
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
        ],
      ),
    );
  }

  Widget _dimOverlay(Size screenSize, double qrLeft, double qrTop, double qrSize) {
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