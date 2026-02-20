
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'services/history_service.dart';
import 'package:intl/intl.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (!_isScanning) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              setState(() {
                _isScanning = false;
              });
              debugPrint('Barcode found! ${barcode.rawValue}');
              
              // Save to History
              HistoryService.addHistoryItem(HistoryItem(
                data: barcode.rawValue!,
                timestamp: DateTime.now(),
                type: HistoryType.scan,
              ));

              _showResultDialog(context, barcode.rawValue!).then((_) {
                 setState(() {
                   _isScanning = true;
                 });
              });
              break; 
            }
          }
        },
      ),
    );
  }

  Future<void> _showResultDialog(BuildContext context, String data) async {
    // Parse VEVENT data
    String eventName = 'Unknown Event';
    String location = 'Unknown Location';
    String time = 'Unknown Time';
    
    if (data.contains('BEGIN:VEVENT')) {
      final lines = data.split('\n');
      for (var line in lines) {
        if (line.startsWith('SUMMARY:')) eventName = line.substring(8);
        if (line.startsWith('LOCATION:')) location = line.substring(9);
        if (line.startsWith('DTSTART:')) {
            // Basic parsing for YYYYMMDDTHHMMSS
            try {
                String raw = line.substring(8).trim();
                if (raw.length >= 15) {
                    DateTime dt = DateTime.parse(raw.replaceAll('T', '')); 
                    // Manual parsing because DateTime.parse expects specific format
                     int year = int.parse(raw.substring(0, 4));
                     int month = int.parse(raw.substring(4, 6));
                     int day = int.parse(raw.substring(6, 8));
                     int hour = int.parse(raw.substring(9, 11));
                     int minute = int.parse(raw.substring(11, 13));
                     dt = DateTime(year, month, day, hour, minute);
                     time = DateFormat('MMM d, y h:mm a').format(dt);
                }
            } catch (e) {
                time = line.substring(8);
            }
        }
      }
    } else {
        eventName = data; // Fallback
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Column(
                children: [
                   Icon(Icons.check_circle, color: Colors.white, size: 60),
                   SizedBox(height: 10),
                   Text(
                     'APPROVED',
                     style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                   ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   Text(
                     eventName,
                     textAlign: TextAlign.center,
                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 10),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.location_on, size: 16, color: Colors.grey),
                       const SizedBox(width: 4),
                       Text(location, style: const TextStyle(color: Colors.grey)),
                     ],
                   ),
                   const SizedBox(height: 5),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.access_time, size: 16, color: Colors.grey),
                       const SizedBox(width: 4),
                       Text(time, style: const TextStyle(color: Colors.grey)),
                     ],
                   ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
             children: [
                 TextButton(
                    onPressed: () => Navigator.pop(context), // Just close dialog = Cancel/Back
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                 ),
                 ElevatedButton(
                    onPressed: () => Navigator.pop(context), // Close to resume scanning
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Scan Again', style: TextStyle(color: Colors.white)),
                 ),
             ],
          )
        ],
      ),
    );
  }
}
